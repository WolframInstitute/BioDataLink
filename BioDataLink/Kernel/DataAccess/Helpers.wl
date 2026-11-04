(* ::Package:: *)

PackageScoped[{bioValidateExpression, bioJSONNumericRangeQ}];

(* Remove quoted strings, including escaped quotes, before inspecting numeric exponents.
   Compare exponent text before conversion so even a very long exponent stays bounded. *)
bioJSONNumericRangeQ[text_String] := Module[{unquoted, exponents},
    unquoted = StringReplace[text, RegularExpression["\"(?:[^\"\\\\]|\\\\.)*\""] -> "\"\""];
    exponents = StringCases[unquoted, RegularExpression["[eE][+-]?[0-9]+"]];
    AllTrue[exponents, Function[exponent,
        With[{digits = StringReplace[exponent, RegularExpression["^[eE][+-]?0*"] -> ""]},
            StringLength[digits] < 5 || digits === "10000"]]]
];

bioMetadataQ[rows_, count_] := ListQ[rows] && Length[rows] === count &&
    AllTrue[rows, AssociationQ[#] && StringQ[Lookup[#, "ID", None]] && StringLength[#["ID"]] > 0 &] &&
    DuplicateFreeQ[Lookup[rows, "ID"]];

bioValidateExpression[data_] := Module[{shape, entries, cells, genes, normalization, provenance, positions},
    If[!AssociationQ[data] || Lookup[data, "SchemaVersion", None] =!= 1,
        Return[bioFailure["InvalidSchema", "Expected a BioDataLink JSON object with SchemaVersion 1."]]];
    {shape, entries, cells, genes, normalization, provenance} = Lookup[data,
        {"Shape", "Entries", "Cells", "Genes", "Normalization", "Provenance"}, None];
    If[!MatchQ[shape, {_Integer?Positive, _Integer?Positive}],
        Return[bioFailure["InvalidShape", "Shape must contain positive cell and gene counts."]]];
    If[!bioMetadataQ[cells, First[shape]] || !bioMetadataQ[genes, Last[shape]],
        Return[bioFailure["InvalidMetadata", "Cells and Genes must match Shape and have unique nonempty string IDs."]]];
    If[!StringQ[normalization] || StringTrim[normalization] === "" ||
            !AssociationQ[provenance] || !AllTrue[Lookup[provenance, {"Source", "Citation"}, None],
                StringQ[#] && StringTrim[#] =!= "" &],
        Return[bioFailure["InvalidProvenance", "Normalization and provenance Source and Citation must be nonempty strings."]]];
    If[!ListQ[entries] || !AllTrue[entries, MatchQ[#, {_Integer, _Integer, _Integer | _Real | _Rational}] &&
            1 <= #[[1]] <= shape[[1]] && 1 <= #[[2]] <= shape[[2]] &&
            TrueQ[Abs[#[[3]]] < Infinity] && #[[3]] != 0 &],
        Return[bioFailure["InvalidEntries", "Entries must be nonzero finite values at valid one-based cell and gene coordinates."]]];
    positions = If[entries === {}, {}, entries[[All, {1, 2}]]];
    If[!DuplicateFreeQ[positions],
        Return[bioFailure["DuplicateCoordinates", "Sparse entry coordinates must be unique."]]];
    If[normalization === "Counts" && !AllTrue[entries, IntegerQ[Last[#]] && Last[#] > 0 &],
        Return[bioFailure["InvalidCounts", "Counts must be nonnegative integers; omit zero entries."]]];
    <|"SchemaVersion" -> 1,
        "ExpressionMatrix" -> SparseArray[(#[[{1, 2}]] -> Last[#] &) /@ entries, shape],
        "CellMetadata" -> Dataset[cells], "GeneMetadata" -> Dataset[genes],
        "Normalization" -> normalization, "Provenance" -> provenance|>
];
