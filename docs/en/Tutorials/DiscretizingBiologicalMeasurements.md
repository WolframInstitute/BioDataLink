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

A finite-state model needs a rule for turning observations into states. A
measurement of 4.3 cm could become “short”, a rank bin, or one bit in a vector.
Those representations retain different information. Before searching for a
simple rule, make the observation rule explicit and test what it discards.

This tutorial uses four floral measurements from the bundled
[UCI Iris dataset](https://archive.ics.uci.edu/dataset/53/iris), not a time
series. Its 150 rows are plant records; they are not successive states of one
plant. The UCI file is attributed under CC BY 4.0, and the
[download tutorial](paclet:WolframInstitute/BioDataLink/tutorial/DownloadingBiologicalData)
checks its bytes and describes its historical-source caveat. All thresholds
below are exploratory choices fitted to this file, not biological cutoffs.

## Define a transparent binary observation rule

Load the four columns in their source order. Use the median of each variable
as an initial threshold, assigning equality to the lower state:

```wl
irisFile = FileNameJoin[{PacletObject["WolframInstitute/BioDataLink"]["Location"],
    "Assets", "Examples", "iris.csv"}];
rows = DeleteCases[Import[irisFile, "CSV"], {} | {""}];
measurements = rows[[All, 1 ;; 4]];
variableNames = {"sepal length", "sepal width", "petal length", "petal width"};
thresholds = Median /@ Transpose[measurements];
encodeBinary[point_, cuts_] := MapThread[Boole[#1 > #2] &, {point, cuts}];
binaryStates = encodeBinary[#, thresholds] & /@ measurements;
AssociationThread[variableNames, thresholds]
```

Place the chosen threshold on each distribution. Each dashed line is a
specified analysis choice, not a boundary inferred from a biological assay:

```wl
GraphicsGrid[Partition[Table[
    Histogram[measurements[[All, j]], {0.2}, "Count",
        Frame -> True, Axes -> False,
        FrameLabel -> {variableNames[[j]] <> " (cm)", "records"},
        Epilog -> {Black, Dashed, Line[{{thresholds[[j]], 0}, {thresholds[[j]], 150}}]},
        ChartStyle -> ColorData[97][j], ImageSize -> 320],
    {j, 4}], 2], ImageSize -> 700]
```

A median split need not produce equal groups when values are tied. The
comparison `>` and the treatment of equality are part of the observation rule;
changing them can change the encoded data.

## Inspect the resulting states

Display one row per plant record and one column per measurement. Dark entries
are above the variable's median; light entries are at or below it:

```wl
ArrayPlot[binaryStates, ColorRules -> {0 -> RGBColor[0.92, 0.95, 0.98],
        1 -> RGBColor[0.14, 0.35, 0.63]},
    Frame -> True, AspectRatio -> 1,
    FrameTicks -> {{Automatic, None},
        {Transpose[{Range[4], {"sepal L", "sepal W", "petal L", "petal W"}}], None}},
    FrameLabel -> {"source row", "measurement"},
    PlotLegends -> SwatchLegend[{RGBColor[0.92, 0.95, 0.98], RGBColor[0.14, 0.35, 0.63]},
        {"at or below median", "above median"}], ImageSize -> 580]
```

The source file groups its species labels. That ordering explains why blocks
appear together in this display. It supplies no sequence of state transitions.
A row permutation would leave the state counts below unchanged.

Four bits allow 16 possible states. Enumerate all of them, including states
that no record occupies, and count records without merging their source rows:

```wl
stateNumbers = FromDigits[#, 2] & /@ binaryStates;
stateCounts = Table[Count[stateNumbers, state], {state, 0, 15}];
stateLabels = StringJoin[ToString /@ IntegerDigits[#, 2, 4]] & /@ Range[0, 15];
BarChart[stateCounts, ChartLabels -> stateLabels,
    Frame -> True, Axes -> False,
    FrameLabel -> {"state: sepal length, sepal width, petal length, petal width", "records"},
    ChartStyle -> RGBColor[0.14, 0.35, 0.63], ImageSize -> 700]
```

A zero-height bar means this encoding has no matching record in this file.
It does not show that the state is biologically impossible. Conversely, records
sharing a state can differ substantially in their original measurements.

## Vary the thresholds before trusting a pattern

Shift each threshold by the same fraction of that variable's sample standard
deviation. Negative shifts lower the thresholds; positive shifts raise them.
Measure the fraction of records whose bit changes and the fraction whose
complete four-bit state changes relative to the median encoding:

```wl
columnScales = StandardDeviation[measurements];
shifts = N[Range[-10, 10]/20];
shiftedStates = Table[encodeBinary[#, thresholds + shift columnScales] & /@ measurements,
    {shift, shifts}];
bitChangeFractions = Mean[Abs[# - binaryStates]] & /@ shiftedStates;
wholeStateChange = (Mean[MapThread[Boole[#1 =!= #2] &, {#, binaryStates}]] &) /@ shiftedStates;
ListLinePlot[Join[
        (Transpose[{shifts, #}] & /@ Transpose[bitChangeFractions]),
        {Transpose[{shifts, wholeStateChange}]}],
    Frame -> True, Axes -> False, PlotRange -> {0, 1},
    FrameLabel -> {"threshold shift (variable standard deviations)", "fraction of records changed"},
    PlotLegends -> Placed[Append[variableNames, "any bit"], Below], ImageSize -> 700]
```

This is sensitivity to a deliberate analysis change. The horizontal scale is
not an estimated measurement error. If a downstream rule only works for one
narrow choice of thresholds, that dependence needs to be reported with the
rule.

## Compare binary states with finer rank bins

Quantile bins retain order but discard within-bin distances. For each variable,
use empirical quantiles at 1/q through (q-1)/q as cuts. The default
[Quantile](https://reference.wolfram.com/language/ref/Quantile.html)
returns observed values; repeated cuts are removed, and equality stays in the
lower bin. Ties can therefore leave fewer than q occupied bins.

```wl
quantileCuts[q_] := DeleteDuplicates[Quantile[#, Range[q - 1]/q]] & /@ Transpose[measurements];
encodeBins[point_, cuts_] := MapThread[
    Function[{value, boundaries}, 1 + Count[boundaries, t_ /; value > t]], {point, cuts}];
requestedBins = Range[2, 8];
cutSets = quantileCuts /@ requestedBins;
binnedStates = Table[encodeBins[#, cuts] & /@ measurements, {cuts, cutSets}];
occupiedStates = Length[DeleteDuplicates[#]] & /@ binnedStates;
```

Measure information loss in the original unit by reconstructing petal length
from its bin mean. This uses the same records to define cuts and means, so the
root mean squared error is a descriptive quantization error, not a held-out
prediction error:

```wl
petalLength = measurements[[All, 3]];
reconstruct[binLabels_, values_] := Module[{means},
    means = GroupBy[Transpose[{binLabels, values}], First -> Last, Mean];
    Lookup[means, binLabels]];
petalReconstructions = reconstruct[#[[All, 3]], petalLength] & /@ binnedStates;
quantizationRMSE = Sqrt[Mean[(# - petalLength)^2]] & /@ petalReconstructions;
GraphicsRow[{
    ListLogPlot[{Transpose[{requestedBins, requestedBins^4}],
        Transpose[{requestedBins, occupiedStates}]}, Joined -> True,
        PlotMarkers -> Automatic, Frame -> True, Axes -> False,
        FrameLabel -> {"requested bins per variable", "joint states (log scale)"},
        PlotLegends -> Placed[{"q^4 possible before ties", "occupied in this file"}, Below],
        ImageSize -> 340],
    ListLinePlot[Transpose[{requestedBins, quantizationRMSE}],
        PlotMarkers -> Automatic, Frame -> True, Axes -> False,
        FrameLabel -> {"requested bins per variable", "petal-length reconstruction RMSE (cm)"},
        PlotRange -> All, ImageSize -> 340]}, ImageSize -> 740]
```

More possible states rapidly exceed the 150 available records. Finer bins can
retain more measurement detail while making each observed state sparsely
supported. The bin families are refitted at each q and are not nested, so a
strictly monotonic error curve is not guaranteed.

## See which distances the binary map loses

Compare continuous distance after standardization with the number of unequal
bits. For each of the 11,175 distinct pairs of records, compute both quantities.
Group the continuous distances by the binary distance:

```wl
standardized = (# - Mean[measurements])/columnScales & /@ measurements;
recordPairs = Subsets[Range[Length[measurements]], {2}];
continuousDistances = EuclideanDistance @@ standardized[[#]] & /@ recordPairs;
bitDistances = (Total[Abs[Subtract @@ binaryStates[[#]]]] &) /@ recordPairs;
distancesByBitCount = Table[Pick[continuousDistances, bitDistances, h], {h, 0, 4}];
BoxWhiskerChart[distancesByBitCount,
    ChartLabels -> Range[0, 4], Frame -> True, Axes -> False,
    FrameLabel -> {"number of unequal bits", "Euclidean distance after standardization"},
    ImageSize -> 650]
```

Pairs with zero unequal bits need not have zero continuous distance. The box
plots describe pairwise distances; the pairs share records and are not
independent biological replicates. They expose the many-to-one observation
map, without assigning a biological interpretation to each finite state.

## What this permits in a rule-based analysis

[Ruliobiology’s finite cellular automata](https://www.wolframcloud.com/obj/wolframinstitute/DeployedResources/Paclet/WolframInstitute/Ruliobiology/Documentation/ref/FiniteCellularAutomaton.html) supply explicit
computational states and update rules. The related [Ruliology rule-space tutorial](https://www.wolframcloud.com/obj/wolframinstitute/DeployedResources/Paclet/WolframInstitute/Ruliology/Documentation/tutorial/AnalyzingCellularAutomatonRuleSpace.html)
explores rules, applied cases and the limits of finite observations. The
connection here is an explicit observation map: measurements become finite
symbols before a rule is compared with them. This tutorial uses built-in
Wolfram Language and does not require either sibling paclet.

A state histogram alone cannot identify an update rule. To study transitions,
obtain measurements with justified temporal or lineage relationships, specify
the observation interval and test alternatives that could produce the same
observations. For a static prediction question, continue with
[Exploring Simple Predictive Rules](paclet:WolframInstitute/BioDataLink/tutorial/ExploringSimplePredictiveRules),
which separates rule selection from held-out evaluation.
