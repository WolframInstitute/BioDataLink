---
Template: Symbol
Name: BioStructureComparisonPlot
Context: WolframInstitute`BioDataLink`
Paclet: WolframInstitute/BioDataLink
URI: WolframInstitute/BioDataLink/ref/BioStructureComparisonPlot
Description: Align and compare residue-keyed coordinate traces
Keywords: [biology, visualization]
RelatedGuides: [BioDataLink, Visualizations]
RelatedTutorials: [ComparingProteinConformations]
SeeAlso: [BioEmbeddingPlot, BioExpressionDotPlot, BioSequenceCompositionPlot, BioSequenceSkewPlot]
---

## Usage

`BioStructureComparisonPlot`[*reference*, *moving*, *regions*]
rigidly aligns ID-keyed coordinate traces and colors them by ID-keyed regions.

## Details & Options

- The reference and moving arguments map matching residue IDs to finite real
  triples. Regions map every residue ID to a string label.
- Residue IDs establish correspondence; no sequence alignment is inferred.
- The reference association's order establishes the trace order in both structures.
- All coordinates and the tube radius must use the same units.
- The reference is translucent; the aligned moving trace is solid.
- Alignment uses rotation and translation, with at least three noncollinear
  residues in each structure. All selected residues enter a least-squares fit;
  coordinates are not reflected or rescaled.

| | |
| --- | --- |
| `"AlignmentResidues"` | `All`, or a list of at least three distinct residue IDs |
| `"CategoryColors"` | `Automatic`, using Tol muted colors for up to nine regions, or a region-to-color association |
| `"TubeRadius"` | `0.3`, in coordinate units |
| `PlotLegends` | `Automatic` |

`Graphics3D` options apply; `ImageSize` defaults to `Automatic`.
Use `BioMoleculePlot3D` for native molecular ribbon and surface renderings.

## Basic Examples

Align two synthetic traces by a shared core:

```wl
reference = <|1 -> {0, 0, 0}, 2 -> {2, 0, 0}, 3 -> {2, 2, 0}, 4 -> {3, 3, 1}, 5 -> {4, 3, 2}|>;
moving = <|1 -> {3, 0, 0}, 2 -> {5, 0, 0}, 3 -> {5, 2, 0}, 4 -> {6, 2, 2}, 5 -> {7, 2, 4}|>;
regions = <|1 -> "core", 2 -> "core", 3 -> "core", 4 -> "tip", 5 -> "tip"|>;
BioStructureComparisonPlot[reference, moving, regions, "AlignmentResidues" -> {1, 2, 3}]
```

## Options

Change region colors and rendering size:

```wl
reference = <|1 -> {0, 0, 0}, 2 -> {2, 0, 0}, 3 -> {2, 2, 0}, 4 -> {3, 2, 1}|>;
moving = Map[# + {1, 2, 3} &, reference];
BioStructureComparisonPlot[reference, moving, <|1 -> "A", 2 -> "A", 3 -> "B", 4 -> "B"|>,
    "CategoryColors" -> <|"A" -> Blue, "B" -> Orange|>, "TubeRadius" -> 0.15, ImageSize -> Medium]
```

## Possible Issues

Collinear alignment points do not determine a unique three-dimensional rotation:

```wl
BioStructureComparisonPlot[<|1 -> {0, 0, 0}, 2 -> {1, 0, 0}, 3 -> {2, 0, 0}|>,
    <|1 -> {0, 1, 0}, 2 -> {1, 1, 0}, 3 -> {2, 1, 0}|>, <|1 -> "A", 2 -> "A", 3 -> "A"|>]
```

The alignment region is an analysis choice. Compare internal distances and
alternative fits before interpreting apparent motion.
