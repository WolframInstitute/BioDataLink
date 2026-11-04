---
Template: TechNote
Name: ExploringCellularAutomatonHypotheses
Title: Exploring Cellular Automaton Hypotheses
Context: WolframInstitute`BioDataLink`
Paclet: WolframInstitute/BioDataLink
URI: WolframInstitute/BioDataLink/tutorial/ExploringCellularAutomatonHypotheses
Keywords: [application, cellular automata, rule space, identifiability, observation map, model complexity, biology]
RelatedGuides: [BioDataLink, ComputationalExplorations, DataAccess]
---

Test why matching one statistic cannot identify a dynamical rule. The example
reduces [UCI Iris petal widths](https://archive.ics.uci.edu/dataset/53/iris)
to a fraction, then compares hypothetical binary cellular automata with it.
The model sites, adjacency and time steps have no measured biological mapping.

This is an identifiability demonstration, not a model of plant development.
The bundled UCI data retain their CC BY 4.0 attribution. Evaluate **Initialization**, then run the examples in order.

## Define the observation

Choose the fraction of records with petal width ≥ 1.5 cm:

```wl
widths = DeleteCases[Import[FileNameJoin[{PacletObject["WolframInstitute/BioDataLink"]["AssetLocation", "Examples"], "iris.csv"}], "CSV"], {} | {""}][[All, 4]];
threshold = 1.5;
targetFraction = Mean[Boole[Thread[widths >= threshold]]];
<|"PlantRecords" -> Length[widths], "WidthThresholdCm" -> threshold,
    "RecordsAtOrAboveThreshold" -> targetFraction Length[widths], "FractionAtOrAboveThreshold" -> N[targetFraction]|>
```

Show the width threshold:

```wl
Histogram[widths, {0, 2.6, 0.1}, GridLines -> {{threshold}, None}, AxesLabel -> {"Petal width (cm)", "Plant records"}]
```

The threshold is illustrative. The file has 50 records per species, so this
pooled fraction describes that balanced sample. It discards species labels,
other traits and the rest of the width distribution.

## Define and enumerate the model

Place 96 binary sites on a ring. Set the initial occupied count to the nearest
representation of the observed fraction, then shuffle with a fixed seed:

```wl
siteCount = 96;
initial = BlockRandom[SeedRandom[20261104]; RandomSample[PadRight[ConstantArray[1, Round[siteCount targetFraction]], siteCount]]];
<|"EmpiricalFraction" -> N[targetFraction], "ModelInitialFraction" -> N[Mean[initial]],
    "RoundingDifference" -> N[Mean[initial] - targetFraction]|>
```

An elementary cellular automaton has 256 binary rule tables. Each synchronous
update reads a site and its two neighbors. The initial list is cyclic, and
one model step has no assigned physical duration.

```wl
rules = Range[0, 255];
steps = 32;
traces = CellularAutomaton[#, initial, steps] & /@ rules;
fractions = Map[Mean, traces, {2}];
finalFractions = fractions[[All, -1]];
finalDisagreements = disagreement /@ traces[[All, -1]];
Dimensions[traces]
```

Traces have axes rule, time and site, including step zero. Compare final
occupied fraction with the fraction of adjacent sites having unequal states:

```wl
ListPlot[Transpose[N[{finalFractions, finalDisagreements}]], PlotRange -> {{0, 1}, {0, 1}},
    AxesLabel -> {"Final occupied fraction", "Final neighbor disagreement"},
    GridLines -> {{N[targetFraction]}, None}]
```

Neither statistic measures biological fitness or algorithmic complexity.

## Compare compatible rules

Accept final fractions within one model site (1/96) of the observed fraction.
This tolerance is not a sampling confidence interval:

```wl
compatibleRules = Pick[rules, Thread[Abs[finalFractions - targetFraction] <= 1/siteCount]];
<|"ComparisonStep" -> steps, "Tolerance" -> N[1/siteCount], "CompatibleRuleCount" -> Length[compatibleRules],
    "CompatibleRules" -> compatibleRules|>
```

Compare selected compatible trajectories, including copying rule 204 and
shifting rule 170:

```wl
selectedRules = With[{ordered = SortBy[compatibleRules, finalDisagreements[[# + 1]] &]},
    DeleteDuplicates[Join[{170, 204}, ordered[[{1, Ceiling[Length[ordered]/2], -1}]]]]];
ListLinePlot[fractions[[selectedRules + 1]], DataRange -> {0, steps}, PlotRange -> {0, 1},
    AxesLabel -> {"Model step", "Occupied fraction"},
    PlotLegends -> ("Rule " <> ToString[#] & /@ selectedRules), GridLines -> {None, {N[targetFraction]}}]
```

Different trajectories can produce the same endpoint fraction. Copying and
shifting preserve a fraction that was built into the initial state; this does
not explain the measured plant distribution.

Test 20 new initial permutations while preserving the occupied count:

```wl
With[{alternatives = BlockRandom[SeedRandom[20261105]; Table[RandomSample[initial], {20}]]},
    BoxWhiskerChart[Table[N[Mean[Last[CellularAutomaton[rule, seed, steps]]]], {rule, selectedRules}, {seed, alternatives}],
        ChartLabels -> selectedRules, PlotRange -> {0, 1}, FrameLabel -> {"Rule", "Final occupied fraction"},
        GridLines -> {None, {N[targetFraction]}}]]
```

Copying and shifting preserve the fraction for every permutation. Other rules
can depend on the arrangement. These repetitions test an unobserved model
assumption, not additional biological samples.

## Add observations that separate predictions

For the same 21 compatible rules, compare three predicted counts: occupied
sites at step 32, unequal neighboring pairs at step 32, and occupied sites at
step 1. Iris supplies no such spatial or temporal observations.

```wl
ruleCoordinates = CirclePoints[Length[compatibleRules]];
modelObservations = AssociationThread[compatibleRules,
    {Total[Last[#]], Total[Abs[Last[#] - RotateLeft[Last[#]]]], Total[#[[2]]]} & /@ traces[[compatibleRules + 1]]];
observationClasses = Table[GatherBy[compatibleRules, Take[modelObservations[#], k] &], {k, 3}];
ambiguityEdges = Flatten[UndirectedEdge @@@ Subsets[#, {2}] & /@ #] & /@ observationClasses;
<|"ClassesPerPanel" -> Length /@ observationClasses, "UnresolvedRulePairs" -> Length /@ ambiguityEdges|>
```

Connect rules with exactly equal observation vectors. Keep their positions fixed:

```wl
GraphicsRow[MapThread[Graph[compatibleRules, #1, VertexCoordinates -> ruleCoordinates, VertexLabels -> "Name",
        GraphHighlight -> {51, 204}, PlotLabel -> #2] &,
    {ambiguityEdges, {"Final occupied count", "+ neighbor differences", "+ step-1 occupied count"}}]]
```

The panels leave 172, 47 and 9 unresolved pairs. Equality forms equivalence
classes for these observations and this run, not for every initial state.

Rule 51 flips each site; rule 204 copies it. After 32 steps both reproduce the
initial array. At step 1 their occupied counts are 55 and 41, so a transient
observation separates them. Counts still cannot distinguish copying from a
spatial shift; that needs site-resolved observations.

The lesson is to specify the observation process before interpreting a rule
search. Biological dynamics require justified spatial or temporal measurements
and independent prediction tests. More candidate rules cannot recover
information discarded by the observation map. Continue with
[Choosing Measurements to Distinguish Models](paclet:WolframInstitute/BioDataLink/tutorial/ChoosingMeasurementsToDistinguishModels)
for finite measurement budgets and error bounds.

## Initialization

Measure adjacent-state disagreement on the ring:

```wl
disagreement[state_] := Mean[Abs[state - RotateLeft[state]]];
```
