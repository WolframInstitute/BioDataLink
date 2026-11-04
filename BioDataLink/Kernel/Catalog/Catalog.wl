(* ::Package:: *)

(* ::Section:: *)
(*PackageExported*)
PackageExported[{BioDatasetInfo, BioDatasetSearch}];

(* ::Section:: *)
(*Usage Messages*)
BioDatasetInfo::usage = "BioDatasetInfo[{provider, id}] gives the bundled metadata for a biological dataset.";
BioDatasetSearch::usage = "BioDatasetSearch[] gives the bundled dataset catalog.\nBioDatasetSearch[query] finds dataset identifiers, titles and descriptions containing query.";

(* ::Section:: *)
(*Function Definitions*)
Options[BioDatasetSearch] = {"Provider" -> All, "Organism" -> All, "Limit" -> All};

BioDatasetSearch[query_String : "", OptionsPattern[]] := Module[
    {records, provider = OptionValue["Provider"], organism = OptionValue["Organism"],
        limit = OptionValue["Limit"], text = ToLowerCase[query]},
    If[!(provider === All || StringQ[provider]) || !(organism === All || StringQ[organism]) ||
            !(limit === All || IntegerQ[limit] && limit >= 0),
        Return[bioFailure["InvalidOption", "Provider and Organism must be strings or All; Limit must be a nonnegative integer or All."]]];
    records = bioCatalogRecords[];
    If[FailureQ[records], Return[records]];
    records = Select[records, Function[record,
        (provider === All || record["Provider"] === provider) &&
        (organism === All || record["Organism"] === organism) &&
        StringContainsQ[ToLowerCase[StringRiffle[Lookup[record, {"ID", "Title", "Description"}], " "]], text]
    ]];
    Dataset[If[limit === All, records, Take[records, UpTo[limit]]]]
];

BioDatasetInfo[id : {_String, _String}] := Module[{records},
    records = bioCatalogRecords[];
    If[FailureQ[records], Return[records]];
    SelectFirst[records, Lookup[#, {"Provider", "ID"}] === id &,
        bioFailure["UnknownDataset", "The dataset is not in the bundled catalog.", <|"DatasetID" -> id|>]]
];
