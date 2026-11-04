(* ::Package:: *)

PackageScoped[{bioLoadAnnData, bioAnnDataProjection}];

$bioAnnDataBridge = FileNameJoin[{DirectoryName[$InputFileName, 3], "Assets", "Python", "h5ad_bridge.py"}];

bioAnnDataSelectionQ[value_] := value === All ||
    MatchQ[value, {__Integer?Positive}] && DuplicateFreeQ[value];

bioAbsolutePythonPathQ[path_String] := If[$OperatingSystem === "Windows",
    StringMatchQ[path, RegularExpression["(?:[A-Za-z]:[\\\\/]|\\\\\\\\).*"]], StringStartsQ[path, "/"]];

bioAnnDataProjection[data_Association, path_String, maximum_Integer] := Module[
    {shape, entries, cells, genes, positions, metadataQ, provenance, valueType},
    If[Lookup[data, "Status", None] === "Error",
        If[!AllTrue[Lookup[data, {"Tag", "Message"}, None], StringQ],
            Return[bioFailure["InvalidBridgeResult", "The H5AD reader returned an invalid error record."]]];
        Return[bioFailure[Lookup[data, "Tag", "InvalidAnnData"],
            Lookup[data, "Message", "The H5AD reader could not complete the projection."]]]];
    {shape, entries, cells, genes} = Lookup[data, {"Shape", "Entries", "CellMetadata", "GeneMetadata"}, None];
    valueType = Lookup[data, "MatrixValueType", None];
    metadataQ[rows_, length_] := ListQ[rows] && Length[rows] === length && AllTrue[rows,
        AssociationQ[#] && StringQ[Lookup[#, "ID", None]] &&
            MatchQ[Lookup[#, "SourceIndex", None], _Integer?Positive] &&
            AssociationQ[Lookup[#, "Annotations", None]] &];
    If[Lookup[data, "Status", None] =!= "OK" || Lookup[data, "Format", None] =!= "AnnData" ||
            !MatchQ[shape, {_Integer?Positive, _Integer?Positive}] || Times @@ shape > maximum,
        Return[bioFailure["InvalidBridgeResult", "The H5AD reader returned an invalid matrix shape."]]];
    If[!MemberQ[{"int8", "int16", "int32", "int64", "uint8", "uint16", "uint32", "uint64",
                "float16", "float32", "float64"}, valueType] ||
            !MatchQ[Lookup[data, "SourceShape", None], {_Integer?Positive, _Integer?Positive}] ||
            !MatchQ[Lookup[data, "OmittedStructures", None], {___String}] ||
            !AssociationQ[Lookup[data, "BackendVersion", None]] ||
            !AllTrue[Lookup[data["BackendVersion"], {"Python", "h5py", "NumPy"}, None], StringQ] ||
            !AllTrue[Lookup[data, {"CellMetadataEncoding", "GeneMetadataEncoding"}, None], AssociationQ] ||
            !IntegerQ[Lookup[data, "SourceFileBytes", None]] || data["SourceFileBytes"] < 0 ||
            !IntegerQ[Lookup[data, "SourceFileModifiedUnixNanoseconds", None]],
        Return[bioFailure["InvalidBridgeResult", "The H5AD reader returned incomplete source metadata."]]];
    If[!metadataQ[cells, shape[[1]]] || !metadataQ[genes, shape[[2]]] ||
            !DuplicateFreeQ[Lookup[cells, "SourceIndex"]] || !DuplicateFreeQ[Lookup[genes, "SourceIndex"]],
        Return[bioFailure["InvalidBridgeResult", "The H5AD reader returned misaligned axis metadata."]]];
    If[Max[Lookup[cells, "SourceIndex"]] > data["SourceShape"][[1]] ||
            Max[Lookup[genes, "SourceIndex"]] > data["SourceShape"][[2]],
        Return[bioFailure["InvalidBridgeResult", "The H5AD reader returned selections outside the source axes."]]];
    If[!ListQ[entries] || !AllTrue[entries, MatchQ[#, {_Integer, _Integer, _Integer | _Real | _Rational}] &&
            1 <= #[[1]] <= shape[[1]] && 1 <= #[[2]] <= shape[[2]] &&
            TrueQ[Abs[#[[3]]] < Infinity] && #[[3]] != 0 &],
        Return[bioFailure["InvalidBridgeResult", "The H5AD reader returned invalid sparse entries."]]];
    positions = If[entries === {}, {}, entries[[All, {1, 2}]]];
    If[!DuplicateFreeQ[positions],
        Return[bioFailure["DuplicateCoordinates", "The selected H5AD matrix contains duplicate coordinates."]]];
    If[Lookup[data, "SelectedCells", None] =!= Lookup[cells, "SourceIndex"] ||
            Lookup[data, "SelectedGenes", None] =!= Lookup[genes, "SourceIndex"],
        Return[bioFailure["InvalidBridgeResult", "The H5AD reader returned inconsistent selections."]]];
    If[StringStartsQ[valueType, "float"],
        entries = Function[entry, ReplacePart[entry, 3 ->
            If[Abs[Last[entry]] < $MinMachineNumber, N[Last[entry], $MachinePrecision], N[Last[entry]]]]] /@ entries];
    provenance = Join[<|"SourceFile" -> path, "ContentHash" -> Missing["NotComputed"],
        "Citation" -> Missing["NotImported"]|>, KeyTake[data,
        {"SourceShape", "SourceLayer", "MatrixValueType", "SelectedCells", "SelectedGenes", "BackendVersion",
            "SourceFileBytes", "SourceFileModifiedUnixNanoseconds"}]];
    Join[KeyDrop[data, {"Status", "Entries", "CellMetadata", "GeneMetadata"}], <|
        "ExpressionMatrix" -> SparseArray[(#[[{1, 2}]] -> Last[#] &) /@ entries, shape],
        "CellMetadata" -> Dataset[cells /. Null -> Missing["NotAvailable"]],
        "GeneMetadata" -> Dataset[genes /. Null -> Missing["NotAvailable"]],
        "Normalization" -> Missing["NotSpecified"], "SourceFile" -> path,
        "ContentHash" -> Missing["NotComputed"], "Provenance" -> provenance|>]
];

bioLoadAnnData[path_String, settings_Association] := Module[
    {python = settings["PythonExecutable"], fullPath, bytes, request, directory = None, requestFile,
        resultFile, process = None, result, content, text, data, maximum = settings["MaxSelectedElements"],
        transfer = settings["MaxTransferBytes"], timeout = settings["TimeConstraint"], layer = settings["Layer"]},
    If[!bioAnnDataSelectionQ[settings["Cells"]] || !bioAnnDataSelectionQ[settings["Genes"]] ||
            !(layer === "X" || MatchQ[layer, {"Layers", _String}] && StringLength[Last[layer]] > 0 &&
                !StringContainsQ[Last[layer], "/"] || layer === {"Raw", "X"}) ||
            !IntegerQ[maximum] || maximum <= 0 || !IntegerQ[transfer] || transfer <= 0 ||
            !MatchQ[timeout, _Integer | _Real | _Rational] || !TrueQ[0 < timeout <= 3600],
        Return[bioFailure["InvalidOption", "AnnData requires valid axis selections, a supported Layer, positive integer limits and TimeConstraint up to 3600 seconds."]]];
    If[python === Automatic, python = Environment["BIODATALINK_PYTHON"]];
    If[!StringQ[python] || StringTrim[python] === "" || !bioAbsolutePythonPathQ[python] ||
            !FileExistsQ[python] || DirectoryQ[python],
        Return[bioFailure["PythonUnavailable", "Set PythonExecutable to an existing absolute interpreter path or set BIODATALINK_PYTHON."]]];
    fullPath = ExpandFileName[path];
    If[!FileExistsQ[fullPath] || DirectoryQ[fullPath],
        Return[bioFailure["FileNotFound", "The local H5AD file does not exist."]]];
    bytes = Quiet[Check[FileByteCount[fullPath], $Failed]];
    If[!IntegerQ[bytes], Return[bioFailure["FileReadFailed", "The local H5AD file could not be read."]]];
    If[bytes > settings["MaxFileBytes"], Return[bioFailure["FileTooLarge", "The local file exceeds MaxFileBytes."]]];
    request = Join[KeyDrop[settings, {"PythonExecutable", "TimeConstraint"}], <|"SourceFile" -> fullPath|>] /.
        {All -> Null, Infinity -> Null};
    WithCleanup[
        directory = Quiet[Check[CreateDirectory[], $Failed]],
        If[!StringQ[directory] || !DirectoryQ[directory],
            Return[bioFailure["FileWriteFailed", "The temporary H5AD directory could not be created."], Module]];
        requestFile = FileNameJoin[{directory, "request.json"}];
        resultFile = FileNameJoin[{directory, "result.json"}];
        result = TimeConstrained[
            If[!StringQ[Quiet[Check[Export[requestFile, request, "RawJSON"], $Failed]]],
                Return[bioFailure["FileWriteFailed", "The temporary H5AD request could not be written."], Module]];
            WithCleanup[
                process = Quiet[Check[StartProcess[{python, $bioAnnDataBridge, requestFile, resultFile}], $Failed]],
                If[Head[process] =!= ProcessObject,
                    bioFailure["PythonUnavailable", "The configured Python interpreter could not be started."],
                    While[ProcessStatus[process] === "Running", Pause[0.02]];
                    If[ProcessInformation[process, "ExitCode"] =!= 0 || !FileExistsQ[resultFile],
                        bioFailure["BackendFailure", "The H5AD reader did not return a completed result."],
                        If[FileByteCount[resultFile] > transfer,
                            bioFailure["TransferTooLarge", "The H5AD result exceeds MaxTransferBytes."],
                            content = ReadByteArray[resultFile];
                            text = Quiet[Check[ByteArrayToString[content, "UTF8"], $Failed]];
                            data = If[StringQ[text] && bioJSONNumericRangeQ[text],
                                Quiet[Check[ImportByteArray[content, "RawJSON"], $Failed]], $Failed];
                            If[AssociationQ[data], bioAnnDataProjection[data, fullPath, maximum],
                                bioFailure["InvalidBridgeResult", "The H5AD reader returned invalid JSON."]]]]],
                If[Head[process] === ProcessObject && Quiet[ProcessStatus[process]] === "Running", Quiet[KillProcess[process]]]
            ],
            timeout, bioFailure["Timeout", "The H5AD projection exceeded TimeConstraint."]],
        If[StringQ[directory] && DirectoryQ[directory], Quiet[DeleteDirectory[directory, DeleteContents -> True]]]
    ];
    result
];
