---
Template: TechNote
Name: AnalyzingSingleCellExpression
Title: Analyzing Single-Cell Expression in Human Blood
Context: WolframInstitute`BioDataLink`
Paclet: WolframInstitute/BioDataLink
URI: WolframInstitute/BioDataLink/tutorial/AnalyzingSingleCellExpression
Keywords: [application, single cell, RNA-seq, PBMC, quality control, Pearson residuals, principal components, UMAP, graph communities, marker genes]
RelatedGuides: [BioDataLink, ComputationalExplorations, DataAccess]
---

Which kinds of cells are in a sample of human blood, and which genes tell them
apart? Single-cell RNA sequencing answers this by counting messenger RNA
molecules in thousands of individual cells. This tutorial follows one real
dataset from filtered UMI counts to provisional cell-type annotations: quality control, a model of
counting noise, principal components, a neighborhood graph, a two-dimensional
map and marker genes.

The data are the [3k PBMCs from a Healthy Donor](https://www.10xgenomics.com/datasets/3-k-pbm-cs-from-a-healthy-donor-1-standard-1-1-0)
dataset from 10x Genomics, distributed under CC BY 4.0. Peripheral blood
mononuclear cells (PBMCs) are the lymphocytes and monocytes of blood. UMI counts estimate captured RNA molecules after reads with matching
unique molecular identifiers are deduplicated. Capture losses, barcode errors
and UMI collisions limit that interpretation. BioDataLink bundles all 2,700 cell barcodes with
513 of the 32,738 genes. All cells come from one donor, so the results describe
this sample, not variation between people.

Evaluate the Initialization section at the end before running the examples.

## Load the counts with their provenance

Read the bundled BioDataLink JSON file:

```wl
pbmc = BioDatasetLoad[File[FileNameJoin[{PacletObject["WolframInstitute/BioDataLink"]["AssetLocation", "Examples"], "PBMC3k", "pbmc3k-subset.json"}]]];
pbmc["ExpressionMatrix"]
```

Rows are cells and columns are genes. Most entries are zero, so the matrix is a
`SparseArray`. The source record travels with the data:

```wl
KeyTake[pbmc["Provenance"], {"Source", "License", "SourceSHA256", "Selection"}]
```

The gene table records why each gene was kept. `HighlyVariable` marks the 300
most variable genes, chosen by a rule reproduced below; `Background` marks 200
randomly sampled genes that serve as a reference:

```wl
pbmc["GeneMetadata"][1 ;; 5]
```

Name the pieces used throughout. Gene symbols are unique in this subset, but
they are display names; use the Ensembl `ID` column to join with other data.
The per-cell totals were computed over all 32,738 genes:

```wl
counts = pbmc["ExpressionMatrix"];
symbols = Normal[pbmc["GeneMetadata"][All, "Symbol"]];
gene = First /@ PositionIndex[symbols];
variable = geneSet[pbmc, "HighlyVariable"];
background = geneSet[pbmc, "Background"];
totals = Normal[pbmc["CellMetadata"][All, "SourceTotalCounts"]];
detected = Normal[pbmc["CellMetadata"][All, "SourceGenesDetected"]];
```

## See what sparse counts look like

Count how often each UMI value occurs among the stored entries:

```wl
ListLogLogPlot[Tally[counts["NonzeroValues"]], Frame -> True, FrameLabel -> {"UMI count", "matrix entries with that count"}]
```

The most common nonzero count is 1. Capturing molecules is a sampling process,
so a gene with modest expression is often missed in a given cell.

The zeros are not random. Order 400 cells by total counts and the genes by how
often they are detected; black marks a nonzero count:

```wl
With[{cells = Take[Ordering[totals, All, Greater], 400], genes = Ordering[Normal[Total[Unitize[counts]]], All, Greater]},
    ArrayPlot[Unitize[counts[[cells, genes]]], FrameLabel -> {"cells, most counts first", "genes, most often detected first"}]]
```

Detection thins out toward rare genes and toward cells with fewer counts. A
zero mixes biology with sampling depth; it does not show that a gene was off.

## Check cell quality

High mitochondrial fractions can accompany damaged cells, while unusually
high gene detection can flag droplets containing more than one cell. These
are screening signals, not specific diagnoses. Compute each cell's fraction
of counts from the 13 mitochondrial genes, whose symbols start with `MT-`:

```wl
mitoFraction = N[Normal[Total[counts[[All, geneSet[pbmc, "Mitochondrial"]]], {2}]]/totals];
```

Plot genes detected against total counts, colored by mitochondrial percentage.
Grid lines mark 200 and 2,500 detected genes, the thresholds of the
[Seurat PBMC tutorial](https://satijalab.org/seurat/articles/pbmc3k_tutorial):

```wl
ListLogLogPlot[MapThread[Style, {Transpose[{totals, detected}], ColorData["BlueGreenYellow"] /@ Rescale[Clip[mitoFraction, {0, 0.1}], {0, 0.1}]}],
    Frame -> True, FrameLabel -> {"UMI counts per cell", "genes detected"}, GridLines -> {None, {200, 2500}},
    PlotLegends -> BarLegend[{"BlueGreenYellow", {0, 10}}, LegendLabel -> "% mitochondrial (capped at 10)"]]
```

Most cells lie on one band. High mitochondrial fractions gather among cells
with few counts, consistent with one common damage signature. Cells above 2,500
genes are candidates for doublet review, but RNA content and cell identity
also affect these measurements. Keep cells within both gene thresholds and under
5% mitochondrial counts:

```wl
keep = Flatten[Position[MapThread[200 <= #1 <= 2500 && #2 < 0.05 &, {detected, mitoFraction}], True]];
kept = counts[[keep]];
Length[keep]
```

These thresholds are conventions for this assay, not universal constants.

## Separate biology from counting noise

Even a gene expressed equally in every cell would vary in its counts, because
molecules are sampled. For Poisson sampling the variance equals the mean, shown
by the dashed line. Compare the random reference genes with the selected genes:

```wl
With[{points = Transpose[{Normal[Mean[kept]], Normal[Variance[kept]]}]},
    Show[ListLogLogPlot[{points[[background]], points[[variable]]}, PlotLegends -> {"random genes", "selected genes"},
            Frame -> True, FrameLabel -> {"mean count per cell", "variance across cells"}],
        LogLogPlot[m, {m, 0.001, 100}, PlotStyle -> Directive[Black, Dashed]]]]
```

The reference genes span the sampling line. Selected genes often vary more
than this simple Poisson model predicts. Biological heterogeneity, technical
variation and differences in capture depth can all contribute; excess variance
alone does not identify cell types.

Analytic Pearson residuals put this comparison on a per-cell scale
([Lause, Berens and Kobak 2021](https://doi.org/10.1186/s13059-021-02451-7)).
The expected count is the cell's total times the gene's share of all counts.
The residual divides the observed difference by a negative binomial standard
deviation (overdispersion 100) and is clipped at the square root of the number
of cells:

```wl
residuals = pearsonResiduals[kept, totals[[keep]]];
Dimensions[residuals]
```

A gene that only reflects sampling noise has residual variance near 1:

```wl
With[{points = Transpose[{Normal[Mean[kept]], Variance[residuals]}]},
    ListLogLogPlot[{points[[background]], points[[variable]]}, PlotLegends -> {"random genes", "selected genes"},
        Frame -> True, FrameLabel -> {"mean count per cell", "residual variance"}, GridLines -> {None, {1}}]]
```

The bundled selection used this rule over every gene of the source matrix. All
of those genes are in the subset, so ranking the subset reproduces it:

```wl
Sort[Take[Ordering[Variance[residuals], All, Greater], 300]] === variable
```

## Find the main axes of variation

Principal component analysis finds uncorrelated gene combinations that capture
the most variance. Apply it to the residuals of the 300 selected genes:

```wl
pcs = PrincipalComponents[residuals[[All, variable]], Method -> "Covariance"];
```

Each component explains less variance than the one before:

```wl
With[{v = Variance[pcs]}, ListPlot[Take[v/Total[v], 40], Filling -> Axis, PlotRange -> All, Frame -> True, FrameLabel -> {"principal component", "fraction of variance"}]]
```

The curve flattens after about 20 components, which the rest of the analysis
uses. Label genes by their correlation with the first two components:

```wl
With[{r = Correlation[residuals[[All, variable]], pcs[[All, ;; 2]]]},
    ListPlot[MapThread[Callout, {r, symbols[[variable]]}], PlotRange -> All, Frame -> True, FrameLabel -> {"correlation with PC 1", "correlation with PC 2"}, AspectRatio -> 1]]
```

Each direction describes correlated expression in this sample. Myeloid genes such as `LYZ`, `S100A9` and
`FCN1` oppose ribosomal and T-cell genes along the first component. The second
separates antigen-presenting genes (`HLA-DRA`, `CD74`) from cytotoxic genes
(`NKG7`, `GZMB`, `CCL5`). Genes such as `PPBP` and `GP9` extend farther along
the negative PC 2 direction. Component signs are arbitrary.

## Group cells by their neighbors

Cells of one type have similar profiles, so they share nearest neighbors. Use
the first 20 components to place the cells on a UMAP map. UMAP (uniform
manifold approximation and projection) arranges points in a plane while keeping
each point's neighbors nearby:

```wl
umap = DimensionReduce[pcs[[All, ;; 20]], 2, Method -> "UMAP", RandomSeeding -> 1];
```

Draw the graph that links each cell to its 12 nearest neighbors, placing every
cell at its map position:

```wl
GraphPlot[NearestNeighborGraph[pcs[[All, ;; 20]], 12], VertexCoordinates -> umap, EdgeStyle -> Opacity[0.05], VertexShapeFunction -> None]
```

Dense bundles show where the graph and the map agree. Few links cross the gaps
between islands. Distances between islands, and island sizes, are not reliable
measurements: UMAP keeps local structure better than global geometry
([Chari and Pachter 2023](https://doi.org/10.1371/journal.pcbi.1011288);
[Lause, Berens and Kobak 2024](https://doi.org/10.1371/journal.pcbi.1012403)).

To find groups, weight each link by the overlap of the two cells' neighbor
sets, then split the graph into communities that are densely linked inside,
using
[FindGraphCommunities](https://reference.wolfram.com/language/ref/FindGraphCommunities.html):

```wl
clusters = graphClusters[pcs[[All, ;; 20]], 12, 20261104];
```

Color the map by community:

```wl
mapPlot[umap, clusters]
```

## Name the communities with marker genes

For display, scale each cell to 10,000 counts and take `Log[1 + x]`, which
keeps zeros at zero:

```wl
logExpression = Log[1. + kept 10000/totals[[keep]]];
```

Show eight classic markers on the map, drawing higher values on top:

```wl
GraphicsGrid[Partition[featurePlot[umap, logExpression[[All, gene[#]]], #] & /@ {"CCR7", "S100A4", "CD8A", "NKG7", "MS4A1", "CD14", "FCGR3A", "PPBP"}, 4], ImageSize -> Large]
```

Each marker lights up its own region: `CCR7` naive T cells, `S100A4` memory T
cells and monocytes, `CD8A` cytotoxic T cells, `NKG7` natural killer (NK) and
cytotoxic T cells, `MS4A1` B cells, `CD14` classical monocytes, `FCGR3A`
non-classical monocytes and NK cells, and `PPBP` the platelet/megakaryocyte lineage. The large T-cell
island holds communities that differ in `CCR7` and `S100A4`, consistent with
naive and memory T-cell states. These markers alone do not uniquely establish
every cell's subtype.

Assign provisional names using the marker sets of the
[Scanpy PBMC tutorial](https://scanpy.readthedocs.io/en/stable/tutorials/basics/clustering-2017.html).
Standardize each marker's mean expression across communities, then give each
community the type whose markers score highest. This rule has no unassigned
class and is not a calibrated cell-type classifier:

```wl
markerSets = <|"CD4 T" -> {"IL7R"}, "CD8 T" -> {"CD8A"}, "NK" -> {"GNLY", "NKG7"}, "B" -> {"MS4A1"},
    "CD14 monocyte" -> {"CD14", "LYZ"}, "FCGR3A monocyte" -> {"FCGR3A", "MS4A7"}, "Dendritic" -> {"FCER1A", "CST3"}, "Platelet/megakaryocyte" -> {"PPBP"}|>;
scores = markerScores[logExpression, clusters, Map[gene, markerSets, {2}]];
```

Each row of the heat map is a cell type and each column a community; dark red
marks a strong match:

```wl
Legended[MatrixPlot[Transpose[scores],
    ColorFunction -> (ColorData["ThermometerColors"][Rescale[#, {-3, 3}]] &), ColorFunctionScaling -> False,
    PlotRange -> {-3, 3}, FrameTicks -> {{Transpose[{Range[Length[markerSets]], Keys[markerSets]}], None}, {Automatic, None}}],
    BarLegend[{"ThermometerColors", {-3, 3}}]]
```

Give each community its best-scoring type and count the cells of each type:

```wl
clusterType = Keys[markerSets][[Flatten[Ordering[#, -1] & /@ scores]]];
cellType = clusterType[[clusters]];
Counts[cellType]
```

Communities that score highest for the same type share its name. Compare the
linear PCA view with UMAP, colored by cell type:

```wl
Row[{mapPlot[pcs[[All, ;; 2]], cellType, PlotStyle -> tolMuted, PlotLegends -> None], mapPlot[umap, cellType, PlotStyle -> tolMuted]}]
```

Both panels show every retained cell. The platelet/megakaryocyte-labeled cells
extend far along PC 2, compressing the other groups in the PCA view. T-cell
states overlap there; UMAP separates the same cells into distinct neighborhoods.

## Let the data propose markers

The marker sets were chosen in advance. Summarize the same data within these
marker-derived labels: for each type,
find the two selected genes whose mean expression most exceeds the mean over
all cells:

```wl
found = Union[Flatten[topGenes[logExpression[[All, variable]], cellType, #, 2] & /@ Union[cellType]]];
symbols[[variable[[found]]]]
```

A dot plot shows two numbers for each type and gene. Dot area is the fraction
of cells with at least one count; color is mean expression, rescaled from the lowest to the highest
type separately for each gene. These are descriptive summaries, not independent
marker validation or differential-expression tests:

```wl
dotPlot[logExpression[[All, variable[[found]]]], cellType, symbols[[variable[[found]]]]]
```

The data recover textbook markers such as `LYZ`, `GNLY` and `PPBP` and add
others: `CD3D` and `LTB` in T cells, `LST1` and `AIF1` in FCGR3A monocytes, and
HLA class II genes (`HLA-DRA`, `CD74`) in B cells, monocytes and dendritic
cells. `CCL5` appears in CD8 T and NK cells and in the platelet/megakaryocyte-labeled group. Shared expression,
ambient RNA or mixed droplets can contribute to such cross-group signals. Each type has a recognizable combination
rather than a single unique gene.

## Count the cell types

```wl
BarChart[KeySort[Counts[cellType]], ChartStyle -> tolMuted, ChartLabels -> Automatic, BarOrigin -> Left, LabelingFunction -> After]
```

CD4 T cells dominate, followed by classical monocytes, B cells and CD8 T cells.
These are shares of captured cells that passed quality control, from one donor.
Cell types differ in RNA content and capture efficiency, so the shares are not
direct estimates of blood composition.

## Treat cluster resolution as a choice

The neighborhood size sets how finely the graph splits. Recompute the
communities with 5, 12 and 40 neighbors, keeping every other step fixed:

```wl
GraphicsRow[Table[With[{labels = graphClusters[pcs[[All, ;; 20]], k, 20261104]},
    mapPlot[umap, labels, PlotLegends -> None, PlotLabel -> Row[{k, " neighbors: ", Max[labels], " communities"}]]], {k, {5, 12, 40}}], ImageSize -> Large]
```

Small neighborhoods split cell types into states; large ones merge related
types such as NK and CD8 T cells, which share cytotoxic programs. The analysis
above uses 12 neighbors because that setting separates the two monocyte types
that the marker genes distinguish. No setting is correct in general. Report
the choice, check that conclusions hold for nearby values, and confirm
identities with marker genes or independent data.

## What this analysis supports

The analysis found expression neighborhoods consistent with major blood
immune populations and assigned provisional names using known markers. The
marker-derived labels and markers rediscovered within them use the same cells;
independent reference data or additional measurements are needed to validate
cell identity. The thresholds, the
residual model, the 300 genes, the 20 components, the 12 neighbors and the seed
are all stated above; changing them can move individual cells between groups.

Cells from one donor are not biological replicates. Comparing people or
conditions needs several donors per group, with statistics across donors rather
than across cells. [Luecken and Theis 2019](https://doi.org/10.15252/msb.20188746)
review these steps in depth.

## Initialization

These helpers keep the analysis inputs short. Category colors come from Paul
Tol's muted palette, which stays distinguishable with common color-vision
deficiencies.

```wl
tolMuted = RGBColor /@ {"#CC6677", "#332288", "#DDCC77", "#117733", "#88CCEE", "#882255", "#44AA99", "#999933", "#AA4499"};
geneSet[data_, flag_] := Flatten[Position[Normal[data["GeneMetadata"][All, flag]], True]];
pearsonResiduals[x_, n_] := With[{mu = Outer[Times, N[n], Normal[Total[x]]/Total[n]]},
    Clip[(Normal[x] - mu)/Sqrt[mu + mu^2/100], {-1, 1} Sqrt[N[Length[n]]]]];
```

`graphClusters` links each cell to its `k` nearest neighbors, weights each link
by the Jaccard overlap of the two closed neighbor sets (each includes its own
cell), and returns a community number
for every cell. The source index identifies the query cell explicitly, so
identical coordinates cannot substitute a different cell in its place:

```wl
graphClusters[x_, k_, seed_] := Module[{index, near, links, communities, labels},
    index = Nearest[x -> "Index"];
    near = Table[Prepend[Take[DeleteCases[index[x[[i]], k + 1], i], k], i], {i, Length[x]}];
    links = Union[Sort /@ Catenate[Thread[{First[#], Rest[#]}] & /@ near]];
    communities = BlockRandom[SeedRandom[seed]; FindGraphCommunities[
        Graph[Range[Length[x]], UndirectedEdge @@@ links,
            EdgeWeight -> (N[Length[Intersection @@ near[[#]]]/Length[Union @@ near[[#]]]] & /@ links)],
        Method -> "Modularity"]];
    labels = ConstantArray[0, Length[x]];
    Do[labels[[communities[[c]]]] = c, {c, Length[communities]}];
    labels];
```

```wl
mapPlot[xy_, labels_, opts___] := With[{groups = KeySort[GroupBy[Thread[labels -> xy], First -> Last]]},
    ListPlot[Values[groups], opts, PlotRange -> All, PlotLegends -> Keys[groups], BaseStyle -> PointSize[0.006], AspectRatio -> 1, Frame -> True, FrameTicks -> None, Axes -> False, ImageSize -> 320]];
featurePlot[xy_, values_, label_] := With[{x = Normal[values], order = Ordering[Normal[values]]},
    Graphics[{PointSize[Small], Point[xy[[order]], VertexColors -> (ColorData[{"LakeColors", "Reverse"}] /@ Rescale[x[[order]]])]},
        PlotLabel -> label, Frame -> True, FrameTicks -> None, AspectRatio -> 1]];
markerScores[expression_, labels_, sets_] := Transpose[Table[
    Mean /@ Standardize[Table[Mean[Normal[expression[[Flatten[Position[labels, c]], set]]]], {c, Max[labels]}]], {set, Values[sets]}]];
topGenes[expression_, labels_, type_, n_] := Take[Ordering[Normal[Mean[expression[[Flatten[Position[labels, type]]]]] - Mean[expression]], All, Greater], n];
dotPlot[columns_, labels_, names_] := Module[{types = Union[labels], fraction, level},
    fraction = Table[Mean[Unitize[Normal[columns[[Flatten[Position[labels, t]]]]]]], {t, types}];
    level = Transpose[Rescale /@ Transpose[Table[Mean[Normal[columns[[Flatten[Position[labels, t]]]]]], {t, types}]]];
    Graphics[Table[{ColorData["BlueGreenYellow"][level[[i, j]]], Disk[{j, -i}, 0.45 Sqrt[fraction[[i, j]]]]}, {i, Length[types]}, {j, Length[names]}],
        Frame -> True, FrameTicks -> {{Transpose[{-Range[Length[types]], types}], None}, {Transpose[{Range[Length[names]], Rotate[#, Pi/2] & /@ names}], None}}]];
```
