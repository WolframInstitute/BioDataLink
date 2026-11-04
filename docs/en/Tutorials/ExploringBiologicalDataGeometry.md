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

Which plant records look similar, and how much does that answer depend on the
measurement scale? A distance, a projection and a clustering all make choices
about which differences matter. This tutorial exposes those choices before
interpreting a figure.

The data are the 150 plant records in the bundled [UCI Iris file](https://archive.ics.uci.edu/dataset/53/iris),
with sepal length, sepal width, petal length and petal width measured in
centimetres. Its three species labels are used for display, not to fit the
principal components or clusters. These are descriptive calculations on the
whole file, with no claim about prediction on new plants. The
[download tutorial](paclet:WolframInstitute/BioDataLink/tutorial/DownloadingBiologicalData)
checks the exact file and its CC BY 4.0 attribution. UCI documents differences
from Fisher's historical article; the distributed values are retained here.

## Keep the observation and variables explicit

Load the local file and preserve its row order. The source row is a record
position, not a time coordinate or evidence of independent sampling:

```wl
irisFile = FileNameJoin[{PacletObject["WolframInstitute/BioDataLink"]["AssetLocation", "Examples"], "iris.csv"}];
rows = DeleteCases[Import[irisFile, "CSV"], {} | {""}];
measurements = rows[[All, 1 ;; 4]];
species = rows[[All, 5]];
variableNames = {"sepal length", "sepal width", "petal length", "petal width"};
speciesNames = DeleteDuplicates[species];
speciesRows = Flatten[Position[species, #]] & /@ speciesNames;
<|"Records" -> Length[measurements], "Variables" -> Length[variableNames],
    "CompleteNumericMatrix" -> MatrixQ[measurements, NumericQ]|>
```

First inspect the four distributions. Use the same 0.2 cm bin width so the
horizontal scales retain their measurement meaning:

```wl
GraphicsGrid[Partition[Table[
    Histogram[measurements[[All, j]], {0.2}, "Count",
        AxesLabel -> {variableNames[[j]] <> " (cm)", "records"}], {j, 4}], 2]]
```

All four variables share a physical unit, but they have different spreads.
A variable with a larger spread can contribute more to squared Euclidean
distance. That contribution is a mathematical weighting; it is not evidence
that the variable is more biologically important.

## Compare two explicitly defined geometries

The first representation retains centimetres. The second subtracts each
column mean and divides by its sample standard deviation. A difference of one
in the second representation means one standard deviation in this file:

```wl
columnMeans = Mean[measurements];
columnScales = StandardDeviation[measurements];
standardized = (# - columnMeans)/columnScales & /@ measurements;
Dataset[MapThread[<|"Variable" -> #1, "MeanCm" -> #2, "StandardDeviationCm" -> #3|> &,
    {variableNames, columnMeans, columnScales}]]
```

These means and scales were fitted to all 150 records for description. A
predictive analysis must estimate them using training records and apply those
same values to held-out records. A zero-variance variable would require an
explicit decision before dividing; none occurs in this file.

[PrincipalComponents](https://reference.wolfram.com/language/ref/PrincipalComponents.html)
forms uncorrelated linear combinations ordered by their variance. Apply its
covariance method to both representations, rather than allowing an implicit
change of scale:

```wl
rawScores = PrincipalComponents[measurements, Method -> "Covariance"];
scaledScores = PrincipalComponents[standardized, Method -> "Covariance"];
Grid[{MapThread[Function[{scores, label}, ListPlot[scores[[#, {1, 2}]] & /@ speciesRows,
    Frame -> True, FrameLabel -> {"component 1", "component 2"}, PlotRange -> All, PlotLabel -> label,
    PlotLegends -> speciesNames]], {{rawScores, scaledScores},
    {"centimetre variables", "standardized variables"}}]}]
```

The projection is a new coordinate system, not a biological trajectory.
Component signs can reverse without changing the geometry. Coloured groups
show how the supplied species labels sit in the projection; their appearance
is not a measured classification accuracy.

Count the fraction of total variance represented by each component:

```wl
varianceFractions = (Variance[#]/Total[Variance[#]] &) /@ {rawScores, scaledScores};
BarChart[Transpose[varianceFractions], ChartLayout -> "Grouped",
    ChartLabels -> {{"PC1", "PC2", "PC3", "PC4"}, None},
    ChartLegends -> {"centimetre variables", "standardized variables"},
    AxesLabel -> {None, "variance fraction"}]
```

The denominator changes when variables are standardized. A larger first
component fraction in one representation does not make that representation
scientifically preferable. It says how concentrated variance is under that
choice of weighting.

## Inspect distances before assigning groups

Compute all pairwise Euclidean distances in the four-dimensional spaces. The
rows and columns stay in source order in both panels; the diagonal compares a
record with itself. The two colour scales have different units:

```wl
rawDistances = Outer[EuclideanDistance, measurements, measurements, 1];
scaledDistances = Outer[EuclideanDistance, standardized, standardized, 1];
Grid[{MapThread[MatrixPlot[#1, PlotLegends -> Automatic,
    FrameLabel -> {"source row", "source row"}, PlotLabel -> #2] &,
    {{rawDistances, scaledDistances}, {"distance in cm", "standardized distance"}}]}]
```

Source ordering puts the species blocks together, making the block structure
easy to see. Reordering records changes this display but does not change any
pairwise distance. Both matrices summarize measurements; neither describes a
causal connection between plants.

## Separate scale sensitivity from algorithm sensitivity

For a controlled comparison, request three k-means clusters in each
representation and repeat seeds 1 through 20. The requested count is an
analysis setting, not an estimated number of biological types. Specify
Euclidean distance so that the clustering function does not automatically
preprocess the supplied representation. This behavior and the seed option are
documented by [ClusteringComponents](https://reference.wolfram.com/language/ref/ClusteringComponents.html).

```wl
seeds = Range[20];
clusterRuns = Table[ClusteringComponents[data, 3, 1, Method -> "KMeans",
    DistanceFunction -> EuclideanDistance, RandomSeeding -> seed],
    {data, {measurements, standardized}}, {seed, seeds}];
coassignmentFractions = Mean[coassignment /@ #] & /@ clusterRuns;
Grid[{MapThread[MatrixPlot[#1, PlotRange -> {0, 1}, PlotLegends -> Automatic,
    FrameLabel -> {"source row", "source row"}, PlotLabel -> #2] &,
    {coassignmentFractions, {"centimetre variables", "standardized variables"}}]}]
```

A coassignment fraction is the proportion of these 20 runs in which two
records belong to the same cluster. It avoids comparing arbitrary cluster
numbers: renaming cluster 1 to cluster 2 changes no pair relation. Intermediate
values identify pairs whose grouping changes across the chosen seeds. The
fraction measures algorithmic sensitivity in this experiment, not a biological
probability or sampling uncertainty.

Quantify changes using every distinct unordered pair of records, excluding
the diagonal. For each seed, compare the pair relations to seed 1 in the same
representation. Also compare the two representations at seed 1:

```wl
recordPairs = Subsets[Range[Length[measurements]], {2}];
pairRuns = Map[pairRelations, clusterRuns, {2}];
seedDisagreement = Function[runs, disagreement[First[runs], #] & /@ runs] /@ pairRuns;
scaleDisagreement = disagreement[pairRuns[[1, 1]], pairRuns[[2, 1]]];
ListLinePlot[Transpose[{seeds, #}] & /@ seedDisagreement, PlotRange -> {0, 1},
    Frame -> True, FrameLabel -> {"random seed", "fraction of pair relations changed"},
    PlotLegends -> {"centimetre variables", "standardized variables"}]
```

```wl
<|"RecordPairs" -> Length[recordPairs],
    "FractionChangedByScalingAtSeed1" -> scaleDisagreement|>
```

The comparison holds the dataset and requested cluster count fixed. It does
not cover uncertainty from sampling, measurement error, alternative distance
functions or other cluster counts. A robust-looking clustering under these
seeds can still change under those choices.

## Carry the representation into the next question

The useful result is a recorded chain: source rows and units, fitted means and
scales, the distance definition, requested cluster count and random seeds.
[Discretizing Biological Measurements](paclet:WolframInstitute/BioDataLink/tutorial/DiscretizingBiologicalMeasurements)
asks what happens when those continuous measurements become finite states.
[Exploring Simple Predictive Rules](paclet:WolframInstitute/BioDataLink/tutorial/ExploringSimplePredictiveRules)
uses a separate training and held-out workflow when the question is prediction.

## Initialization

Evaluate these helper definitions before the examples above. The data choices
and analysis parameters remain in the main examples.

```wl
coassignment[assignment_] := Outer[Boole[#1 == #2] &, assignment, assignment];
pairRelations[assignment_] := (Boole[assignment[[#[[1]]]] == assignment[[#[[2]]]]] &) /@ recordPairs;
disagreement[a_, b_] := N[Mean[Abs[a - b]]];
```
