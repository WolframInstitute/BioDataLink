---
Template: TechNote
Name: ChoosingMeasurementsToDistinguishModels
Title: Choosing Measurements to Distinguish Models
Context: WolframInstitute`BioDataLink`
Paclet: WolframInstitute/BioDataLink
URI: WolframInstitute/BioDataLink/tutorial/ChoosingMeasurementsToDistinguishModels
Keywords: [application, model comparison, measurement selection, graphs, observability, tolerance, synthetic]
RelatedGuides: [BioDataLink, ComputationalExplorations, DataAccess]
---

Several models can agree on the measurements already considered. Which
additional observable would separate their predictions? This tutorial moves
from one measurement to a panel, then asks how the answer changes when
measurement precision is limited.

Everything below is synthetic: the candidate models, marker names, predicted
responses and error bounds. The calculation demonstrates a model-conditional
comparison, not an experimental result or a recommendation for a biological
assay. It uses native Wolfram Language graphs and small exhaustive computations;
no external modeling paclet or online data is required.

The connection to the [Ruliology rule-space tutorial](https://www.wolframcloud.com/obj/wolframinstitute/DeployedResources/Paclet/WolframInstitute/Ruliology/Documentation/tutorial/AnalyzingCellularAutomatonRuleSpace.html)
is the distinction between a complete rule and the cases an observation
constrains. Here the prediction matrix is supplied explicitly so that we can
study the measurement choice separately from how predictions were generated.

## Specify a small family of candidate predictions

Let each candidate have three binary choices, `a`, `b` and `c`. These are
mathematical parameters, not identified genes or mechanisms. Define six
possible observables: marker A and marker B at a baseline, after a pulse and
during recovery. The labels describe hypothetical measurement conditions;
the values below are invented dimensionless signals, not simulated biology.

```wl
candidateParameters = Tuples[{0, 1}, 3];
modelIDs = Range[Length[candidateParameters]];
modelNames = ("M" <> ToString[#] &) /@ modelIDs;
observableNames = {"A baseline", "B baseline", "A pulse", "B pulse", "A recovery", "B recovery"};
predictions = Function[parameters,
    With[{a = parameters[[1]], b = parameters[[2]], c = parameters[[3]]},
        {1 + 2 a, 1 + 2 b, 1 + 2 Mod[a + b, 2],
            1 + c/2, 1 + a + b, 1 + Mod[a + c, 2]/2}]] /@ candidateParameters;
Legended[ArrayPlot[predictions, Frame -> True, AspectRatio -> 1,
    FrameTicks -> {{Transpose[{modelIDs, modelNames}], None},
        {Transpose[{Range[6], observableNames}], None}},
    FrameLabel -> {"candidate model", "observable"}, PlotRange -> {1, 3},
    ColorFunction -> "SolarColors", ImageSize -> 560],
    BarLegend[{"SolarColors", {1, 3}}, LegendLabel -> "synthetic signal"]]
```

The rows preserve model identity across every later figure. There are eight
candidate models and six possible observables. Changing only `c` changes the
affected predictions by half a signal unit, whereas some other differences span
two units.
A measurement's usefulness therefore depends on both the candidate predictions
and the assumed precision.

## Define what one measurement can distinguish

Assume the absolute measurement error is bounded by `epsilon`. For a predicted
value `mu`, any outcome in the closed interval `mu ± epsilon` is allowed.
Two candidates are guaranteed to have disjoint outcome intervals for one
observable only when their predictions differ by **more than** `2 epsilon`.
Touching intervals at equality still overlap.

For a panel, require this strict separation on at least one selected observable.
Otherwise the two rectangular sets of allowed outcomes overlap: some common
outcome could be consistent with both models. This criterion permits every
combination of coordinate errors within the stated bounds; it does not assign
an error distribution, model probability or likelihood.

```wl
epsilon = 1/10;
modelPairs = Subsets[modelIDs, {2}];
measurementIDs = Range[Length[observableNames]];
separationMatrix[bound_] := Table[
    Boole[Abs[predictions[[pair[[1]], j]] - predictions[[pair[[2]], j]]] > 2 bound],
    {pair, modelPairs}, {j, measurementIDs}];
separation = separationMatrix[epsilon];
pairLabels = (StringRiffle[modelNames[[#]], " / "] &) /@ modelPairs;
Legended[ArrayPlot[separation, Frame -> True, AspectRatio -> 1.25,
    ColorRules -> {0 -> RGBColor[0.93, 0.95, 0.98], 1 -> RGBColor[0.14, 0.36, 0.58]},
    FrameTicks -> {{Transpose[{Range[Length[modelPairs]], pairLabels}], None},
        {Transpose[{measurementIDs, observableNames}], None}},
    FrameLabel -> {"unordered model pair", "single observable"}, ImageSize -> 620],
    SwatchLegend[{RGBColor[0.93, 0.95, 0.98], RGBColor[0.14, 0.36, 0.58]},
        {"intervals overlap", "intervals separated"}]]
```

Each dark square identifies one pair separated by one observable under this
bound. Counting dark squares alone is insufficient when selecting several
observables: two columns may separate many of the same pairs.

## Add measurements that cover unresolved pairs

Count each unordered model pair once. A panel covers a pair when at least one
of its observables separates that pair. This is an unweighted combinatorial
objective, not expected information gain. It assigns no different importance
to models, outcomes, assay costs or biological consequences.

The following greedy procedure repeatedly adds the observable that separates
the most uncovered pairs. Ties go to the first remaining observable in the
recorded column order. It stops when no observable provides a positive gain:

```wl
coveredPairs[panel_, matrix_] := If[panel === {}, {},
    Select[Range[Length[modelPairs]], Max[matrix[[#, panel]]] == 1 &]];
coverage[panel_, matrix_] := Length[coveredPairs[panel, matrix]];
greedyPanel[matrix_] := Module[{panel = {}, remaining = measurementIDs,
    covered = {}, gains, best},
    While[remaining =!= {},
        gains = (Length[Complement[coveredPairs[{#}, matrix], covered]] &) /@ remaining;
        If[Max[gains] == 0, Break[]];
        best = remaining[[First[FirstPosition[gains, Max[gains]]]]];
        AppendTo[panel, best];
        covered = coveredPairs[panel, matrix];
        remaining = DeleteCases[remaining, best]];
    panel];
greedyOrder = greedyPanel[separation];
<|"ChosenOrder" -> observableNames[[greedyOrder]],
    "PairsSeparatedAfterEachAddition" ->
        Table[coverage[Take[greedyOrder, k], separation], {k, Length[greedyOrder]}]|>
```

The chosen sequence is A recovery, B pulse, then A baseline. It separates
20, 26 and finally all 28 candidate pairs. At the second step another observable
has the same gain; the stated tie rule makes this particular path reproducible.
No measurement outcome has yet been observed, so no candidate has been rejected.

## Keep graph positions fixed while edges disappear

Make one vertex per model. An edge means the selected panel has **not**
guaranteed separation of that pair: their allowed outcome boxes overlap.
Adding measurements removes such edges but retains every vertex, including
isolated models. Vertex positions have no biological or geometric meaning.

Use [VertexCoordinates](https://reference.wolfram.com/language/ref/VertexCoordinates.html)
to reuse the same circle in every graph, so a layout change cannot masquerade
as a change in model relationships:

```wl
fixedCoordinates = Thread[modelIDs -> N[CirclePoints[Length[modelIDs]]]];
modelGraph[panel_, bound_, title_] := Module[{matrix, unresolved},
    matrix = separationMatrix[bound];
    unresolved = Complement[Range[Length[modelPairs]], coveredPairs[panel, matrix]];
    Graph[modelIDs, (UndirectedEdge @@ # &) /@ modelPairs[[unresolved]],
        VertexCoordinates -> fixedCoordinates,
        VertexLabels -> MapThread[#1 -> Placed[Style[#2, White, 11], Center] &,
            {modelIDs, modelNames}],
        VertexStyle -> RGBColor[0.14, 0.36, 0.58], VertexSize -> {"Scaled", 0.12},
        EdgeStyle -> Directive[RGBColor[0.68, 0.43, 0.18], Opacity[0.7], AbsoluteThickness[1.3]],
        PlotLabel -> Column[{title, ToString[Length[unresolved]] <> " unresolved pairs"},
            Alignment -> Center], ImagePadding -> 18, ImageSize -> 310]];
panels = Table[Take[greedyOrder, k], {k, 0, Length[greedyOrder]}];
Grid[Partition[Map[Function[panel,
    modelGraph[panel, epsilon,
        If[panel === {}, "no measurements", StringRiffle[observableNames[[panel]], " +\n"]]]],
    panels], 2], Spacings -> {2, 1}]
```

The graph progresses from 28 edges to 8, then 2, then none. A missing edge is
separation under these predictions and bounds; it is not a measured causal
interaction or an observed transition. An empty graph means every pair in this
finite candidate family has disjoint allowed outcomes on the selected panel.
It does not establish that the true biological system is one of these models.

## Compare the greedy panel with every small alternative

Six observables have only 64 subsets, including the empty panel. Enumerate
them with [Subsets](https://reference.wolfram.com/language/ref/Subsets.html)
and find the largest coverage at each exact panel size. Also compare simply
adding columns in their original order:

```wl
budgets = Range[0, Length[measurementIDs]];
allPanelScores = Flatten[Table[
    {k, coverage[panel, separation]}, {k, budgets}, {panel, Subsets[measurementIDs, {k}]}], 1];
optimalCoverage = Table[Max[coverage[#, separation] & /@ Subsets[measurementIDs, {k}]], {k, budgets}];
greedyCoverage = Table[coverage[Take[greedyOrder, UpTo[k]], separation], {k, budgets}];
sourceOrderCoverage = Table[coverage[Take[measurementIDs, k], separation], {k, budgets}];
coverageStyles = {Directive[RGBColor[0.14, 0.36, 0.58], Thick],
    Directive[RGBColor[0.85, 0.43, 0.12], Dashed, Thick],
    Directive[RGBColor[0.35, 0.6, 0.4], Thick]};
Legended[Show[
    ListPlot[allPanelScores, PlotStyle -> Directive[Gray, Opacity[0.35], PointSize[0.017]]],
    ListLinePlot[{Transpose[{budgets, optimalCoverage}],
        Transpose[{budgets, greedyCoverage}], Transpose[{budgets, sourceOrderCoverage}]},
        PlotStyle -> coverageStyles, PlotMarkers -> Automatic],
    Frame -> True, Axes -> False, PlotRange -> {{-0.1, 6.1}, {0, 29}},
    FrameLabel -> {"observable budget", "separated pairs out of 28"}, ImageSize -> 700],
    Placed[LineLegend[coverageStyles,
        {"best exact-size panel", "greedy, up to budget", "source column order"}], Below]]
```

Grey points represent every panel, with overlaps where scores coincide. The
greedy curve reaches the exact optimum in this fixture and needs three
observables for complete separation. Its curve stops adding measurements once
all pairs are covered; larger budgets are allowances, not measurements actually
added. No pair of observables can cover all 28 pairs here. The original column
order needs four observables because its third column adds no separation beyond
the first two. Greedy selection is not guaranteed to be optimal for a different
prediction matrix or objective.

## Reconsider the panel when precision changes

Hold the low-error greedy panel fixed and increase the assumed error bound.
Compare it with all six observables and with the best three-observable panel
reselected at each bound. The plot uses exact rational bounds and steps to the
right, so equality retains the closed-interval overlap convention:

```wl
errorBounds = Range[0, 40]/40;
noiseCoverage = Table[With[{matrix = separationMatrix[bound]},
    {coverage[greedyOrder, matrix], coverage[measurementIDs, matrix],
        Max[coverage[#, matrix] & /@ Subsets[measurementIDs, {3}]]}], {bound, errorBounds}];
ListStepPlot[(Transpose[{errorBounds, #}] & /@ Transpose[noiseCoverage]), Right,
    Frame -> True, Axes -> False, PlotRange -> {{0, 1.03}, {-0.5, 29}},
    FrameLabel -> {"assumed absolute error bound", "separated pairs out of 28"},
    PlotStyle -> {Directive[RGBColor[0.85, 0.43, 0.12], Thick],
        Directive[RGBColor[0.14, 0.36, 0.58], Thick], Directive[RGBColor[0.35, 0.6, 0.4], Dashed, Thick]},
    PlotLegends -> Placed[{"fixed low-error panel", "all six observables", "best three at each bound"}, Below],
    ImageSize -> 700]
```

At a bound of 0.25, the half-unit differences involving `c` no longer guarantee
separation: their intervals touch. Even all six observables then leave four
pairs unresolved. At larger bounds the panel chosen for low error can perform
worse than a newly selected panel. These changes follow the supplied numbers;
no noise distribution or experimental precision has been estimated.

More observations of the same kind do not automatically resolve this limit.
The calculation does not model replication, correlated errors, model parameter
uncertainty or a systematic bias that repeats across measurements. Those require
an explicit extension of the observation model.

## Do not mistake graph connectivity for indistinguishability

Return to A recovery alone, whose possible predictions are 1, 2 and 3. Compare
three error bounds using the same model positions:

```wl
Grid[{Table[Graph[modelGraph[{5}, bound,
    "A recovery; error bound " <> ToString[N[bound]]], ImageSize -> 240],
    {bound, {1/10, 3/5, 1}}]},
    Spacings -> {1, 0}]
```

At a bound of 0.6, a model predicting 1 overlaps a model predicting 2, and that
model overlaps one predicting 3. Predictions 1 and 3 still have disjoint
intervals. The graph is connected, but those pairs are distinguishable. Pairwise
interval overlap is not transitive, so connected components are not equivalence
classes of mutually indistinguishable models. The edges, rather than component
membership, carry the stated meaning.

A useful next measurement must therefore be described relative to a candidate
family, predicted observables, a defensible observation model and an explicit
objective. The [cellular-automaton hypothesis tutorial](paclet:WolframInstitute/BioDataLink/tutorial/ExploringCellularAutomatonHypotheses)
shows a setting where candidate predictions come from update rules.
[Understanding Sparse Measurements](paclet:WolframInstitute/BioDataLink/tutorial/UnderstandingSparseMeasurements)
shows why an absent measurement cannot be silently treated as a measured zero
when constructing such a comparison.
