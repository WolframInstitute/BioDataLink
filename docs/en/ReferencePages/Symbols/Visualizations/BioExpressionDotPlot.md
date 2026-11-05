---
Template: Symbol
Name: BioExpressionDotPlot
Context: WolframInstitute`BioDataLink`
Paclet: WolframInstitute/BioDataLink
URI: WolframInstitute/BioDataLink/ref/BioExpressionDotPlot
Description: Compare group mean expression and detection fractions
Keywords: [biology, visualization]
RelatedGuides: [BioDataLink, Visualizations]
RelatedTutorials: [AnalyzingSingleCellExpression, UnderstandingSparseMeasurements]
SeeAlso: [BioEmbeddingPlot, BioSequenceCompositionPlot, BioSequenceSkewPlot, BioStructureComparisonPlot]
---

## Usage

`BioExpressionDotPlot`[*matrix*, *groups*, *features*]
plots mean expression by color and the fraction above a detection threshold
by dot area.

## Details & Options

- Rows are observations and columns are features. Supply one string group per
  row and one unique string feature label per column.
- Values must be finite and nonnegative. Dense matrices and `SparseArray` are
  supported. Implicit zeros are measured zeros, not missing measurements.
- All observations in a group contribute to its mean and detection denominator.
- Groups appear in order of first occurrence, from bottom to top. Features
  appear left to right in the supplied order.
- Tooltips give the group, feature, observation count, mean and detected fraction.
- The function does not normalize or log-transform measurements.

| | |
| --- | --- |
| `"DetectionThreshold"` | `0`; detection means strictly greater than the threshold |
| `"ColorScaling"` | `"Global"` for a shared mean scale, or `"PerFeature"` for a separate relative scale in each column |
| `ColorFunction` | `"BlueGreenYellow"` |
| `PlotLegends` | `Automatic` |

Constant columns receive the lowest relative color under `"PerFeature"`.
Standard `Graphics` options apply; `ImageSize` defaults to `Automatic`.

## Basic Examples

Compare a small synthetic expression matrix:

```wl
BioExpressionDotPlot[{{3, 0, 1}, {0, 2, 0}, {5, 1, 0}, {0, 4, 2}},
    {"group A", "group A", "group B", "group B"}, {"gene 1", "gene 2", "gene 3"}]
```

## Scope

Aggregate sparse observations before drawing the group summaries:

```wl
BioExpressionDotPlot[SparseArray[{{1, 1} -> 3, {2, 2} -> 4, {3, 1} -> 2}, {3, 2}],
    {"A", "A", "B"}, {"marker 1", "marker 2"}]
```

## Options

Compare relative expression within each feature:

```wl
BioExpressionDotPlot[{{10, 0}, {20, 2}, {40, 1}, {80, 3}}, {"A", "A", "B", "B"}, {"abundant", "rare"},
    "ColorScaling" -> "PerFeature", "DetectionThreshold" -> 1]
```

A fraction changes when the threshold changes; mean expression does not.
Relative colors cannot compare absolute abundance between features.

## Possible Issues

Resolve missing measurements before plotting; do not replace them with zero:

```wl
BioExpressionDotPlot[{{1, Missing["NotMeasured"]}}, {"A"}, {"x", "y"}]
```
