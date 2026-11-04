(* ::Package:: *)

PackageScoped[{bioCatalogRecords, bioFailure}];

bioFailure[tag_String, message_String, details_Association : <||>] :=
    Failure[tag, Join[<|"MessageTemplate" -> message|>, details]];

$bioCatalogFile = FileNameJoin[{DirectoryName[$InputFileName, 3], "Assets", "Catalog", "pertpy.json"}];

bioCatalogRecordQ[record_, revision_] := AssociationQ[record] &&
    AllTrue[Lookup[record, {"Provider", "ID", "Title", "Description", "DocumentationURL", "SourceURL"}, None],
        StringQ[#] && StringTrim[#] =!= "" &] &&
    Lookup[record, "SourceRevision", None] === revision &&
    AllTrue[Lookup[record, {"Organism", "Citation"}, None], # === Null || StringQ[#] &] &&
    MatchQ[Lookup[record, "DownloadURLs", None], {__String}] &&
    AllTrue[record["DownloadURLs"], StringStartsQ[#, "https://"] &] &&
    MemberQ[{True, False}, Lookup[record, "NativeImportSupported", None]];

bioCatalogRecords[] := Module[{snapshot, revision, records},
    snapshot = Quiet[Check[Import[$bioCatalogFile, "RawJSON"], $Failed], {Import::nffil, Import::jsonhintpos}];
    If[!AssociationQ[snapshot] || Lookup[snapshot, "SchemaVersion", None] =!= 1 ||
            !MatchQ[Lookup[snapshot, "Records", None], {__Association}],
        Return[bioFailure["InvalidCatalog", "The bundled catalog could not be read."]]];
    revision = Lookup[snapshot, "SourceRevision", None];
    records = snapshot["Records"];
    If[!StringQ[revision] || !StringMatchQ[revision, RegularExpression["[0-9a-f]{40}"]] ||
            !AllTrue[records, bioCatalogRecordQ[#, revision] &] ||
            !DuplicateFreeQ[Lookup[#, {"Provider", "ID"}] & /@ records],
        Return[bioFailure["InvalidCatalog", "The bundled catalog has malformed, duplicate or inconsistent records."]]];
    records /. Null -> Missing["NotAvailable"]
];
