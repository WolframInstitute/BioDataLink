(* ::Package:: *)

(* ::Section:: *)
(*PackageExported*)
PackageExported[BioDatasetLoad];

(* ::Section:: *)
(*Usage Messages*)
BioDatasetLoad::usage = "BioDatasetLoad[File[path]] imports a local BioDataLink JSON expression dataset as a sparse matrix, metadata and provenance.";

(* ::Section:: *)
(*Function Definitions*)
Options[BioDatasetLoad] = {"MaxFileBytes" -> 10000000};

BioDatasetLoad[File[path_String], OptionsPattern[]] := Module[
    {limit = OptionValue["MaxFileBytes"], fullPath, data, result, bytes, stream, content, text},
    If[!(limit === Infinity || IntegerQ[limit] && limit > 0),
        Return[bioFailure["InvalidOption", "MaxFileBytes must be a positive integer or Infinity."]]];
    fullPath = ExpandFileName[path];
    If[!FileExistsQ[fullPath] || DirectoryQ[fullPath],
        Return[bioFailure["FileNotFound", "The local dataset file does not exist.", <|"SourceFile" -> fullPath|>]]];
    bytes = Quiet[Check[FileByteCount[fullPath], $Failed]];
    If[!IntegerQ[bytes],
        Return[bioFailure["FileReadFailed", "The local dataset file could not be read.", <|"SourceFile" -> fullPath|>]]];
    If[bytes > limit,
        Return[bioFailure["FileTooLarge", "The local file exceeds MaxFileBytes.", <|"FileBytes" -> bytes|>]]];
    stream = Quiet[Check[OpenRead[fullPath, BinaryFormat -> True], $Failed]];
    If[Head[stream] =!= InputStream,
        Return[bioFailure["FileReadFailed", "The local dataset file could not be read.", <|"SourceFile" -> fullPath|>]]];
    content = WithCleanup[
        Quiet[Check[If[limit === Infinity, ReadByteArray[stream], ReadByteArray[stream, limit + 1]], $Failed]],
        Close[stream]];
    If[content === EndOfFile, content = ByteArray[{}]];
    If[Head[content] =!= ByteArray,
        Return[bioFailure["FileReadFailed", "The local dataset file could not be read.", <|"SourceFile" -> fullPath|>]]];
    If[Length[content] > limit,
        Return[bioFailure["FileTooLarge", "The local file exceeds MaxFileBytes.", <|"FileBytes" -> Length[content]|>]]];
    text = Quiet[Check[ByteArrayToString[content, "UTF8"], $Failed]];
    If[!StringQ[text], Return[bioFailure["InvalidJSON", "The local file is not valid UTF-8 JSON."]]];
    If[!bioJSONNumericRangeQ[text],
        Return[bioFailure["UnsupportedNumericRange", "JSON numeric exponents must have absolute value at most 10000."]]];
    data = Quiet[Check[ImportByteArray[content, "RawJSON"], $Failed],
        {Import::jsonhintpos, Import::jsonhint, Import::jsonkeynstr, Import::jsonhintposandchar,
            Import::jsonnullinput, Import::nffil}];
    If[data === $Failed, Return[bioFailure["InvalidJSON", "The local file is not valid JSON."]]];
    result = bioValidateExpression[data];
    If[FailureQ[result], Return[result]];
    Join[result, <|"SourceFile" -> fullPath, "ContentHash" -> Hash[content, "SHA256", "HexString"]|>]
];
