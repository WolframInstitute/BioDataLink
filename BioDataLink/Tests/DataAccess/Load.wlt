Needs["WolframInstitute`BioDataLink`"];

$bioTestFixture = FileNameJoin[{PacletObject["WolframInstitute/BioDataLink"]["Location"],
    "Assets", "Examples", "toy-expression.json"}];

bioTestLoad[data_] := Module[{path = CreateTemporary[], result},
    Export[path, data, "RawJSON"];
    result = BioDatasetLoad[File[path]];
    DeleteFile[path];
    result
];

bioTestLoadNumber[token_String] := Module[{path = CreateTemporary[], result},
    Export[path, "{\"SchemaVersion\":1,\"Shape\":[1,1],\"Entries\":[[1,1," <> token <>
        "]],\"Cells\":[{\"ID\":\"cell\"}],\"Genes\":[{\"ID\":\"gene\"}]," <>
        "\"Normalization\":\"Synthetic\",\"Provenance\":{\"Source\":\"Synthetic\",\"Citation\":\"Test fixture\"}}", "String"];
    result = BioDatasetLoad[File[path]];
    DeleteFile[path];
    result
];

VerificationTest[
    With[{data = BioDatasetLoad[File[$bioTestFixture]]},
        {Normal[data["ExpressionMatrix"]], Lookup[Normal[data["CellMetadata"]], "ID"],
            Lookup[Normal[data["GeneMetadata"]], "ID"], data["Normalization"], data["Provenance"]["Synthetic"]}],
    {{{3, 0}, {0, 5}, {2, 1}}, {"cell-1", "cell-2", "cell-3"}, {"gene-A", "gene-B"}, "Counts", True},
    TestID -> "Load-HandCheckedCellByGeneMatrixAndIdentity"
]

VerificationTest[
    With[{data = BioDatasetLoad[File[$bioTestFixture]]},
        {Head[data["ExpressionMatrix"]], data["ContentHash"],
            data["SourceFile"] === ExpandFileName[$bioTestFixture]}],
    {SparseArray, "10f8e79c49486cf105708ed1329a19bdc66beedad01be0be717253becdeebf06", True},
    TestID -> "Load-SparseOutputAndContentProvenance"
]

VerificationTest[
    With[{base = Import[$bioTestFixture, "RawJSON"]},
        {Normal[bioTestLoad[Join[base, <|"Entries" -> {}|>]]["ExpressionMatrix"]],
            MatchQ[bioTestLoad[Join[base, <|"Entries" -> {{1, 1, 2}, {1, 1, 3}}|>]], Failure["DuplicateCoordinates", _]]}],
    {{{0, 0}, {0, 0}, {0, 0}}, True},
    TestID -> "Load-ImplicitZerosAndDuplicateCoordinates"
]

VerificationTest[
    With[{base = Import[$bioTestFixture, "RawJSON"]},
        FailureQ[bioTestLoad[Join[base, <|"Entries" -> #|>]]] & /@
            {{{0, 1, 2}}, {{1, 3, 2}}, {{1, 1, 0}}, {{1, 1, -2}}, {{1, 1, 1.5}}, {{1, 1, "2"}}, {{1, 1, Null}}}],
    ConstantArray[True, 7],
    TestID -> "Load-RejectInvalidCoordinatesCountsAndTypes"
]

VerificationTest[
    With[{base = Import[$bioTestFixture, "RawJSON"]},
        {FailureQ[bioTestLoad[Join[base, <|"SchemaVersion" -> 2|>]]],
            FailureQ[bioTestLoad[Join[base, <|"Shape" -> {2, 3}|>]]],
            FailureQ[bioTestLoad[Join[base, <|"Genes" -> {<|"ID" -> "x"|>, <|"ID" -> "x"|>}|>]]],
            FailureQ[bioTestLoad[Join[base, <|"Provenance" -> <||>|>]]],
            FailureQ[bioTestLoad[Join[base, <|"Normalization" -> ""|>]]]}],
    ConstantArray[True, 5],
    TestID -> "Load-RejectSchemaMetadataAndMissingSemantics"
]

VerificationTest[
    With[{base = Import[$bioTestFixture, "RawJSON"]},
        Normal[bioTestLoad[Join[base, <|"Normalization" -> "Centered", "Entries" -> {{1, 2, -0.5}}|>]]["ExpressionMatrix"]]],
    {{0, -0.5}, {0, 0}, {0, 0}},
    TestID -> "Load-DeclaredNormalizedValuesAllowSignedReals"
]

VerificationTest[
    {MatchQ[BioDatasetLoad[File[$bioTestFixture], "MaxFileBytes" -> 1], Failure["FileTooLarge", _]],
        FailureQ[BioDatasetLoad[File[$bioTestFixture], "MaxFileBytes" -> 0]],
        MatchQ[BioDatasetLoad[File[$bioTestFixture <> ".missing"]], Failure["FileNotFound", _]]},
    {True, True, True},
    TestID -> "Load-ExplicitSizeBudgetAndMissingFile"
]

VerificationTest[
    With[{bytes = FileByteCount[$bioTestFixture]},
        {AssociationQ[BioDatasetLoad[File[$bioTestFixture], "MaxFileBytes" -> bytes]],
            MatchQ[BioDatasetLoad[File[$bioTestFixture], "MaxFileBytes" -> bytes - 1], Failure["FileTooLarge", _]]}],
    {True, True},
    TestID -> "Load-ByteLimitIncludesExactBoundary"
]

VerificationTest[
    With[{base = Import[$bioTestFixture, "RawJSON"]},
        Normal[bioTestLoad[Join[base, <|"Entries" -> {{1, 1, 9007199254740993}}|>]]["ExpressionMatrix"]]],
    {{9007199254740993, 0}, {0, 0}, {0, 0}},
    TestID -> "Load-ExactCountsBeyondMachinePrecision"
]

VerificationTest[
    MatchQ[bioTestLoadNumber[#], Failure["UnsupportedNumericRange", _]] & /@
        {"1e999999999999", "1e10001", "1E-10001", "1e+00010001"},
    ConstantArray[True, 4],
    TestID -> "Load-RejectUnboundedNumericExponentsBeforeParsing"
]

VerificationTest[
    {bioTestLoadNumber["1e10000"]["ExpressionMatrix"][[1, 1]] === 10^10000,
        bioTestLoadNumber["1e-10000"]["ExpressionMatrix"][[1, 1]] === 10^-10000,
        bioTestLoadNumber["1e+00010000"]["ExpressionMatrix"][[1, 1]] === 10^10000,
        bioTestLoadNumber["1e-1"]["ExpressionMatrix"][[1, 1]] === 1/10},
    ConstantArray[True, 4],
    TestID -> "Load-NumericExponentBoundariesAndExactScientificNotation"
]

VerificationTest[
    With[{base = Import[$bioTestFixture, "RawJSON"],
            source = "Text e+999999999999, quoted \"1e10001\" and escaped \\1e-999999999999"},
        bioTestLoad[Join[base, <|"Provenance" -> <|"Source" -> source, "Citation" -> "Synthetic test"|>|>]]["Provenance"]["Source"] === source],
    True,
    TestID -> "Load-ExponentPreflightPreservesQuotedMetadata"
]

VerificationTest[
    Module[{path = CreateTemporary[], result},
        Export[path, "{broken JSON", "Text"];
        result = BioDatasetLoad[File[path]];
        DeleteFile[path];
        MatchQ[result, Failure["InvalidJSON", _]]
    ],
    True,
    TestID -> "Load-MalformedJSONIsAFailure"
]

VerificationTest[
    Module[{path = CreateTemporary[], result},
        result = BioDatasetLoad[File[path]];
        DeleteFile[path];
        MatchQ[result, Failure["InvalidJSON", _]]
    ],
    True,
    TestID -> "Load-EmptyFileIsInvalidJSON"
]

VerificationTest[
    Module[{saved = Options[BioDatasetLoad], result},
        SetOptions[BioDatasetLoad, "MaxFileBytes" -> 1];
        result = {FailureQ[BioDatasetLoad[File[$bioTestFixture]]],
            AssociationQ[BioDatasetLoad[File[$bioTestFixture], "MaxFileBytes" -> Infinity]]};
        Options[BioDatasetLoad] = saved;
        result
    ],
    {True, True},
    TestID -> "Load-SetOptionsAndExplicitOverride"
]
