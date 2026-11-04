(* ::Package:: *)

(* ::Section:: *)
(*PackageExported*)
PackageExported[{BioDataSourceInfo, BioDataSourceSearch, BioDataURL}];

(* ::Section:: *)
(*Usage Messages*)
BioDataSourceInfo::usage = "BioDataSourceInfo[prefix] gives source metadata, resource endpoints and provenance for a registered identifier namespace.";
BioDataSourceSearch::usage = "BioDataSourceSearch[] gives the bundled source directory.\nBioDataSourceSearch[query] finds registered prefixes, names and descriptions containing query.";
BioDataURL::usage = "BioDataURL[{prefix, id}] constructs an Identifiers.org resolver URL for an identifier in a registered namespace.";

(* ::Section:: *)
(*Function Definitions*)
Options[BioDataSourceSearch] = {"IncludeDeprecated" -> False, "Limit" -> All};

BioDataSourceSearch[query_String : "", OptionsPattern[]] := Module[
    {data, selected, limit = OptionValue["Limit"], deprecated = OptionValue["IncludeDeprecated"]},
    If[!MemberQ[{True, False}, deprecated] || !(limit === All || IntegerQ[limit] && limit >= 0),
        Return[bioFailure["InvalidOption", "IncludeDeprecated must be True or False; Limit must be a nonnegative integer or All."]]];
    data = bioSourceData[];
    If[FailureQ[data], Return[data]];
    selected = Pick[data["Summaries"], StringContainsQ[data["SearchText"], ToLowerCase[query]], True];
    If[!deprecated, selected = Select[selected, !TrueQ[#["Deprecated"]] &]];
    Dataset[If[limit === All, selected, Take[selected, UpTo[limit]]]]
];

BioDataSourceInfo[prefix_String] := Module[{data, position, record},
    data = bioSourceData[];
    If[FailureQ[data], Return[data]];
    position = Lookup[data["Index"], ToLowerCase[prefix], None];
    If[position === None,
        Return[bioFailure["UnknownSource", "The identifier namespace is not in the bundled registry.", <|"Prefix" -> prefix|>]]];
    record = data["Records"][[position]];
    Join[data["Summaries"][[position]], <|
        "Pattern" -> Lookup[record, "pattern", Missing["NotAvailable"]],
        "SampleID" -> Lookup[record, "sampleId", Missing["NotAvailable"]],
        "NamespaceEmbeddedInLUI" -> record["namespaceEmbeddedInLui"],
        "Resources" -> record["resources"], "RegistryRecord" -> record,
        "Provenance" -> data["Provenance"]|>]
];

BioDataURL[{prefix_String, id_String}] := Module[{source, accession = id, canonical},
    If[StringTrim[id] === "" || StringLength[id] > 4096 ||
            StringContainsQ[id, RegularExpression["[\\x00-\\x1F\\x7F]"]],
        Return[bioFailure["InvalidIdentifier", "The identifier must be nonempty, at most 4096 characters and contain no control characters."]]];
    source = BioDataSourceInfo[prefix];
    If[FailureQ[source], Return[source]];
    canonical = source["Prefix"];
    If[TrueQ[source["NamespaceEmbeddedInLUI"]],
        If[!StringContainsQ[accession, ":"],
            Return[bioFailure["EmbeddedIdentifierRequired",
                "This namespace requires the complete source identifier, including its original prefix and case."]]];
        If[!StringMatchQ[accession, RegularExpression["[^:\\s]+:.*\\S.*"]],
            Return[bioFailure["InvalidIdentifier", "The identifier must contain a local accession after its prefix."]]],
        accession = canonical <> ":" <> accession];
    (* The resolver requires literal accession colons and slashes (e.g. GO and DOI).
       Preserve their path syntax while encoding query, fragment and other characters. *)
    "https://identifiers.org/" <> If[TrueQ[source["NamespaceEmbeddedInLUI"]], canonical <> "/", ""] <>
        StringReplace[URLEncode[accession], {"%3A" -> ":", "%2F" -> "/"}]
];
