(* ::Package:: *)

PackageScoped[{bioDownloadURLQ, bioRetrieveArtifact}];

$bioCurlVersions = <||>;

bioDownloadURLQ[url_String] := Module[{parts},
    If[StringLength[url] > 16384 || StringContainsQ[url, RegularExpression["[\\x00-\\x20\\x7F\\\\]"]], Return[False]];
    parts = Quiet[Check[URLParse[url], $Failed]];
    AssociationQ[parts] && ToLowerCase[Lookup[parts, "Scheme", ""]] === "https" &&
        StringQ[Lookup[parts, "Domain", None]] && parts["Domain"] =!= "" &&
        Lookup[parts, "User", None] === None
];

bioDownloadPublicURL[url_String] := Quiet[Check[
    URLBuild[KeyDrop[URLParse[url], {"User", "Query", "Fragment"}]], Missing["NotAvailable"]]];

(* No shell is used. URLs travel through curl's standard input, not its command
   line. Always stop an owned child on timeout or an interrupted computation. *)
bioDownloadProcess[arguments_List, input_String, deadline_] := Module[{process = None, output, code},
    If[AbsoluteTime[] >= deadline, Return[bioFailure["Timeout", "The download time budget was exhausted."]]];
    WithCleanup[
        process = Quiet[Check[StartProcess[arguments], $Failed]],
        If[Head[process] =!= ProcessObject, Return[bioFailure["DependencyUnavailable", "The download backend could not be started."], Module]];
        If[input =!= "", WriteString[process, input]];
        Close[ProcessConnection[process, "StandardInput"]];
        While[ProcessStatus[process] === "Running" && AbsoluteTime[] < deadline, Pause[0.02]];
        If[ProcessStatus[process] === "Running",
            bioFailure["Timeout", "The download time budget was exhausted."],
            code = ProcessInformation[process, "ExitCode"];
            output = ReadString[process];
            <|"ExitCode" -> code, "StandardOutput" -> If[StringQ[output], output, ""]|>],
        If[Head[process] === ProcessObject && ProcessStatus[process] === "Running", Quiet[KillProcess[process]]]
    ]
];

bioCurlProgram[setting_, deadline_] := Module[{candidates, program, result, version, numbers, paths, signature, cached},
    If[AbsoluteTime[] >= deadline, Return[bioFailure["Timeout", "The download time budget was exhausted."]]];
    If[setting === Automatic,
        paths = Environment["PATH"];
        paths = If[StringQ[paths], StringSplit[paths, If[$OperatingSystem === "Windows", ";", ":"]], {}];
        candidates = DeleteDuplicates[FileNameJoin[{#, If[$OperatingSystem === "Windows", "curl.exe", "curl"]}] & /@ paths];
        Do[If[FileType[candidate] === File,
            result = bioCurlProgram[ExpandFileName[candidate], deadline];
            If[MatchQ[result, Failure["Timeout", _]], Return[result, Module]];
            If[StringQ[result], Return[result, Module]]], {candidate, candidates}];
        Return[bioFailure["DependencyUnavailable", "Downloads require curl 8.4 or later on PATH, or an absolute CurlExecutable path."]]];
    program = If[ExpandFileName[setting] === setting && FileType[setting] === File, setting, None];
    If[program === None, Return[bioFailure["DependencyUnavailable", "Downloads require curl 8.4 or later on PATH, or an absolute CurlExecutable path."]]];
    program = ExpandFileName[program];
    signature = Quiet[Check[{FileByteCount[program], FileDate[program]}, $Failed]];
    If[signature === $Failed, Return[bioFailure["DependencyUnavailable", "The curl executable could not be inspected."]]];
    cached = Lookup[$bioCurlVersions, program, None];
    If[AssociationQ[cached] && cached["Signature"] === signature,
        Return[If[FailureQ[cached["Result"]], cached["Result"], program]]];
    result = bioDownloadProcess[{program, "--disable", "--version"}, "", Min[deadline, AbsoluteTime[] + 5]];
    If[MatchQ[result, Failure["Timeout", _]], Return[result]];
    If[FailureQ[result] || result["ExitCode"] =!= 0,
        Return[bioFailure["DependencyUnavailable", "The curl download backend could not be verified."]]];
    version = StringCases[result["StandardOutput"], RegularExpression["(?m)^curl ([0-9]+\\.[0-9]+\\.[0-9]+)"] -> "$1"];
    If[version === {}, Return[bioFailure["DependencyUnavailable", "The download backend must be curl 8.4 or later."]]];
    numbers = FromDigits /@ StringSplit[First[version], "."];
    If[numbers . {1000000, 1000, 1} < 8004000,
        result = bioFailure["DependencyUnavailable", "curl 8.4 or later is required to bound transfers without a Content-Length header."];
        AssociateTo[$bioCurlVersions, program -> <|"Signature" -> signature, "Result" -> result|>]; Return[result]];
    AssociateTo[$bioCurlVersions, program -> <|"Signature" -> signature, "Result" -> First[version]|>];
    program
];

bioCurlTransfer[program_, url_, temporary_, limit_, deadline_] := Module[{arguments, result, parts, code, status},
    arguments = {program, "--disable", "--silent", "--globoff", "--no-netrc",
        "--disallow-username-in-url", "--proto", "=https", "--proto-redir", "=https",
        "--location", "--max-redirs", "5", "--fail", "--header", "Accept-Encoding: identity",
        "--max-filesize", ToString[limit + 1], "--max-time", ToString[N[Max[0.001, deadline - AbsoluteTime[]]], InputForm],
        "--output", temporary, "--write-out", "%{http_code}\n%{num_redirects}\n%{url_effective}", "--config", "-"};
    result = bioDownloadProcess[arguments,
        "url = \"" <> StringReplace[url, {"\\" -> "\\\\", "\"" -> "\\\""}] <> "\"\n", deadline];
    If[FailureQ[result], Return[result]];
    code = result["ExitCode"];
    parts = StringSplit[result["StandardOutput"], "\n", 3];
    status = If[Length[parts] >= 1 && StringMatchQ[First[parts], DigitCharacter ~~ DigitCharacter ~~ DigitCharacter], FromDigits[First[parts]], 0];
    If[code === 63, Return[bioFailure["FileTooLarge", "The transfer exceeds MaxFileBytes."]]];
    If[code === 28, Return[bioFailure["Timeout", "The download time budget was exhausted."]]];
    If[status === 429, Return[bioFailure["RateLimited", "The server rate-limited the download; retry later."]]];
    If[status >= 400, Return[bioFailure["HTTPError", "The server returned an unsuccessful HTTP response.", <|"StatusCode" -> status|>]]];
    If[code =!= 0, Return[bioFailure["DownloadFailed", "The HTTPS transfer failed.", <|"BackendExitCode" -> code|>]]];
    If[status =!= 200 || Length[parts] =!= 3 || !StringMatchQ[parts[[2]], DigitCharacter ..] || !bioDownloadURLQ[parts[[3]]],
        Return[bioFailure["HTTPError", "Expected a complete HTTP 200 response.", <|"StatusCode" -> status|>]]];
    <|"ResolvedURL" -> bioDownloadPublicURL[parts[[3]]], "RedirectCount" -> FromDigits[parts[[2]]]|>
];

bioRetrieveArtifact[url_, path_, limit_, expectedHash_, expectedBytes_, overwrite_, timeout_, setting_] := Module[
    {destination, directory, temporary, created = False, program, deadline, transfer, bytes, digest, moved, result},
    deadline = AbsoluteTime[] + timeout;
    destination = ExpandFileName[path];
    directory = DirectoryName[destination];
    If[!DirectoryQ[directory] || DirectoryQ[destination],
        Return[bioFailure["InvalidDestination", "The destination must be a file in an existing directory."]]];
    If[FileExistsQ[destination] && !overwrite,
        Return[bioFailure["DestinationExists", "The destination exists; choose another path or explicitly enable Overwrite."]]];
    program = bioCurlProgram[setting, deadline];
    If[FailureQ[program], Return[program]];
    temporary = FileNameJoin[{directory, ".biodatalink-" <> CreateUUID[] <> ".part"}];
    WithCleanup[
        created = StringQ[Quiet[Check[CreateFile[temporary], $Failed]]],
        If[!created, Return[bioFailure["FileWriteFailed", "The temporary download file could not be created."], Module]];
        result = TimeConstrained[
            transfer = bioCurlTransfer[program, url, temporary, limit, deadline];
            If[FailureQ[transfer], Return[transfer, Module]];
            bytes = Quiet[Check[FileByteCount[temporary], $Failed]];
            If[!IntegerQ[bytes], Return[bioFailure["FileWriteFailed", "The downloaded file could not be inspected."], Module]];
            If[bytes > limit, Return[bioFailure["FileTooLarge", "The transfer exceeds MaxFileBytes."], Module]];
            If[IntegerQ[expectedBytes] && bytes =!= expectedBytes,
                Return[bioFailure["SizeMismatch", "The downloaded byte count differs from ExpectedByteCount.", <|"ByteCount" -> bytes, "ExpectedByteCount" -> expectedBytes|>], Module]];
            digest = Quiet[Check[FileHash[temporary, "SHA256", "HexString"], $Failed]];
            If[!StringQ[digest], Return[bioFailure["FileReadFailed", "The downloaded file could not be hashed."], Module]];
            If[expectedHash =!= Automatic && digest =!= ToLowerCase[expectedHash],
                Return[bioFailure["ChecksumMismatch", "The downloaded SHA-256 differs from ExpectedSHA256.", <|"ContentHash" -> digest|>], Module]];
            If[AbsoluteTime[] >= deadline, Return[bioFailure["Timeout", "The download time budget was exhausted."], Module]];
            Join[<|"File" -> File[destination], "SourceURL" -> bioDownloadPublicURL[url],
                "RequestURLHash" -> Hash[ByteArray[ToCharacterCode[url, "UTF8"]], "SHA256", "HexString"],
                "ByteCount" -> bytes, "ContentHash" -> digest,
                "ExpectedSHA256" -> If[expectedHash === Automatic, Missing["NotProvided"], ToLowerCase[expectedHash]],
                "ExpectedByteCount" -> If[expectedBytes === Automatic, Missing["NotProvided"], expectedBytes],
                "Verification" -> If[expectedHash === Automatic, "ComputedSHA256Only", "VerifiedSHA256"],
                "RetrievedAt" -> DateString[Now, {"ISODate", "T", "Time", "Z"}, TimeZone -> 0]|>, transfer],
            Max[0.001, deadline - AbsoluteTime[]], bioFailure["Timeout", "The download time budget was exhausted."]];
        If[FailureQ[result], Return[result, Module]];
        If[AbsoluteTime[] >= deadline, Return[bioFailure["Timeout", "The download time budget was exhausted."], Module]];
        (* The verified final rename is outside the timer: an elapsed budget must
           not report failure after replacing a previously valid destination. *)
        moved = Quiet[Check[RenameFile[temporary, destination, OverwriteTarget -> overwrite], $Failed]];
        If[StringQ[moved], result, bioFailure["FileWriteFailed", "The verified file could not be moved into place."]],
        If[created && FileExistsQ[temporary], Quiet[DeleteFile[temporary]]]
    ]
];
