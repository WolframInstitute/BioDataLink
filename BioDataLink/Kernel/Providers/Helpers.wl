(* ::Package:: *)

PackageScoped[{bioProviderQuery, bioResolveAPIKey, bioCursorPosition, bioQueryCursor}];

$bioLastRequest = <||>;

bioUnsignedInteger[value_Integer] := If[value >= 0, value, $Failed];
bioUnsignedInteger[value_String] := If[StringLength[value] <= 20 &&
    StringMatchQ[value, DigitCharacter ..], FromDigits[value], $Failed];
bioUnsignedInteger[_] := $Failed;

bioResolveAPIKey[None] := None;
bioResolveAPIKey[{kind : "Environment" | "SystemCredential", name_String}] := Module[{key},
    If[StringTrim[name] === "", Return[bioFailure["InvalidOption", "The credential name must be nonempty."]]];
    key = Quiet[Check[If[kind === "Environment", Environment[name], SystemCredential[name]], $Failed]];
    If[StringQ[key] && StringTrim[key] =!= "", key,
        bioFailure["CredentialUnavailable", "The named credential must contain a nonempty API key string."]]
];
bioResolveAPIKey[_] := bioFailure["InvalidOption", "APIKey must be None or a named Environment or SystemCredential reference."];

bioQueryCursor[provider_, query_, position_] :=
    provider <> ":" <> Hash[query, "SHA256", "HexString"] <> ":" <> ToString[position];

bioCursorPosition[provider_, query_, Automatic] := If[provider === "GEO", 0, None];
bioCursorPosition[provider_, query_, cursor_String] := Module[{prefix, position},
    prefix = provider <> ":" <> Hash[query, "SHA256", "HexString"] <> ":";
    If[!StringStartsQ[cursor, prefix] || StringLength[cursor] > 8192,
        Return[bioFailure["InvalidCursor", "The cursor must belong to this provider and query."]]];
    position = StringDrop[cursor, StringLength[prefix]];
    If[provider === "GEO", position = bioUnsignedInteger[position]];
    If[position === $Failed || position === "",
        bioFailure["InvalidCursor", "The cursor is malformed."], position]
];
bioCursorPosition[_, _, _] := bioFailure["InvalidCursor", "Cursor must be Automatic or a returned cursor string."];

bioHTTPRead[request_, timeout_] := URLRead[request, {"StatusCode", "Headers", "BodyByteArray"},
    Authentication -> <||>, CookieFunction -> (Null &), FollowRedirects -> False,
    Interactive -> False, ProgressReporting -> False, VerifySecurityCertificates -> True,
    TimeConstraint -> timeout];

bioProviderRequest[provider_, operation_, parameters_, deadline_, interval_] := Module[
    {url, wait, remaining, request, response, status, body, text, data, retry, details},
    url = Switch[{provider, operation},
        {"BioStudies", "Search"}, "https://www.ebi.ac.uk/biostudies/api/v1/search",
        {"GEO", "Search"}, "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi",
        {"GEO", "Summary"}, "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi"];
    wait = Max[0, Lookup[$bioLastRequest, provider, 0] + interval - AbsoluteTime[]];
    If[AbsoluteTime[] + wait >= deadline, Return[bioFailure["Timeout", "The query time budget was exhausted."]]];
    If[wait > 0, Pause[wait]];
    remaining = deadline - AbsoluteTime[];
    request = HTTPRequest[url, Join[
        <|"Cookies" -> None, "Headers" -> {"Accept" -> "application/json"}|>,
        If[provider === "GEO", <|"Method" -> "POST", "Body" -> parameters|>,
            <|"Method" -> "GET", "Query" -> parameters|>]]];
    $bioLastRequest[provider] = AbsoluteTime[];
    response = Quiet[Check[bioHTTPRead[request, remaining], $Failed]];
    If[!AssociationQ[response], Return[bioFailure[
        If[AbsoluteTime[] >= deadline, "Timeout", "NetworkFailure"],
        "The provider request could not be completed.", <|"Provider" -> provider|>]]];
    status = Lookup[response, "StatusCode", None];
    If[!IntegerQ[status], Return[bioFailure["InvalidResponse", "The provider returned an invalid HTTP response."]]];
    details = <|"Provider" -> provider, "StatusCode" -> status|>;
    If[status === 429 || status === 503,
        retry = Cases[Lookup[response, "Headers", {}],
            (name_String -> value_String) /; ToLowerCase[name] === "retry-after" :> value];
        retry = If[retry === {}, $Failed, bioUnsignedInteger[First[retry]]];
        If[IntegerQ[retry], details["RetryAfter"] = retry];
        Return[bioFailure[If[status === 429, "RateLimited", "ServiceUnavailable"],
            "The provider cannot serve the request now; retry later.", details]]];
    If[300 <= status < 400, Return[bioFailure["RedirectRefused", "The provider requested a redirect.", details]]];
    If[MemberQ[{401, 403}, status], Return[bioFailure["AuthenticationFailed", "The provider did not authorize the request.", details]]];
    If[status =!= 200, Return[bioFailure["ProviderError", "The provider returned an unsuccessful response.", details]]];
    body = Lookup[response, "BodyByteArray", None];
    If[Head[body] =!= ByteArray, Return[bioFailure["InvalidResponse", "The provider response body is missing."]]];
    text = Quiet[Check[ByteArrayToString[body, "UTF8"], $Failed]];
    If[!StringQ[text] || !bioJSONNumericRangeQ[text],
        Return[bioFailure["InvalidResponse", "The provider response is not supported JSON."]]];
    data = Quiet[Check[ImportByteArray[body, "RawJSON"], $Failed]];
    If[AssociationQ[data], data, bioFailure["InvalidResponse", "The provider response is not a JSON object."]]
];

bioOptionalText[record_, key_] := With[{value = Lookup[record, key, Null]},
    If[StringQ[value] && StringTrim[value] =!= "", value, Missing["NotAvailable"]]];

bioOrganism[record_] := With[{value = Lookup[record, "taxon", Null]},
    If[MatchQ[value, {__String}], value, bioOptionalText[record, "taxon"]]];

bioQueryResult[provider_, query_, rows_, total_, exact_, next_] := <|
    "Records" -> Dataset[rows /. Null -> Missing["NotAvailable"]], "Total" -> total, "TotalIsExact" -> exact,
    "NextCursor" -> If[next === None, None, bioQueryCursor[provider, query, next]],
    "Provider" -> provider, "Query" -> query,
    "SourceURL" -> If[provider === "BioStudies", "https://www.ebi.ac.uk/biostudies/api/v1/search",
        "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi"],
    "RetrievedAt" -> DateString[Now, {"ISODate", "T", "Time", "Z"}, TimeZone -> 0]|>;

bioProviderQuery["BioStudies", query_, size_, cursor_, _, deadline_] := Module[
    {parameters, data, hits, total, exact, next, rows},
    parameters = {"query" -> query, "pagination" -> "cursor", "pageSize" -> ToString[size]};
    If[cursor =!= None, AppendTo[parameters, "cursor" -> cursor]];
    data = bioProviderRequest["BioStudies", "Search", parameters, deadline, 1.];
    If[FailureQ[data], Return[data]];
    {hits, exact, next} = Lookup[data, {"hits", "isTotalHitsExact", "nextCursor"}, None];
    total = bioUnsignedInteger[Lookup[data, "totalHits", None]];
    If[!ListQ[hits] || Length[hits] > size || !IntegerQ[total] ||
            !MemberQ[{True, False}, exact] || !(next === Null || StringQ[next] && next =!= "" &&
                StringLength[next] <= 8000 && next =!= cursor) ||
            !AllTrue[hits, AssociationQ[#] && StringQ[Lookup[#, "accession", None]] && #["accession"] =!= "" &],
        Return[bioFailure["InvalidResponse", "The BioStudies search response has an unsupported structure."]]];
    If[!DuplicateFreeQ[Lookup[hits, "accession"]],
        Return[bioFailure["InvalidResponse", "The BioStudies page contains duplicate accessions."]]];
    rows = Function[hit, <|"Provider" -> "BioStudies", "ID" -> hit["accession"],
        "Title" -> bioOptionalText[hit, "title"], "Description" -> bioOptionalText[hit, "content"],
        "Organism" -> Missing["NotAvailable"], "Citation" -> Missing["NotAvailable"],
        "SourceURL" -> URLBuild[<|"Scheme" -> "https", "Domain" -> "www.ebi.ac.uk",
            "Path" -> {"biostudies", "studies", hit["accession"]}|>],
        "NativeImportSupported" -> False, "ProviderMetadata" -> hit|>] /@ hits;
    bioQueryResult["BioStudies", query, rows, total, exact, If[next === Null, None, next]]
];

bioProviderQuery["GEO", query_, size_, offset_, key_, deadline_] := Module[
    {parameters, data, search, total, start, ids, summaries, rows, interval, term},
    interval = If[key === None, 0.34, 0.11];
    term = If[StringTrim[query] === "", "gse[ETYP]", "(" <> query <> ") AND gse[ETYP]"];
    parameters = {"db" -> "gds", "retmode" -> "json", "tool" -> "BioDataLink"};
    If[key =!= None, AppendTo[parameters, "api_key" -> key]];
    data = bioProviderRequest["GEO", "Search", Join[parameters,
        {"term" -> term, "retmax" -> ToString[size], "retstart" -> ToString[offset]}], deadline, interval];
    If[FailureQ[data], Return[data]];
    search = Lookup[data, "esearchresult", None];
    If[!AssociationQ[search] || KeyExistsQ[data, "error"] || KeyExistsQ[search, "ERROR"] ||
            KeyExistsQ[search, "errorlist"],
        Return[bioFailure["ProviderError", "GEO could not interpret the search query."]]];
    total = bioUnsignedInteger[Lookup[search, "count", None]];
    start = bioUnsignedInteger[Lookup[search, "retstart", None]];
    ids = Lookup[search, "idlist", None];
    If[!IntegerQ[total] || start =!= offset || !ListQ[ids] || Length[ids] > size ||
            !AllTrue[ids, StringQ[#] && StringMatchQ[#, DigitCharacter ..] &] || !DuplicateFreeQ[ids],
        Return[bioFailure["InvalidResponse", "The GEO search response has an unsupported structure."]]];
    If[(ids === {} && offset < total) || (ids =!= {} && offset + Length[ids] > total),
        Return[bioFailure["InvalidResponse", "The GEO result count does not match the returned page."]]];
    If[ids === {}, Return[bioQueryResult["GEO", query, {}, total, True, None]]];
    data = bioProviderRequest["GEO", "Summary", Append[parameters, "id" -> StringRiffle[ids, ","]], deadline, interval];
    If[FailureQ[data], Return[data]];
    summaries = Lookup[data, "result", None];
    If[!AssociationQ[summaries] || !AllTrue[ids, Function[id,
            AssociationQ[Lookup[summaries, id, None]] &&
            Lookup[summaries[id], "uid", None] === id &&
            StringQ[Lookup[summaries[id], "accession", None]] &&
            StringMatchQ[summaries[id]["accession"], "GSE" ~~ DigitCharacter ..]]],
        Return[bioFailure["InvalidResponse", "GEO did not return a Series summary for every search result."]]];
    rows = Function[id, With[{record = summaries[id]}, <|
        "Provider" -> "GEO", "ID" -> record["accession"],
        "Title" -> bioOptionalText[record, "title"], "Description" -> bioOptionalText[record, "summary"],
        "Organism" -> bioOrganism[record], "Citation" -> Missing["NotAvailable"],
        "SourceURL" -> URLBuild[<|"Scheme" -> "https", "Domain" -> "www.ncbi.nlm.nih.gov",
            "Path" -> {"geo", "query", "acc.cgi"}, "Query" -> {"acc" -> record["accession"]}|>],
        "NativeImportSupported" -> False, "ProviderMetadata" -> record|>]] /@ ids;
    If[!DuplicateFreeQ[Lookup[rows, "ID"]],
        Return[bioFailure["InvalidResponse", "The GEO page contains duplicate Series accessions."]]];
    bioQueryResult["GEO", query, rows, total, True,
        If[offset + Length[ids] < total, offset + Length[ids], None]]
];
