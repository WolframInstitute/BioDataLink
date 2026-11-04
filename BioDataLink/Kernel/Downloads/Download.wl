(* ::Package:: *)

PackageExported[BioDatasetDownload];

BioDatasetDownload::usage = "BioDatasetDownload[url, File[path]] downloads an HTTPS artifact to a local file after verifying its size and optional SHA-256 checksum.";

Options[BioDatasetDownload] = {
    "MaxFileBytes" -> 100000000, "ExpectedSHA256" -> Automatic,
    "ExpectedByteCount" -> Automatic, "Overwrite" -> False,
    "TimeConstraint" -> 60, "CurlExecutable" -> Automatic
};

BioDatasetDownload[url_String, File[path_String], OptionsPattern[]] := Module[
    {limit = OptionValue["MaxFileBytes"], expectedHash = OptionValue["ExpectedSHA256"],
        expectedBytes = OptionValue["ExpectedByteCount"], overwrite = OptionValue["Overwrite"],
        timeout = OptionValue["TimeConstraint"], program = OptionValue["CurlExecutable"]},
    If[!IntegerQ[limit] || !(0 < limit < 2^63 - 1) ||
            !(expectedHash === Automatic || StringQ[expectedHash] &&
                StringMatchQ[expectedHash, RegularExpression["[0-9A-Fa-f]{64}"]]) ||
            !(expectedBytes === Automatic || IntegerQ[expectedBytes] && expectedBytes >= 0) ||
            !MemberQ[{True, False}, overwrite] ||
            !MatchQ[timeout, _Integer | _Real | _Rational] || !TrueQ[0 < timeout <= 3600] ||
            !(program === Automatic || StringQ[program] && StringTrim[program] =!= ""),
        Return[bioFailure["InvalidOption", "Download limits, integrity checks or backend options are invalid."]]];
    If[IntegerQ[expectedBytes] && expectedBytes > limit,
        Return[bioFailure["FileTooLarge", "ExpectedByteCount exceeds MaxFileBytes."]]];
    If[!bioDownloadURLQ[url],
        Return[bioFailure["InvalidURL", "Use an HTTPS URL without embedded user credentials, spaces or control characters."]]];
    If[path === "", Return[bioFailure["InvalidDestination", "Specify a local file path in an existing directory."]]];
    bioRetrieveArtifact[url, path, limit, expectedHash, expectedBytes, overwrite, timeout, program]
];
