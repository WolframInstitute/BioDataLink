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

Can a network summarize variation among measured organisms? A similarity
network makes each observation a vertex and connects nearby measurements.
Its edges describe an analysis choice: they are not observed interactions,
ancestry or physical contacts. This distinction matters when using a network
as the starting point for a Ruliobiology model of local interactions.

This tutorial constructs networks from four floral measurements, compares two
edge rules and two distance scales, and measures sensitivity to neighborhood
size and hypothetical measurement perturbations. All inputs run offline on the
attributed Iris copy
included with BioDataLink. The resulting graphs describe these 150 records;
they do not establish population structure beyond the sample.

## Define the observations and the distance

The [UCI Iris record](https://archive.ics.uci.edu/dataset/53/iris) gives four
measurements in centimetres and a species label. The bundled bytes retain the
distributed values, including the historical differences noted by UCI.
See [Downloading and Inspecting Biological Data](DownloadingBiologicalData.md)
for the checked hash and CC BY 4.0 attribution.

```wl
irisFile = FileNameJoin[{PacletObject["WolframInstitute/BioDataLink"]["AssetLocation", "Examples"], "iris.csv"}];
rows = DeleteCases[Import[irisFile, "CSV"], {} | {""}];
measurements = N[rows[[All, 1 ;; 4]]];
species = rows[[All, 5]];
sourceRows = Range[Length[rows]];
speciesNames = DeleteDuplicates[species];
speciesColors = ColorData[97] /@ Range[3];
colorBySpecies = AssociationThread[speciesNames, speciesColors];
Take[MapThread[<|"SourceRow" -> #1, "MeasurementsCm" -> #2,
    "Species" -> #3|> &, {sourceRows, measurements, species}], 3]
```

The source row is an identifier within this file. It is not a measured time
or a coordinate in the organism. First inspect two of the measured variables:

```wl
ListPlot[Table[Pick[measurements[[All, {3, 4}]], species, name], {name, speciesNames}],
    PlotLegends -> speciesNames, AxesLabel -> {"Petal length (cm)", "Petal width (cm)"}]
```

Petal dimensions visibly separate some labeled records. The graph below uses
all four variables. Standardize each column using its sample mean and sample
standard deviation so that a one-standard-deviation difference has equal
weight in each variable. This is a declared distance convention, not a claim
that all four traits have equal biological importance. It also gives correlated
traits separate contributions to the distance.

```wl
centers = Mean /@ Transpose[measurements];
scales = StandardDeviation /@ Transpose[measurements];
standardized = (# - centers)/scales & /@ measurements;
<|"Observations" -> Length[standardized],
    "Variables" -> Length[First[standardized]],
    "PositiveScales" -> AllTrue[scales, Positive]|>
```

For new data, resolve missing measurements and constant columns before
standardizing. Do not silently replace missing measurements with zero. For a
prediction task, estimate these transformations using training records only;
this tutorial is a descriptive analysis of the complete sample.

## Build a reusable neighbor index

[Nearest (WL)](https://reference.wolfram.com/language/ref/Nearest.html) can
return source indices and retain a search index for repeated queries. Equal
distance ties follow input order. We preserve that order and explicitly remove
the query record itself; an identical measurement from a different record
remains a possible neighbor.

```wl
neighborIndex = Nearest[standardized -> "Index",
    DistanceFunction -> EuclideanDistance];
neighbors = Table[Take[DeleteCases[
    neighborIndex[standardized[[i]], 16], i], 15], {i, Length[sourceRows]}];
Take[MapThread[<|"SourceRow" -> #1, "NearestRows" -> Take[#2, 3]|> &,
    {sourceRows, neighbors}], 3]
```

Precompute at most 15 neighbors per record once, then reuse their prefixes.
For larger datasets this avoids repeatedly constructing the same search
structure. Exact nearest-neighbor search still depends on dimensionality and
data distribution; this small example is not a throughput benchmark for
millions of cells.

An undirected union edge is present if either endpoint chooses the other. A
mutual edge requires both choices. Use an association for reverse-edge lookup:

```wl
unionEdges = edgeSet[neighbors, 8, False];
mutualEdges = edgeSet[neighbors, 8, True];
<|"UnionEdges" -> Length[unionEdges], "MutualEdges" -> Length[mutualEdges]|>
```

## Compare edge rules with a fixed display

Use the first two principal component coordinates only for display. The
neighbors were computed in four standardized dimensions. A short edge in the
display does not certify a short four-dimensional distance; projections can
hide differences. Reuse identical coordinates and colors in every graph so
that apparent changes come from edges, rather than a new layout.
Native vertex tooltips retain the source row and recorded species when the
graphs are evaluated in an interactive notebook, without adding 150 visible labels.

```wl
displayCoordinates = PrincipalComponents[standardized][[All, 1 ;; 2]];
vertexTooltips = MapThread[#1 -> Placed[{#1, #2}, Tooltip] &, {sourceRows, species}];
baseNetwork = Graph[sourceRows, {}, VertexCoordinates -> displayCoordinates,
    VertexLabels -> vertexTooltips,
    VertexStyle -> Thread[sourceRows -> Lookup[colorBySpecies, species]]];
Legended[GraphicsRow[MapThread[Graph[EdgeAdd[baseNetwork, #1], PlotLabel -> #2] &,
    {{unionEdges, mutualEdges}, {"Union", "Mutual"}}]], SwatchLegend[speciesColors, speciesNames]]
```

The same vertices can have different connectivity under the two definitions.
Mutual neighborhoods remove one-sided links and may isolate observations.
Neither definition is automatically the correct one for biology. Species
labels supply a visual annotation here and did not enter neighbor selection.

## Does connectivity depend on the measurement scale?

All four original measurements use centimetres, so ordinary Euclidean distance
in their original units is another defensible descriptive convention. It gives
more weight to traits that vary more in centimetres. Standardization gives a
one-standard-deviation change equal weight in every trait. Neither choice
removes the need to justify a distance for a particular biological question.

Construct a second neighbor index on the original measurements. Keep the same
source rows, candidate-query size, cached fifteen-neighbor prefixes,
eight-neighbor union rule and display coordinates. Highlighted edges occur
only in the scale shown by that panel; the other edges occur under both scales.
The vertex colors still indicate the recorded species labels.

```wl
rawNeighborIndex = Nearest[measurements -> "Index", DistanceFunction -> EuclideanDistance];
rawNeighbors = Table[Take[DeleteCases[rawNeighborIndex[measurements[[i]], 16], i], 15],
    {i, Length[sourceRows]}];
rawEdges = edgeSet[rawNeighbors, 8, False];
sharedScaleEdges = Intersection[rawEdges, unionEdges];
GraphicsRow[MapThread[Graph[
    HighlightGraph[EdgeAdd[baseNetwork, #1], Complement[#1, sharedScaleEdges]], PlotLabel -> #2] &,
    {{rawEdges, unionEdges}, {"Distance in centimetres", "Distance in standardized units"}}]]
```

Because coordinates are fixed, an edge change cannot be explained by a new
graph layout. The shared display remains a two-dimensional projection of the
standardized measurements, even for the graph whose neighbors were selected
in centimetres. Read distances from the original numerical definition, not
from the apparent length of an edge on the page.

Compare connectivity as well as edge overlap. Two vertices are in the same
2-edge-connected component when at least two edge-disjoint paths connect
them. Comparing that partition with ordinary connected components tests
whether removing a single edge could split an existing component.
See [KEdgeConnectedComponents (WL)](https://reference.wolfram.com/language/ref/KEdgeConnectedComponents.html).

```wl
scaleGraphs = Graph[sourceRows, #] & /@ {rawEdges, unionEdges};
<|"EdgeCounts" -> (EdgeCount /@ scaleGraphs),
    "SharedEdges" -> Length[sharedScaleEdges],
    "EdgeJaccardOverlap" -> N[Length[sharedScaleEdges]/Length[Union[rawEdges, unionEdges]]],
    "ComponentSizes" -> (ReverseSort[Length /@ ConnectedComponents[#]] & /@ scaleGraphs),
    "NoSingleEdgeSplitsAComponent" ->
        (Sort[Sort /@ ConnectedComponents[#]] ===
            Sort[Sort /@ KEdgeConnectedComponents[#, 2]] & /@ scaleGraphs)|>
```

In the evaluated setup, the centimetre and standardized graphs have 799 and
787 edges respectively, with 582 shared edges and a Jaccard overlap of about
0.580. The first graph has
components of 100 and 50 records; the second connects all 150 records.
Both return `True` for the single-edge test. Thus the visually narrow
connection in the standardized display is not an individual graph-theoretic
bridge, whose deletion would increase the number of components.

The inputs here use machine precision. Nearly tied distances can change order
under numerical or search settings, so preserve the displayed neighbor-query
convention when reproducing exact edge counts.

These observations answer a robustness question about this analysis:
connectivity depends on the scale convention. They do not establish that
plants communicate through the displayed connections, or that a species
boundary is present or absent in nature. The same issue applies when a
similarity graph is supplied as a hypothetical neighborhood for a rule model.

## Treat neighborhood size as an assumption

Compare three union graphs. Increasing the number of neighbors includes
longer-range similarities and can merge components:

```wl
GraphicsRow[Table[Graph[EdgeAdd[baseNetwork, edgeSet[neighbors, k, False]],
    PlotLabel -> Row[{k, " neighbors per record"}]], {k, {3, 8, 15}}]]
```

A connected component is a set joined by paths in the constructed graph.
It need not be a species, cell type or biological compartment. Count components
and summarize degree, the number of incident edges, across all tested values:

```wl
kValues = Range[15];
unionGraphs = Graph[sourceRows, edgeSet[neighbors, #, False]] & /@ kValues;
mutualGraphs = Graph[sourceRows, edgeSet[neighbors, #, True]] & /@ kValues;
Grid[{{ListLinePlot[{Length[ConnectedComponents[#]] & /@ unionGraphs,
    Length[ConnectedComponents[#]] & /@ mutualGraphs}, DataRange -> {1, 15}, PlotRange -> All,
    Frame -> True, FrameLabel -> {"neighbors requested", "connected components"}, PlotLegends -> {"Union", "Mutual"}],
    ListLinePlot[{Mean[VertexDegree[#]] & /@ unionGraphs, Mean[VertexDegree[#]] & /@ mutualGraphs},
        DataRange -> {1, 15}, PlotRange -> All, Frame -> True, FrameLabel -> {"neighbors requested", "mean degree"},
        PlotLegends -> {"Union", "Mutual"}]} }]
```

The requested number is a directed neighbor count before symmetrization.
Consequently, union degrees can exceed it, and mutual degrees can fall below
it. This explains why these curves need not follow the line degree equals k.

## Test edge stability under declared perturbations

Now add independent Gaussian perturbations to standardized measurements at
three amplitudes. These are analyst-chosen scenarios, not estimated instrument
errors. Keep the original standardization fixed so the experiment isolates
the coordinate perturbation. Use 12 repetitions per amplitude with a recorded
seed. Compare each union graph with the original using the Jaccard overlap:
the number of shared edges divided by the number of edges in either graph.

```wl
amplitudes = {0.01, 0.05, 0.15};
repetitions = 12;
perturbationEdges = BlockRandom[SeedRandom[20261104];
    Table[perturbedEdges[standardized, amplitude, 8], {amplitude, amplitudes}, {repetitions}]];
stability = Map[N[Length[Intersection[unionEdges, #]]/Length[Union[unionEdges, #]]] &,
    perturbationEdges, {2}];
BoxWhiskerChart[stability, ChartLabels -> amplitudes, PlotRange -> {0, 1},
    FrameLabel -> {"Perturbation SD (standardized units)", "Edge Jaccard overlap"}]
```

Edges near a neighbor cutoff can change even when the overall geometry looks
similar. Overlap below one is a sensitivity result conditional on this noise
model. It is not a confidence interval or a probability that an edge is real.
All repetitions start from the same measured records and differ only in
simulated perturbations; repetitions do not add independent plant samples.

## Which connections persist when individual edges change?

An overlap distribution does not identify the changing connections. Reuse the
stored edge sets at perturbation SD 0.05, without rerunning the neighbor search.
Count how many of the twelve repetitions contain each edge. The left graph
contains every edge seen at least once, highlighting those seen in all twelve.
The right graph keeps only edges present in all twelve repetitions.
Every source row remains a vertex, including any that might become isolated.

```wl
selectedAmplitude = First[FirstPosition[amplitudes, 0.05]];
edgeRepeatCounts = Counts[Flatten[perturbationEdges[[selectedAmplitude]], 1]];
observedEdges = Keys[edgeRepeatCounts];
alwaysEdges = Keys[Select[edgeRepeatCounts, # == repetitions &]];
GraphicsRow[{Graph[HighlightGraph[EdgeAdd[baseNetwork, observedEdges], alwaysEdges],
    PlotLabel -> "Any repetition; highlighted in all twelve"],
    Graph[EdgeAdd[baseNetwork, alwaysEdges], PlotLabel -> "All twelve repetitions"]}]
```

Across these repetitions, 1150 distinct edges appear. Of the original 787
edges, 480 occur in all twelve repetitions. The all-twelve graph remains
connected across all 150 records. Thus the identity of individual edges can
be sensitive while the coarse conclusion of connectedness persists under
this particular perturbation experiment.

Vary the required number of repetitions rather than choosing only one cutoff.
Count retained edges and records in the largest connected component at each
cutoff. Both curves below are fractions, but they have different denominators:
all 1150 observed edges, and all 150 source records respectively.

```wl
minimumRepetitions = Range[repetitions];
thresholdGraphs = Table[Graph[sourceRows, Keys[Select[edgeRepeatCounts, # >= minimum &]]],
    {minimum, minimumRepetitions}];
retainedEdgeFractions = N[(EdgeCount /@ thresholdGraphs)/Length[observedEdges]];
largestComponentFractions = N[
    (Max[Length /@ ConnectedComponents[#]] & /@ thresholdGraphs)/Length[sourceRows]];
ListLinePlot[{retainedEdgeFractions, largestComponentFractions}, DataRange -> {1, repetitions},
    Frame -> True, FrameLabel -> {"minimum repetitions", "fraction"}, PlotRange -> {0, 1.05},
    PlotLegends -> {"edge fraction", "largest-component record fraction"}]
```

All twelve threshold graphs remain connected here, while the retained edge
fraction falls to 480/1150, about 0.417. Connectivity alone therefore hides
substantial changes in local neighborhoods. A rule that reads those neighbors
could still change behavior; that requires a separate, explicitly defined
dynamical experiment.

These repetition counts are conditional sensitivity summaries. They are not
confidence levels, estimated probabilities of a true biological edge, or
independent confirmation of an interaction. The thresholded graph is a derived
summary of the simulated edge sets and need not itself be an eight-neighbor
graph. Reusing the stored edge lists avoids rebuilding neighbor indices for
this summary; much larger analyses should accumulate edge counts as results arrive
when retaining every replicate is unnecessary.

## Applications to biological rule models

This workflow provides an explicit observation-to-network map. A subsequent
rule model could place discrete states on these vertices and update each state
using its neighbors. That would introduce a hypothetical interaction structure
derived from phenotype similarity. To interpret it as communication, contact
or regulation, compare it with independently measured interactions.

Useful extensions include comparing networks built from morphology and gene
expression for the same identified observations; testing whether an inferred
pattern persists across union and mutual graphs; and reporting network
statistics separately by biological replicate. Preserve record identifiers
through each transformation. If multiple cells come from one donor, thousands
of vertices do not imply thousands of independent donors.

The next step is to ask which model observations would discriminate between
rules. [Exploring Cellular Automaton Hypotheses](ExploringCellularAutomatonHypotheses.md)
demonstrates why fitting one static statistic is insufficient.

## Computational references

- [Nearest (WL)](https://reference.wolfram.com/language/ref/Nearest.html) describes reusable nearest-neighbor functions and index output.
- [PrincipalComponents (WL)](https://reference.wolfram.com/language/ref/PrincipalComponents.html) defines the projection used for display.
- [ConnectedComponents (WL)](https://reference.wolfram.com/language/ref/ConnectedComponents.html) defines connectivity in the constructed graph.
- [Graph (WL)](https://reference.wolfram.com/language/ref/Graph.html) documents fixed vertex coordinates and graph properties.
- [VertexLabels (WL)](https://reference.wolfram.com/language/ref/VertexLabels.html) documents native tooltip labels for retaining source identities.

## Initialization

Evaluate these helper definitions before the examples above. The data choices
and analysis parameters remain in the main examples.

```wl
edgeSet[neighborLists_, k_, mutual_] := Module[{pairs, membership},
    pairs = Flatten[MapIndexed[
        Thread[{ConstantArray[First[#2], k], Take[#1, k]}] &,
        neighborLists], 1];
    If[TrueQ[mutual],
        membership = AssociationThread[DirectedEdge @@@ pairs,
            ConstantArray[True, Length[pairs]]];
        pairs = Select[pairs, KeyExistsQ[membership, DirectedEdge @@ Reverse[#]] &]];
    DeleteDuplicates[UndirectedEdge @@@ (Sort /@ pairs)]
];
perturbedEdges[data_, amplitude_, k_] := Module[{perturbed, index, near},
    perturbed = data + RandomVariate[NormalDistribution[0, amplitude], Dimensions[data]];
    index = Nearest[perturbed -> "Index", DistanceFunction -> EuclideanDistance];
    near = Table[Take[DeleteCases[index[perturbed[[i]], k + 1], i], k], {i, Length[data]}];
    edgeSet[near, k, False]];
```
