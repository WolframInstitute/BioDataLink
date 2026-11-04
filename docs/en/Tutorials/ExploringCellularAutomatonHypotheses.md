---
Template: TechNote
Name: ExploringCellularAutomatonHypotheses
Title: Exploring Cellular Automaton Hypotheses
Context: WolframInstitute`BioDataLink`
Paclet: WolframInstitute/BioDataLink
URI: WolframInstitute/BioDataLink/tutorial/ExploringCellularAutomatonHypotheses
Keywords: [application, cellular automata, rule space, identifiability, observation map, biology]
RelatedGuides: [BioDataLink, ComputationalExplorations, DataAccess]
---

How much does a static biological measurement tell us about a dynamical rule?
This tutorial connects one measured summary to a deliberately simplified model,
enumerates a complete small rule space, and shows that distinct rules can match
the same summary. The aim is to understand an inference limitation before using
rule search to propose biological mechanisms.

The approach follows Ruliology's practice of comparing explicit rule tables,
initial conditions and observed traces. All model computations here use built-in
Wolfram Language functions. No Ruliology or Ruliobiology installation is required.
The plant measurements are real; the lattice, binary states and updates are
constructed hypotheses. There is no measured temporal or spatial sequence in
this dataset to identify a cellular automaton rule.

## Define one empirical constraint

Use the attributed UCI Iris file bundled with BioDataLink. Its four variables
are floral measurements in centimetres. The source includes 50 records per
species; the pooled fraction below is specific to this balanced sample, not an
estimate for a naturally occurring mixture of the species. See
[UCI Iris](https://archive.ics.uci.edu/dataset/53/iris) and
[Downloading and Inspecting Biological Data](DownloadingBiologicalData.md)
for provenance, historical differences and the retained source bytes.

Choose a petal-width threshold of 1.5 cm before comparing rules. This is an
illustrative analyst choice, not a known biological switching point:

```wl
exampleDirectory = FileNameJoin[{
    PacletObject["WolframInstitute/BioDataLink"]["Location"], "Assets", "Examples"}];
rows = DeleteCases[Import[FileNameJoin[{exampleDirectory, "iris.csv"}], "CSV"], {} | {""}];
widths = rows[[All, 4]];
threshold = 1.5;
measuredStates = Boole[# >= threshold] & /@ widths;
targetFraction = Mean[measuredStates];
<|"PlantRecords" -> Length[widths], "WidthThresholdCm" -> threshold,
    "RecordsAtOrAboveThreshold" -> Total[measuredStates],
    "FractionAtOrAboveThreshold" -> N[targetFraction]|>
```

Inspect the actual measurements and the chosen cutoff:

```wl
Histogram[widths, {0, 2.6, 0.1}, "Count", Frame -> True,
    FrameLabel -> {"Petal width (cm)", "Plant records"},
    GridLines -> {{threshold}, None},
    GridLinesStyle -> Directive[Red, Dashed, Thick],
    PlotLabel -> "A declared threshold: 1.5 cm", ImageSize -> 540]
```

Binning in the histogram serves display only. The fraction was computed from
the original measurements using the explicit greater-than-or-equal comparison.
We will retain only this fraction, intentionally discarding the species labels,
the other traits and the distribution of widths.

## Make the observation-to-model map explicit

Represent a hypothetical system by 96 binary sites on a ring. Match its initial
occupied fraction to the nearest representable value, and randomly permute the
occupied sites using a fixed seed. The sites are not the 150 plants. Their order
does not come from the CSV, and adjacency has no measured biological meaning.

```wl
siteCount = 96;
occupiedCount = Round[siteCount targetFraction];
initial = BlockRandom[SeedRandom[20261104]; RandomSample[
    Join[ConstantArray[1, occupiedCount], ConstantArray[0, siteCount - occupiedCount]]]];
<|"EmpiricalFraction" -> N[targetFraction],
    "ModelInitialFraction" -> N[Mean[initial]],
    "RoundingDifference" -> N[Mean[initial] - targetFraction]|>
```

Plot the constructed initial state. Blue denotes state 1 and light gray state
0; neither color represents a directly observed molecular state:

```wl
stateColors = {0 -> GrayLevel[0.93], 1 -> RGBColor[0.12, 0.4, 0.65]};
ArrayPlot[{initial}, ColorRules -> stateColors, Frame -> True,
    FrameTicks -> {{None, None}, {Automatic, None}},
    FrameLabel -> {None, "Hypothetical site index"}, AspectRatio -> 0.09,
    PlotLabel -> "Constructed ring state; the two ends are adjacent", ImageSize -> 620]
```

For each elementary cellular automaton, a site's next binary state depends on
its current state and its two immediate neighbors. Eight possible three-site
neighborhoods each have a binary output, giving 2^8 = 256 rule tables.
[CellularAutomaton (WL)](https://reference.wolfram.com/language/ref/CellularAutomaton.html)
treats a bare initial list as cyclic, so the first and last sites are neighbors.
Updates are synchronous and one model step has no assigned physical duration.

## Enumerate the rule space once

Compute each trace for 32 steps, retaining the initial state as step zero.
Reuse these traces for every plot and statistic:

```wl
rules = Range[0, 255];
steps = 32;
traces = CellularAutomaton[#, initial, steps] & /@ rules;
fractions = Map[Mean, traces, {2}];
finalFractions = fractions[[All, -1]];
disagreement[state_] := Mean[Abs[state - RotateLeft[state]]];
finalDisagreements = disagreement /@ traces[[All, -1]];
Dimensions[traces]
```

The result has axes rule, model time and hypothetical site. The disagreement
statistic is the fraction of adjacent pairs with different states on the ring.
It measures local variation in these binary arrays; it is not a measure of
algorithmic complexity or biological fitness.

Compare nine rules using the same initial state, scale and color mapping.
Array rows increase downward, so the top row is step zero:

```wl
Clear[tracePlot];
tracePlot[rule_, size_] := ArrayPlot[traces[[rule + 1]], ColorRules -> stateColors,
    Frame -> True, FrameTicks -> {{{1, "0"}, {17, "16"}, {33, "32"}}, None},
    FrameLabel -> {"Step (downward)", "Site"},
    PlotLabel -> "Rule " <> ToString[rule], ImageSize -> size];
GraphicsGrid[Partition[tracePlot[#, 220] & /@ {0, 30, 54, 90, 110, 150, 170, 204, 232}, 3],
    ImageSize -> 720]
```

The image gallery displays distinct computations, all driven by a compact
local rule. It does not establish that the corresponding patterns occur in
these plants. Rule 204 copies each site, and rule 170 shifts the configuration
around the ring. Both preserve the occupied fraction without explaining how
the measured distribution arose.

## Compare rules through a specified observation

Our observation map reduces the final model state to its occupied fraction.
Plot that fraction against the neighbor-disagreement statistic; each point is
one rule. Distinct rules can overlap at the same plotted coordinates:

```wl
ListPlot[Transpose[N[{finalFractions, finalDisagreements}]],
    Frame -> True, FrameLabel -> {"Final occupied fraction", "Final neighbor disagreement"},
    PlotRange -> {{0, 1}, {0, 1}},
    GridLines -> {{N[targetFraction]}, None},
    GridLinesStyle -> Directive[Red, Dashed],
    PlotStyle -> Directive[RGBColor[0.12, 0.4, 0.65], PointSize[0.012], Opacity[0.65]],
    PlotLabel -> "256 rules; dashed line is the empirical fraction", ImageSize -> 540]
```

Declare a tolerance of one model site, 1/96, around the empirical fraction.
This is a numerical comparison criterion chosen for the example; it is not a
sampling confidence interval. Count compatible rules and retain their numbers:

```wl
tolerance = 1/siteCount;
compatibleRules = Pick[rules, (Abs[# - targetFraction] <= tolerance &) /@ finalFractions];
<|"ComparisonStep" -> steps, "Tolerance" -> N[tolerance],
    "CompatibleRuleCount" -> Length[compatibleRules],
    "CompatibleRules" -> compatibleRules|>
```

Select three compatible rules spanning the observed range of neighbor
disagreement. Include the identity and shift rules for comparison. This
selection illustrates variation among accepted models; it is not a ranking of
biological plausibility:

```wl
orderedCompatible = SortBy[compatibleRules, finalDisagreements[[# + 1]] &];
selectedRules = DeleteDuplicates[Join[{170, 204}, orderedCompatible[[
    DeleteDuplicates[{1, Ceiling[Length[orderedCompatible]/2], Length[orderedCompatible]}]]]]];
ListLinePlot[fractions[[selectedRules + 1]], DataRange -> {0, steps},
    Frame -> True, FrameLabel -> {"Model step", "Occupied fraction"},
    PlotLegends -> Placed[("Rule " <> ToString[#] & /@ selectedRules), Below],
    GridLines -> {None, {N[targetFraction]}}, GridLinesStyle -> Directive[Red, Dashed],
    PlotRange -> {0, 1}, ImageSize -> 620]
```

Different intermediate trajectories can satisfy the same final comparison.
Overlapping lines are also informative: this scalar observable can hide very
different arrays. Matching the final fraction is neither a prediction of the
unobserved trajectory nor evidence for a causal mechanism.

## Challenge the result with new initial arrangements

Keep the same number of occupied sites but draw 20 new permutations. Recompute
the final fraction for each selected rule using these new arrangements. This
tests dependence on the unobserved model initial condition:

```wl
alternativeInitials = BlockRandom[SeedRandom[20261105];
    Table[RandomSample[initial], {20}]];
seedFractions = Table[N[Mean[Last[CellularAutomaton[rule, seed, steps]]]],
    {rule, selectedRules}, {seed, alternativeInitials}];
BoxWhiskerChart[seedFractions,
    ChartLabels -> ("Rule " <> ToString[#] & /@ selectedRules),
    FrameLabel -> {"Rule", "Final occupied fraction"}, PlotRange -> {0, 1},
    GridLines -> {None, {N[targetFraction]}},
    GridLinesStyle -> Directive[Red, Dashed],
    PlotLabel -> "20 constructed initial arrangements per rule", ImageSize -> 620]
```

Identity and shift preserve the fraction for every permutation on the ring.
Other compatible rules may depend on the arrangement. These repetitions probe
the model assumption; they do not increase biological replication or validate
the ring topology. A different boundary condition or observation time would
define a different experiment.

## Applications: design observations that distinguish rules

The practical lesson is to define what is observed before interpreting a rule
search. For measured time-lapse spatial data, one could compare local
transitions, spatial correlations and transient trajectories, retaining units,
frame intervals and missing observations. Separate data used to select a rule
from data used to assess its predictions. Compare against simple copying,
shifting and constant-output baselines.

For perturbation experiments, define how an intervention changes a model state
or rule, and compare predicted responses with independent treated and control
replicates. A drug concentration is not automatically a cellular automaton
parameter; the mapping needs an explicit biological hypothesis. Static
single-cell snapshots alone do not supply observed state transitions.

For this Iris example, collecting additional temporal and spatial information
would be necessary to argue for dynamics. Even many more rules cannot recover
information that the observation map deliberately discarded. The companion
[Exploring Simple Predictive Rules](ExploringSimplePredictiveRules.md) shows a
different, directly testable objective: predicting a recorded label from
measured traits with held-out evaluation.

## Computational references

- [CellularAutomaton (WL)](https://reference.wolfram.com/language/ref/CellularAutomaton.html) specifies numbered rules, periodic initial lists and time-step output.
- [ArrayPlot (WL)](https://reference.wolfram.com/language/ref/ArrayPlot.html) specifies matrix orientation, row coordinates and color rules.
- [BlockRandom (WL)](https://reference.wolfram.com/language/ref/BlockRandom.html) isolates the recorded simulation seeds from the surrounding session.
