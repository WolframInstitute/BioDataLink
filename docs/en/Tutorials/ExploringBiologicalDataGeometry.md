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
GraphicsRow[MapThread[MatrixPlot[Mean[coassignment /@ #1], PlotRange -> {0, 1}, PlotLegends -> Automatic,
    FrameLabel -> {"source row", "source row"}, PlotLabel -> #2] &,
    {clusterRuns, {"centimetre variables", "standardized variables"}}]]
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

## Initialization

Helpers compare pair membership across clusterings:

```wl
coassignment[assignment_] := Outer[Boole[#1 == #2] &, assignment, assignment];
pairRelations[assignment_] := (Boole[assignment[[#[[1]]]] == assignment[[#[[2]]]]] &) /@ recordPairs;
disagreement[a_, b_] := N[Mean[Abs[a - b]]];
```
