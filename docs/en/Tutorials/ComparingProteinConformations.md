---
Template: TechNote
Name: ComparingProteinConformations
Title: Comparing Protein Conformations
Context: WolframInstitute`BioDataLink`
Paclet: WolframInstitute/BioDataLink
URI: WolframInstitute/BioDataLink/tutorial/ComparingProteinConformations
Keywords: [application, protein structure, PDB, adenylate kinase, conformational change, distance matrix, rigid domains, Ramachandran plot]
RelatedGuides: [BioDataLink, ComputationalExplorations, Downloads, Sources]
---

How does an enzyme change shape when it binds its substrates? Adenylate kinase
converts ATP and AMP into two ADP molecules, keeping the cell's energy balance.
Its crystal structures have been solved both without ligands and bound to Ap5A,
an inhibitor that mimics ATP and AMP together. Comparing the two structures
locates large coordinate differences, approximately rigid regions and
candidate hinge regions.

The structures are *Escherichia coli* adenylate kinase entries
[4AKE](https://www.rcsb.org/structure/4AKE) (open, no ligand) and
[1AKE](https://www.rcsb.org/structure/1AKE) (closed, with Ap5A) from the
Protein Data Bank, distributed under CC0. BioDataLink bundles the unmodified
files, compressed. Two snapshots from crystals show end states; they do not
show the path between them or how often each state occurs in solution.

Evaluate the Initialization section at the end before running the examples.

## Load the two structures

Build a resolver link for an entry from the bundled source directory; this
runs offline:

```wl
BioDataURL[{"pdb", "4AKE"}]
```

The bundled files were retrieved from the PDB with `BioDatasetDownload` and
checked against recorded SHA-256 hashes. This online input repeats the step
for the closed structure; it is not run when the documentation is built:

```wl
#| eval: false
BioDatasetDownload["https://files.rcsb.org/download/1AKE.pdb", File[FileNameJoin[{CreateDirectory[], "1AKE.pdb"}]],
    "ExpectedSHA256" -> "651e952f55f1317f50f4e82b7f0e99053397032cd8da5b2896f79d0af9f619a9"]
```

Import both bundled files as `BioMolecule` objects:

```wl
{open, closed} = Import[FileNameJoin[{PacletObject["WolframInstitute/BioDataLink"]["AssetLocation", "Examples"], "AdenylateKinase", # <> ".pdb.gz"}], "BioMolecule"] & /@ {"4AKE", "1AKE"};
closed
```

Each file reports the publication that describes it:

```wl
Dataset[KeyTake[First[BioMoleculeValue[#, "Citations"]], {"Journal", "Year", "Title"}] & /@ <|"4AKE" -> open, "1AKE" -> closed|>]
```

A crystal can hold several copies of a protein. Both files contain two protein
chains, A and B; the closed structure also holds one Ap5A molecule per chain
and water:

```wl
BioMoleculeValue[closed, "ChainTypes"]
```

Use chain A of each structure. The selected chains have identical sequences, which makes residue-wise
comparison possible. Coordinate differences can reflect conformation, crystal
packing and measurement uncertainty:

```wl
SameQ @@ (BioMoleculeValue[#, "BioSequences"]["A"] & /@ {open, closed})
```

```wl
GraphicsRow[BioMoleculePlot3D[BioMoleculeValue[#, "PolymerChains"]["A"]] & /@ {open, closed}, ImageSize -> Large]
```

The open enzyme (left) spreads its domains apart; the closed enzyme (right)
folds them around the inhibitor.

## Compare residue distances

Each residue's alpha carbon (Cα) traces the backbone. Take the 214 Cα positions
of chain A in each structure, in ångströms:

```wl
ca = BioMoleculeValue[#, "BackboneCoordinateValues"]["A"] & /@ {open, closed};
distances = DistanceMatrix /@ ca;
Dimensions[distances]
```

Two residues are in contact when their Cα atoms are within 8 Å. Overlay the
contact maps of both structures:

```wl
With[{contacts = UnitStep[8 - #] & /@ distances},
    ArrayPlot[contacts[[1]] + 2 contacts[[2]], ColorRules -> {0 -> White, 1 -> okabeIto[[6]], 2 -> okabeIto[[5]], 3 -> Gray},
        PlotLegends -> SwatchLegend[{okabeIto[[6]], okabeIto[[5]], Gray}, {"open only", "closed only", "both"}], FrameTicks -> Automatic, FrameLabel -> {"residue", "residue"}]]
```

Most contacts are shared. Helices form the thick band along the diagonal and
β-strands pair into short lines off it. The contacts that appear only in the
closed structure lie far from the diagonal, between parts of the chain that
are distant in sequence.

Subtract the open distances from the closed distances. Blue pairs come closer
when the enzyme closes and red pairs move apart; the scale is symmetric around
zero:

```wl
Legended[MatrixPlot[distances[[2]] - distances[[1]],
    ColorFunction -> (ColorData["ThermometerColors"][Rescale[#, {-25, 25}]] &), ColorFunctionScaling -> False,
    PlotRange -> {-25, 25}, FrameLabel -> {"residue", "residue"}], BarLegend[{"ThermometerColors", {-25, 25}}]]
```

The map is built from blocks. Inside a block, distances barely change: that pattern is
consistent with approximately rigid motion. Between blocks, distances shrink by up
to about 25 Å.

## Find the rigid domains from the motion

Residues that move together can have similar patterns of distance changes
to the rest of the chain. Cluster these patterns into three groups, fixing
the seed. Choosing three groups is an analysis assumption, not a result of
estimating how many domains the protein has:

```wl
domains = ClusteringComponents[Abs[distances[[2]] - distances[[1]]], 3, 1, Method -> "KMeans", RandomSeeding -> 20261104];
```

List the contiguous stretches of sequence in each group:

```wl
With[{runs = SplitBy[Range[Length[domains]], domains[[#]] &]}, Thread[(MinMax /@ runs) -> domains[[First /@ runs]]]]
```

Two compact stretches move, residues 35 to 59 and 122 to 157, while the rest of
the chain forms one group. These are the two mobile domains described for this
enzyme: the NMP-binding domain, which closes over AMP, and the LID, which
closes over ATP ([Müller et al. 1996](https://doi.org/10.1016/S0969-2126%2896%2900018-4)).
The rest is the CORE. Name each group by a residue it contains, and give each a
color:

```wl
domainName = AssociationThread[domains[[{1, 45, 140}]], {"CORE", "NMP-binding", "LID"}];
domainColor = AssociationThread[domains[[{1, 45, 140}]], {Gray, okabeIto[[1]], okabeIto[[2]]}];
```

## Superimpose the core and measure the motion

Collect the residues of each domain:

```wl
members = GroupBy[Range[Length[domains]], domainName[domains[[#]]] &];
Length /@ members
```

Find the rotation and translation that best map the open CORE onto the closed
CORE, and apply it to the whole open chain:

```wl
aligned = Last[FindGeometricTransform[ca[[2, members["CORE"]]], ca[[1, members["CORE"]]], TransformationClass -> "Rigid"]] /@ ca[[1]];
```

The displacement after this fit measures the difference between corresponding
residue positions in the two structures. It is not the distance traveled
along a molecular trajectory:

```wl
ListPlot[byDomain[Range[Length[domains]], Norm /@ (aligned - ca[[2]])], Filling -> Axis, PlotStyle -> Values[domainColor],
    PlotLegends -> Values[domainName], Frame -> True, FrameLabel -> {"residue", "C\[Alpha] displacement (\[Angstrom])"}]
```

The LID has the largest aligned displacements: residues 148 to 150 differ
by about 24 Å. The NMP-binding
domain moves up to about 18 Å, and the CORE moves at most about 6 Å, at its
boundaries with the two domains. Draw both chains in the frame of the closed
structure, with the open chain faint and the inhibitor as black spheres:

```wl
With[{colors = domainColor /@ domains, inhibitor = Flatten[BioMoleculeValue[closed, "AtomCoordinateValues"]["C"], 1]},
    Graphics3D[{Opacity[0.25], Tube[aligned, 0.6, VertexColors -> colors], Opacity[1], Tube[ca[[2]], 0.6, VertexColors -> colors],
        Black, Sphere[inhibitor, 0.5]}, Boxed -> False, Lighting -> "Neutral"]]
```

Rotate the graphic to see the LID and the NMP-binding domain folding over the
inhibitor from two sides.

How rigid is each domain on its own? Fit each domain separately and measure the
root mean square deviation (RMSD) of its Cα positions, in ångströms:

```wl
fitRMSD[ca[[1, #]], ca[[2, #]]] & /@ members
```

The LID moves as an almost perfect rigid body, fitting to about 0.4 Å. The CORE
fits to about 2.3 Å, mostly because of residues next to the moving domains.
The NMP-binding domain fits to about 2.1 Å: it also changes shape inside as it
closes.

## Locate the hinges

The backbone bends through its dihedral angles φ (phi) and ψ (psi), which set
how each residue's backbone rotates. A Ramachandran plot shows these angles
for every residue of the closed structure, colored by secondary structure:

```wl
With[{angles = QuantityMagnitude[BioMoleculeValue[closed, "RamachandranAngles"]["A"]],
        helix = Flatten[Range @@@ BioMoleculeValue[closed, "Helices"]["A"]], strand = Flatten[Range @@@ BioMoleculeValue[closed, "Sheets"]["A"]]},
    ListPlot[{angles[[helix]], angles[[strand]], angles[[Complement[Range[Length[angles]], helix, strand]]]},
        PlotStyle -> okabeIto[[{6, 5, 8}]], PlotLegends -> {"helix", "strand", "other"}, PlotRange -> {{-180, 180}, {-180, 180}},
        AspectRatio -> 1, Frame -> True, FrameLabel -> {"\[Phi] (degrees)", "\[Psi] (degrees)"}]]
```

Helices cluster near φ = −60°, ψ = −45° and strands in the upper left, as the
geometry of the peptide chain requires. Now compare each residue's angles
between the two structures. Angles wrap around at ±180°, so take the shorter
way around the circle; the two end residues each lack one angle and are left
out:

```wl
With[{angles = QuantityMagnitude[BioMoleculeValue[#, "RamachandranAngles"]["A"]][[2 ;; -2]] & /@ {open, closed}},
    ListPlot[byDomain[Range[2, Length[domains] - 1], Max /@ Abs[Mod[angles[[2]] - angles[[1]] + 180, 360] - 180]], Filling -> Axis,
        PlotRange -> All, PlotStyle -> Values[domainColor], PlotLegends -> Values[domainName], Frame -> True, FrameLabel -> {"residue", "largest change in \[Phi] or \[Psi] (degrees)"}]]
```

Most residues keep their angles within a few tens of degrees, even in the
domains that travel 20 Å. Only eight residues change by more than 60°: residues
41, 42, 45 and 46 inside the NMP-binding domain, 128 and 129 near the start of the LID,
and 159 and 160 just after it. These changes mark candidate bending regions; two end states do not uniquely
assign the motion to hinges or determine its path.

## Find what the inhibitor touches

List the residues with any atom within 4 Å of the inhibitor, then count them by
domain:

```wl
contactResidues = With[{atoms = BioMoleculeValue[closed, "AtomCoordinateValues"]["A"],
        toInhibitor = Nearest[Flatten[BioMoleculeValue[closed, "AtomCoordinateValues"]["C"], 1] -> "Distance"]},
    Select[Range[Length[atoms]], Min[toInhibitor[atoms[[#]]]] < 4 &]];
Counts[domainName /@ domains[[contactResidues]]]
```

Twenty-two CORE residues touch the inhibitor, including the phosphate-binding
loop at residues 9 to 15, which wraps its phosphate chain. Six residues each
from the NMP-binding domain and the LID also reach it, in this closed structure. The contacts locate the bound inhibitor; they do
not establish a unique binding pathway or a contact occupancy in solution.

## What the comparison shows

Two static structures support a three-group partition of distance-change
patterns, aligned displacements and candidate hinge regions without supplying
residue boundaries in advance. This partition is descriptive; approximate
rigidity and a chosen cluster count do not prove independently moving domains.
The ranges found here come from chain A and one clustering; the B chains in the
same files offer a check against crystal-packing effects.

Crystal structures are averages over many molecules held in a lattice. Motion
between the end states, intermediate states and their populations in solution
need other evidence, such as spectroscopy, more structures or simulations.

## Initialization

The categorical colors are the Okabe-Ito palette, which remains distinguishable
with common color-vision deficiencies.

```wl
okabeIto = RGBColor /@ {"#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2", "#D55E00", "#CC79A7", "#000000"};
```

`byDomain` splits per-residue values into one series per domain, so plots can
color them with `domainColor`. `fitRMSD` superimposes the points `a` on `b`
and returns the remaining RMSD:

```wl
byDomain[residues_, values_] := Lookup[GroupBy[Transpose[{residues, values}], domainName[domains[[First[#]]]] &], Values[domainName]];
fitRMSD[a_, b_] := With[{fit = Last[FindGeometricTransform[b, a, TransformationClass -> "Rigid"]]}, RootMeanSquare[Norm /@ (fit /@ a - b)]];
```
