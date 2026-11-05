---
Template: TechNote
Name: ExploringBiologicalDataGeometry
Title: Exploring the Geometry of Biological Measurements
Context: WolframInstitute`BioDataLink`
Paclet: WolframInstitute/BioDataLink
URI: WolframInstitute/BioDataLink/tutorial/ExploringBiologicalDataGeometry
Keywords: [application, iris, principal components, distance, clustering, scaling, sensitivity]
RelatedGuides: [BioDataLink, ComputationalExplorations, DataAccess, Downloads]
---

See how scaling changes distances, principal components and clustering in the
[UCI Iris measurements](https://archive.ics.uci.edu/dataset/53/iris).
The file has 150 plant records and four floral measurements in centimetres.
Species labels are used only for display. This is a descriptive analysis of
the whole file, not a prediction test.

The [download tutorial](paclet:WolframInstitute/BioDataLink/tutorial/DownloadingBiologicalData)
records the file identity and CC BY 4.0 attribution. Evaluate **Initialization**, then run the examples in order.

## Load and scale measurements

```wl
rows = DeleteCases[Import[FileNameJoin[{PacletObject["WolframInstitute/BioDataLink"]["AssetLocation", "Examples"], "iris.csv"}], "CSV"], {} | {""}];
measurements = rows[[All, 1 ;; 4]];
species = rows[[All, 5]];
variableNames = {"sepal length", "sepal width", "petal length", "petal width"};
speciesNames = DeleteDuplicates[species];
speciesRows = Flatten[Position[species, #]] & /@ speciesNames;
<|"Records" -> Length[measurements], "Variables" -> Length[variableNames],
    "CompleteNumericMatrix" -> MatrixQ[measurements, NumericQ]|>
```

Compare centimetres with standardized values: subtract each variable's mean
and divide by its sample standard deviation.

```wl
standardized = Standardize[measurements];
TableForm[{Mean[measurements], StandardDeviation[measurements]},
    TableHeadings -> {{"mean (cm)", "standard deviation (cm)"}, variableNames}]
```

Standardization changes how variables contribute to distance. All scales here
use the full dataset; a predictive workflow must fit them on training data only.
No variable has zero variance in this file.

## Compare principal components and distances

Use the covariance method for both representations:

```wl
rawScores = PrincipalComponents[measurements, Method -> "Covariance"];
scaledScores = PrincipalComponents[standardized, Method -> "Covariance"];
Grid[{MapThread[Function[{scores, label}, ListPlot[scores[[#, {1, 2}]] & /@ speciesRows,
    Frame -> True, FrameLabel -> {"component 1", "component 2"}, PlotRange -> All, PlotLabel -> label,
    PlotLegends -> speciesNames]], {{rawScores, scaledScores},
    {"centimetre variables", "standardized variables"}}]}]
```

Components are linear combinations, not biological trajectories. Their signs
are arbitrary. Compare the variance fractions:

```wl
BarChart[Transpose[Normalize[Variance[#], Total] & /@ {rawScores, scaledScores}],
    ChartLabels -> {{"PC1", "PC2", "PC3", "PC4"}, None},
    ChartLegends -> {"centimetre variables", "standardized variables"}, AxesLabel -> {None, "variance fraction"}]
```

Each representation has its own total variance. A larger first-component
fraction does not make a scale biologically preferable.

```wl
Grid[{MapThread[MatrixPlot[DistanceMatrix[#1], PlotLegends -> Automatic,
    FrameLabel -> {"source row", "source row"}, PlotLabel -> #2] &,
    {{measurements, standardized}, {"distance in cm", "standardized distance"}}]}]
```

Distance matrices use source row order and separate color scales. Species are
grouped in the source file, which makes blocks visible; reordering rows changes
the display, not the distances.

## Check clustering sensitivity

Request three k-means groups with Euclidean distance and repeat seeds 1–20.
The number of groups is an assumption. Each heat-map value is the fraction of
runs assigning a pair to the same group:

```wl
seeds = Range[20];
clusterRuns = Table[ClusteringComponents[data, 3, 1, Method -> "KMeans",
    DistanceFunction -> EuclideanDistance, RandomSeeding -> seed],
    {data, {measurements, standardized}}, {seed, seeds}];
Grid[{MapThread[MatrixPlot[Mean[coassignment /@ #1], PlotRange -> {0, 1}, PlotLegends -> Automatic,
    FrameLabel -> {"source row", "source row"}, PlotLabel -> #2, ImageSize -> 300] &,
    {clusterRuns, {"centimetre variables", "standardized variables"}}]}]
```

Comparing pair membership avoids arbitrary cluster numbers. Measure changes
relative to seed 1, then compare scales at seed 1:

```wl
recordPairs = Subsets[Range[Length[measurements]], {2}];
pairRuns = Map[pairRelations, clusterRuns, {2}];
ListLinePlot[Table[disagreement[First[runs], run], {runs, pairRuns}, {run, runs}], DataRange -> MinMax[seeds],
    PlotRange -> {0, 1}, Frame -> True, FrameLabel -> {"random seed", "fraction of pair relations changed"},
    PlotLegends -> {"centimetre variables", "standardized variables"}]
```

Compare scaling at a fixed seed:

```wl
<|"RecordPairs" -> Length[recordPairs],
    "FractionChangedByScalingAtSeed1" -> disagreement[pairRuns[[1, 1]], pairRuns[[2, 1]]]|>
```

These fractions measure sensitivity to the chosen seeds and scaling, not
biological probabilities. Sampling, measurement error, distance choice and
cluster count remain other sources of uncertainty.

Retain units, fitted scales, distances, cluster count and seeds. For thresholded
states, continue with
[Discretizing Biological Measurements](paclet:WolframInstitute/BioDataLink/tutorial/DiscretizingBiologicalMeasurements);
for held-out evaluation, use
[Exploring Simple Predictive Rules](paclet:WolframInstitute/BioDataLink/tutorial/ExploringSimplePredictiveRules).

## Identify which measurements define the geometry

A correlation matrix shows which variables carry related information. It is
unchanged by converting centimetres to millimetres, but the raw Euclidean
distances are not.

```wl
MatrixPlot[Correlation[measurements], ColorFunction -> (ColorData["ThermometerColors"][Rescale[#, {-1, 1}]] &),
    ColorFunctionScaling -> False, PlotRange -> {-1, 1}, PlotLegends -> BarLegend[{"ThermometerColors", {-1, 1}}],
    FrameTicks -> {{Transpose[{Range[4], variableNames}], None}, {Transpose[{Range[4], Rotate[#, Pi/2] & /@ variableNames}], None}}]
```

Correlated measurements can count a common direction more than once. Whether
that is desirable depends on the scientific question.

Correlate each measurement with the first two standardized PCs:

```wl
With[{loadings = Correlation[standardized, scaledScores[[All, ;; 2]]]},
    ListPlot[MapThread[Callout, {loadings, variableNames}], PlotRange -> {{-1, 1}, {-1, 1}}, AspectRatio -> 1,
        Frame -> True, FrameLabel -> {"correlation with PC 1", "correlation with PC 2"}]]
```

The arrows usually shown on a PCA plot summarize variable relationships, not
forces or developmental directions. These correlations help explain why a
projection separates particular records.

## Measure the information lost by projection

Compare distances in four standardized variables with distances in one, two
and three PCs. Use every unordered record pair, including pairs that overlap
in the two-dimensional picture.

```wl
fullDistances = EuclideanDistance @@ standardized[[#]] & /@ recordPairs;
projectionDistances = Table[EuclideanDistance @@ scaledScores[[#, ;; d]] & /@ recordPairs, {d, 3}];
GraphicsRow[Table[ListPlot[Transpose[{fullDistances, projectionDistances[[d]]}],
    Frame -> True, FrameLabel -> {"four-variable distance", Row[{d, "-PC distance"}]}, PlotRange -> All,
    Prolog -> {Gray, Line[{{0, 0}, {Max[fullDistances], Max[fullDistances]}}]}], {d, 3}], ImageSize -> Large]
```

The diagonal is perfect distance preservation. A high fraction of explained
variance can coexist with distortion for individual pairs.

## Remove one measurement at a time

Refit the projection after omitting each standardized variable. Use the same
source IDs and full species annotations to preserve colors across panels.

```wl
observationIDs = Range[Length[species]];
speciesAnnotations = AssociationThread[observationIDs, species];
GraphicsGrid[Partition[Table[BioEmbeddingPlot[
    AssociationThread[observationIDs, PrincipalComponents[standardized[[All, Complement[Range[4], {j}]]]][[All, ;; 2]]],
    speciesAnnotations, PlotLegends -> None, PlotLabel -> "without " <> variableNames[[j]],
    FrameLabel -> {"PC 1", "PC 2"}], {j, 4}], 2], ImageSize -> Large]
```

Axes are refitted in every panel, so their signs and rotations need not agree.
Compare neighborhoods or pair distances, not the apparent direction of motion
between panels.

## Use a control that destroys dependence between variables

Independently permute each measurement column. This preserves every marginal
distribution while removing correspondence between measurements from the same
plant. Compare standardized PCA variance fractions with the observed data:

```wl
permutedVariance = BlockRandom[SeedRandom[20261106]; Table[
    Normalize[Variance[PrincipalComponents[Transpose[RandomSample /@ Transpose[standardized]]]], Total], {40}]];
BoxWhiskerChart[Transpose[permutedVariance], ChartLabels -> {"PC 1", "PC 2", "PC 3", "PC 4"},
    Epilog -> {Red, PointSize[Medium], Point[Transpose[{Range[4], Normalize[Variance[scaledScores], Total]}]]},
    FrameLabel -> {"component", "variance fraction"}]
```

Red points are the observed fractions. Differences from this control reflect
joint structure beyond the four marginal distributions. They do not identify
its biological cause or validate species as a clustering target.

## Initialization

Helpers compare pair membership across clusterings:

```wl
coassignment[assignment_] := Outer[Boole[#1 == #2] &, assignment, assignment];
pairRelations[assignment_] := (Boole[assignment[[#[[1]]]] == assignment[[#[[2]]]]] &) /@ recordPairs;
disagreement[a_, b_] := N[Mean[Abs[a - b]]];
```
