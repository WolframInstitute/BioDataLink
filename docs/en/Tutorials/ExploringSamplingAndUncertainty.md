---
Template: TechNote
Name: ExploringSamplingAndUncertainty
Title: Exploring Sampling and Uncertainty in Biological Measurements
Context: WolframInstitute`BioDataLink`
Paclet: WolframInstitute/BioDataLink
URI: WolframInstitute/BioDataLink/tutorial/ExploringSamplingAndUncertainty
Keywords: [application, sampling, uncertainty, bootstrap, permutation, missingness, effect size, Iris]
RelatedGuides: [BioDataLink, ComputationalExplorations, DataAccess, Visualizations]
RelatedTutorials: [ExploringBiologicalDataGeometry, ExploringSimplePredictiveRules, UnderstandingSparseMeasurements]
---

How stable is a difference between two groups of measured plants? Use the
[UCI Iris measurements](https://archive.ics.uci.edu/dataset/53/iris) (CC BY 4.0)
to compare distributions, resampling variation, label permutations, measurement
error, and selective missingness. The goal is to separate a visible difference
from the assumptions needed to generalize it.

The file contains 50 records per species. Its sampling design does not establish
representativeness of natural populations. Resampling these rows creates
computational replicates, not additional independent plants.

Evaluate **Initialization**, then run the experiments in order.

## Inspect the observations before comparing means

```wl
file = FileNameJoin[{PacletObject["WolframInstitute/BioDataLink"]["AssetLocation", "Examples"], "iris.csv"}];
rows = DeleteCases[Import[file, "CSV"], {} | {""}];
measurements = N[rows[[All, ;; 4]]];
species = rows[[All, 5]];
variables = {"sepal length", "sepal width", "petal length", "petal width"};
groups = {"Iris-versicolor", "Iris-virginica"};
indices = Flatten[Position[species, #]] & /@ groups;
widths = measurements[[#, 4]] & /@ indices;
Histogram[widths, {0, 2.7, 0.1}, "Probability", ChartLegends -> groups,
    Frame -> True, FrameLabel -> {"petal width (cm)", "fraction of records"}]
```

The shared bins retain overlap between the groups. A difference of means is
only one summary of these distributions.

View the individual plants in the petal measurement plane:

```wl
BioEmbeddingPlot[AssociationThread[Flatten[indices], measurements[[Flatten[indices], {3, 4}]]],
    AssociationThread[Range[Length[species]], species], FrameTicks -> Automatic,
    FrameLabel -> {"petal length (cm)", "petal width (cm)"}]
```

The extra annotations preserve the full species color vocabulary. The
coordinates here are measured centimetres, not an embedding inferred by a model.

## Compare several summaries of the same data

```wl
Dataset[AssociationThread[groups, <|"Records" -> Length[#], "MeanCm" -> Mean[#],
    "MedianCm" -> Median[#], "StandardDeviationCm" -> StandardDeviation[#],
    "InterquartileRangeCm" -> Subtract @@ Reverse[Quantile[#, {1/4, 3/4}]]|> & /@ widths]]
```

Compare empirical cumulative distributions. Their vertical separation reveals
where one group tends to have larger measurements without selecting histogram
bins:

```wl
Plot[Evaluate[CDF[EmpiricalDistribution[#], x] & /@ widths], {x, 0.5, 2.7},
    PlotLegends -> groups, Frame -> True, FrameLabel -> {"petal width (cm)", "fraction at or below width"}]
```

Record the mean and median differences, always second group minus first:

```wl
observedDifference = Mean[widths[[2]]] - Mean[widths[[1]]];
<|"MeanDifferenceCm" -> observedDifference,
    "MedianDifferenceCm" -> Median[widths[[2]]] - Median[widths[[1]]],
    "DifferenceInPooledSDUnits" -> observedDifference/Sqrt[Mean[Variance /@ widths]]|>
```

The standardized effect changes its denominator, not the underlying records.
Keep the difference in centimetres alongside it.

## Bootstrap the difference of means

Resample each group independently with replacement, preserving its sample size.
Repeat 1,000 times with a recorded seed:

```wl
bootstrapDifferences = BlockRandom[SeedRandom[20261106]; Table[
    Mean[RandomChoice[widths[[2]], Length[widths[[2]]]]] - Mean[RandomChoice[widths[[1]], Length[widths[[1]]]]], {1000}]];
Histogram[bootstrapDifferences, Automatic, "Probability", GridLines -> {{observedDifference}, None},
    Frame -> True, FrameLabel -> {"resampled mean difference (cm)", "fraction of resamples"}]
```

The distribution describes row-resampling variation conditional on this file.
A population interpretation additionally needs appropriate independent sampling;
rows clustered by plant, site or collection would need a design-aware resample.

Show the central 95% of this bootstrap distribution:

```wl
Quantile[bootstrapDifferences, {0.025, 0.5, 0.975}]
```

A narrow interval does not cover systematic errors, selective sampling, or an
unrecorded collection effect.

## Test how sample size changes the resampling spread

Repeat the same calculation at 5, 10, 20 and 50 sampled records per group:

```wl
sampleSizes = {5, 10, 20, 50};
sizeExperiments = BlockRandom[SeedRandom[20261107]; Table[Table[
    Mean[RandomChoice[widths[[2]], n]] - Mean[RandomChoice[widths[[1]], n]], {300}], {n, sampleSizes}]];
BoxWhiskerChart[sizeExperiments, ChartLabels -> sampleSizes, GridLines -> {None, {observedDifference}},
    FrameLabel -> {"resampled records per group", "mean difference (cm)"}]
```

Smaller samples give more variable estimates under this empirical model. The
experiment changes sample size while holding the observed distributions fixed;
it does not represent collecting from additional environments.

## Compare with a label-permutation null

Pool the two groups and randomly redistribute their labels, retaining 50 records
per group. This is a different experiment from bootstrapping: it removes the
observed association between group label and measurement.

```wl
pooled = Join @@ widths;
permutationDifferences = BlockRandom[SeedRandom[20261108]; Table[With[{shuffled = RandomSample[pooled]},
    Mean[Drop[shuffled, 50]] - Mean[Take[shuffled, 50]]], {1000}]];
Histogram[permutationDifferences, Automatic, "Probability", GridLines -> {{observedDifference}, None},
    Frame -> True, FrameLabel -> {"mean difference after label permutation (cm)", "fraction of permutations"},
    PlotRange -> {{Min[permutationDifferences], observedDifference + 0.05}, All}]
```

Permutation inference assumes labels are exchangeable under the null. Biological
relatedness, sampling strata, or confounding may make arbitrary permutations
inappropriate. The experiment alone cannot verify exchangeability.

Use a plus-one correction when reporting a Monte Carlo tail frequency:

```wl
N[(1 + Count[permutationDifferences, d_ /; Abs[d] >= Abs[observedDifference]])/(1 + Length[permutationDifferences])]
```

This frequency is conditional on the specified null and randomization scheme.
It is not the probability that the groups are biologically identical.

## Inspect all four variables on their original scales

```wl
GraphicsGrid[Partition[Table[BoxWhiskerChart[measurements[[#, j]] & /@ indices, ChartLabels -> groups,
    FrameLabel -> {None, variables[[j]] <> " (cm)"}, PlotRange -> All], {j, 4}], 2], ImageSize -> Large]
```

Choosing the largest apparent difference after inspecting many variables is a
selection step. A confirmatory analysis must account for that selection rather
than presenting the selected comparison as prespecified.

## Add measurement error without changing group membership

Add independent zero-mean noise with known scenario standard deviations. Plot
the resulting difference of means over 200 repetitions per scenario:

```wl
errorScales = {0.01, 0.05, 0.1, 0.2};
errorDifferences = BlockRandom[SeedRandom[20261109]; Table[Table[
    With[{noisy = (# + RandomVariate[NormalDistribution[0, sd], Length[#]] &) /@ widths},
        Mean[noisy[[2]]] - Mean[noisy[[1]]]], {200}], {sd, errorScales}]];
BoxWhiskerChart[errorDifferences, ChartLabels -> errorScales, GridLines -> {None, {observedDifference}},
    FrameLabel -> {"assumed measurement-error SD (cm)", "mean difference (cm)"}]
```

Independent zero-mean errors increase variability without imposing a directional
bias. A systematic offset affecting one group would shift the difference instead
and would not disappear through more measurements of that same group.

## Challenge the result with selective missingness

Remove progressively more of the narrowest petals in the first group. Compare
its retained mean with the mean obtained by randomly retaining the same number
of records. The second group remains unchanged.

```wl
removedFractions = Range[0, 0.4, 0.05];
selectedDifferences = Table[Mean[widths[[2]]] - Mean[Drop[Sort[widths[[1]]], Floor[q Length[widths[[1]]]]]], {q, removedFractions}];
randomRemovalDifferences = BlockRandom[SeedRandom[20261110]; Table[Mean[Table[
    Mean[widths[[2]]] - Mean[RandomSample[widths[[1]], Length[widths[[1]]] - Floor[q Length[widths[[1]]]]]], {100}]], {q, removedFractions}]];
ListLinePlot[{Transpose[{removedFractions, selectedDifferences}], Transpose[{removedFractions, randomRemovalDifferences}]},
    PlotLegends -> {"remove narrowest petals", "random removal, average"}, Frame -> True,
    FrameLabel -> {"fraction removed from first group", "mean difference (cm)"}]
```

Missingness related to the measurement changes the retained population. A
bootstrap of the retained rows will not recover the missing narrow petals or
correct the resulting selection bias.

## Compare robustness to an extreme observation

Replace one first-group observation by a range of hypothetical values. Track
mean and median differences while holding every other observation fixed:

```wl
replacementValues = Range[0, 5, 0.1];
ListLinePlot[Table[Transpose[{replacementValues,
    Table[summary[widths[[2]]] - summary[ReplacePart[widths[[1]], 1 -> x]], {x, replacementValues}]}],
    {summary, {Mean, Median}}], PlotLegends -> {"mean difference", "median difference"},
    Frame -> True, FrameLabel -> {"replacement value (cm)", "group difference (cm)"}]
```

Robustness is a property of an estimator under a stated perturbation. It does
not justify discarding an unusual observation without checking its provenance.

## Keep the experiments distinct

```wl
<|"SourceSHA256" -> FileHash[file, "SHA256", "HexString"], "Groups" -> groups,
    "Measurement" -> "petal width in centimetres", "EffectDirection" -> "virginica minus versicolor",
    "BootstrapReplicates" -> 1000, "PermutationReplicates" -> 1000,
    "Seeds" -> Range[20261106, 20261110], "PopulationSamplingDesignVerified" -> False|>
```

The observed distributions, bootstrap spread, permutation null, measurement
error scenarios and missingness experiment answer different questions. Agreement
among them strengthens a descriptive account; it does not replace independent
sampling, a justified observation model, or a prospective validation study.

## Initialization

The experiments use native plotting, resampling and probability functions.

```wl
Needs["WolframInstitute`BioDataLink`"];
```
