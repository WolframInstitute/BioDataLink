---
Template: Symbol
Name: BioSequenceSkewPlot
Context: WolframInstitute`BioDataLink`
Paclet: WolframInstitute/BioDataLink
URI: WolframInstitute/BioDataLink/ref/BioSequenceSkewPlot
Description: Plot strand composition in complete DNA windows
Keywords: [biology, visualization]
RelatedGuides: [BioDataLink, Visualizations]
RelatedTutorials: [ReadingBacterialGenomeComposition]
SeeAlso: [BioEmbeddingPlot, BioExpressionDotPlot, BioSequenceCompositionPlot, BioStructureComparisonPlot]
---

## Usage

`BioSequenceSkewPlot`[*sequence*, *window*]
plots (G − C)/(G + C) in complete, nonoverlapping DNA windows.

## Details & Options

- The sequence is a case-insensitive DNA string with IUPAC ambiguity codes.
- The window is a positive integer no longer than the sequence. An incomplete
  terminal window is excluded.
- Coordinates are one-based window midpoints, in bases.
- Ambiguous bases contribute to neither count. A window with no selected
  bases has an undefined skew and is omitted from the plotted values. If every
  complete window is undefined, the function returns a `Failure`.

| | |
| --- | --- |
| `"BasePair"` | `{"G", "C"}`; any two distinct uppercase A/C/G/T bases |
| `FrameLabel` | `{"position (bases)", "skew"}` |
| `PlotRange` | `All` |

`ListLinePlot` options apply. `ImageSize` defaults to `Automatic`.
The function plots descriptive counts; it does not identify an origin or
infer a replication mechanism.

## Basic Examples

Plot a synthetic change in strand composition:

```wl
BioSequenceSkewPlot[StringRepeat["GGGCAA", 40] <> StringRepeat["CCCGTT", 40], 24, Filling -> Axis]
```

## Options

Compare AT skew at two resolutions:

```wl
sequence = StringRepeat["AAATGC", 40] <> StringRepeat["TTTAGC", 40];
GraphicsRow[BioSequenceSkewPlot[sequence, #, "BasePair" -> {"A", "T"},
    PlotRange -> {-1, 1}, PlotLabel -> Row[{#, " bases"}]] & /@ {24, 96}]
```

## Possible Issues

The denominator can be zero even for valid DNA:

```wl
BioSequenceSkewPlot["GGGGAAAACCCC", 4, PlotMarkers -> Automatic]
```

The middle window contains no G or C and has no defined GC skew.
