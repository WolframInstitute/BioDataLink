(* ::Package:: *)

(* ::Section:: *)
(*PackageExported*)
PackageExported[BioDatasetQuery];

(* ::Section:: *)
(*Usage Messages*)
BioDatasetQuery::usage = "BioDatasetQuery[provider, query] searches live public BioStudies or GEO study metadata and returns one page with provenance and a continuation cursor.";

(* ::Section:: *)
(*Function Definitions*)
Options[BioDatasetQuery] = {"PageSize" -> 20, "Cursor" -> Automatic, "TimeConstraint" -> 30, "APIKey" -> None};

BioDatasetQuery[provider_String, query_String, OptionsPattern[]] := Module[
    {size = OptionValue["PageSize"], cursor = OptionValue["Cursor"], timeout = OptionValue["TimeConstraint"],
        keySpec = OptionValue["APIKey"], key, position, deadline},
    If[!MemberQ[{"BioStudies", "GEO"}, provider],
        Return[bioFailure["UnsupportedProvider", "Live queries support BioStudies and GEO."]]];
    If[StringLength[query] > 4096 || !IntegerQ[size] || !(1 <= size <= 100) ||
            !MatchQ[timeout, _Integer | _Real | _Rational] || !TrueQ[0 < timeout <= 300],
        Return[bioFailure["InvalidOption", "Query must have at most 4096 characters, PageSize must be 1 to 100, and TimeConstraint must be positive and at most 300 seconds."]]];
    If[provider =!= "GEO" && keySpec =!= None,
        Return[bioFailure["UnsupportedCredential", "APIKey is supported only for GEO public API quotas."]]];
    position = bioCursorPosition[provider, query, cursor];
    If[FailureQ[position], Return[position]];
    deadline = AbsoluteTime[] + timeout;
    TimeConstrained[
        key = bioResolveAPIKey[keySpec];
        If[FailureQ[key], key, bioProviderQuery[provider, query, size, position, key, deadline]],
        timeout, bioFailure["Timeout", "The query time budget was exhausted."]]
];
