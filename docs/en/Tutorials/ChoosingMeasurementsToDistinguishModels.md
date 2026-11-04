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
    GraphicsGrid[Partition[MapThread[Labeled, {graphs, panelLabels}], 2]]]
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
    VertexCoordinates -> fixedCoordinates, VertexLabels -> Automatic];
```
