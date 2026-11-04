Needs["WolframInstitute`BioDataLink`"];

$bioDownloadDigest = "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad";
SetAttributes[bioMockDownload, HoldFirst];
bioMockDownload[expression_, payload_String : "abc", exit_Integer : 0, status_Integer : 200] := Module[{calls = {}, result},
    result = Block[{
        WolframInstitute`BioDataLink`Downloads`Helpers`Private`bioCurlProgram = Function[{setting, deadline}, "/synthetic/curl"],
        WolframInstitute`BioDataLink`Downloads`Helpers`Private`bioDownloadProcess = Function[{arguments, input, deadline},
            AppendTo[calls, <|"Arguments" -> arguments, "Input" -> input|>];
            With[{position = First[First[Position[arguments, "--output"]]]},
                Export[arguments[[position + 1]], payload, "Text", CharacterEncoding -> "UTF8"]];
            <|"ExitCode" -> exit, "StandardOutput" -> ToString[status] <> "\n1\nhttps://example.org/file?token=synthetic-secret"|>]},
        expression];
    {result, calls}
];

VerificationTest[
    Module[{directory = CreateDirectory[], file, result, calls, answer},
        file = FileNameJoin[{directory, "result.csv"}];
        WithCleanup[
            {result, calls} = bioMockDownload[BioDatasetDownload["https://example.org/file?token=synthetic-secret", File[file],
                "MaxFileBytes" -> 3, "ExpectedByteCount" -> 3, "ExpectedSHA256" -> ToUpperCase[$bioDownloadDigest]]];
            answer = {Import[file, "Text"], Lookup[result, {"ByteCount", "ContentHash", "Verification", "SourceURL", "ResolvedURL", "RedirectCount"}],
                StringContainsQ[ToString[result, InputForm], "synthetic-secret"],
                StringContainsQ[ToString[calls[[1]]["Arguments"]], "synthetic-secret"],
                StringContainsQ[calls[[1]]["Input"], "synthetic-secret"],
                FileNames[".biodatalink-*", directory]};
            answer,
            DeleteDirectory[directory, DeleteContents -> True]]],
    {"abc", {3, $bioDownloadDigest, "VerifiedSHA256", "https://example.org/file", "https://example.org/file", 1}, False, False, True, {}},
    TestID -> "Download-VerifiedBytesProvenanceAndURLRedaction"
]

VerificationTest[
    Module[{directory = CreateDirectory[], file, result, answer},
        file = FileNameJoin[{directory, "result.bin"}];
        WithCleanup[
            result = First[bioMockDownload[BioDatasetDownload["https://example.org/file", File[file]]]];
            {result["Verification"], MissingQ[result["ExpectedSHA256"]], result["File"] === File[file]},
            DeleteDirectory[directory, DeleteContents -> True]]],
    {"ComputedSHA256Only", True, True},
    TestID -> "Download-ComputedHashDoesNotImplyUpstreamVerification"
]

VerificationTest[
    Module[{directory = CreateDirectory[], file, outcomes},
        file = FileNameJoin[{directory, "existing.bin"}];
        WithCleanup[
            Export[file, "existing", "Text"];
            outcomes = {
                First[bioMockDownload[BioDatasetDownload["https://example.org/file", File[file], "Overwrite" -> True, "ExpectedByteCount" -> 4]]],
                First[bioMockDownload[BioDatasetDownload["https://example.org/file", File[file], "Overwrite" -> True, "ExpectedSHA256" -> StringRepeat["0", 64]]]],
                First[bioMockDownload[BioDatasetDownload["https://example.org/file", File[file], "Overwrite" -> True, "MaxFileBytes" -> 2]]]
            };
            {outcomes[[All, 1]], Import[file, "Text"], FileNames[".biodatalink-*", directory]},
            DeleteDirectory[directory, DeleteContents -> True]]],
    {{"SizeMismatch", "ChecksumMismatch", "FileTooLarge"}, "existing", {}},
    TestID -> "Download-FailedVerificationPreservesExistingDestination"
]

VerificationTest[
    Module[{directory = CreateDirectory[], file, rejected, accepted},
        file = FileNameJoin[{directory, "existing.bin"}];
        WithCleanup[
            Export[file, "existing", "Text"];
            rejected = bioMockDownload[BioDatasetDownload["https://example.org/file", File[file]]];
            accepted = First[bioMockDownload[BioDatasetDownload["https://example.org/file", File[file], "Overwrite" -> True]]];
            {MatchQ[First[rejected], Failure["DestinationExists", _]], Length[Last[rejected]], AssociationQ[accepted], Import[file, "Text"]},
            DeleteDirectory[directory, DeleteContents -> True]]],
    {True, 0, True, "abc"},
    TestID -> "Download-OverwriteIsExplicitAndAppliedAfterVerification"
]

VerificationTest[
    Module[{directory = CreateDirectory[], file, outcomes},
        file = FileNameJoin[{directory, "result.bin"}];
        WithCleanup[
            outcomes = Function[pair, First[bioMockDownload[BioDatasetDownload["https://example.org/file", File[file]], "partial", First[pair], Last[pair]]]] /@
                {{63, 200}, {28, 200}, {22, 429}, {22, 503}, {60, 0}, {0, 206}};
            {outcomes[[All, 1]], FileExistsQ[file], FileNames[".biodatalink-*", directory]},
            DeleteDirectory[directory, DeleteContents -> True]]],
    {{"FileTooLarge", "Timeout", "RateLimited", "HTTPError", "DownloadFailed", "HTTPError"}, False, {}},
    TestID -> "Download-FailedAndPartialTransfersLeaveNoCompletedFile"
]

VerificationTest[
    Module[{directory = CreateDirectory[], file, result, calls},
        file = FileNameJoin[{directory, "result.bin"}];
        WithCleanup[
            {result, calls} = bioMockDownload[{
                BioDatasetDownload["http://example.org/file", File[file]],
                BioDatasetDownload["https://user:password@example.org/file", File[file]],
                BioDatasetDownload["https://example.org/with space", File[file]],
                BioDatasetDownload["https://example.org/file", File[file], "MaxFileBytes" -> Infinity],
                BioDatasetDownload["https://example.org/file", File[file], "ExpectedSHA256" -> "bad"],
                BioDatasetDownload["https://example.org/file", File[file], "TimeConstraint" -> 0],
                BioDatasetDownload["https://example.org/file", File[file], "MaxFileBytes" -> 2, "ExpectedByteCount" -> 3],
                BioDatasetDownload["https://example.org/file", File[FileNameJoin[{directory, "absent", "result.bin"}]]]
            }];
            {FailureQ /@ result, Length[calls], FileNames["*", directory]},
            DeleteDirectory[directory, DeleteContents -> True]]],
    {ConstantArray[True, 8], 0, {}},
    TestID -> "Download-CheapValidationPrecedesFilesystemAndNetworkWork"
]

VerificationTest[
    Module[{directory = CreateDirectory[], file, result, calls, saved = Options[BioDatasetDownload]},
        file = FileNameJoin[{directory, "result.bin"}];
        WithCleanup[
            SetOptions[BioDatasetDownload, "MaxFileBytes" -> 2];
            result = First[bioMockDownload[BioDatasetDownload["https://example.org/file", File[file]]]];
            calls = First[bioMockDownload[BioDatasetDownload["https://example.org/file", File[file], "MaxFileBytes" -> 3]]];
            {MatchQ[result, Failure["FileTooLarge", _]], AssociationQ[calls]},
            Options[BioDatasetDownload] = saved; DeleteDirectory[directory, DeleteContents -> True]]],
    {True, True},
    TestID -> "Download-SetOptionsAndExplicitOverride"
]

VerificationTest[
    Module[{directory = CreateDirectory[], result, calls, arguments},
        WithCleanup[
            {result, calls} = bioMockDownload[BioDatasetDownload["https://example.org/file", File[FileNameJoin[{directory, "result.bin"}]]]];
            arguments = calls[[1]]["Arguments"];
            {arguments[[2]], MemberQ[Partition[arguments, 2, 1], {"--proto", "=https"}],
                MemberQ[Partition[arguments, 2, 1], {"--proto-redir", "=https"}],
                MemberQ[arguments, "--disallow-username-in-url"], MemberQ[arguments, "--no-netrc"],
                FreeQ[arguments, "--insecure" | "--compressed"]},
            DeleteDirectory[directory, DeleteContents -> True]]],
    {"--disable", True, True, True, True, True},
    TestID -> "Download-TransportPreservesHTTPSAndRawArtifactBytes"
]

VerificationTest[
    Module[{file = CreateTemporary[], calls = 0, first, second, upgraded, cached},
        WithCleanup[
            Export[file, "curl 8.3.0", "Text"],
            Block[{WolframInstitute`BioDataLink`Downloads`Helpers`Private`$bioCurlVersions = <||>,
                    WolframInstitute`BioDataLink`Downloads`Helpers`Private`bioDownloadProcess = Function[{arguments, input, deadline},
                        calls++; <|"ExitCode" -> 0, "StandardOutput" -> Import[First[arguments], "Text"]|>]},
                first = WolframInstitute`BioDataLink`Downloads`Helpers`Private`bioCurlProgram[file, AbsoluteTime[] + 5];
                second = WolframInstitute`BioDataLink`Downloads`Helpers`Private`bioCurlProgram[file, AbsoluteTime[] + 5];
                Export[file, "curl 8.7.1 upgraded executable", "Text"];
                upgraded = WolframInstitute`BioDataLink`Downloads`Helpers`Private`bioCurlProgram[file, AbsoluteTime[] + 5];
                cached = WolframInstitute`BioDataLink`Downloads`Helpers`Private`bioCurlProgram[file, AbsoluteTime[] + 5];
                {FailureQ[first], FailureQ[second], upgraded === file, cached === file, calls}],
            DeleteFile[file]]],
    {True, True, True, True, 2},
    TestID -> "Download-BackendUpgradeInvalidatesVersionCache"
]
