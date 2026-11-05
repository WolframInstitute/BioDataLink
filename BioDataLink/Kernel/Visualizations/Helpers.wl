(* ::Package:: *)

PackageScoped[{bioVisualRealQ, bioVisualMatrixQ, bioVisualColors, bioVisualColorFunction,
    bioVisualLegend, bioDNAQ, bioWordGrid}];

bioVisualRealQ[x_] := NumericQ[x] && NumberQ[N[x]] && TrueQ[Im[N[x]] == 0] && TrueQ[Abs[x] < Infinity];
bioVisualMatrixQ[x_] := MatrixQ[x, bioVisualRealQ] && Length[x] > 0 && Last[Dimensions[x]] > 0;

(* Use the full annotation vocabulary, including annotations outside a selected embedding.
   Passing the same annotation association therefore preserves colors across subsets. *)
bioVisualColors[labels_List, specification_] := Module[{categories = Union[labels], palette},
    palette = RGBColor /@ {"#CC6677", "#332288", "#DDCC77", "#117733", "#88CCEE", "#882255", "#44AA99", "#999933", "#AA4499"};
    Which[
        specification === Automatic && Length[categories] <= Length[palette],
            AssociationThread[categories, Take[palette, Length[categories]]],
        AssociationQ[specification] && AllTrue[categories, KeyExistsQ[specification, #] &] &&
                AllTrue[Lookup[specification, categories], ColorQ], KeyTake[specification, categories],
        True, bioFailure["InvalidColors", "Supply a color association covering every category; Automatic supports at most nine categories."]
    ]
];
bioVisualColorFunction[specification_] := Module[{f = If[StringQ[specification], Quiet[Check[ColorData[specification], $Failed]], specification]},
    If[Quiet[Check[ColorQ[f[0.5]], False]], f,
        bioFailure["InvalidColorFunction", "ColorFunction must map values from zero to one to colors."]]
];
bioVisualLegend[graphic_, None, legend_] := graphic;
bioVisualLegend[graphic_, Automatic, legend_] := Legended[graphic, Placed[legend, Right]];
bioVisualLegend[graphic_, placement_Placed, legend_] := Legended[graphic, placement /. Placed[Automatic, p_] :> Placed[legend, p]];
bioVisualLegend[graphic_, specification_, legend_] := Legended[graphic, specification];

bioDNAQ[sequence_String] := StringMatchQ[ToUpperCase[sequence], RegularExpression["[ACGTRYSWKMBDHVN]+"]];
(* Ambiguity codes separate runs: words never bridge an unmeasured base. The most recent
   nucleotide determines the largest quadrant; A/T occupy the lower half, C/G the upper. *)
bioWordGrid[sequence_String, k_Integer] := Module[{n = 2^k, runs, points},
    runs = Select[StringCases[ToUpperCase[sequence], RegularExpression["[ACGT]+"]], StringLength[#] >= k &];
    If[runs === {}, Return[ConstantArray[0, {n, n}]]];
    points = Catenate[Function[run, With[{digits = Characters[run] /. {"A" -> 0, "C" -> 1, "G" -> 3, "T" -> 2}},
        Transpose[{ListCorrelate[2^Range[0, k - 1], Quotient[digits, 2]],
            ListCorrelate[2^Range[0, k - 1], Mod[digits, 2]]}]]] /@ runs];
    Transpose[BinCounts[points, {-0.5, n - 0.5, 1}, {-0.5, n - 0.5, 1}]]
];
