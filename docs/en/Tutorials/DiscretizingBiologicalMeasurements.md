---
Template: TechNote
Name: DiscretizingBiologicalMeasurements
Title: Discretizing Biological Measurements
Context: WolframInstitute`BioDataLink`
Paclet: WolframInstitute/BioDataLink
URI: WolframInstitute/BioDataLink/tutorial/DiscretizingBiologicalMeasurements
Keywords: [application, iris, threshold, rank, quantile, finite state, information loss, sensitivity]
RelatedGuides: [BioDataLink, ComputationalExplorations, DataAccess, Downloads]
---

Convert continuous measurements into finite states, then check the information
lost. The example uses four floral measurements from the
[UCI Iris dataset](https://archive.ics.uci.edu/dataset/53/iris) (CC BY 4.0).
Its 150 rows are different plant records, not a time series.

Thresholds are exploratory choices fitted to this file, not biological cutoffs.
Evaluate **Initialization**, then run the examples in order.

## Define and inspect binary states

Set a bit to 1 above a variable's median and 0 otherwise:

```wl
measurements = DeleteCases[Import[FileNameJoin[{PacletObject["WolframInstitute/BioDataLink"]["AssetLocation", "Examples"], "iris.csv"}], "CSV"], {} | {""}][[All, 1 ;; 4]];
variableNames = {"sepal length", "sepal width", "petal length", "petal width"};
thresholds = Median[measurements];
binaryStates = encodeBinary[#, thresholds] & /@ measurements;
AssociationThread[variableNames, thresholds]
```

Show thresholds on the measurement distributions:

```wl
GraphicsGrid[Partition[Table[Histogram[measurements[[All, j]], {0.2},
    AxesLabel -> {variableNames[[j]] <> " (cm)", "records"}, GridLines -> {{thresholds[[j]]}, None}], {j, 4}], 2]]
```

Ties stay in the lower state, so median splits need not create equal groups.

```wl
ArrayPlot[binaryStates, AspectRatio -> 1, PlotLegends -> Automatic, FrameLabel -> {"source row", "measurement"},
    FrameTicks -> {{Automatic, None}, {Transpose[{Range[4], {"sepal L", "sepal W", "petal L", "petal W"}}], None}}]
```

The source file groups species together. The resulting blocks do not represent
state transitions. Count all 16 possible four-bit states:

```wl
BarChart[BinCounts[FromDigits[#, 2] & /@ binaryStates, {0, 16, 1}],
    ChartLabels -> Range[0, 15], AxesLabel -> {"state number", "records"}]
```

Bits follow sepal length, sepal width, petal length and petal width. State 0 is
`0000`; state 15 is `1111`. Unoccupied states are absent from this file, not
necessarily biologically impossible.

## Test threshold sensitivity

Shift thresholds by ±0.5 standard deviations and count changes relative to
the median encoding:

```wl
ListLinePlot[Transpose[Table[changedFractions[thresholds + shift StandardDeviation[measurements]], {shift, Range[-10, 10]/20}]],
    DataRange -> {-0.5, 0.5}, PlotRange -> {0, 1}, PlotLegends -> Append[variableNames, "any bit"],
    Frame -> True, FrameLabel -> {"threshold shift (standard deviations)", "fraction of records changed"}]
```

This tests an analysis choice, not an estimated measurement-error distribution.
Report any downstream result that depends on a narrow threshold choice.

## Compare finer bins

Use empirical quantiles for 2–8 bins. Remove duplicate cuts and assign equality
to the lower bin; ties can leave fewer occupied bins than requested.

```wl
requestedBins = Range[2, 8];
binnedStates = Table[encodeBins[#, quantileCuts[q]] & /@ measurements, {q, requestedBins}];
```

Compare occupied states and petal-length reconstruction error using bin means:

```wl
With[{petalLength = measurements[[All, 3]]},
    Grid[{{ListLogPlot[{requestedBins^4, Length[DeleteDuplicates[#]] & /@ binnedStates}, DataRange -> MinMax[requestedBins],
            Joined -> True, Frame -> True, FrameLabel -> {"bins per variable", "joint states (log scale)"},
            PlotLegends -> {"possible before ties", "occupied"}],
        ListLinePlot[RootMeanSquare[reconstruct[#[[All, 3]], petalLength] - petalLength] & /@ binnedStates,
            DataRange -> MinMax[requestedBins], Frame -> True, FrameLabel -> {"bins per variable", "petal-length RMSE (cm)"}]}}]]
```

More bins retain detail but leave fewer records per state. Cuts are refitted
for each bin count, so errors need not decrease monotonically. This is
within-sample quantization error, not held-out prediction error.

## Check lost distances

For all 11,175 record pairs, compare standardized Euclidean distance with the
number of unequal bits:

```wl
With[{pairs = Subsets[Range[Length[measurements]], {2}], standardized = Standardize[measurements]},
    BoxWhiskerChart[Table[EuclideanDistance @@ standardized[[#]] & /@ Select[pairs, HammingDistance @@ binaryStates[[#]] == h &], {h, 0, 4}],
        ChartLabels -> Range[0, 4], FrameLabel -> {"number of unequal bits", "Euclidean distance after standardization"}]]
```

Records sharing a binary state can still differ in their measurements. Pairs
share records and are not independent replicates. A state histogram cannot
identify an update rule; that requires justified temporal or lineage data.
For static prediction, continue with
[Exploring Simple Predictive Rules](paclet:WolframInstitute/BioDataLink/tutorial/ExploringSimplePredictiveRules).

## Inspect where the state boundaries lie

Draw petal length and width, colored by their two-bit state. The vertical and
horizontal lines are the chosen medians; small movements near these lines can
change state without a large change in measurement.

```wl
BioEmbeddingPlot[AssociationThread[Range[Length[measurements]], measurements[[All, {3, 4}]]],
    AssociationThread[Range[Length[measurements]], StringJoin[ToString /@ #] & /@ binaryStates[[All, {3, 4}]]],
    FrameLabel -> {"petal length (cm)", "petal width (cm)"}, FrameTicks -> Automatic,
    GridLines -> {{thresholds[[3]]}, {thresholds[[4]]}}]
```

The axis labels retain physical units. Binary distance is a new representation,
not a change of units in the original measurement space.

## Test dependence between the encoded variables

Shuffle each bit column independently. This preserves each bit's frequency but
destroys which bits co-occur in a plant. Compare occupied joint states with
those in the observed encoding:

```wl
shuffledStates = BlockRandom[SeedRandom[20261106]; Table[Transpose[RandomSample /@ Transpose[binaryStates]], {100}]];
Histogram[Length[DeleteDuplicates[#]] & /@ shuffledStates, {0.5, 16.5, 1}, "Probability",
    GridLines -> {{Length[DeleteDuplicates[binaryStates]]}, None}, Frame -> True,
    FrameLabel -> {"occupied joint states", "fraction of permutations"}]
```

Fewer occupied states than this null suggests dependence among encoded traits.
It does not identify which biological constraints generated that dependence.

## Compare reconstruction for every measured variable

For two, four and eight bins, reconstruct each measurement from its bin's mean.
Inspect predicted versus observed values instead of relying on one aggregate
error score:

```wl
GraphicsGrid[Table[With[{labels = binnedStates[[First[FirstPosition[requestedBins, q]]]][[All, j]], original = measurements[[All, j]]},
    ListPlot[Transpose[{original, reconstruct[labels, original]}], Frame -> True,
        FrameLabel -> {"observed (cm)", "bin mean (cm)"}, PlotLabel -> Row[{variableNames[[j]], ": ", q, " bins"}],
    Prolog -> {Gray, Line[Transpose[{MinMax[original], MinMax[original]}]]}]], {j, 4}, {q, {2, 4, 8}}], ImageSize -> Large]
```

Horizontal bands show the precision discarded by quantization. The bin means
were estimated from the same records; this remains a reconstruction experiment,
not an out-of-sample prediction result.

## Measure boundary sensitivity under a stated error model

Add independent Gaussian noise of 0.02, 0.05 and 0.1 cm to each measurement.
Keep the original median thresholds fixed, and repeat each scenario 40 times:

```wl
noiseLevels = {0.02, 0.05, 0.1};
stateChanges = BlockRandom[SeedRandom[20261106]; Table[Table[
    With[{states = encodeBinary[#, thresholds] & /@ (measurements + RandomVariate[NormalDistribution[0, sd], Dimensions[measurements]])},
        N[Mean[Boole[MapThread[UnsameQ, {states, binaryStates}]]]]], {40}], {sd, noiseLevels}]];
BoxWhiskerChart[stateChanges, ChartLabels -> noiseLevels, PlotRange -> {0, 1},
    FrameLabel -> {"assumed error SD (cm)", "fraction of records changing state"}]
```

These noise levels are scenarios, not measured instrument uncertainties.
Stable conclusions should survive plausible changes in thresholds, resolution
and measurement error; each addresses a different assumption.

## Initialization

Helpers encode thresholds and quantiles, measure sensitivity and reconstruct
values from bin means:

```wl
encodeBinary[point_, cuts_] := Boole[Thread[point > cuts]];
changedFractions[cuts_] := With[{states = encodeBinary[#, cuts] & /@ measurements},
    Append[Mean[Abs[states - binaryStates]], Mean[Boole[MapThread[UnsameQ, {states, binaryStates}]]]]];
quantileCuts[q_] := DeleteDuplicates[Quantile[#, Range[q - 1]/q]] & /@ Transpose[measurements];
encodeBins[point_, cuts_] := MapThread[1 + Count[#2, t_ /; #1 > t] &, {point, cuts}];
reconstruct[labels_, values_] := Lookup[GroupBy[Transpose[{labels, values}], First -> Last, Mean], labels];
```
