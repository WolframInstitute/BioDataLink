---
Template: TechNote
Name: ReadingBacterialGenomeComposition
Title: Reading the Composition of a Bacterial Genome
Context: WolframInstitute`BioDataLink`
Paclet: WolframInstitute/BioDataLink
URI: WolframInstitute/BioDataLink/tutorial/ReadingBacterialGenomeComposition
Keywords: [application, genome, DNA sequence, GC skew, replication origin, gene orientation, chaos game representation, k-mers, Borrelia]
RelatedGuides: [BioDataLink, ComputationalExplorations, Downloads, Sources]
---

Can the letters of a genome reveal how it is copied? DNA replication starts at
an origin and proceeds in both directions. The two strands are copied
differently, and over evolutionary time this leaves a compositional signature.
This tutorial estimates an origin-associated compositional transition from a
bacterial chromosome, then compares gene orientation and word usage around it.

The genome is the linear chromosome of *Borreliella* (*Borrelia*)
*burgdorferi* B31, the agent of Lyme disease, first sequenced by
[Fraser et al. 1997](https://doi.org/10.1038/37551). BioDataLink bundles the
RefSeq record NC_001318.1 (910,724 bases) and its gene annotation, as retrieved
from NCBI. The bacterium also carries more than 20 plasmids, which are not
included here.

Evaluate the Initialization section at the end before running the examples.

## Load the sequence

The source directory resolves the RefSeq accession offline:

```wl
BioDataURL[{"refseq", "NC_001318.1"}]
```

The bundled file was retrieved with `BioDatasetDownload`, which checks the
bytes against a SHA-256 hash. This online input repeats that step; it is not
run when the documentation is built:

```wl
#| eval: false
BioDatasetDownload["https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=NC_001318.1&rettype=fasta&retmode=text",
    File[FileNameJoin[{CreateDirectory[], "NC_001318.1.fasta"}]],
    "ExpectedSHA256" -> "fe3ef476bc7ce076bc388a08162440de10163f49272b0c4f2d2030dfce5ddfae"]
```

Import the bundled copy as a string of bases:

```wl
genome = First[Import[FileNameJoin[{PacletObject["WolframInstitute/BioDataLink"]["AssetLocation", "Examples"], "BorreliaB31", "NC_001318.1.fasta.gz"}], "Sequence"]];
StringLength[genome]
```

Count each letter:

```wl
Counts[Characters[genome]]
```

Besides A, C, G and T, a few dozen positions carry IUPAC ambiguity codes, such
as R for A or G. They are too few to matter for composition and are skipped
where a calculation needs exact bases. The chromosome is strongly AT-rich: G
and C make up only 29% of the bases.

## Find the replication origin

On the strand copied continuously (the leading strand), G tends to exceed C
([Lobry 1996](https://doi.org/10.1093/oxfordjournals.molbev.a025626)).
Measure the GC skew, (G − C)/(G + C), and the analogous AT skew in windows of
10,000 bases:

```wl
With[{windows = StringPartition[genome, 10000]},
    ListLinePlot[{skew[#, "G", "C"] & /@ windows, skew[#, "A", "T"] & /@ windows},
        DataRange -> {0.0050005, 0.9050005}, Filling -> Axis,
        PlotLegends -> {"GC skew", "AT skew"}, Frame -> True, FrameLabel -> {"position (Mb)", "skew"}]]
```

Both skews flip sign in the middle of the chromosome, and they stay strong for
hundreds of thousands of bases. Left of the flip, the sequence in the file is
the lagging strand; to the right it is the leading strand, rich in G and T.

Adding the base-by-base contribution of G (+1) and C (−1) turns the noisy
windows into one curve ([Grigoriev 1998](https://doi.org/10.1093/nar/26.10.2286)).
Its minimum gives a candidate origin-associated transition:

```wl
cumulative = Accumulate[Characters[genome] /. {"G" -> 1, "C" -> -1, _String -> 0}];
origin = First[Ordering[cumulative, 1]]
```

```wl
With[{positions = Range[1, StringLength[genome], 1000]},
    ListLinePlot[Transpose[{positions, cumulative[[positions]]}], GridLines -> {{origin}, None},
        Frame -> True, FrameLabel -> {"position (bases)", "cumulative G \[Minus] C"}]]
```

The minimum lies at base 458,236, within 3,000 bases of the chromosome's
midpoint. Experiments located the origin of bidirectional replication at the
center of this linear chromosome
([Picardeau, Lobry and Hinnebusch 1999](https://doi.org/10.1046/j.1365-2958.1999.01368.x)):
the compositional estimate is consistent with that independently measured region.

## Follow the genes

The annotation lists each gene's start, end and strand. Read it as a table;
`"MissingValuePattern" -> None` keeps the minus-strand symbol `-` as text:

```wl
genes = Select[Import[FileNameJoin[{PacletObject["WolframInstitute/BioDataLink"]["AssetLocation", "Examples"], "BorreliaB31", "NC_001318.1.gff3.gz"}],
    "TSV", "MissingValuePattern" -> None], Length[#] == 9 && #[[3]] == "gene" &][[All, {4, 5, 7}]];
Length[genes]
```

Draw every gene as a bar above the axis for the plus strand and below it for
the minus strand, with the origin as a vertical line:

```wl
With[{plus = Select[genes, Last[#] == "+" &], minus = Select[genes, Last[#] == "-" &]},
    Graphics[{okabeIto[[5]], Rectangle[{#[[1]], 0}, {#[[2]], 1}] & /@ plus, okabeIto[[6]], Rectangle[{#[[1]], -1}, {#[[2]], 0}] & /@ minus,
        Black, Line[{{origin, -1.3}, {origin, 1.3}}]}, AspectRatio -> 1/6, Frame -> True, FrameTicks -> {{{{0.5, "+"}, {-0.5, "-"}}, None}, {Automatic, None}}, ImageSize -> Large]]
```

Count the genes on each strand on either side of the origin:

```wl
Counts /@ GroupBy[genes, If[#[[1]] < origin, "left of origin", "right of origin"] & -> Last]
```

About two thirds of the genes on each side point in the direction of the
replication fork: on the minus strand to the left and the plus strand to the
right. This orientation bias is common in bacteria and is usually explained by
fewer head-on collisions between the replication and transcription machinery
([Rocha 2008](https://doi.org/10.1146/annurev.genet.42.110807.091653)).

## See the genome's word usage

The chaos game turns a sequence into a picture of its words
([Jeffrey 1990](https://doi.org/10.1093/nar/18.8.2163)). Place A, C, G and T
at the corners of a square, start at the center, and for each base move halfway
toward its corner. Counting the points in a grid of 256 by 256 cells counts
every 8-letter word, because the last 8 bases determine the cell. The helper
`wordGrid` counts these words with exact integer coordinates. It omits words
containing ambiguous bases and the initial positions before a full word exists:

```wl
ArrayPlot[Log[1. + wordGrid[genome, 256]], DataReversed -> True, ColorFunction -> "SunsetColors",
    FrameTicks -> {{{{1, "A"}, {256, "C"}}, None}, {{{1, "A"}, {256, "T"}}, None}}]
```

Bright cells are common words and dark cells rare ones; G is in the top-right
corner. The bright bottom edge holds words made of A and T, and the dark upper
region words rich in G and C. The same pattern repeats inside every
sub-square, because each smaller square holds the words that end with a given
letter.

Compare the word frequencies of the two halves of the chromosome, on a coarser
grid of 5-letter words. Red cells are more frequent right of the origin:

```wl
With[{left = wordGrid[StringTake[genome, origin], 32], right = wordGrid[StringDrop[genome, origin], 32]},
    Legended[MatrixPlot[Log2[((right + 1)/Total[right + 1, 2])/((left + 1)/Total[left + 1, 2])], DataReversed -> True,
        ColorFunction -> (ColorData["ThermometerColors"][Rescale[#, {-2.5, 2.5}]] &),
        ColorFunctionScaling -> False, PlotRange -> {-2.5, 2.5}, FrameTicks -> None],
        BarLegend[{"ThermometerColors", {-2.5, 2.5}}]]]
```

One pseudocount is added to every word before each half is normalized; words
crossing the split are excluded. The square splits left from right. Its right half holds words ending in G or T,
which are enriched on the leading strand; its left half holds words ending in A
or C. The strand asymmetry is not limited to G and C counts: it reshapes the
frequency of thousands of words.

## What the sequence supports

Base composition identified a transition near the experimentally mapped
origin and a bias in gene orientation on either side.
These are statistical signatures accumulated over evolution, not direct
measurements of replication in living cells. Recombination, horizontal gene
transfer and local selection can blur them, so other genomes show weaker or
displaced skews. The window size, the ambiguity-code handling and the sign
convention, (G − C)/(G + C), are stated above.

## Initialization

`skew` measures the excess of one base over its partner in a sequence window.
`wordGrid` counts complete exact-base words in an `n` × `n` chaos-game grid,
where `n` is a power of two. Each uninterrupted A/C/G/T run is counted
separately, so ambiguity codes cannot create artificial words across gaps.
Rows run from A and T at the bottom to C and G at the top. Colors come from the Okabe-Ito palette, which stays
distinguishable with common color-vision deficiencies.

```wl
okabeIto = RGBColor /@ {"#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2", "#D55E00", "#CC79A7", "#000000"};
skew[sequence_, a_, b_] := N[(StringCount[sequence, a] - StringCount[sequence, b])/StringCount[sequence, a | b]];
wordGrid[sequence_, n_] := Module[{k = IntegerExponent[n, 2], words, points},
    words = Select[StringCases[sequence, RegularExpression["[ACGT]+"]], StringLength[#] >= k &];
    points = Catenate[Function[run, With[{digits = Characters[run] /. {"A" -> 0, "C" -> 1, "G" -> 3, "T" -> 2}},
        Transpose[{ListCorrelate[2^Range[0, k - 1], Quotient[digits, 2]],
            ListCorrelate[2^Range[0, k - 1], Mod[digits, 2]]}]]] /@ words];
    Transpose[BinCounts[points, {-0.5, n - 0.5, 1}, {-0.5, n - 0.5, 1}]]];
```
