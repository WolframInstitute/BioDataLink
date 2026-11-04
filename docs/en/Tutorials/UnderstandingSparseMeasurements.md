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

Distinguish recorded zeros from unmeasured values before combining matrices
or comparing models. This offline example uses **synthetic** counts and two
invented assay panels; it supports no biological conclusions.

Evaluate **Initialization**, then run the examples in order.

## Read values with their identifiers

```wl
data = BioDatasetLoad[File[FileNameJoin[{PacletObject["WolframInstitute/BioDataLink"]["AssetLocation", "Examples"], "toy-expression.json"}]]]
```

```wl
counts = data["ExpressionMatrix"];
```

Plot the matrix with labeled axes:

```wl
MatrixPlot[counts, PlotLegends -> Automatic,
    FrameTicks -> matrixTicks[Normal[data["CellMetadata"][All, "ID"]], Normal[data["GeneMetadata"][All, "ID"]]]]
```

The matrix is `{{3, 0}, {0, 5}, {2, 1}}`. JSON version 1 treats omitted entries
as zero and has no measurement-availability mask. In real data, a zero count
does not prove biological absence. Keep large arrays sparse; use `Normal`
only on bounded selections or reduced results.

## Keep a separate measurement mask

Construct four profiles measuring variables A–D and four measuring C–F.
Panel A's second profile is deliberately ten times its first:

```wl
panelA = With[{firstProfile = Join[Normal[counts[[1]]], {2, 0}]},
    {firstProfile, 10 firstProfile, Join[Normal[counts[[2]]], {0, 1}], Join[Normal[counts[[3]]], {0, 0}]}];
panelB = {{0, 2, 4, 0}, {1, 0, 0, 3}, {0, 3, 1, 0}, {2, 1, 0, 2}};
panelVariables = "gene-" <> # & /@ {"A", "B", "C", "D", "E", "F"};
panelObservations = Flatten[Outer[StringJoin, {"A", "B"}, ToString /@ Range[4]]];
```

Place both panels on the union of variables. `available` records which entries
were measured; zeros outside a panel are only storage placeholders.

```wl
values = SparseArray[Join[Join[#, {0, 0}] & /@ panelA,
    Join[{0, 0}, #] & /@ panelB]];
available = SparseArray[Join[ConstantArray[{1, 1, 1, 1, 0, 0}, 4],
    ConstantArray[{0, 0, 1, 1, 1, 1}, 4]]];
```

Distinguish unmeasured values from recorded zeros:

```wl
With[{status = MapThread[If[#2 == 0, "unmeasured", If[#1 == 0, "recorded zero", "positive count"]] &,
        {Normal[values], Normal[available]}, 2]},
    ArrayPlot[status, PlotLegends -> Automatic,
        ColorRules -> {"recorded zero" -> LightGray, "positive count" -> Blue, "unmeasured" -> Orange},
        FrameTicks -> matrixTicks[panelObservations, panelVariables]]]
```

The mask comes from the stated assay design. It cannot be recovered from
numerical zeros, and the JSON reader does not supply it.

## Use the measured denominator

Compare means over all rows with means over rows that measured each variable:

```wl
With[{totals = Normal[Total[values]], measured = Normal[Total[available]]},
    BarChart[Transpose[N[{totals/Length[panelObservations], totals/measured}]],
        ChartLabels -> {panelVariables, None}, ChartLegends -> {"all rows, with zero padding", "measured rows only"},
        AxesLabel -> {None, "mean synthetic count"}]]
```

Zero padding halves the means for A, B, E and F, each measured in four rows.
C and D are measured in all eight rows. A variable never measured needs a
missing result, not division by zero. Correcting this denominator does not
remove batch effects or sampling bias.

## Align before comparing

Permute panel A, then restore its row and column order:

```wl
rowOrder = {4, 2, 1, 3};
columnOrder = {4, 2, 1, 3};
permuted = panelA[[rowOrder, columnOrder]];
restored = permuted[[Ordering[rowOrder], Ordering[columnOrder]]];
```

Compare matrices before and after alignment:

```wl
GraphicsRow[{
    alignmentPlot[panelA, Range[4], Range[4], "source"],
    alignmentPlot[permuted, rowOrder, columnOrder, "permuted"],
    alignmentPlot[restored, Range[4], Range[4], "restored"]}]
```

Measure the alignment discrepancy:

```wl
<|"BeforeAlignment" -> Total[Flatten[(panelA - permuted)^2]],
    "AfterAlignment" -> Total[Flatten[(panelA - restored)^2]]|>
```

Restoration removes the artificial discrepancy. For real data, derive positions
from IDs and check namespaces, duplicates and missing matches. H5AD's
`SourceIndex` distinguishes repeated labels within a source; it is not a
cross-study gene identifier. See
[Reading Selected AnnData Measurements](paclet:WolframInstitute/BioDataLink/tutorial/ReadingAnnDataSlices).

## Make the scale explicit

Within panel A, divide each row by its total over the same four variables:

```wl
fractions = N[#/Total[#] & /@ panelA];
```

Compare distances before and after scaling:

```wl
GraphicsRow[{distancePlot[DistanceMatrix[N[panelA]], "counts"], distancePlot[DistanceMatrix[fractions], "fractions"]}]
```

Profiles A1 and A2 now coincide because their original counts differ only by
a factor of ten. The plots have different units and separate color scales.
This illustrates rescaling, not a recommended normalization for every assay.

```wl
BarChart[Total[Unitize[Flatten[#]]] & /@ {panelA, fractions, Log[1 + fractions], Standardize[fractions, Mean, 1 &]},
    ChartLabels -> {"counts", "fractions", "log", "centered"}, AxesLabel -> {None, "nonzero entries among 16 positions"}]
```

Row scaling and `Log[1 + x]` preserve zeros; mean-centering usually does not.
Avoid materializing a large dense matrix just to inspect a small selection.
A layer name such as `normalized` or `raw` does not verify measurement scale
or coverage.

## Score only observed entries

Candidate A matches measured entries but predicts 20 at unmeasured positions.
Candidate B predicts zero everywhere. Compare mean squared errors:

```wl
With[{candidateA = Normal[values] + 20 (1 - Normal[available]),
        candidateB = ConstantArray[0, Dimensions[values]]},
    BarChart[N[{paddedMSE[#], maskedMSE[#]} & /@ {candidateA, candidateB}],
        ChartLabels -> {{"candidate A", "candidate B"}, None},
        ChartLegends -> {"zero-padded error", "measured-only error"}, AxesLabel -> {None, "squared synthetic counts"}]]
```

Measured-only error favors A; zero padding incorrectly favors B. Neither score
tests predictions at unmeasured positions. Real model comparisons also need an
observation mapping, stated preprocessing and independent evaluation units.

## Record the construction

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

For real data, retain accession, revision, file identity, selected axes and
measurement-availability evidence. Pairwise distance matrices contain n²
entries even when their input is sparse; select a manageable subset first.

## Initialization

Plotting helpers preserve identifiers. The two loss functions differ only in
whether unmeasured positions enter the score.

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
