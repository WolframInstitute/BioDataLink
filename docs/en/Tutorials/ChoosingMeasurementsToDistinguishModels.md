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

Evaluate the Initialization section at the end before running the examples.

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
The `prediction` helper defines the following six expressions:

```wl
prediction[{a, b, c}]
```

Enumerate the eight parameter choices and evaluate their predictions:

```wl
predictions = prediction /@ Tuples[{0, 1}, 3];
```

Name the rows and columns before plotting:

```wl
modelIDs = Range[Length[predictions]];
observableNames = {"A baseline", "B baseline", "A pulse", "B pulse", "A recovery", "B recovery"};
measurementIDs = Range[Length[observableNames]];
```

```wl
MatrixPlot[predictions, PlotLegends -> Automatic, FrameLabel -> {"candidate model", "observable"}]
```

Row numbers identify the models; column numbers follow `observableNames`.
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
separation = separationMatrix[epsilon];
```

```wl
ArrayPlot[separation, FrameTicks -> Automatic, AspectRatio -> 1, FrameLabel -> {"model pair", "observable"}]
```

Each black square identifies one pair separated by one observable under this
bound. Row numbers follow `modelPairs`; columns follow `observableNames`. Counting dark squares alone is insufficient when selecting several
observables: two columns may separate many of the same pairs.

## Add measurements that cover unresolved pairs

Count each unordered model pair once. A panel covers a pair when at least one
of its observables separates that pair. This is an unweighted combinatorial
objective, not expected information gain. It assigns no different importance
to models, outcomes, assay costs or biological consequences.

The `greedyPanel` helper repeatedly adds the observable that separates
the most uncovered pairs. Ties go to the first remaining observable in the
recorded column order. It stops when no observable provides a positive gain.
Its definition is in Initialization:

```wl
greedyOrder = greedyPanel[separation];
observableNames[[greedyOrder]]
```

Count the pairs separated after each addition:

```wl
coverage[Take[greedyOrder, #], separation] & /@ Range[Length[greedyOrder]]
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
fixedCoordinates = N[CirclePoints[Length[modelIDs]]];
panels = Table[Take[greedyOrder, k], {k, 0, Length[greedyOrder]}];
graphs = modelGraph[#, epsilon] & /@ panels;
```

```wl
With[{panelLabels = Prepend[StringRiffle[observableNames[[#]], " + "] & /@ Rest[panels], "No measurements"]},
    GraphicsGrid[Partition[MapThread[Labeled, {graphs, panelLabels}], 2]]]
```

```wl
EdgeCount /@ graphs
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
With[{budgets = Range[0, Length[measurementIDs]]},
    ListPlot[Flatten[Table[{k, coverage[panel, separation]}, {k, budgets}, {panel, Subsets[measurementIDs, {k}]}], 1],
        AxesLabel -> {"observables", "separated pairs"}]]
```

Compute the best score for each exact panel size, then compare both orders:

```wl
With[{budgets = Range[0, Length[measurementIDs]]},
    ListLinePlot[{Table[Max[coverage[#, separation] & /@ Subsets[measurementIDs, {k}]], {k, budgets}],
            coverage[Take[greedyOrder, UpTo[#]], separation] & /@ budgets,
            coverage[Take[measurementIDs, #], separation] & /@ budgets},
        DataRange -> {0, 6}, PlotMarkers -> Automatic, PlotLegends -> {"best exact-size panel", "greedy", "source order"},
        AxesLabel -> {"observable budget", "separated pairs"}]]
```

The points represent every panel, with overlaps where scores coincide.
The best-panel and greedy curves coincide in this fixture. The greedy
procedure reaches the exact optimum here and needs three
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
ListStepPlot[Transpose[Table[{coverage[greedyOrder, m], coverage[measurementIDs, m],
        Max[coverage[#, m] & /@ Subsets[measurementIDs, {3}]]}, {m, separationMatrix /@ (Range[0, 40]/40)}]],
    Right, DataRange -> {0, 1}, PlotLegends -> {"fixed low-error panel", "all six observables", "best three at each bound"},
    AxesLabel -> {"assumed absolute error bound", "separated pairs"}]
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
GraphicsRow[Table[Labeled[modelGraph[{5}, bound], Row[{"error bound: ", bound}]],
    {bound, {1/10, 3/5, 1}}]]
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


## Initialization

Define the synthetic prediction model:

```wl
prediction[{a_, b_, c_}] := {1 + 2 a, 1 + 2 b, 1 + 2 Mod[a + b, 2], 1 + c/2, 1 + a + b, 1 + Mod[a + c, 2]/2};
```

Compare each pair of prediction rows against the stated error bound:

```wl
separationMatrix[bound_] := Boole[Thread[Abs[Subtract @@ predictions[[#]]] > 2 bound]] & /@ modelPairs;
coveredPairs[panel_, matrix_] := Union @@ (Flatten[Position[matrix[[All, #]], 1]] & /@ panel);
coverage[panel_, matrix_] := Length[coveredPairs[panel, matrix]];
```

At each greedy step, consider the current panel first, followed by its
one-observable extensions in column order. `MaximalBy` retains ties in that
order. Keeping the current panel first stops the process when no extension
improves its score:

```wl
greedyStep[panel_, matrix_] := First[MaximalBy[Prepend[Append[panel, #] & /@ Complement[measurementIDs, panel], panel], coverage[#, matrix] &]];
greedyPanel[matrix_] := NestWhile[greedyStep[#, matrix] &, {}, UnsameQ, 2];
```

Build each graph from unresolved pairs, retaining all vertices and the same
coordinates. Labels identify models; their positions do not imply biology:

```wl
modelGraph[panel_, bound_] := Graph[modelIDs,
    UndirectedEdge @@@ modelPairs[[Complement[Range[Length[modelPairs]], coveredPairs[panel, separationMatrix[bound]]]]],
    VertexCoordinates -> fixedCoordinates, VertexLabels -> Automatic];
```
