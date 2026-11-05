---
Template: Symbol
Name: BioEmbeddingPlot
Context: WolframInstitute`BioDataLink`
Paclet: WolframInstitute/BioDataLink
URI: WolframInstitute/BioDataLink/ref/BioEmbeddingPlot
Description: Plot ID-aligned embeddings and annotations
Keywords: [biology, visualization]
RelatedGuides: [BioDataLink, Visualizations]
RelatedTutorials: [AnalyzingSingleCellExpression, ExploringBiologicalDataGeometry]
SeeAlso: [BioExpressionDotPlot, BioSequenceCompositionPlot, BioSequenceSkewPlot, BioStructureComparisonPlot]
---

## Usage

`BioEmbeddingPlot`[*coordinates*, *annotations*]
plots ID-keyed two-dimensional coordinates colored by ID-keyed annotations.

## Details & Options

- Both arguments are associations. Annotations are joined by ID, not position.
- Every coordinate ID needs an annotation. Extra annotations establish a common
  category vocabulary or numeric color range across subsets.
- Categorical annotations are strings. Continuous annotations are finite real
  values; larger values are drawn last.
- Coordinates must be finite real pairs. The function does not compute an embedding.

| | |
| --- | --- |
| `"ColorMode"` | `"Categorical"` or `"Continuous"` |
| `"CategoryColors"` | `Automatic`, using Tol muted colors for up to nine categories, or a category-to-color association |
| `"ColorRange"` | `Automatic`, using all numeric annotations, or `{min, max}`; values outside the range are clipped for color only |
| `ColorFunction` | `"BlueGreenYellow"` for continuous annotations |
| `PlotLegends` | `Automatic`; use `None` to omit the legend |

Standard `Graphics` options apply. `ImageSize` defaults to `Automatic`.

## Basic Examples

Plot synthetic observations with annotations supplied in a different order:

```wl
xy = <|"cell-1" -> {0, 0}, "cell-2" -> {1, 0.5}, "cell-3" -> {2.5, 2}, "cell-4" -> {3, 2.5}|>;
labels = <|"cell-4" -> "B", "cell-2" -> "A", "cell-1" -> "A", "cell-3" -> "B"|>;
BioEmbeddingPlot[xy, labels]
```

## Scope

Retain the full annotation association when plotting a subset:

```wl
xy = <|"a" -> {0, 0}, "b" -> {1, 1}, "c" -> {2, 0}|>;
labels = <|"a" -> "A", "b" -> "B", "c" -> "C"|>;
Grid[{{BioEmbeddingPlot[xy, labels, ImageSize -> 260], BioEmbeddingPlot[KeyTake[xy, {"b", "c"}], labels, ImageSize -> 260]}}]
```

## Options

Use a fixed numeric range for comparable expression colors:

```wl
BioEmbeddingPlot[<|"a" -> {0, 0}, "b" -> {1, 1}, "c" -> {2, 0}|>, <|"a" -> 0, "b" -> 2, "c" -> 8|>,
    "ColorMode" -> "Continuous", "ColorRange" -> {0, 10}, ImageSize -> Medium]
```

## Possible Issues

Missing annotations return a `Failure`:

```wl
BioEmbeddingPlot[<|"a" -> {0, 1}|>, <|"b" -> "type"|>]
```

Embedding distances and island sizes need not represent biological distances
or population sizes. Inspect the original measurement space.
