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
edge rules, and measures sensitivity to neighborhood size and hypothetical
measurement perturbations. All inputs run offline on the attributed Iris copy
included with BioDataLink. The resulting graphs describe these 150 records;
they do not establish population structure beyond the sample.

## Define the observations and the distance

The [UCI Iris record](https://archive.ics.uci.edu/dataset/53/iris) gives four
measurements in centimetres and a species label. The bundled bytes retain the
distributed values, including the historical differences noted by UCI.
See [Downloading and Inspecting Biological Data](DownloadingBiologicalData.md)
for the checked hash and CC BY 4.0 attribution.

```wl
exampleDirectory = FileNameJoin[{
    PacletObject["WolframInstitute/BioDataLink"]["Location"], "Assets", "Examples"}];
rows = DeleteCases[Import[FileNameJoin[{exampleDirectory, "iris.csv"}], "CSV"], {} | {""}];
measurements = N[rows[[All, 1 ;; 4]]];
species = rows[[All, 5]];
sourceRows = Range[Length[rows]];
speciesNames = DeleteDuplicates[species];
speciesColors = {RGBColor[0.1, 0.45, 0.7], RGBColor[0.85, 0.35, 0.1],
    RGBColor[0.2, 0.6, 0.4]};
colorBySpecies = AssociationThread[speciesNames, speciesColors];
Take[MapThread[<|"SourceRow" -> #1, "MeasurementsCm" -> #2,
    "Species" -> #3|> &, {sourceRows, measurements, species}], 3]
```

The source row is an identifier within this file. It is not a measured time
or a coordinate in the organism. First inspect two of the measured variables:

```wl
ListPlot[Table[Pick[measurements[[All, {3, 4}]], species, name],
    {name, speciesNames}], PlotStyle -> speciesColors,
    PlotLegends -> Placed[speciesNames, Below], Frame -> True,
    FrameLabel -> {"Petal length (cm)", "Petal width (cm)"},
    PlotLabel -> "Measured traits: each point is one plant record",
    ImageSize -> 540]
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
Clear[edgeSet];
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

```wl
displayCoordinates = PrincipalComponents[standardized][[All, 1 ;; 2]];
Clear[drawNetwork];
drawNetwork[edges_, title_, size_] := Graph[sourceRows, edges,
    VertexCoordinates -> displayCoordinates,
    VertexStyle -> Thread[sourceRows -> Lookup[colorBySpecies, species]],
    VertexSize -> {"Scaled", 0.018},
    EdgeStyle -> Directive[GrayLevel[0.5], Opacity[0.35]],
    PlotLabel -> title, ImageSize -> size];
Legended[GraphicsRow[{
    drawNetwork[unionEdges, "Union: either record chooses the other", 300],
    drawNetwork[mutualEdges, "Mutual: both records choose each other", 300]},
    ImageSize -> 640], Placed[SwatchLegend[speciesColors, speciesNames], Below]]
```

The same vertices can have different connectivity under the two definitions.
Mutual neighborhoods remove one-sided links and may isolate observations.
Neither definition is automatically the correct one for biology. Species
labels supply a visual annotation here and did not enter neighbor selection.

## Treat neighborhood size as an assumption

Compare three union graphs. Increasing the number of neighbors includes
longer-range similarities and can merge components:

```wl
GraphicsRow[Table[drawNetwork[edgeSet[neighbors, k, False],
    "Neighbors per record: " <> ToString[k], 220], {k, {3, 8, 15}}],
    ImageSize -> 700]
```

A connected component is a set joined by paths in the constructed graph.
It need not be a species, cell type or biological compartment. Count components
and summarize degree, the number of incident edges, across all tested values:

```wl
kValues = Range[15];
unionGraphs = Graph[sourceRows, edgeSet[neighbors, #, False]] & /@ kValues;
mutualGraphs = Graph[sourceRows, edgeSet[neighbors, #, True]] & /@ kValues;
Grid[{{
    ListLinePlot[{Length[ConnectedComponents[#]] & /@ unionGraphs,
        Length[ConnectedComponents[#]] & /@ mutualGraphs},
        DataRange -> {1, 15}, Frame -> True,
        FrameLabel -> {"Neighbors requested", "Connected components"},
        PlotMarkers -> Automatic, PlotLegends -> Placed[{"Union", "Mutual"}, Below],
        PlotRange -> All, ImageSize -> 320],
    ListLinePlot[{Mean[VertexDegree[#]] & /@ unionGraphs,
        Mean[VertexDegree[#]] & /@ mutualGraphs}, DataRange -> {1, 15},
        Frame -> True, FrameLabel -> {"Neighbors requested", "Mean degree"},
        PlotMarkers -> Automatic, PlotLegends -> Placed[{"Union", "Mutual"}, Below],
        PlotRange -> All, ImageSize -> 320]}}]
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
stability = BlockRandom[SeedRandom[20261104];
    Table[Table[Module[{perturbed, index, near, edges},
        perturbed = standardized + RandomVariate[
            NormalDistribution[0, amplitude], Dimensions[standardized]];
        index = Nearest[perturbed -> "Index", DistanceFunction -> EuclideanDistance];
        near = Table[Take[DeleteCases[index[perturbed[[i]], 9], i], 8],
            {i, Length[sourceRows]}];
        edges = edgeSet[near, 8, False];
        N[Length[Intersection[unionEdges, edges]]/Length[Union[unionEdges, edges]]]],
        {12}], {amplitude, amplitudes}]];
BoxWhiskerChart[stability, ChartLabels -> (ToString /@ amplitudes),
    FrameLabel -> {"Perturbation SD (standardized units)", "Edge Jaccard overlap"},
    PlotRange -> {0, 1}, PlotLabel -> "Sensitivity to hypothetical measurement changes",
    ImageSize -> 540]
```

Edges near a neighbor cutoff can change even when the overall geometry looks
similar. Overlap below one is a sensitivity result conditional on this noise
model. It is not a confidence interval or a probability that an edge is real.
All repetitions start from the same measured records and differ only in
simulated perturbations; repetitions do not add independent plant samples.

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
