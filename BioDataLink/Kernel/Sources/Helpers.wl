(* ::Package:: *)

PackageScoped[{bioSourceData, bioSourceSummary}];

$bioSourcesFile = FileNameJoin[{DirectoryName[$InputFileName, 3], "Assets", "Sources", "identifiers.json"}];
$bioSourcesCache = <||>;

bioSourceRecordQ[record_] := AssociationQ[record] &&
    AllTrue[Lookup[record, {"prefix", "name", "description"}, None], StringQ] &&
    StringMatchQ[record["prefix"], RegularExpression["[a-z0-9][a-z0-9._-]*"]] &&
    IntegerQ[Lookup[record, "id", None]] && record["id"] > 0 &&
    MemberQ[{True, False}, Lookup[record, "deprecated", None]] &&
    MemberQ[{True, False}, Lookup[record, "namespaceEmbeddedInLui", None]] &&
    MatchQ[Lookup[record, "resources", None], {___Association}];

bioSourceSummary[record_Association] := <|
    "Prefix" -> record["prefix"], "Name" -> record["name"],
    "Description" -> record["description"], "Deprecated" -> record["deprecated"],
    "ResourceCount" -> Length[record["resources"]]|>;

(* Bundled snapshots are immutable for a kernel session. Cache only a validated
   success, keyed by file path; build search text and identifier indexes once. *)
bioSourceData[] := Module[{cached, snapshot, records, data},
    cached = Lookup[$bioSourcesCache, $bioSourcesFile, None];
    If[AssociationQ[cached], Return[cached]];
    snapshot = Quiet[Check[Import[$bioSourcesFile, "RawJSON"], $Failed]];
    If[!AssociationQ[snapshot] || Lookup[snapshot, "SchemaVersion", None] =!= 1 ||
            Lookup[snapshot, "Provider", None] =!= "Identifiers.org" ||
            !MatchQ[Lookup[snapshot, "Records", None], {__Association}] ||
            !StringQ[Lookup[snapshot, "SourceSHA256", None]] ||
            !StringMatchQ[snapshot["SourceSHA256"], RegularExpression["[0-9a-f]{64}"]],
        Return[bioFailure["InvalidSourceRegistry", "The bundled source registry could not be read."]]];
    records = snapshot["Records"];
    If[!AllTrue[records, bioSourceRecordQ] ||
            !DuplicateFreeQ[Lookup[records, "prefix"]] || !DuplicateFreeQ[Lookup[records, "id"]],
        Return[bioFailure["InvalidSourceRegistry", "The bundled source registry contains malformed or duplicate records."]]];
    records = records /. Null -> Missing["NotAvailable"];
    data = <|"Records" -> records,
        "Index" -> AssociationThread[Lookup[records, "prefix"], Range[Length[records]]],
        "Summaries" -> (bioSourceSummary /@ records),
        "SearchText" -> (ToLowerCase[StringRiffle[Lookup[#, {"prefix", "name", "description"}], " "]] & /@ records),
        "Provenance" -> KeyDrop[snapshot, "Records"]|>;
    AssociateTo[$bioSourcesCache, $bioSourcesFile -> data];
    data
];
