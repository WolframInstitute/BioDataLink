---
Template: Guide
Name: ComputationalExplorations
Title: Computational Explorations of Biological Data
Context: WolframInstitute`BioDataLink`
Paclet: WolframInstitute/BioDataLink
URI: WolframInstitute/BioDataLink/guide/ComputationalExplorations
Description: Compare measurements, representations and simple computational hypotheses with explicit evidence
Keywords: [biology, computation, visualization, single cell, protein structure, genomes, time series, geometry, rules, observation models]
RelatedGuides: [BioDataLink, DataAccess, Downloads]
RelatedTutorials: [AnalyzingSingleCellExpression, ChoosingMeasurementsToDistinguishModels, ComparingCoronavirusGenomes, ComparingProteinConformations, ConstructingBiologicalSimilarityNetworks, DiscretizingBiologicalMeasurements, ExploringBiologicalDataGeometry, ExploringCellularAutomatonHypotheses, ExploringSimplePredictiveRules, FindingCircadianRhythms, ReadingBacterialGenomeComposition, UnderstandingSparseMeasurements]
---

## Abstract

A useful analysis begins with an observation: which organism or sample was
measured, what each row represents, which variables were recorded and which
values are missing. The tutorials connect those questions to computed figures
and small, explicit experiments in Wolfram Language.

Five case studies analyze real public data bundled with BioDataLink. Which cell
groups have distinct marker patterns? Follow
[single-cell expression](paclet:WolframInstitute/BioDataLink/tutorial/AnalyzingSingleCellExpression)
from raw counts to provisional cell annotations. How do two structures of an
enzyme differ? Align
[protein conformations](paclet:WolframInstitute/BioDataLink/tutorial/ComparingProteinConformations)
and compare regional displacements. Which compositional patterns are consistent
with replication-associated asymmetry? Examine a
[bacterial genome](paclet:WolframInstitute/BioDataLink/tutorial/ReadingBacterialGenomeComposition).
How do related viral sequences differ? Compare
[coronavirus genomes](paclet:WolframInstitute/BioDataLink/tutorial/ComparingCoronavirusGenomes)
using exact shared words and genome composition. Which transcripts show approximately daily
variation? Explore
[circadian rhythms](paclet:WolframInstitute/BioDataLink/tutorial/FindingCircadianRhythms)
in an hourly liver time series.

Actual UCI Iris measurements support examples of geometry, discretization,
networks and static prediction. Clearly labeled synthetic measurements support
examples of sparse data and observation models. Changing a scale, threshold,
seed or measurement mask reveals which conclusions depend on that choice.

The rule-based explorations draw on ideas from Ruliology and Ruliobiology:
enumerate a defined family, compare alternatives and limit conclusions to the
observations available. They use built-in Wolfram Language and require neither
sibling paclet. A fit to a finite observation does not identify a unique
biological mechanism. Static rows do not establish a trajectory.

Which patterns survive preprocessing? Compare
[measurement geometry](paclet:WolframInstitute/BioDataLink/tutorial/ExploringBiologicalDataGeometry),
[finite-state encodings](paclet:WolframInstitute/BioDataLink/tutorial/DiscretizingBiologicalMeasurements)
and [sparse measurement semantics](paclet:WolframInstitute/BioDataLink/tutorial/UnderstandingSparseMeasurements).
Which similarities survive perturbation? Examine
[biological similarity networks](paclet:WolframInstitute/BioDataLink/tutorial/ConstructingBiologicalSimilarityNetworks).

Which models give the same observable predictions? Explore
[cellular-automaton hypotheses](paclet:WolframInstitute/BioDataLink/tutorial/ExploringCellularAutomatonHypotheses).
Which additional measurement separates them? Use
[measurement-panel selection](paclet:WolframInstitute/BioDataLink/tutorial/ChoosingMeasurementsToDistinguishModels),
where native Wolfram Language graphs keep every candidate in a fixed position
as panels and assumed error bounds change.

A recommended progression starts with data and provenance, then geometry,
sparse data and thresholds. Move to
[predictive rules](paclet:WolframInstitute/BioDataLink/tutorial/ExploringSimplePredictiveRules)
from constants through a single comparison to AND/OR combinations. Next examine
similarity neighborhoods, then cellular-automaton rule spaces, and finally
measurement choice from single observables to panels and noise sensitivity.
Complexity means a stated number of comparisons, neighborhood sites or states;
a larger rule number does not itself mean a more complex rule or biology.

WL marks a built-in Wolfram Language function.

## Functions

### Analyze Real Biological Data

- `BioDatasetLoad` read the bundled single-cell count matrix with its gene selection and provenance
- `BioMoleculeValue` (WL) extract chains, coordinates and backbone angles from a protein structure
- `DimensionReduce` (WL) place cells on a two-dimensional map that keeps their neighbors close
- `FindGeometricTransform` (WL) superimpose two structures on their rigid core
- `FindGraphCommunities` (WL) group cells by communities of a neighborhood graph
- `Fourier` (WL) split time series into periodic components
- `LeastSquares` (WL) fit a rhythm to every time series at once

### Keep the Measurements and Their Meaning Together

- `BioDatasetDownload` retrieve a chosen file with optional size and content checks
- `BioDatasetLoad` read a supported local matrix with aligned metadata
- `Dataset` (WL) inspect source annotations and select records explicitly
- `SparseArray` (WL) preserve numerical zero entries implicitly

### Explore Geometry and Representation

- `ClusteringComponents` (WL) assign clusters with an explicit method, distance and seed
- `EuclideanDistance` (WL) compare numerical feature vectors in a stated scale
- `PrincipalComponents` (WL) inspect a linear projection and its retained variance
- `Quantile` (WL) define rank-based bins while recording ties and cutoffs

### Compare Finite Computational Hypotheses

- `ArrayPlot` (WL) inspect finite states or simulation observations
- `CellularAutomaton` (WL) generate states from an explicitly specified update rule
- `Graph` (WL) represent a chosen relation without implying a causal interaction
- `Outer` (WL) enumerate a defined collection of comparisons
- `Subsets` (WL) compare every measurement panel in a small finite family
- `VertexCoordinates` (WL) hold model positions fixed while graph relationships change

## References

- [10x Genomics 3k PBMCs from a Healthy Donor](https://www.10xgenomics.com/datasets/3-k-pbm-cs-from-a-healthy-donor-1-standard-1-1-0)
- [GEO series GSE11923, mouse liver time series](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE11923)
- [NCBI RefSeq NC_001318.1, *Borrelia burgdorferi* B31 chromosome](https://www.ncbi.nlm.nih.gov/nuccore/NC_001318.1)
- [NCBI RefSeq NC_045512.2, SARS-CoV-2 Wuhan-Hu-1](https://www.ncbi.nlm.nih.gov/nuccore/NC_045512.2)
- [Protein Data Bank entry 1AKE](https://www.rcsb.org/structure/1AKE)
- [Protein Data Bank entry 4AKE](https://www.rcsb.org/structure/4AKE)
- [Ruliobiology finite cellular automata](https://www.wolframcloud.com/obj/wolframinstitute/DeployedResources/Paclet/WolframInstitute/Ruliobiology/Documentation/ref/FiniteCellularAutomaton.html)
- [Ruliology rule-space tutorial](https://www.wolframcloud.com/obj/wolframinstitute/DeployedResources/Paclet/WolframInstitute/Ruliology/Documentation/tutorial/AnalyzingCellularAutomatonRuleSpace.html)
- [UCI Iris dataset](https://archive.ics.uci.edu/dataset/53/iris)
