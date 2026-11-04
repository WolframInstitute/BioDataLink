---
Template: TechNote
Name: ExploringCellularAutomatonHypotheses
Title: Exploring Cellular Automaton Hypotheses
Context: WolframInstitute`BioDataLink`
Paclet: WolframInstitute/BioDataLink
URI: WolframInstitute/BioDataLink/tutorial/ExploringCellularAutomatonHypotheses
Keywords: [application, cellular automata, rule space, identifiability, observation map, mutation graph, model complexity, biology]
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
irisFile = FileNameJoin[{PacletObject["WolframInstitute/BioDataLink"]["AssetLocation", "Examples"], "iris.csv"}];
rows = DeleteCases[Import[irisFile, "CSV"], {} | {""}];
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
Histogram[widths, {0, 2.6, 0.1}, "Count", GridLines -> {{threshold}, None},
    AxesLabel -> {"Petal width (cm)", "Plant records"}]
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

Plot the constructed initial state. Black denotes state 1 and white state 0;
neither represents a directly observed molecular state:

```wl
ArrayPlot[{initial}, Frame -> True, FrameTicks -> {{None, None}, {Automatic, None}},
    FrameLabel -> {None, "Hypothetical site index"}]
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
GraphicsGrid[Partition[Table[ArrayPlot[traces[[rule + 1]], Frame -> True,
    FrameTicks -> {{{1, "0"}, {17, "16"}, {33, "32"}}, None},
    FrameLabel -> {"Step (downward)", "Site"}, PlotLabel -> Row[{"Rule ", rule}]],
    {rule, {0, 30, 54, 90, 110, 150, 170, 204, 232}}], 3]]
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
ListPlot[Transpose[N[{finalFractions, finalDisagreements}]], PlotRange -> {{0, 1}, {0, 1}},
    AxesLabel -> {"Final occupied fraction", "Final neighbor disagreement"},
    GridLines -> {{N[targetFraction]}, None}]
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
ListLinePlot[fractions[[selectedRules + 1]], DataRange -> {0, steps}, PlotRange -> {0, 1},
    AxesLabel -> {"Model step", "Occupied fraction"},
    PlotLegends -> ("Rule " <> ToString[#] & /@ selectedRules), GridLines -> {None, {N[targetFraction]}}]
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
alternativeInitials = BlockRandom[SeedRandom[20261105]; Table[RandomSample[initial], {20}]];
seedFractions = Table[N[Mean[Last[CellularAutomaton[rule, seed, steps]]]],
    {rule, selectedRules}, {seed, alternativeInitials}];
BoxWhiskerChart[seedFractions, ChartLabels -> selectedRules, PlotRange -> {0, 1},
    FrameLabel -> {"Rule", "Final occupied fraction"}, GridLines -> {None, {N[targetFraction]}}]
```

Identity and shift preserve the fraction for every permutation on the ring.
Other compatible rules may depend on the arrangement. These repetitions probe
the model assumption; they do not increase biological replication or validate
the ring topology. A different boundary condition or observation time would
define a different experiment.

## Are the compatible rules connected by small changes?

A list of accepted rules does not reveal whether a small program change can
move between them. Construct a mutation graph: each vertex is one of the same
21 compatible rule numbers, and an undirected edge changes exactly one of the
eight rule-table outputs. The empirical criterion, seed, boundary and step
count remain unchanged. No additional rule is admitted for this graph.

An elementary rule number encodes eight binary outputs. Flipping bit 0 changes
the output for neighborhood 000, while flipping bit 7 changes the output for
111. [BitXor (WL)](https://reference.wolfram.com/language/ref/BitXor.html) makes
each of these eight possible changes explicit. A membership association avoids
searching the accepted list repeatedly:

```wl
compatibleSet = AssociationThread[compatibleRules, ConstantArray[True, Length[compatibleRules]]];
mutationEdges = Flatten[Table[With[{neighbor = BitXor[rule, 2^bit]},
    If[rule < neighbor && KeyExistsQ[compatibleSet, neighbor], UndirectedEdge[rule, neighbor], Nothing]],
    {rule, compatibleRules}, {bit, 0, 7}], 1];
ruleCoordinates = CirclePoints[Length[compatibleRules]];
Graph[compatibleRules, mutationEdges, VertexCoordinates -> ruleCoordinates, VertexLabels -> "Name",
    EdgeLabels -> (# -> Placed[changedNeighborhood[#], Tooltip] & /@ mutationEdges)]
```

Only three pairs are connected: 26–154, 82–210 and 85–117. The other 15 vertices
are isolated under this move. Hovering over an edge identifies the local
neighborhood whose output changes. The circular positions are a display
convention, not a geometric distance between programs.

Isolation does not make a rule implausible. It says that none of its eight
single-output changes also passes this particular comparison. Paths through
rejected rules, changes of several outputs, other initial states or another
observation criterion could connect a different graph. These edges describe
edits to mathematical rule tables, not observed genetic mutations or a
probability law for biological evolution.

This adapts the distinction between rule changes and observed behavior in
Ruliology's
[cellular-automaton rule-space tutorial](https://www.wolframcloud.com/obj/wolframinstitute/DeployedResources/Paclet/WolframInstitute/Ruliology/Documentation/tutorial/AnalyzingCellularAutomatonRuleSpace.html).
An undirected graph is sufficient here because no fitness ordering or
selection process has been defined.

## Which additional observations would separate the rules?

A mutation edge and an observational ambiguity edge answer different
questions. Two distant rule tables can give the same measured summary. For
the same 21 rules, compute three exact integer observables from the already
stored traces: occupied sites at step 32, neighboring pairs with different
states at step 32, and occupied sites at step 1.

These extra values are model predictions. Iris supplies neither a spatial
neighbor measurement nor an observation at model step 1. We are asking which
observations could distinguish candidates if a suitable observation process
were available, rather than pretending those measurements already exist.

```wl
modelObservations = AssociationThread[compatibleRules, Table[
    <|"FinalCount" -> Total[traces[[rule + 1, -1]]],
      "NeighborDifferences" -> Total[Abs[traces[[rule + 1, -1]] -
          RotateLeft[traces[[rule + 1, -1]]]]],
      "FirstStepCount" -> Total[traces[[rule + 1, 2]]]|>,
    {rule, compatibleRules}]];
observationPanels = {{"FinalCount"},
    {"FinalCount", "NeighborDifferences"},
    {"FinalCount", "NeighborDifferences", "FirstStepCount"}};
observationClasses = Table[GatherBy[compatibleRules,
    Lookup[modelObservations[#], panel] &], {panel, observationPanels}];
ambiguityEdges = (Flatten[
    (UndirectedEdge @@@ Subsets[#, {2}]) & /@ #, 1] &) /@ observationClasses;
<|"ClassesPerPanel" -> (Length /@ observationClasses),
  "UnresolvedRulePairs" -> (Length /@ ambiguityEdges)|>
```

Here an edge means that two rules have **exactly the same observation vector**.
Equality of these integer vectors is transitive, so its groups are genuine
equivalence classes for the specified observation panel. This is separate
from the original tolerance around a fixed empirical target. A pairwise
“close enough” relation need not be transitive and would not justify the same
interpretation of connected components.

Keep every vertex in the same position across all three graphs. Add
observations cumulatively, so an unresolved pair can lose its edge but cannot
gain one. Highlight rules 51 and 204 for the comparison below:

```wl
panelTitles = {"Final occupied count", "+ neighbor differences", "+ step-1 occupied count"};
GraphicsRow[Table[Graph[compatibleRules, ambiguityEdges[[panel]],
    VertexCoordinates -> ruleCoordinates, VertexLabels -> "Name",
    GraphHighlight -> {51, 204}, PlotLabel -> panelTitles[[panel]]], {panel, 3}]]
```

The panels leave 172, 47 and 9 unresolved pairs, respectively. Their 2, 10
and 14 classes all refer to the same accepted rules. More detailed model
observations separate some candidates, while the remaining groups identify
ambiguities that this panel still cannot resolve. A group is equivalence
under these observables and this run, not equivalence of the update rules for
all possible initial states.

Rule 51 flips every binary site at each step; rule 204 copies it. Both return
the initial array after the even number of steps used here, so the final
occupied count and final neighbor differences cannot separate them. The
first-step count does: this seed has 41 occupied sites, so copying leaves 41
while flipping gives 55. This illustrates a concrete reason to sample a
transient, rather than only an endpoint. Copying rule 204 and shifting rules
170 and 240 still share a group: these counts do not identify which sites
changed. Site-resolved observations would test a different prediction. The
[measurement-selection tutorial](ChoosingMeasurementsToDistinguishModels.md)
extends the question to finite measurement-panel budgets and imperfect
measurement resolution.

## Increase the neighborhood while keeping the comparison fixed

Now increase what a local update can read. A radius-zero rule sees only its
own current site. A radius-one rule sees that site and one neighbor on each
side. A radius-two rule sees five sites in total. Keep the initial state,
periodic boundary and 32-step observation window fixed.

For unrestricted binary lookup rules of radius *r*, there are
`2^(2 r + 1)` input neighborhoods and one binary output choice for each.
The rule-space size is therefore `2^(2^(2 r + 1))`: 4 rules at radius 0,
256 at radius 1, and 4,294,967,296 at radius 2. Exhaustively repeating the
previous search at radius 2 would be a different computational undertaking.

Instead, define one transparent larger-neighborhood rule: output 1 when at
least three of five sites are 1. This is a totalistic rule, meaning that only
the count of occupied input sites matters, not their arrangement. It is one
of 64 radius-two binary totalistic lookup rules, a small restricted family
within the full space. The following constructs just 32 outputs to specify
this one rule; it does not enumerate billions of candidate rules.

```wl
comparisonSpecs = {{0, 2, 0}, {2, 2, 0},
    {majorityRuleNumber[1], 2, 1}, {majorityRuleNumber[2], 2, 2}};
comparisonNames = {"constant 0 (radius 0)", "copy (radius 0)",
    "majority (radius 1)", "majority (radius 2)"};
comparisonTraces = CellularAutomaton[#, initial, steps] & /@ comparisonSpecs;
GraphicsGrid[Partition[Table[ArrayPlot[comparisonTraces[[i]], Frame -> True,
    FrameTicks -> {{{1, "0"}, {17, "16"}, {33, "32"}}, None},
    FrameLabel -> {"Step (downward)", "Site"}, PlotLabel -> comparisonNames[[i]]], {i, 4}], 2]]
```

The three-site majority is elementary rule 232; the five-site lookup number
is 4276676736. Constant and copying updates provide simple reference cases.
The two majority rules use the same voting principle but have access to
different local information. Increased radius does not, by itself, explain
the biological measurements or guarantee a closer summary match.

Compare the same two final-state observables across these four deliberately
chosen programs. The horizontal grid line applies only to the occupied fraction; no
empirical neighbor-disagreement value was supplied:

```wl
comparisonFractions = Mean /@ comparisonTraces[[All, -1]];
comparisonDisagreements = disagreement /@ comparisonTraces[[All, -1]];
comparisonTicks = Transpose[{Range[4], {"constant r=0", "copy r=0", "majority r=1", "majority r=2"}}];
GraphicsRow[{
    ListPlot[comparisonFractions, Ticks -> {comparisonTicks, Automatic}, PlotRange -> {{0.5, 4.5}, {-0.05, 1.05}},
        AxesLabel -> {None, "Final occupied fraction"}, GridLines -> {None, {N[targetFraction]}}],
    ListPlot[comparisonDisagreements, Ticks -> {comparisonTicks, Automatic}, PlotRange -> {{0.5, 4.5}, {-0.05, 1.05}},
        AxesLabel -> {None, "Final neighbor disagreement"}]}]
```

In this run, copying comes closest to the empirical fraction because the
initial fraction was constructed to match it. The majority rules reduce
neighbor disagreement while also lowering the occupied fraction. The wider
neighborhood therefore does not improve agreement with this particular
constraint. Zero disagreement is achieved by the constant-zero rule as well;
that statistic alone does not identify a useful biological organization.

These are illustrative programs, not four fitted winners or a search over
all radius-two rules. The unrestricted larger family can express more
responses to local configurations, while the two retained summaries still
discard most of each trace. Evaluating a richer family scientifically would
require observations that constrain its additional inputs: for example,
measured five-site neighborhoods and subsequent state changes, with an
explicit mapping from biological measurements to sites and states. Iris
provides none of that spatial or temporal information.

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
- [BitXor (WL)](https://reference.wolfram.com/language/ref/BitXor.html) changes specified binary outputs in a numbered rule table.
- [Graph (WL)](https://reference.wolfram.com/language/ref/Graph.html) retains explicit vertices, including isolated rules, with their source rule numbers.
- [VertexCoordinates (WL)](https://reference.wolfram.com/language/ref/VertexCoordinates.html) fixes vertex positions across observation comparisons.

## Initialization

Evaluate these helper definitions before the examples above. The data choices
and analysis parameters remain in the main examples.

```wl
disagreement[state_] := Mean[Abs[state - RotateLeft[state]]];
changedNeighborhood[UndirectedEdge[a_, b_]] := IntegerDigits[IntegerLength[BitXor[a, b], 2] - 1, 2, 3];
majorityRuleNumber[radius_] := FromDigits[
    Boole[Total[#] >= radius + 1] & /@ Tuples[{1, 0}, 2 radius + 1], 2];
```
