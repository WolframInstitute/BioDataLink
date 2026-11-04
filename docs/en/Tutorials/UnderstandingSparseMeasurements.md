---
Template: TechNote
Name: UnderstandingSparseMeasurements
Title: Understanding Sparse Measurements
Context: WolframInstitute`BioDataLink`
Paclet: WolframInstitute/BioDataLink
URI: WolframInstitute/BioDataLink/tutorial/UnderstandingSparseMeasurements
Keywords: [application, sparse arrays, missing measurements, alignment, normalization, model comparison]
RelatedGuides: [BioDataLink, ComputationalExplorations, DataAccess]
---

What does an empty-looking position in a measurement matrix mean? A stored zero,
an unmeasured variable and a value on a different processing scale require
different treatment. This workflow starts from the bundled synthetic JSON
file, constructs two explicitly defined assay panels, and shows how these
choices change summaries and candidate-model scores.

All numerical examples are synthetic. They illustrate data handling and
arithmetic, not gene regulation, cell types, treatment effects or biological
replication. The larger example is a deterministic construction from a few
fixture values and stated constants; it has no organism, accession or random
seed. Ordinary examples run offline without Python or Ruliobiology.

## Read a matrix together with its meaning

Evaluate the Initialization section at the end of this tutorial. Read the
bundled synthetic file and inspect the returned record:

```wl
data = BioDatasetLoad[File[FileNameJoin[{PacletObject["WolframInstitute/BioDataLink"]["AssetLocation", "Examples"], "toy-expression.json"}]]]
```

The matrix has three observation rows and two variable columns. Its metadata
call these example cells and genes; those labels describe the fixture's intended
interface, not real biological objects. The file declares integer counts.

```wl
counts = data["ExpressionMatrix"];
```

Plot the counts with their row and column identifiers:

```wl
MatrixPlot[counts, PlotLegends -> Automatic,
    FrameTicks -> matrixTicks[Normal[data["CellMetadata"][All, "ID"]], Normal[data["GeneMetadata"][All, "ID"]]]]
```

The entries are `{{3, 0}, {0, 5}, {2, 1}}`. JSON schema version 1 represents
omitted entries as numerical zeros; it has no separate measurement-availability
mask. A zero count in experimental data means no count was recorded by the
specified assay and processing. It does not alone establish biological absence.

Keep the sparse representation for arithmetic. Wolfram Language supports
plotting sparse arrays directly; converting an entire large sparse array with
`Normal` can require far more memory than the stored entries. This tutorial
uses `Normal` only on explicitly small arrays or reduced vectors.
See the official [SparseArray documentation](https://reference.wolfram.com/language/ref/SparseArray.html).

## Construct two panels with different measured variables

Suppose one panel measures variables A through D, while another measures C
through F. Construct four profiles in each panel. The second profile in panel A
is exactly ten times its first profile; this deliberate relationship will make
the effect of rescaling visible later.

```wl
panelA = With[{firstProfile = Join[Normal[counts[[1]]], {2, 0}]},
    {firstProfile, 10 firstProfile, Join[Normal[counts[[2]]], {0, 1}], Join[Normal[counts[[3]]], {0, 0}]}];
panelB = {{0, 2, 4, 0}, {1, 0, 0, 3}, {0, 3, 1, 0}, {2, 1, 0, 2}};
panelVariables = "gene-" <> # & /@ {"A", "B", "C", "D", "E", "F"};
panelObservations = Flatten[Outer[StringJoin, {"A", "B"}, ToString /@ Range[4]]];
```

Place the two panels on their union of variables. `values` uses zeros as storage
placeholders outside each measured panel. The separate `available` matrix is
essential: 1 means measured and 0 means unmeasured. It is constructed here from
the stated panel design, not inferred from observed zeros or imported by the
JSON reader.

```wl
values = SparseArray[Join[Join[#, {0, 0}] & /@ panelA,
    Join[{0, 0}, #] & /@ panelB]];
available = SparseArray[Join[ConstantArray[{1, 1, 1, 1, 0, 0}, 4],
    ConstantArray[{0, 0, 1, 1, 1, 1}, 4]]];
```

Use separate categories for a recorded zero, a positive count and an
unmeasured position:

```wl
With[{status = MapThread[If[#2 == 0, "unmeasured", If[#1 == 0, "recorded zero", "positive count"]] &,
        {Normal[values], Normal[available]}, 2]},
    ArrayPlot[status, PlotLegends -> Automatic,
        ColorRules -> {"recorded zero" -> LightGray, "positive count" -> Blue, "unmeasured" -> Orange},
        FrameTicks -> matrixTicks[panelObservations, panelVariables]]]
```

This categorical figure separates missingness from numerical intensity. The
explicit rules associate each status with one color, as supported by
[ArrayPlot](https://reference.wolfram.com/language/ref/ArrayPlot.html).
The unmeasured positions would disappear into the zero category if the mask
were discarded. In real combined data, use source-provided assay coverage or a
documented measurement mask; the pattern of numerical zeros cannot reconstruct
that information.

Compare the number of measured variables with the number having positive
recorded counts in each observation:

```wl
With[{measured = Normal[Total[available, {2}]], positive = Normal[Total[Unitize[values], {2}]]},
    BarChart[Transpose[{measured, positive}],
        ChartLabels -> {panelObservations, None}, ChartLegends -> {"measured variables", "positive counts"},
        AxesLabel -> {None, "number of variables"}]]
```

Every synthetic observation covers four variables, while its positive-count
support is smaller. These are different quantities. Neither count defines a
biological quality threshold in this example. Counts of positive values also
depend on the processing scale: centered measurements can be negative, and
thresholding changes their support.

## Check the denominator before averaging

For variable j, a mean over measured observations divides its recorded total
by the number of observations in which it was measured. Dividing by all eight
rows instead treats every unmeasured position as an observed zero.

```wl
With[{totals = Normal[Total[values]], measured = Normal[Total[available]]},
    BarChart[Transpose[N[{totals/Length[panelObservations], totals/measured}]],
        ChartLabels -> {panelVariables, None}, ChartLegends -> {"all rows, with zero padding", "measured rows only"},
        AxesLabel -> {None, "mean synthetic count"}]]
```

Variables A, B, E and F are measured in four rows, so the zero-filled mean is
half their measured-only mean. Variables C and D are measured in all eight rows,
so their two means agree. Every variable is measured at least once here; a
variable with no measured observations needs an explicit missing result rather
than division by zero.

The measured-only mean corrects this arithmetic denominator. It does not make
panels interchangeable or correct selection bias, batches or sampling design.
Comparing panels scientifically would still require a defensible common assay
and a model of how observations were collected.

## Align identifiers before comparing arrays

Reordering rows or columns changes positional comparisons even if every value
is retained. Permute panel A and restore it with the inverse permutations:

```wl
rowOrder = {4, 2, 1, 3};
columnOrder = {4, 2, 1, 3};
permuted = panelA[[rowOrder, columnOrder]];
restored = permuted[[Ordering[rowOrder], Ordering[columnOrder]]];
```

Compare the source, permuted and restored matrices, retaining their identifiers:

```wl
GraphicsRow[{
    alignmentPlot[panelA, Range[4], Range[4], "source"],
    alignmentPlot[permuted, rowOrder, columnOrder, "permuted"],
    alignmentPlot[restored, Range[4], Range[4], "restored"]}]
```

The panels share the same color scale. The inverse permutation restores the
source matrix exactly; comparing the unaligned arrays gives an artificial
discrepancy. Show those squared discrepancies explicitly:

```wl
<|"BeforeAlignment" -> Total[Flatten[(panelA - permuted)^2]],
    "AfterAlignment" -> Total[Flatten[(panelA - restored)^2]]|>
```

For a real source, derive positions from identifiers and check uniqueness,
namespace and missing matches before reordering. Two identical-looking gene
labels can denote separate source columns. Do not build a mapping that silently
overwrites duplicates.

The optional H5AD reader retains each original label together with a one-based
`"SourceIndex"`. After configuring the reader as described in
[Reading Selected AnnData Measurements](paclet:WolframInstitute/BioDataLink/tutorial/ReadingAnnDataSlices),
the following local example exposes the bundled fixture's duplicate `"g1"`
labels. It is not evaluated in ordinary documentation builds; replace the
interpreter path before running it.

```wl
#| eval: false
With[{h5ad = FileNameJoin[{PacletObject["WolframInstitute/BioDataLink"]["AssetLocation", "Examples"], "toy-anndata.h5ad"}]},
    BioDatasetLoad[File[h5ad], "Format" -> "AnnData", "PythonExecutable" -> "/path/to/biodatalink-h5ad/bin/python",
        "Cells" -> {1, 2}, "Genes" -> {1, 2, 3}]["GeneMetadata"][All, {"SourceIndex", "ID"}]]
```

The checked fixture has `"g1"` at source positions 1 and 2 and `"g3"` at
position 3. A source position distinguishes columns within that source and
revision; it is not a gene identifier that can be matched across studies.

## Make measurement scale part of the comparison

Use only panel A for this comparison, since every row shares the same four
measured variables. Divide each profile by its own positive total to obtain
fractions over those four variables. This is an explicit analytical
transformation, not a claim that the result is a recommended normalization
for an experimental study.

```wl
fractions = N[#/Total[#] & /@ panelA];
```

Each distance matrix has its own color scale and units:

```wl
GraphicsRow[{distancePlot[DistanceMatrix[N[panelA]], "counts"], distancePlot[DistanceMatrix[fractions], "fractions"]}]
```

Rows A1 and A2 have identical fractions because one count profile is ten times
the other. Their count-space distance is positive and their fraction-space
distance is zero. The two panels have different units and independent color
scales; color intensity should be read against each legend. This construction
shows that a comparison must specify its scale. It does not establish that the
two observations share a biological state.

Rescaling and transformations also affect whether sparse storage remains
useful. Division by a positive row total and `Log[1 + x]` preserve exact zeros.
Subtracting each variable's mean generally changes those zeros:

```wl
BarChart[Total[Unitize[Flatten[#]]] & /@ {panelA, fractions, Log[1 + fractions], Standardize[fractions, Mean, 1 &]},
    ChartLabels -> {"counts", "fractions", "log", "centered"}, AxesLabel -> {None, "nonzero entries among 16 positions"}]
```

Only these tiny matrices are materialized. For large data, preserve a sparse
matrix plus a separate offset when the downstream calculation supports it;
avoid constructing a dense centered matrix merely to inspect a small subset.
That algebraic representation must still give the same intended calculation.

AnnData supports `X`, same-shaped alternative layers and other structures.
The storage schema specifies their organization, not the biological meaning
of a layer name. See the official
[AnnData on-disk specification](https://anndata.readthedocs.io/en/stable/fileformat-prose.html).
BioDataLink therefore records the selected layer and leaves normalization
unspecified when importing H5AD. A named `normalized` layer or a `raw` storage
location does not establish counts, a transformation or measurement coverage.
This optional example makes the chosen layer and axes explicit:

```wl
#| eval: false
With[{h5ad = FileNameJoin[{PacletObject["WolframInstitute/BioDataLink"]["AssetLocation", "Examples"], "toy-anndata.h5ad"}]},
    KeyTake[BioDatasetLoad[File[h5ad], "Format" -> "AnnData", "PythonExecutable" -> "/path/to/biodatalink-h5ad/bin/python",
            "Cells" -> {1, 2}, "Genes" -> {1, 2, 3}, "Layer" -> {"Layers", "normalized"}],
        {"SourceLayer", "SelectedCells", "SelectedGenes", "Normalization"}]]
```

The reader returns the selected matrix and annotations, not a full AnnData
object or an inferred measurement mask. Review `"OmittedStructures"` and the
source's processing documentation before analysis.

## Score candidate predictions on the measured domain

An application to Ruliobiology starts with an observation model: a defined
mapping from a simulated system to the measured variables, units and sample
positions. Without that mapping, comparing cellular-automaton states or other
simulation output directly with gene-count columns has no established
scientific interpretation.

Here two deliberately artificial candidates illustrate just the scoring step.
Candidate A exactly reproduces all measured entries but predicts 20 in every
unmeasured position. Candidate B predicts zero everywhere. No rule search is
performed and neither candidate is a fitted biological model.

Compare mean squared errors on all padded positions and on measured positions:

```wl
With[{candidateA = Normal[values] + 20 (1 - Normal[available]),
        candidateB = ConstantArray[0, Dimensions[values]]},
    BarChart[N[{paddedMSE[#], maskedMSE[#]} & /@ {candidateA, candidateB}],
        ChartLabels -> {{"candidate A", "candidate B"}, None},
        ChartLegends -> {"zero-padded error", "measured-only error"}, AxesLabel -> {None, "squared synthetic counts"}]]
```

On measured entries, candidate A has zero error and candidate B has positive
error. Zero padding penalizes A's unobserved predictions enough to prefer B.
The measured-only score makes no claim about which prediction is correct in
unmeasured positions. It merely prevents those positions from being treated as
observations.

For a genuine rule comparison, record the observation mapping, feature order,
assay coverage, preprocessing and loss together. Hold out independent
experimental units for evaluation where the design permits; cells from one
sample do not automatically supply independent biological replicates. A useful
score on a synthetic construction is an implementation check, not evidence of
a molecular mechanism.

## Keep the reconstruction record

Record the file identity and every choice that defines this example:

```wl
<|"SourceContentHash" -> data["ContentHash"],
    "Construction" -> "UnderstandingSparseMeasurements, deterministic panels version 1",
    "Synthetic" -> True, "Observations" -> panelObservations,
    "Variables" -> panelVariables,
    "MeasuredVariablePositions" -> <|"A" -> Range[4], "B" -> Range[3, 6]|>,
    "DeclaredScale" -> "Synthetic integer counts",
    "FractionTransform" -> "Divide panel A rows by their totals over variables A-D",
    "PredictionScore" -> "Mean squared error on explicitly measured entries"|>
```

This record and the visible panel construction reproduce the figures without
network access. For external data, retain the source accession and revision,
file identity, measurement-availability evidence and processing documentation
alongside the selected axes. Select bounded matrix slices before converting
them to dense arrays or constructing pairwise distances: an n-observation
distance matrix itself contains n squared entries even when its input is sparse.

## Initialization

These helpers supply identifier ticks and repeated plots. The alignment plots
share the source matrix's range; the distance plots retain independent scales.
The two loss functions differ only in which positions they count as measured.

```wl
matrixTicks[rows_, columns_] := {{Thread[{Range[Length[rows]], rows}], None}, {Thread[{Range[Length[columns]], columns}], None}};
alignmentPlot[matrix_, rows_, columns_, label_] := MatrixPlot[matrix,
    FrameTicks -> matrixTicks[panelObservations[[rows]], panelVariables[[columns]]],
    PlotRange -> {0, Max[panelA]}, PlotLabel -> label];
distancePlot[matrix_, label_] := MatrixPlot[matrix,
    FrameTicks -> matrixTicks[Take[panelObservations, 4], Take[panelObservations, 4]],
    PlotLegends -> Automatic, PlotLabel -> label];
maskedMSE[prediction_] := Mean[Pick[Flatten[(Normal[values] - prediction)^2], Flatten[Normal[available]], 1]];
paddedMSE[prediction_] := Mean[Flatten[(Normal[values] - prediction)^2]];
```
