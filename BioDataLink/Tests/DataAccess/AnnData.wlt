Needs["WolframInstitute`BioDataLink`"];

bioAnnDataExample = <|"Status" -> "OK", "Format" -> "AnnData", "Shape" -> {2, 3}, "MatrixValueType" -> "int64",
    "SourceShape" -> {3, 4}, "SourceLayer" -> "X", "SelectedCells" -> {3, 1}, "SelectedGenes" -> {4, 1, 2},
    "Entries" -> {{1, 1, 17}, {1, 2, 9007199254740993}, {2, 1, 5}, {2, 3, 2}},
    "CellMetadata" -> {<|"ID" -> "c2", "SourceIndex" -> 3, "Annotations" -> <|"cell_type" -> Null|>|>,
        <|"ID" -> "c0", "SourceIndex" -> 1, "Annotations" -> <||>|>},
    "GeneMetadata" -> {<|"ID" -> "g4", "SourceIndex" -> 4, "Annotations" -> <||>|>,
        <|"ID" -> "g1", "SourceIndex" -> 1, "Annotations" -> <||>|>,
        <|"ID" -> "g1", "SourceIndex" -> 2, "Annotations" -> <||>|>},
    "CellMetadataEncoding" -> <||>, "GeneMetadataEncoding" -> <||>,
    "OmittedStructures" -> {"raw", "layers/normalized", "uns"},
    "BackendVersion" -> <|"Python" -> "3.13.9", "h5py" -> "3.16.0", "NumPy" -> "2.5.4"|>,
    "SourceFileBytes" -> 64480, "SourceFileModifiedUnixNanoseconds" -> 1793800956446958753|>;

VerificationTest[
    Module[{result = WolframInstitute`BioDataLink`PackageScope`bioAnnDataProjection[bioAnnDataExample, "synthetic.h5ad", 100]},
        {Normal[result["ExpressionMatrix"]], Lookup[Normal[result["GeneMetadata"]], "ID"],
            Normal[result["CellMetadata"]][[1]]["Annotations"]["cell_type"], result["ContentHash"],
            result["Normalization"], KeyExistsQ[result, "SchemaVersion"]}],
    {{{17, 9007199254740993, 0}, {5, 0, 2}}, {"g4", "g1", "g1"},
        Missing["NotAvailable"], Missing["NotComputed"], Missing["NotSpecified"], False},
    TestID -> "AnnData-NativeProjectionPreservesSparseValuesDuplicateLabelsAndMissingMetadata"
]

VerificationTest[
    Module[{variants},
        variants = {
            Join[bioAnnDataExample, <|"Shape" -> {3, 2}|>],
            Join[bioAnnDataExample, <|"Entries" -> {{1, 1, 1}, {1, 1, 2}}|>],
            Join[bioAnnDataExample, <|"Entries" -> {{1, 4, 1}}|>],
            Join[bioAnnDataExample, <|"SelectedGenes" -> {1, 2, 3}|>],
            KeyDrop[bioAnnDataExample, "BackendVersion"],
            Join[bioAnnDataExample, <|"SourceShape" -> {1, 1}|>]
        };
        FailureQ[WolframInstitute`BioDataLink`PackageScope`bioAnnDataProjection[#, "synthetic.h5ad", 100]] & /@ variants],
    ConstantArray[True, 6],
    TestID -> "AnnData-BridgeContractRejectsMisalignmentInvalidEntriesAndDuplicateCoordinates"
]

VerificationTest[
    WolframInstitute`BioDataLink`PackageScope`bioAnnDataProjection[
        <|"Status" -> "Error", "Tag" -> "MissingMeasurement", "Message" -> "Selected values are nonfinite."|>, "synthetic.h5ad", 100],
    Failure["MissingMeasurement", <|"MessageTemplate" -> "Selected values are nonfinite."|>],
    TestID -> "AnnData-PreservesSpecificBackendFailure"
]

VerificationTest[
    Module[{result},
        result = WolframInstitute`BioDataLink`PackageScope`bioAnnDataProjection[
            Join[bioAnnDataExample, <|"MatrixValueType" -> "float64", "Entries" -> {{1, 1, 1/10^20}, {1, 2, 1/10^323}}|>],
            "synthetic.h5ad", 100];
        {Head[result["ExpressionMatrix"][[1, 1]]], Precision[result["ExpressionMatrix"][[1, 1]]],
            Head[result["ExpressionMatrix"][[1, 2]]], TrueQ[result["ExpressionMatrix"][[1, 2]] > 0]}],
    {Real, MachinePrecision, Real, True},
    TestID -> "AnnData-ScientificNotationStaysApproximateWithoutUnderflowToZero"
]

VerificationTest[
    Module[{saved = Options[BioDatasetLoad], result},
        WithCleanup[
            SetOptions[BioDatasetLoad, "Cells" -> {1}, "PythonExecutable" -> "/configured/python"],
            result = Block[{WolframInstitute`BioDataLink`PackageScope`bioLoadAnnData = Function[{path, settings}, settings]},
                {BioDatasetLoad[File["example.h5ad"], "Format" -> "AnnData"]["Cells"],
                    BioDatasetLoad[File["example.h5ad"], "Format" -> "AnnData", "Cells" -> {3, 2}]["Cells"],
                    BioDatasetLoad[File["example.h5ad"], "Format" -> "AnnData"]["PythonExecutable"]}],
            Options[BioDatasetLoad] = saved];
        result],
    {{1}, {3, 2}, "/configured/python"},
    TestID -> "AnnData-SetOptionsAndExplicitSelectionOverridesAreForwarded"
]

VerificationTest[
    {MatchQ[BioDatasetLoad[File["none"], "Format" -> "H5AD"], Failure["UnsupportedFormat", _]],
        MatchQ[BioDatasetLoad[File["none"], "Cells" -> {1}], Failure["UnsupportedOption", _]],
        MatchQ[BioDatasetLoad[File["none"], "Format" -> "AnnData", "Cells" -> {1, 1}], Failure["InvalidOption", _]],
        MatchQ[BioDatasetLoad[File["none"], "Format" -> "AnnData", "Genes" -> {}], Failure["InvalidOption", _]],
        MatchQ[BioDatasetLoad[File["none"], "Format" -> "AnnData", "Layer" -> {"Layers", "../X"}], Failure["InvalidOption", _]],
        MatchQ[BioDatasetLoad[File["none"], "Format" -> "AnnData", "MaxSelectedElements" -> 0], Failure["InvalidOption", _]],
        MatchQ[BioDatasetLoad[File["none"], "Format" -> "AnnData", "MaxTransferBytes" -> Infinity], Failure["InvalidOption", _]],
        MatchQ[BioDatasetLoad[File["none"], "Format" -> "AnnData", "TimeConstraint" -> Infinity], Failure["InvalidOption", _]]},
    ConstantArray[True, 8],
    TestID -> "AnnData-InvalidFormatsSelectionsAndBoundsFailBeforePython"
]

VerificationTest[
    {MatchQ[BioDatasetLoad[File["none"], "Format" -> "AnnData", "PythonExecutable" -> "python3"], Failure["PythonUnavailable", _]],
        MatchQ[BioDatasetLoad[File["none"], "Format" -> "AnnData", "PythonExecutable" -> FileNameJoin[{$TemporaryDirectory, CreateUUID[]}]],
            Failure["PythonUnavailable", _]]},
    {True, True},
    TestID -> "AnnData-NoInterpreterDiscoveryOrInstallation"
]
