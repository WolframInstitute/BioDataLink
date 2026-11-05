---
Template: Symbol
Name: BioSequenceCompositionPlot
Context: WolframInstitute`BioDataLink`
Paclet: WolframInstitute/BioDataLink
URI: WolframInstitute/BioDataLink/ref/BioSequenceCompositionPlot
Description: Plot overlapping DNA-word counts on a chaos-game grid
Keywords: [biology, visualization]
RelatedGuides: [BioDataLink, Visualizations]
RelatedTutorials: [ReadingBacterialGenomeComposition]
SeeAlso: [BioEmbeddingPlot, BioExpressionDotPlot, BioSequenceSkewPlot, BioStructureComparisonPlot]
---

## Usage

`BioSequenceCompositionPlot`[*sequence*, *k*]
plots counts of overlapping *k*-base DNA words on a chaos-game grid.

## Details & Options

- The sequence is a DNA string, case insensitive, with IUPAC ambiguity codes.
- Ambiguity codes break words. Positions on either side are not joined.
- Word length is an integer from 1 through 8. The grid has 2^*k* rows and
  2^*k* columns; counts include overlaps.
- A/T occupy the lower quadrants and C/G the upper quadrants. The most recent
  base determines the largest quadrant.
- Empty input, invalid letters or no complete words return a `Failure`.

| | |
| --- | --- |
| `"CountScaling"` | `"Log"` displays `Log[1 + count]`; `"Linear"` displays counts |
| `ColorFunction` | `"BlueGreenYellow"` |
| `DataReversed` | `True` |
| `PlotLegends` | `Automatic` |

Other `ArrayPlot` options apply. `ImageSize` defaults to `Automatic`.

## Basic Examples

Count pairs in a synthetic DNA string:

```wl
BioSequenceCompositionPlot["AAAACCCCGGGGTTTTACGTACGT", 2]
```

## Scope

Compare independent bases with a repeated synthetic pattern:

```wl
sequences = BlockRandom[SeedRandom[7];
    {StringJoin[RandomChoice[{"A", "C", "G", "T"}, 5000]], StringRepeat["AACCGT", 833]}];
GraphicsRow[BioSequenceCompositionPlot[#, 4, PlotLegends -> None] & /@ sequences]
```

## Options

Display raw counts on a linear scale:

```wl
BioSequenceCompositionPlot["ACGTACGTACGT", 1, "CountScaling" -> "Linear"]
```

## Possible Issues

An ambiguous base prevents a word from spanning that position:

```wl
BioSequenceCompositionPlot["ACNAC", 3]
```

Composition does not establish ancestry, function or a causal mechanism.
