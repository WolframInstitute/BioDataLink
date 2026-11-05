---
Template: Guide
Name: Visualizations
Title: Visualizing Biological Data
Context: WolframInstitute`BioDataLink`
Paclet: WolframInstitute/BioDataLink
URI: WolframInstitute/BioDataLink/guide/Visualizations
Description: Plot aligned measurements, expression summaries, sequence composition and structural comparisons
Keywords: [biology, visualization, expression, embeddings, sequences, structures]
RelatedGuides: [BioDataLink, ComputationalExplorations, DataAccess]
RelatedTutorials: [AnalyzingSingleCellExpression, ComparingProteinConformations, ConstructingBiologicalSimilarityNetworks, ExploringBiologicalDataGeometry, ExploringSamplingAndUncertainty, FindingCircadianRhythms, ReadingBacterialGenomeComposition, UnderstandingSparseMeasurements]
---

## Abstract

Compare biological measurements with explicit identifiers, denominators,
coordinate conventions and color scales. Combine BioDataLink's specialized
plots with native Wolfram Language graphics for visual computational essays.

WL denotes a built-in Wolfram Language function; WFR denotes a Function
Repository function.

## Functions

### Cells and Expression

- `BioEmbeddingPlot` align coordinate and annotation associations by observation ID
- `BioExpressionDotPlot` compare group means and detection fractions
- `DimensionReduce` (WL) compute a low-dimensional embedding
- `MatrixPlot` (WL) display an ordered measurement matrix

### Sequence Composition

- `BioSequenceCompositionPlot` count overlapping DNA words on a chaos-game grid
- `BioSequenceSkewPlot` compare base counts in complete windows
- `BioSequencePlot` (WL) display sequence annotations

### Structures and Conformations

- `BioStructureComparisonPlot` align residue-keyed traces using a chosen region
- `BioMoleculePlot3D` (WL) render molecular ribbons, atoms and surfaces
- `DistanceMatrix` (WL) compare internal distances independently of orientation

### Rhythms, Networks and Experimental Comparisons

- `BoxWhiskerChart` (WL) compare resampling and perturbation distributions
- `Graph` (WL) display relationships with fixed coordinates across comparisons
- `ListLinePlot` (WL) compare observed trajectories and fitted models
- `ListPolarPlot` (WL) compare periodic phases and amplitudes
- [ChordDiagram (WFR)](https://resources.wolframcloud.com/FunctionRepository/resources/ChordDiagram/) draw relationships around a circle

## References

- [Wolfram Language visualization gallery](https://reference.wolfram.com/language/guide/VisualizationGallery.html)
- [Crameri et al. 2020, The misuse of colour in science communication](https://doi.org/10.1038/s41467-020-19160-7)
