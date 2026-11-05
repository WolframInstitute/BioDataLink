Needs["WolframInstitute`BioDataLink`"];

VerificationTest[
    Module[{g = BioEmbeddingPlot[<|"a" -> {1, 2}, "b" -> {3, 4}|>, <|"b" -> "B", "a" -> "A"|>, PlotLegends -> None]},
        Cases[g, Tooltip[Point[p_], a_Association] :> {p, a["ID"], a["Annotation"]}, Infinity]],
    {{{1, 2}, "a", "A"}, {{3, 4}, "b", "B"}}, TestID -> "Embedding-AlignAnnotationsByID"]

VerificationTest[
    Module[{a = <|"a" -> "A", "b" -> "B", "c" -> "C"|>, full, subset},
        full = BioEmbeddingPlot[<|"a" -> {1, 1}, "b" -> {2, 2}|>, a, PlotLegends -> None];
        subset = BioEmbeddingPlot[<|"b" -> {2, 2}|>, a, PlotLegends -> None];
        Cases[full, {c_?ColorQ, Tooltip[Point[{2, 2}], _]} :> c, Infinity] ===
            Cases[subset, {c_?ColorQ, Tooltip[Point[{2, 2}], _]} :> c, Infinity]],
    True, TestID -> "Embedding-SubsetPreservesCategoryColor"]

VerificationTest[
    Cases[BioEmbeddingPlot[<|"a" -> {1, 1}, "b" -> {2, 2}|>, <|"a" -> 10, "b" -> 0|>,
        "ColorMode" -> "Continuous", PlotLegends -> None], Tooltip[_Point, a_Association] :> a["ID"], Infinity],
    {"b", "a"}, TestID -> "Embedding-HighValuesDrawLast"]

VerificationTest[FailureQ[BioEmbeddingPlot[<|"a" -> {0, 1}|>, <||>]], True, TestID -> "Embedding-RejectMissingID"]
VerificationTest[FailureQ[BioEmbeddingPlot[<|"a" -> {0, Infinity}|>, <|"a" -> "A"|>]], True, TestID -> "Embedding-RejectNonfiniteCoordinates"]

VerificationTest[
    Module[{matrix = SparseArray[{{1, 1} -> 2, {2, 2} -> 4, {3, 1} -> 6, {3, 2} -> 2}, {3, 2}], data},
        data = Cases[BioExpressionDotPlot[matrix, {"A", "A", "B"}, {"x", "y"}], Tooltip[_Disk, a_Association] :> a, Infinity];
        Lookup[data, {"Group", "Feature", "Observations", "Mean", "Fraction"}]],
    {{"A", "x", 2, 1, 1/2}, {"A", "y", 2, 2, 1/2}, {"B", "x", 1, 6, 1}, {"B", "y", 1, 2, 1}},
    TestID -> "Expression-SparseGroupMeansAndDetectionFractions"]

VerificationTest[
    With[{r = Cases[BioExpressionDotPlot[{{2}, {0}, {3}}, {"A", "A", "B"}, {"x"}], Disk[_, radius_] :> radius, Infinity]},
        Abs[(First[r]/Last[r])^2 - 1/2] < 10^-12], True, TestID -> "Expression-DotAreaRepresentsFraction"]

VerificationTest[
    Cases[BioExpressionDotPlot[{{2}, {3}, {0}}, {"A", "A", "A"}, {"x"}, "DetectionThreshold" -> 2],
        Tooltip[_Disk, a_Association] :> a["Fraction"], Infinity], {1/3}, TestID -> "Expression-ThresholdIsStrict"]

VerificationTest[FailureQ[BioExpressionDotPlot[{{-1, 2}}, {"A"}, {"x", "y"}]], True, TestID -> "Expression-RejectNegativeMeasurements"]
VerificationTest[FailureQ[BioExpressionDotPlot[{{1, 2}}, {"A"}, {"x", "x"}]], True, TestID -> "Expression-RejectDuplicateFeatureLabels"]
VerificationTest[FailureQ[BioExpressionDotPlot[{{1, Missing[]}}, {"A"}, {"x", "y"}]], True, TestID -> "Expression-RejectMissingRatherThanZeroFill"]

VerificationTest[WolframInstitute`BioDataLink`PackageScope`bioWordGrid["ACCGGGTTTT", 1],
    {{1, 4}, {2, 3}}, TestID -> "Sequence-BaseQuadrants"]
VerificationTest[WolframInstitute`BioDataLink`PackageScope`bioWordGrid["acNac", 2],
    {{0, 0, 0, 0}, {0, 0, 0, 0}, {2, 0, 0, 0}, {0, 0, 0, 0}}, TestID -> "Sequence-AmbiguityBreaksWordsAndCaseIsAccepted"]
VerificationTest[FailureQ[BioSequenceCompositionPlot["ACGT", 9]], True, TestID -> "Sequence-BoundGridSize"]
VerificationTest[FailureQ[BioSequenceCompositionPlot["NNNN", 2]], True, TestID -> "Sequence-NoWordsIsNotAnEmptySuccess"]
VerificationTest[FailureQ[BioSequenceCompositionPlot["ACZGT", 2]], True, TestID -> "Sequence-RejectInvalidAlphabet"]
VerificationTest[
    First[Cases[BioSequenceSkewPlot["GGGGCCCCGG", 4], Line[points_] :> points, Infinity]],
    {{2.5, 1.}, {6.5, -1.}}, TestID -> "Skew-OneBasedMidpointsAndIncompleteTailExcluded"]
VerificationTest[FailureQ[BioSequenceSkewPlot["ACGT", 2, "BasePair" -> {"G", "G"}]], True, TestID -> "Skew-DistinctBasesRequired"]
VerificationTest[FailureQ[BioSequenceSkewPlot["AAAATTTT", 4]], True, TestID -> "Skew-AllUndefinedWindowsReturnFailure"]

VerificationTest[
    First[Cases[BioExpressionDotPlot[{{0}, {6}}, {"A", "B"}, {"x"}],
        BarLegend[{f_, range_}, ___] :> {f[First[range]], f[Last[range]]}, Infinity]],
    ColorData["BlueGreenYellow"] /@ {0, 1}, TestID -> "Expression-LegendUsesSameColorScaleAsDots"]

VerificationTest[
    Module[{reference, moving, plot, traces},
        reference = <|1 -> {0, 0, 0}, 2 -> {1, 0, 0}, 3 -> {0, 1, 0}, 4 -> {0, 0, 1}|>;
        moving = Reverse[Map[{3, 2, 1} + RotationTransform[Pi/3, {0, 0, 1}][#] &, reference]];
        plot = BioStructureComparisonPlot[reference, moving, AssociationThread[Keys[reference], ConstantArray["core", 4]]];
        traces = Cases[plot, Tube[points_, _, ___] :> points, Infinity];
        Max[Abs[Flatten[Subtract @@ traces]]] < 10^-10], True, TestID -> "Structure-RigidAlignmentUsesResidueIDs"]
VerificationTest[
    FailureQ[BioStructureComparisonPlot[<|1 -> {0, 0, 0}, 2 -> {1, 0, 0}, 3 -> {2, 0, 0}|>,
        <|1 -> {0, 1, 0}, 2 -> {1, 1, 0}, 3 -> {2, 1, 0}|>, <|1 -> "A", 2 -> "A", 3 -> "A"|>]],
    True, TestID -> "Structure-RejectCollinearAlignment"]

VerificationTest[
    Module[{reference, moving, aligned, signedVolume},
        reference = <|1 -> {0., 0, 0}, 2 -> {2., 0, 0}, 3 -> {0., 3, 0}, 4 -> {0., 0, 4}|>;
        moving = Map[{-#[[1]], #[[2]], #[[3]]} &, reference];
        aligned = Last[Cases[BioStructureComparisonPlot[reference, moving,
            AssociationThread[Keys[reference], ConstantArray["core", 4]]], Tube[points_, _, ___] :> points, Infinity]];
        signedVolume[points_] := Det[Rest[points] - ConstantArray[First[points], 3]];
        {Abs[signedVolume[aligned] - signedVolume[Values[moving]]] < 10^-10,
            Norm[Mean[aligned] - Mean[Values[reference]]] < 10^-10}],
    {True, True}, TestID -> "Structure-FitPreservesHandednessAndUsesAllSelectedPoints"]

VerificationTest[
    Module[{saved = Options[BioEmbeddingPlot], result},
        WithCleanup[
            SetOptions[BioEmbeddingPlot, ImageSize -> 240];
            result = ImageSize /. Options[BioEmbeddingPlot[<|"a" -> {0, 0}|>, <|"a" -> "A"|>, PlotLegends -> None], ImageSize];
            {result, ImageSize /. Options[BioEmbeddingPlot[<|"a" -> {0, 0}|>, <|"a" -> "A"|>, ImageSize -> 360, PlotLegends -> None], ImageSize]},
            Options[BioEmbeddingPlot] = saved]], {240, 360}, TestID -> "VisualOptions-SetOptionsAndExplicitOverride"]
