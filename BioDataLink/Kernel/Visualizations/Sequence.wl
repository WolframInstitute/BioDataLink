(* ::Package:: *)

PackageExported[{BioSequenceCompositionPlot, BioSequenceSkewPlot}];
BioSequenceCompositionPlot::usage = "BioSequenceCompositionPlot[sequence, k] plots counts of overlapping k-base DNA words on a chaos-game grid. Ambiguity codes break words; 1 <= k <= 8.";
BioSequenceSkewPlot::usage = "BioSequenceSkewPlot[sequence, window] plots (G-C)/(G+C) in complete nonoverlapping DNA windows at their one-based midpoint positions.";

Options[BioSequenceCompositionPlot] = Join[{"CountScaling" -> "Log", ColorFunction -> "BlueGreenYellow",
    DataReversed -> True, PlotLegends -> Automatic},
    FilterRules[Options[ArrayPlot], Except[ColorFunction | DataReversed | PlotLegends]]];
BioSequenceCompositionPlot[sequence_String, k_Integer, opts : OptionsPattern[]] := Module[{counts, scaling = OptionValue["CountScaling"]},
    If[!bioDNAQ[sequence] || !Between[k, {1, 8}],
        Return[bioFailure["InvalidSequence", "Use DNA with IUPAC ambiguity codes and a word length from 1 through 8."]]];
    If[!MemberQ[{"Log", "Linear"}, scaling], Return[bioFailure["InvalidOption", "CountScaling must be Log or Linear."]]];
    counts = bioWordGrid[sequence, k];
    If[Total[counts, 2] == 0, Return[bioFailure["NoCompleteWords", "There are no complete unambiguous words of this length."]]];
    ArrayPlot[If[scaling === "Log", Log[1. + counts], counts],
        FilterRules[Flatten[{opts, Options[BioSequenceCompositionPlot]}], Options[ArrayPlot]]]
];

Options[BioSequenceSkewPlot] = Join[{"BasePair" -> {"G", "C"}, Frame -> True, Axes -> False,
    FrameLabel -> {"position (bases)", "skew"}, PlotRange -> All},
    FilterRules[Options[ListLinePlot], Except[Frame | Axes | FrameLabel | PlotRange]]];
BioSequenceSkewPlot[sequence_String, window_Integer, opts : OptionsPattern[]] := Module[
    {pair = OptionValue["BasePair"], text = ToUpperCase[sequence], starts, points},
    If[!bioDNAQ[sequence] || window < 1 || window > StringLength[sequence],
        Return[bioFailure["InvalidSequence", "Use IUPAC DNA and a positive window no longer than the sequence."]]];
    If[!MatchQ[pair, {_String, _String}] || !DuplicateFreeQ[pair] || !AllTrue[pair, MemberQ[{"A", "C", "G", "T"}, #] &],
        Return[bioFailure["InvalidOption", "BasePair must contain two distinct uppercase DNA bases."]]];
    starts = Range[1, StringLength[text] - window + 1, window];
    points = Table[With[{part = StringTake[text, {start, start + window - 1}]},
        With[{a = StringCount[part, First[pair]], b = StringCount[part, Last[pair]]},
            {start + (window - 1)/2, If[a + b == 0, Missing["NoSelectedBases"], N[(a - b)/(a + b)]]}]], {start, starts}];
    If[AllTrue[points, MissingQ[Last[#]] &], Return[bioFailure["NoDefinedWindows", "No complete window contains either selected base."]]];
    ListLinePlot[points, FilterRules[Flatten[{opts, Options[BioSequenceSkewPlot]}], Options[ListLinePlot]]]
];
