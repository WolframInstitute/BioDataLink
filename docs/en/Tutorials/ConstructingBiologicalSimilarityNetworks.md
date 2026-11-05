---
Template: TechNote
Name: ConstructingBiologicalSimilarityNetworks
Title: Constructing Biological Similarity Networks
Context: WolframInstitute`BioDataLink`
Paclet: WolframInstitute/BioDataLink
URI: WolframInstitute/BioDataLink/tutorial/ConstructingBiologicalSimilarityNetworks
Keywords: [application, graph, nearest neighbors, phenotype, sensitivity, networks]
RelatedGuides: [BioDataLink, ComputationalExplorations, DataAccess, Downloads]
---

Build a similarity graph and test how its edges change with scaling,
neighborhood size and perturbations. Vertices are observations; edges represent
similar measurements, not measured interactions or ancestry.

The example uses 150 [UCI Iris records](https://archive.ics.uci.edu/dataset/53/iris),
with four floral measurements in centimetres. The bundled copy retains UCI's
values and CC BY 4.0 attribution. Evaluate **Initialization**, then run the examples in order.

## Load and standardize

```wl
rows = DeleteCases[Import[FileNameJoin[{PacletObject["WolframInstitute/BioDataLink"]["AssetLocation", "Examples"], "iris.csv"}], "CSV"], {} | {""}];
measurements = N[rows[[All, 1 ;; 4]]];
species = rows[[All, 5]];
sourceRows = Range[Length[rows]];
speciesNames = DeleteDuplicates[species];
speciesColors = ColorData[97] /@ Range[3];
colorBySpecies = AssociationThread[speciesNames, speciesColors];
Take[MapThread[<|"SourceRow" -> #1, "MeasurementsCm" -> #2, "Species" -> #3|> &, {sourceRows, measurements, species}], 3]
```

Subtract each variable's mean and divide by its sample standard deviation:

```wl
standardized = With[{centers = Mean /@ Transpose[measurements], scales = StandardDeviation /@ Transpose[measurements]},
    (# - centers)/scales & /@ measurements];
<|"Observations" -> Length[standardized],
    "Variables" -> Length[First[standardized]],
    "PositiveScales" -> AllTrue[StandardDeviation /@ Transpose[measurements], Positive]|>
```

This gives a one-standard-deviation change equal weight in each variable.
It does not establish equal biological importance. Resolve missing values and
constant columns first; predictive workflows must fit scales on training data.

## Define neighbors and edges

Build one index retaining up to 15 neighbors per record. Remove the query row
itself while preserving other records with identical measurements:

```wl
neighbors = neighborLists[standardized];
Take[MapThread[<|"SourceRow" -> #1, "NearestRows" -> Take[#2, 3]|> &, {sourceRows, neighbors}], 3]
```

At eight neighbors, a union edge requires either endpoint to select the other;
a mutual edge requires both:

```wl
unionEdges = edgeSet[neighbors, 8, False];
mutualEdges = edgeSet[neighbors, 8, True];
<|"UnionEdges" -> Length[unionEdges], "MutualEdges" -> Length[mutualEdges]|>
```

Use identical PCA coordinates and species colors in both graphs. Neighbors
come from four dimensions; the two-dimensional projection is only a display.

```wl
baseNetwork = With[{displayCoordinates = PrincipalComponents[standardized][[All, 1 ;; 2]],
        vertexTooltips = MapThread[#1 -> Placed[{#1, #2}, Tooltip] &, {sourceRows, species}]},
    Graph[sourceRows, {}, VertexCoordinates -> displayCoordinates, VertexLabels -> vertexTooltips,
        VertexStyle -> Thread[sourceRows -> Lookup[colorBySpecies, species]]]];
Legended[GraphicsRow[MapThread[Graph[EdgeAdd[baseNetwork, #1], PlotLabel -> #2] &,
    {{unionEdges, mutualEdges}, {"Union", "Mutual"}}]], SwatchLegend[speciesColors, speciesNames]]
```

Mutual edges can isolate records. Neither edge rule is automatically the right
biological definition. Species labels did not enter neighbor selection.

## Test scaling and neighborhood size

Build another graph using centimetres instead of standardized coordinates.
Highlight edges unique to each scale while keeping the display fixed:

```wl
rawEdges = edgeSet[neighborLists[measurements], 8, False];
sharedScaleEdges = Intersection[rawEdges, unionEdges];
GraphicsRow[MapThread[Graph[
    HighlightGraph[EdgeAdd[baseNetwork, #1], Complement[#1, sharedScaleEdges]], PlotLabel -> #2] &,
    {{rawEdges, unionEdges}, {"Distance in centimetres", "Distance in standardized units"}}]]
```

Compare edge overlap and connected components. The final check asks whether
removing one edge could split a component:

```wl
With[{scaleGraphs = Graph[sourceRows, #] & /@ {rawEdges, unionEdges}},
    <|"EdgeCounts" -> (EdgeCount /@ scaleGraphs),
        "SharedEdges" -> Length[sharedScaleEdges],
        "EdgeJaccardOverlap" -> N[Length[sharedScaleEdges]/Length[Union[rawEdges, unionEdges]]],
        "ComponentSizes" -> (ReverseSort[Length /@ ConnectedComponents[#]] & /@ scaleGraphs),
        "NoSingleEdgeSplitsAComponent" ->
            (Sort[Sort /@ ConnectedComponents[#]] === Sort[Sort /@ KEdgeConnectedComponents[#, 2]] & /@ scaleGraphs)|>]
```

Here the graphs have 799 and 787 edges, with 582 shared. The centimetre graph
has components of 100 and 50 records; the standardized graph connects all 150.
Neither has a single-edge bridge. Nearly tied machine-precision distances can
affect exact counts; retain the neighbor-query convention when reproducing them.

Now vary the requested neighbors:

```wl
GraphicsRow[Table[Graph[EdgeAdd[baseNetwork, edgeSet[neighbors, k, False]],
    PlotLabel -> Row[{k, " neighbors per record"}]], {k, {3, 8, 15}}]]
```

More neighbors can merge components. Components need not represent species,
cell types or compartments; apparent edge lengths in this projection are not
the original distances.

## Test perturbation sensitivity

Add independent Gaussian noise with standard deviations 0.01, 0.05 and 0.15
in standardized units. Keep scaling fixed and use 12 repetitions per level.
Jaccard overlap is shared edges divided by edges in either graph:

```wl
amplitudes = {0.01, 0.05, 0.15};
repetitions = 12;
perturbationEdges = BlockRandom[SeedRandom[20261104];
    Table[perturbedEdges[standardized, amplitude, 8], {amplitude, amplitudes}, {repetitions}]];
With[{stability = Map[N[Length[Intersection[unionEdges, #]]/Length[Union[unionEdges, #]]] &, perturbationEdges, {2}]},
    BoxWhiskerChart[stability, ChartLabels -> amplitudes, PlotRange -> {0, 1},
        FrameLabel -> {"Perturbation SD (standardized units)", "Edge Jaccard overlap"}]]
```

These are chosen perturbations, not estimated instrument errors. Edge changes
measure sensitivity to this scenario; repetitions are not new biological
samples and overlaps are not confidence levels.

Retain row IDs, scaling, distance, edge rule, neighborhood size and seed.
Before using this graph as an interaction network, compare it with independent
interaction measurements.

## Inspect how neighborhood size changes the graph

Sweep the requested neighbors from one through fifteen. Record connected
components and the degree distribution, which counts neighbors in the final
undirected graph rather than the directed search result.

```wl
networkSweep = Table[Graph[sourceRows, edgeSet[neighbors, k, False]], {k, 15}];
GraphicsRow[{
    ListLinePlot[Length[ConnectedComponents[#]] & /@ networkSweep, Frame -> True,
        FrameLabel -> {"requested neighbors", "connected components"}],
    BoxWhiskerChart[VertexDegree /@ networkSweep, ChartLabels -> Range[15],
        FrameLabel -> {"requested neighbors", "undirected degree"}]}]
```

Union edges can give a vertex many more than k neighbors. Connectivity is a
property of the graph construction, not evidence that the observations form
one interacting biological system.

## Compare local mixing with a label-permutation control

Measure the fraction of graph edges joining different source species. Species
labels enter only this descriptive check, after graph construction.

```wl
edgePairs = List @@@ unionEdges;
observedMixing = Mean[Boole[Unequal @@ species[[#]]] & /@ edgePairs];
permutedMixing = BlockRandom[SeedRandom[20261106]; Table[With[{labels = RandomSample[species]},
    Mean[Boole[Unequal @@ labels[[#]]] & /@ edgePairs]], {100}]];
Histogram[N[permutedMixing], Automatic, "Probability", GridLines -> {{N[observedMixing]}, None},
    Frame -> True, FrameLabel -> {"fraction of cross-species edges", "fraction of permutations"}]
```

The control preserves graph topology and label counts. Separation from this
null demonstrates association between graph neighbors and labels in this file;
it does not establish generalization to new populations.

Map each vertex's fraction of differently labeled neighbors on the fixed PCA
coordinates. Vertices with no neighbors would need a missing result.

```wl
mixingByVertex = Table[With[{adjacent = AdjacencyList[Graph[sourceRows, unionEdges], i]},
    N[Mean[Boole[species[[#]] =!= species[[i]]] & /@ adjacent]]], {i, sourceRows}];
BioEmbeddingPlot[AssociationThread[sourceRows, PrincipalComponents[standardized][[All, ;; 2]]],
    AssociationThread[sourceRows, mixingByVertex], "ColorMode" -> "Continuous", "ColorRange" -> {0, 1},
    FrameLabel -> {"PC 1", "PC 2"}]
```

A boundary vertex is a prompt to inspect its measurements and neighbors.
It is not automatically mislabeled or a transitional biological state.

## Locate fragile edges rather than averaging them away

For the 0.05-standard-deviation perturbations above, estimate how often each
original edge survives. Keep the original vertex coordinates fixed and draw
fragile edges more prominently:

```wl
edgeSurvival = AssociationThread[unionEdges,
    Table[N[Count[MemberQ[#, edge] & /@ perturbationEdges[[2]], True]/repetitions], {edge, unionEdges}]];
Graph[EdgeAdd[baseNetwork, unionEdges], EdgeStyle -> KeyValueMap[#1 -> Directive[
    ColorData["BlueGreenYellow"][#2], AbsoluteThickness[If[#2 < 0.5, 1.8, 0.5]]] &, edgeSurvival],
    PlotLabel -> "original edges under repeated perturbations", ImageSize -> Large]
```

An average Jaccard overlap can hide a small unstable region. These survival
frequencies are conditional on the chosen perturbation model and are not
confidence probabilities for biological interactions.

## Separate layout variation from network variation

Display the same graph with fixed measurement coordinates and with a spring
layout. Its adjacency matrix is identical in both panels:

```wl
With[{g = Graph[sourceRows, unionEdges, VertexStyle -> Thread[sourceRows -> Lookup[colorBySpecies, species]]]},
    GraphicsRow[{Graph[g, VertexCoordinates -> PrincipalComponents[standardized][[All, ;; 2]],
            AspectRatio -> 1, ImageSize -> 300, PlotLabel -> "measurement projection"],
        Graph[g, GraphLayout -> "SpringElectricalEmbedding", AspectRatio -> 1, ImageSize -> 300,
            PlotLabel -> "graph layout"]}, ImageSize -> Large]]
```

Spatial separation in a graph layout is a drawing choice. Interpret it through
explicit edges, path lengths or measurement distances, with the corresponding
construction recorded.

## Initialization

Helpers reuse a nearest-neighbor index, construct union or mutual edges and
apply the stated perturbation model.

```wl
neighborLists[data_] := With[{nearest = Nearest[data -> "Index"]},
    Table[Take[DeleteCases[nearest[data[[i]], 16], i], 15], {i, Length[data]}]];
edgeSet[lists_, k_, mutual_] := Module[{pairs = Flatten[MapIndexed[Thread[{First[#2], Take[#1, k]}] &, lists], 1], chosen},
    chosen = AssociationThread[pairs -> True];
    If[mutual, pairs = Select[pairs, KeyExistsQ[chosen, Reverse[#]] &]];
    DeleteDuplicates[UndirectedEdge @@@ (Sort /@ pairs)]];
perturbedEdges[data_, amplitude_, k_] :=
    edgeSet[neighborLists[data + RandomVariate[NormalDistribution[0, amplitude], Dimensions[data]]], k, False];
```
