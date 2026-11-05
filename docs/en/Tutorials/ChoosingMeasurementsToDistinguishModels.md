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

Choose measurements that separate candidate predictions under a stated error
bound. Models, marker names, signals and error bounds here are **synthetic**;
this is a method demonstration, not an assay recommendation.

Evaluate **Initialization**, then run the examples in order.

## Specify predictions and precision

Eight models differ in three binary parameters. Each predicts six dimensionless
signals at hypothetical baseline, pulse and recovery conditions:

```wl
prediction[{a, b, c}]
```

Enumerate the candidate models:

```wl
predictions = prediction /@ Tuples[{0, 1}, 3];
```

```wl
modelIDs = Range[Length[predictions]];
observableNames = {"A baseline", "B baseline", "A pulse", "B pulse", "A recovery", "B recovery"};
measurementIDs = Range[Length[observableNames]];
```

Display their predicted signals:

```wl
MatrixPlot[predictions, PlotLegends -> Automatic, FrameLabel -> {"candidate model", "observable"}]
```

If absolute error is bounded by `epsilon`, each prediction allows a closed
interval of ±`epsilon`. Two models are guaranteed to separate only when at
least one selected observable differs by **more than** `2 epsilon`.
Equality still permits an overlapping outcome.

```wl
epsilon = 1/10;
modelPairs = Subsets[modelIDs, {2}];
separation = separationMatrix[epsilon];
```

Show which measurements separate each model pair:

```wl
ArrayPlot[separation, FrameTicks -> Automatic, AspectRatio -> 1, FrameLabel -> {"model pair", "observable"}]
```

Black entries mark separated model pairs. A panel covers a pair if any selected
column separates it. This unweighted objective assigns no probabilities, assay
costs or different importance to models.

## Add informative measurements

Greedily add the column covering the most unresolved pairs. Ties follow column
order; stop when no column adds coverage:

```wl
greedyOrder = greedyPanel[separation];
observableNames[[greedyOrder]]
```

Count separated pairs as measurements are added:

```wl
coverage[Take[greedyOrder, #], separation] & /@ Range[Length[greedyOrder]]
```

A recovery, B pulse and A baseline separate 20, 26 and then all 28 pairs.
No outcome has been measured, so no model has yet been rejected.

Display unresolved pairs as edges, keeping every model at a fixed position:

```wl
fixedCoordinates = N[CirclePoints[Length[modelIDs]]];
panels = Table[Take[greedyOrder, k], {k, 0, Length[greedyOrder]}];
graphs = modelGraph[#, epsilon] & /@ panels;
```

Plot unresolved pairs for each panel:

```wl
With[{panelLabels = Prepend[StringRiffle[observableNames[[#]], " + "] & /@ Rest[panels], "No measurements"]},
    Grid[Partition[MapThread[Labeled, {graphs, panelLabels}], 2], Spacings -> {2, 2}]]
```

The graphs retain 28, 8, 2 and finally zero edges. An empty graph means full
pairwise separation within this candidate family and error model, not proof
that the true system belongs to the family.

## Check the greedy result

Compare all 64 subsets of the six observables with the greedy and original
column orders:

```wl
With[{budgets = Range[0, Length[measurementIDs]]},
    ListLinePlot[{Table[Max[coverage[#, separation] & /@ Subsets[measurementIDs, {k}]], {k, budgets}],
            coverage[Take[greedyOrder, UpTo[#]], separation] & /@ budgets,
            coverage[Take[measurementIDs, #], separation] & /@ budgets},
        DataRange -> {0, 6}, PlotMarkers -> Automatic, PlotLegends -> {"best exact-size panel", "greedy", "source order"},
        AxesLabel -> {"observable budget", "separated pairs"}]]
```

Greedy selection reaches the optimum here: three observables separate every
pair, while source order needs four. Greedy selection is not generally optimal.
Larger budgets on its curve do not add measurements after full coverage.

## Test the precision assumption

Increase the error bound. Compare the fixed panel, all six measurements and
the best three-measurement panel reselected at each bound:

```wl
ListStepPlot[Transpose[Table[{coverage[greedyOrder, m], coverage[measurementIDs, m],
        Max[coverage[#, m] & /@ Subsets[measurementIDs, {3}]]}, {m, separationMatrix /@ (Range[0, 40]/40)}]],
    Right, DataRange -> {0, 1}, PlotLegends -> {"fixed low-error panel", "all six observables", "best three at each bound"},
    AxesLabel -> {"assumed absolute error bound", "separated pairs"}]
```

At `epsilon = 0.25`, half-unit prediction differences cease to guarantee
separation; even all six measurements leave four pairs unresolved. A panel
chosen for low error can become inferior at higher error.

The calculation permits every combination of errors within the bounds. It does
not model error probabilities, replication, correlated errors, bias or parameter
uncertainty. Overlap is not transitive: graph connectivity does not mean all
model pairs are indistinguishable. Interpret individual edges.

For predictions generated by update rules, see
[Exploring Cellular Automaton Hypotheses](paclet:WolframInstitute/BioDataLink/tutorial/ExploringCellularAutomatonHypotheses).

## Include unequal measurement costs

Assign synthetic costs to the six observables and enumerate every panel. Plot
cost against the number of separated model pairs; identify panels for which no
other panel costs less and separates at least as many pairs.

```wl
measurementCosts = {1, 1, 3, 2, 4, 3};
allPanels = Subsets[measurementIDs];
panelResults = {Total[measurementCosts[[#]]], coverage[#, separation]} & /@ allPanels;
frontier = Select[Range[Length[allPanels]], Function[i,
    !AnyTrue[Delete[panelResults, i], #[[1]] <= panelResults[[i, 1]] && #[[2]] >= panelResults[[i, 2]] && # =!= panelResults[[i]] &]]];
ListPlot[{panelResults, panelResults[[frontier]]}, PlotStyle -> {Gray, Red}, Frame -> True,
    FrameLabel -> {"synthetic measurement cost", "separated model pairs"}, PlotLegends -> {"all panels", "nondominated panels"}]
```

This replaces a count budget with an explicit cost model. Costs are invented;
changing them can change the preferred panel without changing any prediction.

## Observe a synthetic outcome and update the candidate set

Use model 3 to generate one outcome with bounded errors. Retain models whose
predictions agree with every selected observation to within the original bound.

```wl
syntheticTruth = 3;
syntheticOutcome = BlockRandom[SeedRandom[20261106]; predictions[[syntheticTruth]] + RandomReal[{-epsilon, epsilon}, 6]];
survivors = Table[Select[modelIDs, Function[id, AllTrue[panel,
    Abs[predictions[[id, #]] - syntheticOutcome[[#]]] <= epsilon &]]], {panel, panels}];
GraphicsRow[MapThread[Graph[modelIDs, {}, VertexCoordinates -> fixedCoordinates,
    VertexLabels -> Automatic, VertexStyle -> Thread[#1 -> Orange], ImageSize -> 180,
    PlotLabel -> Row[{#2, " measurements"}]] &,
    {survivors, Range[0, Length[panels] - 1]}], ImageSize -> Large]
```

Highlighted vertices remain compatible with this particular observed outcome.
This differs from guaranteed pair separation, which considers every allowed
outcome. The true model remains only because it belongs to the candidate family
and the simulated errors obey the assumed bound.

## Repeat outcomes without changing the experiment

Generate 100 new bounded-error outcomes from each model. Count compatible
models for the first one, two and three greedy measurements:

```wl
survivorCounts = BlockRandom[SeedRandom[20261107]; Table[
    Flatten[Table[With[{outcome = predictions[[truth]] + RandomReal[{-epsilon, epsilon}, 6]},
        Count[modelIDs, id_ /; AllTrue[Take[greedyOrder, budget], Abs[predictions[[id, #]] - outcome[[#]]] <= epsilon &]]],
        {truth, modelIDs}, {100}]], {budget, Length[greedyOrder]}]];
BoxWhiskerChart[survivorCounts, ChartLabels -> Range[Length[greedyOrder]],
    FrameLabel -> {"greedy measurements", "compatible models per simulated outcome"}]
```

The simulation adds an independent uniform-error distribution that was absent
from the worst-case guarantee. Its frequencies are conditional on that new
assumption and the equally weighted candidate models.

## Locate the hardest model pair

For each three-measurement panel, compute the smallest maximum prediction
separation over all model pairs. Half this value is the largest common error
bound below which that panel guarantees full separation.

```wl
threePanels = Subsets[measurementIDs, {3}];
separationMargins = Table[Min[Max[Abs[Subtract @@ predictions[[#, panel]]]] & /@ modelPairs]/2, {panel, threePanels}];
BarChart[N[separationMargins], Frame -> True, ChartLabels -> (StringRiffle[ToString /@ #, ","] & /@ threePanels),
    FrameLabel -> {"three-measurement panel (column IDs)", "strict upper bound on guaranteed error"}, ImageSize -> Large]
```

The minimum pair determines a guarantee, even if most pairs are easy to
separate. Combine margins, costs and plausible error models before choosing
measurements; none of these synthetic calculations recommends a real assay.

## Initialization

Synthetic predictions, strict interval separation, greedy coverage and fixed
graph positions:

```wl
prediction[{a_, b_, c_}] := {1 + 2 a, 1 + 2 b, 1 + 2 Mod[a + b, 2], 1 + c/2, 1 + a + b, 1 + Mod[a + c, 2]/2};
```

```wl
separationMatrix[bound_] := Boole[Thread[Abs[Subtract @@ predictions[[#]]] > 2 bound]] & /@ modelPairs;
coveredPairs[panel_, matrix_] := Union @@ (Flatten[Position[matrix[[All, #]], 1]] & /@ panel);
coverage[panel_, matrix_] := Length[coveredPairs[panel, matrix]];
```

```wl
greedyStep[panel_, matrix_] := First[MaximalBy[Prepend[Append[panel, #] & /@ Complement[measurementIDs, panel], panel], coverage[#, matrix] &]];
greedyPanel[matrix_] := NestWhile[greedyStep[#, matrix] &, {}, UnsameQ, 2];
```

```wl
modelGraph[panel_, bound_] := Graph[modelIDs,
    UndirectedEdge @@@ modelPairs[[Complement[Range[Length[modelPairs]], coveredPairs[panel, separationMatrix[bound]]]]],
    VertexCoordinates -> fixedCoordinates, VertexLabels -> Automatic, ImageSize -> 260];
```
