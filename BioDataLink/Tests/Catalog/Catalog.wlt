Needs["WolframInstitute`BioDataLink`"];

bioTestCatalog[snapshot_] := Module[{file = CreateTemporary[], result},
    Export[file, snapshot, "RawJSON"];
    result = Block[{WolframInstitute`BioDataLink`Catalog`Helpers`Private`$bioCatalogFile = file},
        BioDatasetSearch[]];
    DeleteFile[file];
    result
];

VerificationTest[
    With[{record = BioDatasetInfo[{"Pertpy", "norman_2019"}]},
        Lookup[record, {"Provider", "ID", "SourceRevision", "NativeImportSupported"}]],
    {"Pertpy", "norman_2019", "40dfeb6a5a50ef557d0d57baaea4aa33e6cbcf82", False},
    TestID -> "Catalog-PinnedNormanRecord"
]

VerificationTest[
    With[{rows = Normal[BioDatasetSearch[]]},
        {Length[rows], DuplicateFreeQ[Lookup[rows, "ID"]],
            AllTrue[rows, MissingQ[#["Organism"]] &]}],
    {55, True, True},
    TestID -> "Catalog-SnapshotIdentityAndUnknownOrganisms"
]

VerificationTest[
    {Length[Normal[BioDatasetSearch["CRISPR"]]] > 0,
        Normal[BioDatasetSearch["CRISPR"]] === Normal[BioDatasetSearch["crispr"]],
        Lookup[Normal[BioDatasetSearch["norman_2019"]], "ID"]},
    {True, True, {"norman_2019", "norman_2019_raw"}},
    TestID -> "Catalog-SearchCaseAndIdentifier"
]

VerificationTest[
    {Normal[BioDatasetSearch["no-such-record-1234"]],
        Normal[BioDatasetSearch["Provider" -> "GEO"]],
        Normal[BioDatasetSearch["Organism" -> "Homo sapiens"]],
        Normal[BioDatasetSearch["Limit" -> 0]],
        Length[Normal[BioDatasetSearch["Limit" -> 2]]]},
    {{}, {}, {}, {}, 2},
    TestID -> "Catalog-FilterAndLimitBoundaries"
]

VerificationTest[
    {MatchQ[BioDatasetInfo[{"Pertpy", "unknown"}], Failure["UnknownDataset", _]],
        FailureQ[BioDatasetSearch["Limit" -> -1]],
        FailureQ[BioDatasetSearch["Provider" -> 1]]},
    {True, True, True},
    TestID -> "Catalog-UnknownRecordAndInvalidOptions"
]

VerificationTest[
    Module[{saved = Options[BioDatasetSearch], result},
        SetOptions[BioDatasetSearch, "Limit" -> 1];
        result = {Length[Normal[BioDatasetSearch[]]], Length[Normal[BioDatasetSearch["Limit" -> 3]]]};
        Options[BioDatasetSearch] = saved;
        result
    ],
    {1, 3},
    TestID -> "Catalog-SetOptionsAndExplicitOverride"
]

VerificationTest[
    Module[{snapshot, first, variants},
        snapshot = Import[FileNameJoin[{PacletObject["WolframInstitute/BioDataLink"]["Location"],
            "Assets", "Catalog", "pertpy.json"}], "RawJSON"];
        first = First[snapshot["Records"]];
        variants = {
            {KeyDrop[first, "Title"]},
            {first, first},
            {Join[first, <|"SourceRevision" -> StringRepeat["0", 40]|>]}
        };
        MatchQ[bioTestCatalog[Join[snapshot, <|"Records" -> #|>]], Failure["InvalidCatalog", _]] & /@ variants
    ],
    {True, True, True},
    TestID -> "Catalog-RejectMalformedDuplicateAndRevisionMismatch"
]
