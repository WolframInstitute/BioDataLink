Needs["WolframInstitute`BioDataLink`"];

(* Integrity of the bundled real-data examples. Expected values come from the
   source datasets and the selection rules in scripts/exampleData.wls. *)
$bioExamples = FileNameJoin[{PacletObject["WolframInstitute/BioDataLink"]["Location"], "Assets", "Examples"}];

(* Pin the parsed content, including fixed provenance, independently of a new
   retrieval time. The reader still reports the SHA-256 of the actual file. *)
pbmcContentHash[record_Association] := Hash[ExportString[
    Append[record, "Provenance" -> KeyDrop[record["Provenance"], "RetrievedAt"]],
    "RawJSON", "Compact" -> True], "SHA256", "HexString"];

VerificationTest[
    With[{data = BioDatasetLoad[File[FileNameJoin[{$bioExamples, "PBMC3k", "pbmc3k-subset.json"}]]]},
        {Dimensions[data["ExpressionMatrix"]], Length[data["ExpressionMatrix"]["NonzeroValues"]], data["Normalization"],
            KeyTake[data["Provenance"], {"License", "SourceSHA256", "Synthetic"}]}],
    {{2700, 513}, 386410, "Counts",
        <|"License" -> "CC BY 4.0", "SourceSHA256" -> "847d6ebd9a1ec9a768f2be7e40ca42cbfe75ebeb6d76a4c24167041699dc28b5", "Synthetic" -> False|>},
    TestID -> "ExampleData-PBMCShapeCountsAndSource"
]

VerificationTest[
    With[{genes = Normal[BioDatasetLoad[File[FileNameJoin[{$bioExamples, "PBMC3k", "pbmc3k-subset.json"}]]]["GeneMetadata"]]},
        {Count[Lookup[genes, #], True] & /@ {"HighlyVariable", "Marker", "Mitochondrial", "Background"},
            Sort[Pick[Lookup[genes, "Symbol"], Lookup[genes, "Mitochondrial"]]] === Sort[Select[Lookup[genes, "Symbol"], StringStartsQ[#, "MT-"] &]],
            OrderedQ[Lookup[genes, "SourceIndex"]], DuplicateFreeQ[Lookup[genes, "ID"]]}],
    {{300, 15, 13, 200}, True, True, True},
    TestID -> "ExampleData-PBMCGeneSelectionFlags"
]

VerificationTest[
    Flatten[Table[With[{record = Import[FileNameJoin[{$bioExamples, folder, "provenance.json"}], "RawJSON"]},
        (Hash[ByteArray[Import[FileNameJoin[{$bioExamples, folder, #["LocalFile"]}], {"GZIP", "Binary"}]], "SHA256", "HexString"] ===
            #["SHA256"]) & /@ record["Files"]], {folder, {"AdenylateKinase", "BorreliaB31", "Coronaviruses"}}]],
    ConstantArray[True, 10],
    TestID -> "ExampleData-CompressedCopiesMatchRecordedHashes"
]

VerificationTest[
    With[{table = Import[FileNameJoin[{$bioExamples, "LiverCircadian", "GSE11923-liver-subset.tsv.gz"}], "TSV", "MissingValuePattern" -> None]},
        {Dimensions[table], table[[1, {1, 2, 3, -1}]], AllTrue[Flatten[table[[2 ;;, 3 ;;]]], NumberQ[#] && # > 0 &]}],
    {{2047, 50}, {"ProbeID", "Symbol", "CT18", "CT65"}, True},
    TestID -> "ExampleData-LiverTimeSeriesShape"
]

VerificationTest[
    {pbmcContentHash[Import[FileNameJoin[{$bioExamples, "PBMC3k", "pbmc3k-subset.json"}], "RawJSON"]],
        Hash[ByteArray[Import[FileNameJoin[{$bioExamples, "LiverCircadian", "GSE11923-liver-subset.tsv.gz"}], {"GZIP", "Binary"}]], "SHA256", "HexString"]},
    {"6667b57fe2ebda253250d8fc799ec860d4076d9dde6143f735ae601b9e100f0a", "b34d6a75261238e0f02ff4807f438f9d0431247735ec37565cada2832431a408"},
    TestID -> "ExampleData-DerivedSubsetIntegrity"
]

VerificationTest[
    With[{record = Import[FileNameJoin[{$bioExamples, "PBMC3k", "pbmc3k-subset.json"}], "RawJSON"]},
        {MatchQ[Quiet[Check[DateObject[record["Provenance"]["RetrievedAt"]], $Failed]], _DateObject],
            pbmcContentHash[Append[record, "Provenance" -> Append[record["Provenance"], "RetrievedAt" -> "2027-01-01T00:00:00Z"]]]}],
    {True, "6667b57fe2ebda253250d8fc799ec860d4076d9dde6143f735ae601b9e100f0a"},
    TestID -> "ExampleData-PBMCIntegritySurvivesFreshRetrieval"
]

VerificationTest[
    With[{data = BioDatasetLoad[File[FileNameJoin[{$bioExamples, "PBMC3k", "pbmc3k-subset.json"}]]]},
        And @@ MapThread[LessEqual, {Normal[Total[data["ExpressionMatrix"], {2}]],
            Normal[data["CellMetadata"][All, "SourceTotalCounts"]]}]],
    True,
    TestID -> "ExampleData-SelectedCountsDoNotExceedSourceTotals"
]
