(* ::Package:: *)

PackageExported[BioExpressionDotPlot];
BioExpressionDotPlot::usage = "BioExpressionDotPlot[matrix, groups, features] plots group mean expression by color and the fraction above a detection threshold by dot area. Rows of matrix are observations and columns correspond to features.";

Options[BioExpressionDotPlot] = Join[{
    "DetectionThreshold" -> 0, "ColorScaling" -> "Global", ColorFunction -> "BlueGreenYellow",
    PlotLegends -> Automatic, Frame -> True, FrameTicks -> Automatic, Axes -> False, PlotRange -> All},
    FilterRules[Options[Graphics], Except[Frame | FrameTicks | Axes | PlotRange]]];

BioExpressionDotPlot[matrix_, groups_List, features_List, opts : OptionsPattern[]] := Module[
    {threshold = OptionValue["DetectionThreshold"], scaling = OptionValue["ColorScaling"], categories, indices, means, fractions,
        relative, range, f, ticks, graphic, legend},
    If[!bioVisualMatrixQ[matrix] || Min[matrix] < 0,
        Return[bioFailure["InvalidExpression", "Expression must be a nonempty finite nonnegative matrix; missing measurements must not be encoded as zeros."]]];
    If[Length[groups] =!= Length[matrix] || Length[features] =!= Last[Dimensions[matrix]] ||
            !AllTrue[Join[groups, features], StringQ] || !DuplicateFreeQ[features],
        Return[bioFailure["InvalidLabels", "Supply one string group per row and one unique string feature label per column."]]];
    If[!bioVisualRealQ[threshold] || threshold < 0 || !MemberQ[{"Global", "PerFeature"}, scaling],
        Return[bioFailure["InvalidOption", "DetectionThreshold must be nonnegative; ColorScaling must be Global or PerFeature."]]];
    f = bioVisualColorFunction[OptionValue[ColorFunction]]; If[FailureQ[f], Return[f]];
    categories = DeleteDuplicates[groups]; indices = Lookup[PositionIndex[groups], categories];
    (* Aggregate sparse rows before materializing the small group-by-feature summaries. *)
    means = Normal[Mean[matrix[[#]]]] & /@ indices;
    fractions = Normal[Mean[Unitize[Clip[matrix[[#]], {threshold, Infinity}] - threshold]]] & /@ indices;
    {relative, range} = If[scaling === "PerFeature",
        {Transpose[(If[Min[#] == Max[#], ConstantArray[0., Length[#]], Rescale[#]] &) /@ Transpose[means]], {0, 1}},
        With[{maximum = Max[means]}, {If[maximum == 0, 0. means, N[means/maximum]], {0, If[maximum == 0, 1, maximum]}}]];
    ticks = {{MapIndexed[{First[#2], #1} &, categories], None},
        {MapIndexed[{First[#2], Rotate[#1, Pi/2]} &, features], None}};
    graphic = Graphics[Table[{f[relative[[i, j]]], Tooltip[Disk[{j, i}, 0.44 Sqrt[fractions[[i, j]]]],
        <|"Group" -> categories[[i]], "Feature" -> features[[j]], "Observations" -> Length[indices[[i]]],
            "Mean" -> means[[i, j]], "Fraction" -> fractions[[i, j]]|>]}, {i, Length[categories]}, {j, Length[features]}],
        FilterRules[Flatten[{opts, Options[BioExpressionDotPlot]}] /. (FrameTicks -> Automatic) :> (FrameTicks -> ticks), Options[Graphics]]];
    legend = With[{cf = f, limits = range}, BarLegend[{(cf[Rescale[#, limits]] &), limits},
        LegendLabel -> Column[{If[scaling === "Global", "mean expression", "relative mean per feature"], Row[{"dot area: fraction > ", threshold}]}]]];
    bioVisualLegend[graphic, OptionValue[PlotLegends], legend]
];
