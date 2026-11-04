Needs["WolframInstitute`BioDataLink`"];

bioSourceFixture = <|"SchemaVersion" -> 1, "Provider" -> "Identifiers.org",
    "SourceSHA256" -> StringRepeat["a", 64], "RetrievedAt" -> "2026-11-04T00:00:00Z",
    "Records" -> {
        <|"id" -> 1, "prefix" -> "go", "name" -> "Gene Ontology", "description" -> "Synthetic ontology fixture",
            "deprecated" -> False, "namespaceEmbeddedInLui" -> True, "sampleId" -> "GO:0008150",
            "pattern" -> "^GO:[0-9]+$", "resources" -> {<|"protectedUrls" -> Null|>}|>,
        <|"id" -> 2, "prefix" -> "doi", "name" -> "Digital Object Identifier", "description" -> "Synthetic article fixture",
            "deprecated" -> False, "namespaceEmbeddedInLui" -> False, "sampleId" -> Null, "resources" -> {}|>,
        <|"id" -> 3, "prefix" -> "old", "name" -> "Old source", "description" -> "Synthetic retired ontology fixture",
            "deprecated" -> True, "namespaceEmbeddedInLui" -> False, "resources" -> {}|>
    }|>;

SetAttributes[bioWithSources, HoldRest];
bioWithSources[snapshot_, expression_] := Module[{file = CreateTemporary[]},
    WithCleanup[
        Export[file, snapshot, "RawJSON"],
        Block[{WolframInstitute`BioDataLink`Sources`Helpers`Private`$bioSourcesFile = file,
                WolframInstitute`BioDataLink`Sources`Helpers`Private`$bioSourcesCache = <||>}, expression],
        DeleteFile[file]]
];

VerificationTest[
    bioWithSources[bioSourceFixture,
        {Lookup[Normal[BioDataSourceSearch[]], "Prefix"],
            Lookup[Normal[BioDataSourceSearch["ONTOLOGY", "IncludeDeprecated" -> True]], "Prefix"],
            Lookup[Normal[BioDataSourceSearch["Limit" -> 1]], "Prefix"],
            Normal[BioDataSourceSearch["Limit" -> 0]], Normal[BioDataSourceSearch["no-such-entry"]]}],
    {{"go", "doi"}, {"go", "old"}, {"go"}, {}, {}},
    TestID -> "Sources-SearchFiltersAndNoMatches"
]

VerificationTest[
    bioWithSources[bioSourceFixture,
        With[{record = BioDataSourceInfo["GO"]},
            {Lookup[record, {"Prefix", "ResourceCount", "SampleID", "NamespaceEmbeddedInLUI"}],
                record["Resources"][[1]]["protectedUrls"], record["Provenance"]["SourceSHA256"]}]],
    {{"go", 1, "GO:0008150", True}, Missing["NotAvailable"], StringRepeat["a", 64]},
    TestID -> "Sources-InfoPreservesMetadataMissingnessAndProvenance"
]

VerificationTest[
    bioWithSources[bioSourceFixture,
        {BioDataURL[{"GO", "GO:0008150"}], BioDataURL[{"go", "GO:0008150"}],
            BioDataURL[{"doi", "10.123/a b?#%"}], BioDataURL[{"doi", "doi:example"}],
            BioDataURL[{"doi", FromCharacterCode[233]}]}],
    {"https://identifiers.org/go/GO:0008150", "https://identifiers.org/go/GO:0008150",
        "https://identifiers.org/doi:10.123/a%20b%3F%23%25", "https://identifiers.org/doi:doi:example",
        "https://identifiers.org/doi:%C3%A9"},
    TestID -> "Sources-ResolverEncodingAndEmbeddedNamespace"
]

VerificationTest[
    bioWithSources[bioSourceFixture,
        {MatchQ[BioDataSourceInfo["unknown"], Failure["UnknownSource", _]],
            FailureQ[BioDataURL[{"go", "GO:"}]], FailureQ[BioDataURL[{"go", ""}]],
            FailureQ[BioDataURL[{"go", "GO: "}]],
            MatchQ[BioDataURL[{"go", "0008150"}], Failure["EmbeddedIdentifierRequired", _]],
            FailureQ[BioDataURL[{"go", "a\nb"}]], FailureQ[BioDataURL[{"go", StringRepeat["1", 4097]}]],
            FailureQ[BioDataSourceSearch["Limit" -> -1]], FailureQ[BioDataSourceSearch["IncludeDeprecated" -> All]]}],
    ConstantArray[True, 9],
    TestID -> "Sources-UnknownSourceAndInvalidOptionsOrIdentifiers"
]

VerificationTest[
    Module[{first = First[bioSourceFixture["Records"]], variants},
        variants = {{KeyDrop[first, "prefix"]}, {first, first}, {Join[first, <|"deprecated" -> Null|>]},
            {Join[first, <|"resources" -> "not a list"|>]}};
        bioWithSources[Join[bioSourceFixture, <|"Records" -> #|>],
            MatchQ[BioDataSourceSearch[], Failure["InvalidSourceRegistry", _]]] & /@ variants],
    ConstantArray[True, 4],
    TestID -> "Sources-RejectMalformedAndDuplicateRegistryRecords"
]

VerificationTest[
    bioWithSources[bioSourceFixture,
        Module[{saved = Options[BioDataSourceSearch], result},
            WithCleanup[
                SetOptions[BioDataSourceSearch, "Limit" -> 1, "IncludeDeprecated" -> True],
                result = {Length[Normal[BioDataSourceSearch[]]],
                    Length[Normal[BioDataSourceSearch["Limit" -> All]]],
                    Length[Normal[BioDataSourceSearch["Limit" -> All, "IncludeDeprecated" -> False]]]},
                Options[BioDataSourceSearch] = saved];
            result]],
    {1, 3, 2},
    TestID -> "Sources-SetOptionsAndExplicitOverrides"
]

VerificationTest[
    Module[{file = CreateTemporary[], first, second},
        WithCleanup[
            Export[file, bioSourceFixture, "RawJSON"],
            Block[{WolframInstitute`BioDataLink`Sources`Helpers`Private`$bioSourcesFile = file,
                    WolframInstitute`BioDataLink`Sources`Helpers`Private`$bioSourcesCache = <||>},
                first = Normal[BioDataSourceSearch[]];
                DeleteFile[file];
                second = Normal[BioDataSourceSearch[]];
                first === second && Length[second] === 2],
            If[FileExistsQ[file], DeleteFile[file]]]],
    True,
    TestID -> "Sources-ValidatedSnapshotIsReusedWithoutDiskReads"
]

VerificationTest[
    With[{source = BioDataSourceInfo["go"], records = Normal[BioDataSourceSearch[]]},
        {source["Prefix"], BioDataURL[{"go", "GO:0008150"}],
            Length[records] > 700, AllTrue[records, !#["Deprecated"] &]}],
    {"go", "https://identifiers.org/go/GO:0008150", True, True},
    TestID -> "Sources-BundledRegistrySupportsOntologyLookup"
]

VerificationTest[
    {BioDataURL[{"mge", "mge:2"}], BioDataURL[{"vario", "VariO:0294"}], BioDataURL[{"eo", "PEO:0007404"}]},
    {"https://identifiers.org/mge/mge:2", "https://identifiers.org/vario/VariO:0294",
        "https://identifiers.org/eo/PEO:0007404"},
    TestID -> "Sources-EmbeddedIdentifiersPreserveLowerMixedAndAlternatePrefixes"
]
