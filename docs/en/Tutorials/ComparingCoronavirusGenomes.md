---
Template: TechNote
Name: ComparingCoronavirusGenomes
Title: Comparing Coronavirus Genomes
Context: WolframInstitute`BioDataLink`
Paclet: WolframInstitute/BioDataLink
URI: WolframInstitute/BioDataLink/tutorial/ComparingCoronavirusGenomes
Keywords: [application, virus, SARS-CoV-2, RaTG13, SARS-CoV, genome comparison, dot plot, shared words, dinucleotide composition]
RelatedGuides: [BioDataLink, ComputationalExplorations, Downloads, Sources]
---

How similar are three related virus genomes, and how does that similarity
vary along each sequence? This tutorial compares three published coronavirus
records through genome organization, exact shared words and dinucleotide
composition. These descriptive measurements do not establish infectivity,
host range or the effects of particular sequence differences.

BioDataLink bundles three NCBI records with their gene annotations:
SARS-CoV-2 isolate Wuhan-Hu-1, NC_045512.2 ([Wu et al. 2020](https://doi.org/10.1038/s41586-020-2008-3));
bat coronavirus RaTG13, MN996532.2 ([Zhou et al. 2020](https://doi.org/10.1038/s41586-020-2012-7));
and SARS coronavirus Tor2, NC_004718.3 ([Marra et al. 2003](https://doi.org/10.1126/science.1085953)).
Three genomes illustrate the methods; they are not a sample of the diversity of
these viruses.

Evaluate the Initialization section at the end before running the examples.

## Load the genomes and their genes

Resolver links for the accessions are built offline:

```wl
BioDataURL[{"refseq", "NC_045512.2"}]
```

The bundled files were retrieved with `BioDatasetDownload` and checked against
recorded SHA-256 hashes. This online input repeats the step for the SARS-CoV-2
sequence; it is not run when the documentation is built:

```wl
#| eval: false
BioDatasetDownload["https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=NC_045512.2&rettype=fasta&retmode=text",
    File[FileNameJoin[{CreateDirectory[], "NC_045512.2.fasta"}]],
    "ExpectedSHA256" -> "0891c00cc2d503f58e0c600ce5ee64e9c64b939525c70d5486bc46cbc7cb073e"]
```

Name the three records and read each sequence:

```wl
accessions = <|"SARS-CoV-2" -> "NC_045512.2", "RaTG13" -> "MN996532.2", "SARS-CoV" -> "NC_004718.3"|>;
genomes = First[Import[example[# <> ".fasta.gz"], "Sequence"]] & /@ accessions;
StringLength /@ genomes
```

All three are RNA genomes of about 30,000 bases, written here as DNA letters.
Read the gene coordinates from each annotation file:

```wl
genes = readGenes[example[# <> ".gff3.gz"]] & /@ accessions;
genes["SARS-CoV-2"]
```

Draw the SARS-CoV-2 genome map, one gene per row:

```wl
genomeMap[genes["SARS-CoV-2"]]
```

Two thirds of the genome encode `ORF1ab`, the replication machinery. The spike
protein `S`, which binds the host cell receptor, comes next, followed by the
envelope `E`, membrane `M` and nucleocapsid `N` proteins and several small
accessory genes.

## Compare whole genomes with dot plots

A dot plot marks every pair of positions where two sequences share the same
12-letter word. Matching regions form diagonal lines:

```wl
GraphicsRow[Table[ListPlot[kmerMatches[genomes["SARS-CoV-2"], genomes[other], 12], PlotStyle -> PointSize[Tiny], AspectRatio -> 1,
    Frame -> True, FrameLabel -> {"SARS-CoV-2 position", other <> " position"}], {other, {"RaTG13", "SARS-CoV"}}], ImageSize -> Large]
```

Both plots show a dominant diagonal, consistent with broadly conserved genome
organization. Exact-word matches alone cannot rule out every rearrangement.
The diagonal against SARS-CoV is
thinner and dotted, because mutations break many of the shared words.

Measure the same idea along the genome: the fraction of 12-letter words in each
complete, nonoverlapping 300-base window of SARS-CoV-2 that also occur anywhere
in the other genome. The last partial window is omitted and points use the
actual window centers. A
word survives only if 12 consecutive bases match, so this fraction falls faster
than percent identity:

```wl
ListLinePlot[Table[sharedWords[genomes["SARS-CoV-2"], genomes[other], 12, 300], {other, {"RaTG13", "SARS-CoV"}}],
    PlotRange -> {0, 1}, PlotLegends -> {"RaTG13", "SARS-CoV"},
    Frame -> True, FrameLabel -> {"SARS-CoV-2 position", "shared 12-letter words"}]
```

Shared-word fractions vary along each genome. RaTG13 generally shares more
words with this SARS-CoV-2 record than SARS-CoV does. A low value identifies
a region with fewer exact matches under this word length; it does not measure
a functional effect. Changing the word length or window size changes the
sensitivity and spatial resolution of this comparison.

## Compare dinucleotide composition

A dinucleotide's relative abundance divides its observed frequency by the
product of its two base frequencies
([Karlin and Burge 1995](https://doi.org/10.1016/s0168-9525%2800%2989076-9)).
Values below 1 mean the pair is underrepresented relative to those base
frequencies; this descriptive statistic does not identify a cause. Compare all 16 pairs on a logarithmic
scale, so that avoidance appears blue and excess red:

```wl
With[{pairs = StringJoin /@ Tuples[{"A", "C", "G", "T"}, 2]},
    Legended[MatrixPlot[Log2[Outer[relativeAbundance, Values[genomes], pairs]],
        ColorFunction -> (ColorData["ThermometerColors"][Rescale[#, {-1.5, 1.5}]] &), ColorFunctionScaling -> False, PlotRange -> {-1.5, 1.5},
        FrameTicks -> {{Transpose[{Range[3], Keys[genomes]}], None}, {Transpose[{Range[16], pairs}], None}}],
        BarLegend[{"ThermometerColors", {-1.5, 1.5}}]]]
```

CG stands out in all three genomes. Compare its relative abundance directly:

```wl
relativeAbundance[#, "CG"] & /@ genomes
```

SARS-CoV-2 and RaTG13 both sit near 0.41, below SARS-CoV at 0.46. The statistic
compares adjacent-base frequencies with a simple independent-base reference.
It does not identify the evolutionary or biochemical processes that produced
the observed composition.

## What the comparison supports

The dot plots show where exact words match, the windowed profiles show how
that statistic varies along a sequence, and relative dinucleotide abundances
summarize composition. None is a complete alignment or a functional assay.
Three genomes cannot reconstruct their evolutionary history: sampling,
recombination and dating require broader evidence and appropriate models.
The stated word length, window size and reference frequencies define the
scope of each result.

## Initialization

These helpers read the bundled files and keep the analysis inputs short.
`kmerMatches` lists the positions of shared `k`-letter words, `sharedWords`
measures the fraction of shared words in complete windows.

```wl
okabeIto = RGBColor /@ {"#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2", "#D55E00", "#CC79A7", "#000000"};
example[file_] := FileNameJoin[{PacletObject["WolframInstitute/BioDataLink"]["AssetLocation", "Examples"], "Coronaviruses", file}];
readGenes[file_] := Association[Cases[Import[file, "TSV", "MissingValuePattern" -> None],
    {_, _, "gene", start_, end_, _, _, _, attributes_} :> First[StringCases[attributes, RegularExpression["Name=([^;]+)"] -> "$1"]] -> {start, end}]];
genomeMap[map_] := Graphics[MapIndexed[{okabeIto[[5]], Rectangle[{#1[[2, 1]], -First[#2]}, {#1[[2, 2]], 0.7 - First[#2]}], Black,
    Text[#1[[1]], {#1[[2, 2]] + 300, 0.35 - First[#2]}, {-1, 0}]} &, List @@@ Normal[map]], AspectRatio -> 1/2, Frame -> True,
    FrameTicks -> {{None, None}, {Automatic, None}}, PlotRange -> {{0, 34000}, All}];
kmerMatches[a_, b_, k_] := With[{index = PositionIndex[StringPartition[b, k, 1]]},
    Catenate[MapIndexed[Thread[{First[#2], Lookup[index, #1, {}]}] &, StringPartition[a, k, 1]]]];
sharedWords[a_, b_, k_, window_] := With[{words = AssociationThread[StringPartition[b, k, 1] -> True]},
    MapIndexed[{(First[#2] - 1) window + (window + 1)/2,
        N[Mean[Boole[Lookup[words, StringPartition[#1, k, 1], False]]]]} &, StringPartition[a, window]]];
relativeAbundance[sequence_, pair_] := N[(StringCount[sequence, pair, Overlaps -> True]/(StringLength[sequence] - 1))/
    Times @@ (StringCount[sequence, #]/StringLength[sequence] & /@ Characters[pair])];
```
