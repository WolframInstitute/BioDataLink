(* ::Package:: *)

PackageExported[BioEmbeddingPlot];
BioEmbeddingPlot::usage = "BioEmbeddingPlot[coordinates, annotations] plots ID-keyed two-dimensional coordinates colored by ID-keyed annotations.\nBioEmbeddingPlot[coordinates, annotations, \"ColorMode\" -> \"Continuous\"] colors points by numeric annotations, drawing larger values last.";

Options[BioEmbeddingPlot] = Join[{
    "ColorMode" -> "Categorical", "CategoryColors" -> Automatic, "ColorRange" -> Automatic,
    ColorFunction -> "BlueGreenYellow", PlotLegends -> Automatic,
    Frame -> True, FrameTicks -> None, Axes -> False, AspectRatio -> 1, PlotRange -> All},
    FilterRules[Options[Graphics], Except[Frame | FrameTicks | Axes | AspectRatio | PlotRange]]];

BioEmbeddingPlot[coordinates_Association, annotations_Association, opts : OptionsPattern[]] := Module[
    {ids = Keys[coordinates], xy = Values[coordinates], values, mode = OptionValue["ColorMode"], colors, range, f, order, legend, graphic},
    If[!bioVisualMatrixQ[xy] || Last[Dimensions[xy]] =!= 2,
        Return[bioFailure["InvalidCoordinates", "Coordinates must be a nonempty association of IDs to finite real pairs."]]];
    If[!AllTrue[ids, KeyExistsQ[annotations, #] &],
        Return[bioFailure["MissingAnnotations", "Every plotted ID needs an annotation."]]];
    values = Lookup[annotations, ids];
    Switch[mode,
        "Categorical",
            If[!AllTrue[Values[annotations], StringQ], Return[bioFailure["InvalidAnnotations", "Categorical annotations must be strings."]]];
            colors = bioVisualColors[Values[annotations], OptionValue["CategoryColors"]];
            If[FailureQ[colors], Return[colors]];
            legend = SwatchLegend[Values[colors], Keys[colors]];
            colors = Lookup[colors, values]; order = Range[Length[ids]],
        "Continuous",
            If[!AllTrue[Values[annotations], bioVisualRealQ], Return[bioFailure["InvalidAnnotations", "Continuous annotations must be finite real values."]]];
            range = Replace[OptionValue["ColorRange"], Automatic :> MinMax[Values[annotations]]];
            If[!MatchQ[range, {_?bioVisualRealQ, _?bioVisualRealQ}] || range[[1]] > range[[2]],
                Return[bioFailure["InvalidColorRange", "ColorRange must be Automatic or an ordered pair of finite values."]]];
            f = bioVisualColorFunction[OptionValue[ColorFunction]]; If[FailureQ[f], Return[f]];
            colors = f /@ If[range[[1]] == range[[2]], ConstantArray[0.5, Length[values]], Rescale[Clip[values, range], range]];
            legend = With[{cf = f, limits = range},
                BarLegend[{(cf[If[First[limits] == Last[limits], 0.5, Rescale[#, limits]]] &), limits}]];
            order = Ordering[values],
        _, Return[bioFailure["InvalidColorMode", "ColorMode must be Categorical or Continuous."]]
    ];
    graphic = Graphics[{PointSize[If[Length[ids] <= 100, Medium, Small]],
        Table[{colors[[i]], Tooltip[Point[xy[[i]]], <|"ID" -> ids[[i]], "Annotation" -> values[[i]]|>]}, {i, order}]},
        FilterRules[Flatten[{opts, Options[BioEmbeddingPlot]}], Options[Graphics]]];
    bioVisualLegend[graphic, OptionValue[PlotLegends], legend]
];
