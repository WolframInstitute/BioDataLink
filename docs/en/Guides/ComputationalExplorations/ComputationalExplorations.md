---
Template: Guide
Name: ComputationalExplorations
Title: Computational Explorations of Biological Data
Context: WolframInstitute`BioDataLink`
Paclet: WolframInstitute/BioDataLink
URI: WolframInstitute/BioDataLink/guide/ComputationalExplorations
Description: Compare measurements, representations and simple computational hypotheses with explicit evidence
Keywords: [biology, computation, visualization, geometry, rules, observation models]
RelatedGuides: [BioDataLink, DataAccess, Downloads]
RelatedTutorials: [ConstructingBiologicalSimilarityNetworks, DiscretizingBiologicalMeasurements, ExploringBiologicalDataGeometry, ExploringCellularAutomatonHypotheses, ExploringSimplePredictiveRules, UnderstandingSparseMeasurements]
---

## Abstract

A useful analysis begins with an observation: which organism or sample was
measured, what each row represents, which variables were recorded and which
values are missing. The tutorials connect those questions to computed figures
and small, explicit experiments in Wolfram Language.

Actual UCI Iris measurements support examples of geometry, discretization,
networks and static prediction. Clearly labeled synthetic measurements support
examples of sparse data and observation models. Changing a scale, threshold,
seed or measurement mask reveals which conclusions depend on that choice.

The rule-based explorations draw on ideas from Ruliology and Ruliobiology:
enumerate a defined family, compare alternatives and limit conclusions to the
observations available. They use built-in Wolfram Language and require neither
sibling paclet. A fit to a finite observation does not identify a unique
biological mechanism. Static rows do not establish a trajectory.

WL marks a built-in Wolfram Language function.

## Functions

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

## References

- [Ruliobiology finite cellular automata](https://www.wolframcloud.com/obj/wolframinstitute/DeployedResources/Paclet/WolframInstitute/Ruliobiology/Documentation/ref/FiniteCellularAutomaton.html)
- [Ruliology rule-space tutorial](https://www.wolframcloud.com/obj/wolframinstitute/DeployedResources/Paclet/WolframInstitute/Ruliology/Documentation/tutorial/AnalyzingCellularAutomatonRuleSpace.html)
- [UCI Iris dataset](https://archive.ics.uci.edu/dataset/53/iris)
