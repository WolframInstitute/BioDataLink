Needs["WolframInstitute`BioDataLink`"];

bioResponse[data_, status_ : 200, headers_ : {}] := <|"StatusCode" -> status,
    "Headers" -> headers, "BodyByteArray" -> ExportByteArray[data, "RawJSON"]|>;

$bioStudyPage = <|"totalHits" -> 2, "isTotalHitsExact" -> False, "nextCursor" -> "provider-token",
    "hits" -> {<|"accession" -> "E-EXAMPLE-1", "title" -> "Synthetic study one", "content" -> "CRISPR example",
        "author" -> "Synthetic author", "files" -> 2, "optional" -> Null|>,
        <|"accession" -> "S-EXAMPLE-2", "title" -> "Synthetic study two"|>}|>;

$bioGEOSearch = <|"esearchresult" -> <|"count" -> "3", "retstart" -> "0", "retmax" -> "2",
    "idlist" -> {"2002", "2001"}|>|>;
$bioGEOSummary = <|"result" -> <|"uids" -> {"2002", "2001"},
    "2001" -> <|"uid" -> "2001", "accession" -> "GSE1", "title" -> "Synthetic study one", "taxon" -> "Homo sapiens"|>,
    "2002" -> <|"uid" -> "2002", "accession" -> "GSE2", "title" -> "Synthetic study two",
        "summary" -> "Synthetic perturbation study", "taxon" -> {"Homo sapiens", "Mus musculus"},
        "pubmedids" -> {"123456"}|>|>|>;

SetAttributes[bioMockQuery, HoldFirst];
bioMockQuery[expression_, responses_List] := Module[{pending = responses, calls = {}, result},
    result = Block[{
        WolframInstitute`BioDataLink`Providers`Helpers`Private`$bioLastRequest = <||>,
        WolframInstitute`BioDataLink`Providers`Helpers`Private`bioHTTPRead = Function[{request, timeout},
            AppendTo[calls, <|"Request" -> request, "Timeout" -> timeout|>];
            If[pending === {}, Failure["UnexpectedRequest", <||>],
                With[{response = First[pending]}, pending = Rest[pending]; response]]]},
        expression];
    {result, calls}
];

VerificationTest[
    Module[{result, calls, rows},
        {result, calls} = bioMockQuery[BioDatasetQuery["BioStudies", "CRISPR", "PageSize" -> 2], {bioResponse[$bioStudyPage]}];
        rows = Normal[result["Records"]];
        {Lookup[rows, "ID"], result["Total"], result["TotalIsExact"], StringQ[result["NextCursor"]],
            MissingQ[rows[[1]]["Organism"]], MissingQ[rows[[1]]["ProviderMetadata"]["optional"]],
            rows[[1]]["ProviderMetadata"]["files"], Length[calls], StringEndsQ[result["RetrievedAt"], "Z"]}
    ],
    {{"E-EXAMPLE-1", "S-EXAMPLE-2"}, 2, False, True, True, True, 2, 1, True},
    TestID -> "Query-BioStudiesSourceIdentityEstimatedTotalAndProviderMetadata"
]

VerificationTest[
    Module[{first, result, calls},
        first = First[bioMockQuery[BioDatasetQuery["BioStudies", "CRISPR"], {bioResponse[$bioStudyPage]}]];
        {result, calls} = bioMockQuery[BioDatasetQuery["BioStudies", "CRISPR", "Cursor" -> first["NextCursor"]],
            {bioResponse[<|"totalHits" -> 2, "isTotalHitsExact" -> True, "hits" -> {}, "nextCursor" -> Null|>]}];
        {Normal[result["Records"]], result["NextCursor"],
            StringContainsQ[ToString[calls[[1]]["Request"]["URL"]], "cursor=provider-token"],
            MatchQ[First[bioMockQuery[BioDatasetQuery["BioStudies", "different", "Cursor" -> first["NextCursor"]], {}]],
                Failure["InvalidCursor", _]]}
    ],
    {{}, None, True, True},
    TestID -> "Query-CursorContinuationAndQueryBinding"
]

VerificationTest[
    Module[{result, calls, rows},
        {result, calls} = bioMockQuery[BioDatasetQuery["GEO", "CRISPR OR RNA", "PageSize" -> 2],
            {bioResponse[$bioGEOSearch], bioResponse[$bioGEOSummary]}];
        rows = Normal[result["Records"]];
        {Lookup[rows, "ID"], rows[[1]]["Organism"], rows[[1]]["ProviderMetadata"]["pubmedids"],
            result["Total"], result["TotalIsExact"], StringQ[result["NextCursor"]], Length[calls],
            ("term" /. calls[[1]]["Request"][[2, "Body"]]) === "(CRISPR OR RNA) AND gse[ETYP]",
            ("id" /. calls[[2]]["Request"][[2, "Body"]]) === "2002,2001"}
    ],
    {{"GSE2", "GSE1"}, {"Homo sapiens", "Mus musculus"}, {"123456"}, 3, True, True, 2, True, True},
    TestID -> "Query-GEOBatchesSummariesPreservesSearchOrderAndSpecies"
]

VerificationTest[
    Module[{result, calls},
        {result, calls} = bioMockQuery[BioDatasetQuery["GEO", "nothing"],
            {bioResponse[<|"esearchresult" -> <|"count" -> "0", "retstart" -> "0", "idlist" -> {}|>|>]}];
        {Normal[result["Records"]], result["Total"], result["NextCursor"], Length[calls]}
    ],
    {{}, 0, None, 1},
    TestID -> "Query-GEOEmptySearchSkipsSummaryRequest"
]

VerificationTest[
    Module[{first, result, calls, page},
        first = First[bioMockQuery[BioDatasetQuery["GEO", "q", "PageSize" -> 2],
            {bioResponse[$bioGEOSearch], bioResponse[$bioGEOSummary]}]];
        page = <|"esearchresult" -> <|"count" -> "3", "retstart" -> "2", "idlist" -> {"2001"}|>|>;
        {result, calls} = bioMockQuery[BioDatasetQuery["GEO", "q", "Cursor" -> first["NextCursor"]],
            {bioResponse[page], bioResponse[$bioGEOSummary]}];
        {Lookup[Normal[result["Records"]], "ID"], result["NextCursor"],
            "retstart" /. calls[[1]]["Request"][[2, "Body"]]}
    ],
    {{"GSE1"}, None, "2"},
    TestID -> "Query-GEOCursorUsesOffsetAndTerminatesAtReportedCount"
]

VerificationTest[
    Module[{result, calls},
        {result, calls} = bioMockQuery[{
            BioDatasetQuery["Other", "q"], BioDatasetQuery["BioStudies", "q", "PageSize" -> 101],
            BioDatasetQuery["BioStudies", "q", "TimeConstraint" -> Infinity],
            BioDatasetQuery["BioStudies", StringRepeat["x", 4097]],
            BioDatasetQuery["BioStudies", "q", "APIKey" -> {"Environment", "UNUSED"}],
            BioDatasetQuery["GEO", "q", "APIKey" -> "literal-secret"],
            BioDatasetQuery["GEO", "q", "Cursor" -> "https://example.org"]}, {}];
        {FailureQ /@ result, Length[calls], StringContainsQ[ToString[result, InputForm], "literal-secret"]}
    ],
    {ConstantArray[True, 7], 0, False},
    TestID -> "Query-InvalidOptionsAndUntrustedCursorNeverReachNetwork"
]

VerificationTest[
    Module[{result, calls, name = "BIODATALINK_TEST_" <> StringReplace[CreateUUID[], "-" -> ""]},
        SetEnvironment[name -> "synthetic-secret-123"];
        {result, calls} = WithCleanup[
            bioMockQuery[BioDatasetQuery["GEO", "q", "APIKey" -> {"Environment", name}],
                {bioResponse[$bioGEOSearch], bioResponse[$bioGEOSummary]}],
            SetEnvironment[name -> None]];
        {AssociationQ[result], AllTrue[calls, MemberQ[#["Request"][[2, "Body"]], "api_key" -> "synthetic-secret-123"] &],
            AllTrue[calls, !StringContainsQ[ToString[#["Request"]["URL"]], "synthetic-secret-123"] &],
            !StringContainsQ[ToString[result, InputForm], "synthetic-secret-123"]}
    ],
    {True, True, True, True},
    TestID -> "Query-NamedCredentialIsOnlyInPOSTBodyAndNeverReturned"
]

VerificationTest[
    With[{result = First[bioMockQuery[BioDatasetQuery["GEO", "q"],
            {Failure["Transport", <|"HTTPRequest" -> "hidden-secret"|>]}]]},
        {MatchQ[result, Failure["NetworkFailure", _]], !StringContainsQ[ToString[result, InputForm], "hidden-secret"]}],
    {True, True},
    TestID -> "Query-TransportFailuresAreSanitized"
]

VerificationTest[
    Module[{result, calls, name = "BIODATALINK_MISSING_" <> StringReplace[CreateUUID[], "-" -> ""]},
        {result, calls} = bioMockQuery[BioDatasetQuery["GEO", "q", "APIKey" -> {"Environment", name}], {}];
        {MatchQ[result, Failure["CredentialUnavailable", _]], Length[calls]}
    ],
    {True, 0},
    TestID -> "Query-MissingNamedCredentialDoesNotFallBackAnonymously"
]

VerificationTest[
    {MatchQ[First[bioMockQuery[BioDatasetQuery["BioStudies", "q"], {bioResponse[<||>, 302]}]], Failure["RedirectRefused", _]],
        With[{failure = First[bioMockQuery[BioDatasetQuery["BioStudies", "q"],
                {bioResponse[<|"echo" -> "hidden-secret"|>, 429, {"Retry-After" -> "10"}]}]]},
            {MatchQ[failure, Failure["RateLimited", _]], failure[[2]]["RetryAfter"],
                !StringContainsQ[ToString[failure, InputForm], "hidden-secret"]}]},
    {True, {True, 10, True}},
    TestID -> "Query-RedirectsAndRateLimitsDoNotExposeResponses"
]

VerificationTest[
    {MatchQ[First[bioMockQuery[BioDatasetQuery["BioStudies", "q"], {bioResponse[<||>]}]], Failure["InvalidResponse", _]],
        MatchQ[First[bioMockQuery[BioDatasetQuery["GEO", "q"],
            {bioResponse[$bioGEOSearch], bioResponse[<|"result" -> <||>|>]}]], Failure["InvalidResponse", _]]},
    {True, True},
    TestID -> "Query-MalformedAndIncompleteMetadataFailExplicitly"
]

VerificationTest[
    Module[{result, calls, saved = Options[BioDatasetQuery]},
        SetOptions[BioDatasetQuery, "PageSize" -> 1];
        {result, calls} = WithCleanup[
            bioMockQuery[BioDatasetQuery["BioStudies", "q", "PageSize" -> 2], {bioResponse[$bioStudyPage]}],
            Options[BioDatasetQuery] = saved];
        {AssociationQ[result], "pageSize" /. calls[[1]]["Request"][[2, "Query"]]}
    ],
    {True, "2"},
    TestID -> "Query-ExplicitOptionOverridesSetOptions"
]

VerificationTest[
    Module[{result, calls},
        {result, calls} = bioMockQuery[BioDatasetQuery["GEO", "q", "TimeConstraint" -> 0.01],
            {bioResponse[$bioGEOSearch], bioResponse[$bioGEOSummary]}];
        {MatchQ[result, Failure["Timeout", _]], Length[calls] <= 1}
    ],
    {True, True},
    TestID -> "Query-OperationBudgetIncludesRatePacing"
]
