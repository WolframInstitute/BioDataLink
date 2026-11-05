---
Template: TechNote
Name: ComparingProteinConformations
Title: Comparing Protein Conformations
Context: WolframInstitute`BioDataLink`
Paclet: WolframInstitute/BioDataLink
URI: WolframInstitute/BioDataLink/tutorial/ComparingProteinConformations
Keywords: [application, protein structure, PDB, adenylate kinase, conformational change, distance matrix, rigid domains, backbone angles]
RelatedGuides: [BioDataLink, ComputationalExplorations, Downloads, Sources]
---

Compare two *E. coli* adenylate kinase structures:
[4AKE](https://www.rcsb.org/structure/4AKE) (open) and
[1AKE](https://www.rcsb.org/structure/1AKE) (closed, bound to the inhibitor Ap5A).
The bundled PDB files are unmodified, compressed copies distributed under CC0.

The examples below superpose the two structures and map how Cα distances change:

![Open and closed adenylate kinase superposed by region, and the closed-minus-open distance map](../Images/ComparingProteinConformations.png "ExampleImage")

The goal is to locate structural differences and candidate bending regions.
Two crystal structures do not reveal a motion pathway or populations in solution.
Evaluate **Initialization**, then run the examples in order.

## Load and match the structures

```wl
{open, closed} = Import[FileNameJoin[{PacletObject["WolframInstitute/BioDataLink"]["AssetLocation", "Examples"], "AdenylateKinase", # <> ".pdb.gz"}], "BioMolecule"] & /@ {"4AKE", "1AKE"};
closed
```

Read the structure citations:

```wl
Dataset[KeyTake[First[BioMoleculeValue[#, "Citations"]], {"Journal", "Year", "Title"}] & /@ <|"4AKE" -> open, "1AKE" -> closed|>]
```

Use chain A in each structure and confirm identical sequences:

```wl
SameQ @@ (BioMoleculeValue[#, "BioSequences"]["A"] & /@ {open, closed})
```

Plot chain A from each structure:

```wl
GraphicsRow[BioMoleculePlot3D[BioMoleculeValue[#, "PolymerChains"]["A"]] & /@ {open, closed}, ImageSize -> Large]
```

The open structure is on the left; the closed structure folds around Ap5A.

## Compare internal distances

Extract the 214 alpha-carbon (Cα) positions in ångströms:

```wl
ca = BioMoleculeValue[#, "BackboneCoordinateValues"]["A"] & /@ {open, closed};
distances = DistanceMatrix /@ ca;
Dimensions[distances]
```

Subtract open-state distances from closed-state distances. Blue indicates
closer residue pairs; red indicates pairs farther apart.

```wl
Legended[MatrixPlot[distances[[2]] - distances[[1]],
    ColorFunction -> (ColorData["ThermometerColors"][Rescale[#, {-25, 25}]] &), ColorFunctionScaling -> False,
    PlotRange -> {-25, 25}, FrameLabel -> {"residue", "residue"}], BarLegend[{"ThermometerColors", {-25, 25}}]]
```

Nearly unchanged blocks suggest approximately rigid regions. Between some
blocks, distances shrink by about 25 Å.

## Define regions and align the core

Cluster distance-change patterns into three groups. Three is an explicit
analysis choice, not an estimated number of domains.

```wl
domains = ClusteringComponents[Abs[distances[[2]] - distances[[1]]], 3, 1, Method -> "KMeans", RandomSeeding -> 20261104];
```

List contiguous residue ranges in each group:

```wl
With[{runs = SplitBy[Range[Length[domains]], domains[[#]] &]}, Thread[(MinMax /@ runs) -> domains[[First /@ runs]]]]
```

The mobile stretches, residues 35–59 and 122–157, correspond to the NMP-binding
and LID domains described by
[Müller et al. 1996](https://doi.org/10.1016/S0969-2126%2896%2900018-4).
Label these groups and the remaining CORE:

```wl
domainName = AssociationThread[domains[[{1, 45, 140}]], {"CORE", "NMP-binding", "LID"}];
domainColor = AssociationThread[domains[[{1, 45, 140}]], {Gray, okabeIto[[1]], okabeIto[[2]]}];
```

Count residues in each region:

```wl
members = GroupBy[Range[Length[domains]], domainName[domains[[#]]] &];
Length /@ members
```

Align the open CORE to the closed CORE using a rigid rotation and translation:

```wl
aligned = Last[FindGeometricTransform[ca[[2, members["CORE"]]], ca[[1, members["CORE"]]], TransformationClass -> "Rigid", Method -> "Linear"]] /@ ca[[1]];
```

Plot displacements after alignment:

```wl
ListPlot[byDomain[Range[Length[domains]], Norm /@ (aligned - ca[[2]])], Filling -> Axis, PlotStyle -> Values[domainColor],
    PlotLegends -> Values[domainName], Frame -> True, FrameLabel -> {"residue", "C\[Alpha] displacement (\[Angstrom])"}]
```

Aligned displacements reach about 24 Å in the LID, 18 Å in the NMP-binding
domain and 6 Å near CORE boundaries. These are differences between structures,
not distances traveled by atoms.

Show both chains; the open chain is translucent and Ap5A is black:

```wl
With[{colors = domainColor /@ domains, inhibitor = Flatten[BioMoleculeValue[closed, "AtomCoordinateValues"]["C"], 1]},
    Graphics3D[{Opacity[0.25], Tube[aligned, 0.6, VertexColors -> colors], Opacity[1], Tube[ca[[2]], 0.6, VertexColors -> colors],
        Black, Sphere[inhibitor, 0.5]}, Boxed -> False, Lighting -> "Neutral"]]
```

Fit each region separately and compute its root mean square deviation (RMSD):

```wl
fitRMSD[ca[[1, #]], ca[[2, #]]] & /@ members
```

The LID fits to about 0.4 Å, CORE to 2.3 Å and NMP-binding domain to 2.1 Å.
The latter two change internally as well as moving relative to the LID.

## Locate bending regions and ligand contacts

Compare backbone angles φ and ψ using the shorter circular difference.
Exclude the two terminal residues, which each lack one angle:

```wl
With[{angles = QuantityMagnitude[BioMoleculeValue[#, "RamachandranAngles"]["A"]][[2 ;; -2]] & /@ {open, closed}},
    ListPlot[byDomain[Range[2, Length[domains] - 1], Max /@ Abs[Mod[angles[[2]] - angles[[1]] + 180, 360] - 180]], Filling -> Axis,
        PlotRange -> All, PlotStyle -> Values[domainColor], PlotLegends -> Values[domainName], Frame -> True, FrameLabel -> {"residue", "largest change in \[Phi] or \[Psi] (degrees)"}]]
```

Eight residues change by more than 60°: 41, 42, 45, 46, 128, 129, 159 and 160.
These are candidate bending regions, not uniquely established hinges.

Count residues with any atom within 4 Å of Ap5A:

```wl
contactResidues = With[{atoms = BioMoleculeValue[closed, "AtomCoordinateValues"]["A"],
        toInhibitor = Nearest[Flatten[BioMoleculeValue[closed, "AtomCoordinateValues"]["C"], 1] -> "Distance"]},
    Select[Range[Length[atoms]], Min[toInhibitor[atoms[[#]]]] < 4 &]];
Counts[domainName /@ domains[[contactResidues]]]
```

The closed structure has contacts from 22 CORE residues and six from each
mobile domain. Contacts describe this structure, not binding occupancy in solution.

Crystal packing, chain choice and clustering can affect the comparison.
Other chains, structures or solution measurements are needed to test the
motion interpretation.

## Distinguish an alignment effect from an internal change

Rotate and translate the open structure without changing any internal
coordinates. Raw coordinate displacements become large; internal distances
remain unchanged. This is a negative control for the comparison method.

```wl
reoriented = ({40, -20, 15} + RotationTransform[Pi/3, {1, 1, 0}][#]) & /@ ca[[1]];
GraphicsRow[{
    ListLinePlot[Norm /@ (reoriented - ca[[1]]), Frame -> True, FrameLabel -> {"residue", "raw displacement (Å)"}],
    ListLinePlot[Max /@ Abs[DistanceMatrix[reoriented] - distances[[1]]], Frame -> True,
        FrameLabel -> {"residue", "largest internal-distance difference (Å)"}, PlotRange -> All]}]
```

The second panel should contain only floating-point roundoff. A change of
orientation is not a conformational change.

## Move the alignment reference and inspect the consequences

Fit the closed trace to the open trace using all residues, CORE only, or LID
only. Residue IDs preserve correspondence even if an input association is
reordered. Colors always represent the same regions.

```wl
residueIDs = Range[Length[First[ca]]];
openTrace = AssociationThread[residueIDs, ca[[1]]];
closedTrace = AssociationThread[residueIDs, ca[[2]]];
regionLabels = AssociationThread[residueIDs, domainName /@ domains];
regionColors = AssociationThread[Values[domainName], Values[domainColor]];
alignmentSets = <|"all residues" -> residueIDs, "CORE" -> members["CORE"], "LID" -> members["LID"]|>;
GraphicsRow[KeyValueMap[BioStructureComparisonPlot[openTrace, closedTrace, regionLabels,
    "AlignmentResidues" -> #2, "CategoryColors" -> regionColors, PlotLegends -> None,
    PlotLabel -> #1, ViewPoint -> {0.4, -2.6, 1.6}] &, alignmentSets], ImageSize -> Large]
```

The open reference is translucent; the aligned closed trace is solid. A region
used for alignment tends to look more stationary. No choice establishes a
physically fixed frame in solution.

Quantify each fit with the same per-residue displacement measure:

```wl
alignmentDisplacements = Map[Function[indices, With[{fit = Last[FindGeometricTransform[ca[[1, indices]], ca[[2, indices]], TransformationClass -> "Rigid", Method -> "Linear"]]},
    Norm /@ (fit /@ ca[[2]] - ca[[1]])]], alignmentSets];
ListLinePlot[Values[alignmentDisplacements], PlotLegends -> Keys[alignmentDisplacements],
    Frame -> True, FrameLabel -> {"residue", "aligned displacement (Å)"}, PlotRange -> All]
```

A statement about displacement should identify the alignment region. The
internal-distance map above supplies a complementary result independent of
that choice.

## Summarize changes within and between regions

Group all unordered residue pairs by their region labels. Each pair contributes
one closed-minus-open distance; self-pairs and duplicate pairs are excluded.

```wl
residuePairs = Subsets[residueIDs, {2}];
pairChanges = KeySort[GroupBy[residuePairs,
    (StringRiffle[Sort[domainName /@ domains[[#]]], " / "] &) ->
        (Extract[distances[[2]] - distances[[1]], #] &)]];
BoxWhiskerChart[Values[pairChanges], ChartLabels -> Placed[Keys[pairChanges], Below], PlotRange -> All,
    FrameLabel -> {"region pair", "closed minus open distance (Å)"}, ImageSize -> Large]
```

Narrow within-region distributions support approximate rigidity at this
resolution. Pair counts share residues and are not independent observations;
the boxes describe distributions, not biological confidence intervals.

## Test the requested number of regions

Recompute distance-pattern clustering with two through five groups. Keep the
CORE alignment from the three-group analysis fixed, so only the partition
changes between panels.

```wl
GraphicsRow[Table[With[{labels = ToString /@ ClusteringComponents[Abs[distances[[2]] - distances[[1]]], k, 1,
        Method -> "KMeans", RandomSeeding -> 20261104]},
    BioStructureComparisonPlot[openTrace, closedTrace, AssociationThread[residueIDs, labels],
        "AlignmentResidues" -> members["CORE"], PlotLegends -> None, PlotLabel -> Row[{k, " groups"}]]],
    {k, 2, 5}], ImageSize -> Large]
```

A visually plausible partition is not a domain definition. Compare persistent
boundaries with independent annotations rather than selecting the most
attractive color arrangement.

## Separate local backbone changes from domain displacement

Plot the observed φ/ψ angle pairs in both structures. Angles wrap at ±180°;
the circular-difference calculation above avoids a spurious jump at that edge.

```wl
backboneAngles = QuantityMagnitude[BioMoleculeValue[#, "RamachandranAngles"]["A"]][[2 ;; -2]] & /@ {open, closed};
ListPlot[backboneAngles, PlotRange -> {{-180, 180}, {-180, 180}}, AspectRatio -> 1,
    Frame -> True, FrameLabel -> {"φ (degrees)", "ψ (degrees)"}, PlotLegends -> {"open", "closed"}]
```

Large rigid-body displacements can coexist with small local angle changes.
Neither angle difference nor displacement alone identifies a causal hinge.

## Change the contact threshold

A contact list depends on the chosen distance cutoff. Hold the coordinates
fixed and vary the cutoff from 3 to 6 Å for distances to Ap5A:

```wl
ligandDistances = With[{atoms = BioMoleculeValue[closed, "AtomCoordinateValues"]["A"],
    nearest = Nearest[Flatten[BioMoleculeValue[closed, "AtomCoordinateValues"]["C"], 1] -> "Distance"]},
    Min[nearest[#]] & /@ atoms];
contactCutoffs = Range[3, 6, 1/4];
ListLinePlot[Table[Transpose[{contactCutoffs, Table[Count[ligandDistances[[indices]], d_ /; d < cutoff], {cutoff, contactCutoffs}]}],
    {indices, Values[members]}], PlotLegends -> Keys[members], Frame -> True,
    FrameLabel -> {"distance cutoff (Å)", "residues near Ap5A"}]
```

This measures threshold sensitivity of a geometric contact definition.
It does not estimate binding strength, occupancy, or an energetic contribution.

Compare an eight-ångström Cα neighborhood in each conformation. Blue entries
are contacts lost on closing; orange entries are contacts gained:

```wl
With[{change = Map[Boole[# < 8] &, distances[[2]], {2}] - Map[Boole[# < 8] &, distances[[1]], {2}]},
    MatrixPlot[change, ColorRules -> {-1 -> Blue, 0 -> White, 1 -> Orange},
        FrameLabel -> {"residue", "residue"}, PlotLegends -> SwatchLegend[{Blue, White, Orange}, {"lost", "unchanged", "gained"}]]]
```

This is a different neighborhood definition from all-atom ligand contacts.
Keep the atom selection and cutoff attached to each result.

## Retain the evidence and its limits

```wl
<|"Structures" -> {"4AKE", "1AKE"}, "Chain" -> "A", "CoordinateUnits" -> "ångströms",
    "MatchedResidues" -> Length[residueIDs], "AlignmentChoices" -> Keys[alignmentSets],
    "RegionCountExperiment" -> Range[2, 5], "LigandCutoffsAngstrom" -> contactCutoffs,
    "IndependentConformations" -> 2|>
```

The comparisons establish differences between two deposited structures and
show which summaries depend on alignment, clustering or distance thresholds.
They do not supply a transition pathway, kinetics or an equilibrium ensemble.

## Initialization

Okabe-Ito colors and helpers for regional plots and rigid-fit RMSD:

```wl
okabeIto = RGBColor /@ {"#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2", "#D55E00", "#CC79A7", "#000000"};
```

```wl
byDomain[residues_, values_] := Lookup[GroupBy[Transpose[{residues, values}], domainName[domains[[First[#]]]] &], Values[domainName]];
fitRMSD[a_, b_] := With[{fit = Last[FindGeometricTransform[b, a, TransformationClass -> "Rigid", Method -> "Linear"]]}, RootMeanSquare[Norm /@ (fit /@ a - b)]];
```
