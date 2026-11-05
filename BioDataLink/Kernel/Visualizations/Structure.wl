(* ::Package:: *)

PackageExported[BioStructureComparisonPlot];
BioStructureComparisonPlot::usage = "BioStructureComparisonPlot[reference, moving, regions] aligns two ID-keyed coordinate traces and colors them by ID-keyed regions. The reference is translucent and the aligned moving trace is solid.";

Options[BioStructureComparisonPlot] = Join[{
    "AlignmentResidues" -> All, "CategoryColors" -> Automatic, "TubeRadius" -> 0.3,
    PlotLegends -> Automatic, Boxed -> False, Lighting -> "Neutral", PlotRange -> All},
    FilterRules[Options[Graphics3D], Except[Boxed | Lighting | PlotRange]]];

BioStructureComparisonPlot[reference_Association, moving_Association, regions_Association, opts : OptionsPattern[]] := Module[
    {ids = Keys[reference], target = Values[reference], source, fitIDs, selected, radius = OptionValue["TubeRadius"], colors, fit, aligned, graphic},
    If[!bioVisualMatrixQ[target] || Last[Dimensions[target]] =!= 3 || Sort[ids] =!= Sort[Keys[moving]] ||
            !AllTrue[ids, KeyExistsQ[regions, #] &] || !AllTrue[Values[regions], StringQ],
        Return[bioFailure["InvalidStructure", "Use matching residue IDs for both traces and a string region for every residue."]]];
    source = Lookup[moving, ids];
    If[!bioVisualMatrixQ[source] || Last[Dimensions[source]] =!= 3 || !bioVisualRealQ[radius] || radius <= 0,
        Return[bioFailure["InvalidStructure", "Coordinates must be finite real triples and TubeRadius must be positive in the same units."]]];
    fitIDs = Replace[OptionValue["AlignmentResidues"], All -> ids];
    If[!ListQ[fitIDs] || Length[fitIDs] < 3 || !DuplicateFreeQ[fitIDs] || !AllTrue[fitIDs, KeyExistsQ[reference, #] &],
        Return[bioFailure["InvalidAlignment", "Select at least three distinct residue IDs present in both traces."]]];
    selected = Lookup[AssociationThread[ids, Range[Length[ids]]], fitIDs];
    If[Min[MatrixRank[# - ConstantArray[Mean[#], Length[#]]] & /@ {source[[selected]], target[[selected]]}] < 2,
        Return[bioFailure["InvalidAlignment", "Alignment residues must not be collinear."]]];
    colors = bioVisualColors[Values[regions], OptionValue["CategoryColors"]]; If[FailureQ[colors], Return[colors]];
    fit = Quiet[Check[Last[FindGeometricTransform[target[[selected]], source[[selected]],
        TransformationClass -> "Rigid", Method -> "Linear"]], $Failed]];
    If[!MatchQ[fit, _TransformationFunction], Return[bioFailure["AlignmentFailed", "A rigid alignment could not be computed."]]];
    aligned = fit /@ source;
    graphic = With[{vertexColors = Lookup[colors, Lookup[regions, ids]]}, Graphics3D[{
        Opacity[0.25], Tooltip[Tube[target, radius, VertexColors -> vertexColors], "reference"],
        Opacity[1], Tooltip[Tube[aligned, radius, VertexColors -> vertexColors], "aligned moving trace"]},
        FilterRules[Flatten[{opts, Options[BioStructureComparisonPlot]}], Options[Graphics3D]]]];
    bioVisualLegend[graphic, OptionValue[PlotLegends], SwatchLegend[Values[colors], Keys[colors]]]
];
