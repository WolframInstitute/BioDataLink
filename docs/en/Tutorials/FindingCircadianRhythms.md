---
Template: TechNote
Name: FindingCircadianRhythms
Title: Finding Circadian Rhythms in Gene Expression
Context: WolframInstitute`BioDataLink`
Paclet: WolframInstitute/BioDataLink
URI: WolframInstitute/BioDataLink/tutorial/FindingCircadianRhythms
Keywords: [application, circadian clock, time series, cosinor, false discovery rate, phase, Fourier, mouse liver, GEO]
RelatedGuides: [BioDataLink, ComputationalExplorations, Providers]
---

Which liver expression profiles are consistent with a daily rhythm, and when
does each fitted rhythm peak? This tutorial fits a fixed 24-hour model to a
small expression dataset and compares phases. A fitted time pattern alone
does not identify the molecular interactions that generate it.

The data come from [Hughes et al. 2009](https://doi.org/10.1371/journal.pgen.1000442),
GEO series GSE11923. Male C57BL/6J mice were kept in constant darkness and
liver samples were taken every hour for 48 hours, from circadian time (CT) 18
to CT 65. CT 0 is the start of the animals' subjective day. Each time point pools
3 to 5 mice on one Affymetrix array. BioDataLink bundles the probes for 19
clock genes plus 2,000 randomly sampled probe sets. The
[GEO series-matrix metadata](https://ftp.ncbi.nlm.nih.gov/geo/series/GSE11nnn/GSE11923/matrix/GSE11923_series_matrix.txt.gz)
identifies its expression values as MAS5 signals; those values are preserved.
The paper instead reports GCRMA expression estimates and MAS5 present/absent
calls. This tutorial analyzes the deposited matrix, not a reproduction of the
paper's preprocessing or rhythm-detection pipeline.

Evaluate the final Initialization section before copying individual inputs
from this page. The generated notebook initializes those helpers automatically;
the section starts closed and can be expanded to inspect them.

## Load the time series

`BioDatasetQuery` finds the series record in GEO. This input is online and is
not run when the documentation is built:

```wl
#| eval: false
With[{result = BioDatasetQuery["GEO", "GSE11923[ACCN]"]}, If[FailureQ[result], result, result["Records"][All, {"ID", "Title", "Organism"}]]]
```

It returns the series "High-temporal resolution profiling of mouse liver" for
*Mus musculus*. Read the bundled table and its source record:

```wl
liver = Import[FileNameJoin[{PacletObject["WolframInstitute/BioDataLink"]["AssetLocation", "Examples"], "LiverCircadian", "GSE11923-liver-subset.tsv.gz"}], "TSV", "MissingValuePattern" -> None];
liver[[;; 4, ;; 6]]
```

```wl
KeyTake[Import[FileNameJoin[{PacletObject["WolframInstitute/BioDataLink"]["AssetLocation", "Examples"], "LiverCircadian", "provenance.json"}], "RawJSON"], {"Accession", "Design", "Values"}]
```

Each row is an Affymetrix probe set, with its gene symbol and 48 signal
values. Several probe sets can map to the same gene. Work with base-2
logarithms, so that a difference of 1 means a twofold signal ratio:

```wl
times = Range[18, 65];
expression = Log2[liver[[2 ;;, 3 ;;]]];
Dimensions[expression]
```

Mean signals vary widely across probe sets. Low signals can be dominated by
background, but this histogram alone cannot establish whether a transcript is
absent:

```wl
Histogram[Mean /@ expression, {0.25}, GridLines -> {{7}, None}, Frame -> True, FrameLabel -> {"mean log2 signal", "probe sets"}]
```

For this exploratory screen, keep probe sets with a mean log2 signal of at
least 7. This explicit intensity filter is not a validated presence/absence
call:

```wl
keep = Flatten[Position[Mean /@ expression, m_ /; m >= 7]];
expressed = expression[[keep]];
names = liver[[2 ;;, 2]][[keep]];
Length[keep]
```

## Fit a daily rhythm to every probe

A cosinor model describes a rhythm as a mean level (the mesor) plus a cosine
with a 24-hour period, an amplitude and a peak time. Fitting it is a linear
regression on the cosine and sine of the time, so all 880 retained probe sets
are fitted at once. An F-test compares the fit with a constant mean, using 2 and 45 degrees
of freedom. Its calibration assumes independent, normally distributed errors
with constant variance for each probe set:

```wl
rhythm = cosinor[expressed, times];
Keys[rhythm]
```

Show the data and the fitted cosines for six clock genes. Gray bands mark
subjective night (CT 12–24 modulo 24); the animals were actually in constant
darkness throughout sampling:

```wl
GraphicsGrid[Partition[rhythmPlot[#] & /@ {"Arntl", "Clock", "Nr1d1", "Dbp", "Per2", "Cry1"}, 3], ImageSize -> Large]
```

The fits capture a repeated component, with visible departures from a pure
cosine. `Arntl` (also called `Bmal1`) and `Clock` peak near the end of
subjective night; `Nr1d1` and `Dbp` peak during subjective day. `Per2` and
`Cry1` peak at different times during subjective night. These are phases of
the fitted 24-hour component, not necessarily the observed hourly maximum.

Adjust the p-values across the 880 retained probe sets with the
[Benjamini–Hochberg procedure](https://doi.org/10.1111/j.2517-6161.1995.tb02031.x).
Here `q` denotes BH-adjusted p-values, not each probe's probability of being
false. Label a probe set rhythmic in this exploratory screen when `q < 0.05`
and the fitted peak-to-trough signal ratio is at least 1.5:

```wl
q = benjaminiHochberg[rhythm["P"]];
rhythmic = Flatten[Position[Transpose[{q, rhythm["Amplitude"]}], {qi_, a_} /; qi < 0.05 && 2 a >= Log2[1.5]]];
Length[rhythmic]
```

The amplitude requirement excludes small fitted effects even when their
adjusted p-values are small. Here 163 of 880 retained probe sets (18.5%) pass both thresholds. The subset deliberately includes clock genes, so this
fraction does not estimate the prevalence of rhythmic expression across the
liver transcriptome.

Find the rhythmic clock genes, keeping the most strongly expressed probe of
each:

```wl
clockProbes = Select[DeleteDuplicates[probeFor /@ Intersection[clockGenes, names]], MemberQ[rhythmic, #] &];
names[[clockProbes]]
```

Plot amplitude against significance and label the clock genes. The grid lines
mark the two thresholds; q values below 10<sup>−16</sup> are drawn at 16:

```wl
With[{points = Transpose[{rhythm["Amplitude"], -Log10[Clip[q, {10^-16, 1}]]}]},
    ListPlot[{points, Callout[points[[#]], names[[#]]] & /@ clockProbes}, PlotStyle -> {GrayLevel[0.7], okabeIto[[6]]}, PlotRange -> All,
        Frame -> True, FrameLabel -> {"amplitude (log2)", "-log10 q"}, GridLines -> {{Log2[1.5]/2}, {-Log10[0.05]}}]]
```

Several selected clock genes have large amplitudes and small adjusted
p-values. Their deliberate inclusion makes this a useful demonstration, not
an unbiased enrichment test.

## Watch the rhythms as a wave

Take the strongest rhythms, with peaks at least twice their troughs, and order
them by peak time. Show each probe standardized to mean 0 and standard
deviation 1:

```wl
With[{order = SortBy[Select[rhythmic, rhythm["Amplitude"][[#]] >= 1/2 &], rhythm["Peak"][[#]] &]},
    MatrixPlot[Clip[Standardize /@ expressed[[order]], {-2.5, 2.5}], ColorFunction -> "ThermometerColors", PlotLegends -> Automatic,
        DataRange -> {{18, 65}, {1, Length[order]}}, FrameLabel -> {"probe sets by peak time", "circadian time (hours)"}, AspectRatio -> 1]]
```

Bands repeat approximately after 24 hours, consistent with the selection for
that component. Shared shifts around some time points could reflect technical
effects or coordinated biology; this plot cannot distinguish them. Count the
fitted peak times in one-hour bins on a 24-hour clock face. Sector radius is the square root of the count, so
sector area is proportional to the number of probes:

```wl
SectorChart[{1, Sqrt[#]} & /@ BinCounts[rhythm["Peak"][[rhythmic]], {0, 24, 1}], SectorOrigin -> {{Pi/2, "Clockwise"}, 0},
    ChartLabels -> Placed[Table[If[Mod[h, 6] == 0, "CT " <> ToString[h], ""], {h, 0, 23}], "RadialOutside"], ChartStyle -> okabeIto[[5]]]
```

## Read the clock from the phases

Place each rhythmic clock gene on a clock face at its peak time, with its
distance from the center equal to its amplitude. The gray circles mark
amplitudes 1, 2 and 3:

```wl
ListPolarPlot[Callout[{Pi/2 - 2 Pi rhythm["Peak"][[#]]/24, rhythm["Amplitude"][[#]]}, names[[#]]] & /@ clockProbes, PlotStyle -> okabeIto[[6]],
    PolarAxes -> {True, False}, PolarGridLines -> {None, {1, 2, 3}}, PolarTicks -> {Table[{Pi/2 - 2 Pi h/24, "CT " <> ToString[h]}, {h, 0, 18, 6}], None},
    ImagePadding -> 30]
```

The selected profiles occupy different phases: `Arntl` and `Clock` peak near
CT 22–24, `Nr1d1` near CT 6, `Dbp` near CT 10 and `Per2` near CT 14.
Phase separation is compatible with the clock biology studied in the source
paper, but does not establish regulatory direction or a feedback connection.

Two genes that peak about 6 hours apart, such as `Per2` and `Cry1`, trace a
loop when plotted against each other. Show the hourly measurements, colored
from the first time point (dark) to the last (yellow), over the loop of their
fitted cosines:

```wl
With[{i = probeFor["Per2"], j = probeFor["Cry1"]},
    Show[ParametricPlot[{fitted[i, t], fitted[j, t]}, {t, 0, 24}, PlotStyle -> Gray],
        Graphics[{PointSize[Medium], Point[Transpose[{expressed[[i]], expressed[[j]]}], VertexColors -> (ColorData["BlueGreenYellow"] /@ Rescale[times])]}],
        PlotRange -> All, Axes -> False, Frame -> True, FrameLabel -> {"Per2 (log2)", "Cry1 (log2)"}, AspectRatio -> 1]]
```

The fitted loop follows mathematically from two phase-shifted cosines.
Measurements from the two days scatter around it. A shared time pattern,
common driver or other confounding could produce such a plot; it is not
independent evidence for a direct interaction or an autonomous oscillator.

## Look beyond 24 hours

A Fourier transform splits each time series into rhythms with periods of 48,
24, 16, 12 and fewer hours. Average the power at each period for rhythmic and
non-rhythmic probes:

```wl
With[{power = Abs[Fourier[# - Mean[#]]]^2 & /@ expressed, others = Complement[Range[Length[expressed]], rhythmic]},
    ListLogLogPlot[{Transpose[{48./Range[12], Mean[power[[rhythmic, 2 ;; 13]]]}], Transpose[{48./Range[12], Mean[power[[others, 2 ;; 13]]]}]},
        Joined -> True, PlotMarkers -> Automatic, PlotLegends -> {"selected rhythmic probe sets", "other retained probe sets"},
        Frame -> True, FrameLabel -> {"period (hours)", "mean power"}]]
```

The 24-hour peak is expected because that component defined the selected
group. Power at 12 or 8 hours can arise from nonsinusoidal daily waveforms;
this average spectrum does not identify independent shorter-period rhythms.
The source study used additional analyses and validation to investigate
shorter-period expression patterns.

## What the analysis supports

This screen identifies probe sets with a detectable fitted 24-hour component
under the stated model, intensity filter and amplitude threshold. It compares
phases within two days of pooled liver samples. One array per time point does
not provide separate animal-level replicates, and the pooled design cannot
estimate between-animal variation at each time.

BH controls the expected false-discovery proportion under valid p-values and
independence or suitable positive dependence. Shared processing, temporal
structure and correlated probe sets can challenge those assumptions; they
have not been validated here. The additional amplitude filter and selected
probe family also limit interpretation, so the combined screen is not a
verified genome-wide 5% false-discovery guarantee. Period estimation,
replicate-aware uncertainty and independent validation would require a more
complete analysis. Messenger RNA patterns do not establish protein rhythms
or molecular mechanisms.

## Initialization

`cosinor` fits a mesor plus a 24-hour cosine to each row of `y` by least
squares and returns the amplitude, the peak time and an F-test p-value.
`benjaminiHochberg` returns BH-adjusted p-values. `SurvivalFunction` computes
the upper-tail probability directly, avoiding subtraction from a CDF near 1.

```wl
okabeIto = RGBColor /@ {"#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2", "#D55E00", "#CC79A7", "#000000"};
clockGenes = {"Arntl", "Bhlhe40", "Bhlhe41", "Ciart", "Clock", "Cry1", "Cry2", "Dbp", "Hlf", "Nfil3", "Npas2", "Nr1d1", "Nr1d2", "Per1", "Per2", "Per3", "Rora", "Rorc", "Tef"};
subjectiveNight = {GrayLevel[0.92], Rectangle[{#, -100}, {# + 12, 100}] & /@ {12, 36, 60}};
cosinor[y_, t_] := Module[{x = N[Transpose[{1 + 0 t, Cos[2 Pi t/24], Sin[2 Pi t/24]}]], b, residual, total},
    b = LeastSquares[x, Transpose[y]];
    residual = Total /@ ((y - Transpose[x . b])^2);
    total = Total /@ ((y - Mean /@ y)^2);
    <|"Mesor" -> b[[1]], "Amplitude" -> Sqrt[b[[2]]^2 + b[[3]]^2], "Peak" -> Mod[24 ArcTan[b[[2]], b[[3]]]/(2 Pi), 24],
        "P" -> SurvivalFunction[FRatioDistribution[2, Length[t] - 3], ((total - residual)/2)/(residual/(Length[t] - 3))]|>];
benjaminiHochberg[p_] := Module[{order = Ordering[p], q},
    q = p[[order]] Length[p]/Range[Length[p]];
    Clip[Reverse[FoldList[Min, Reverse[q]]], {0, 1}][[Ordering[order]]]];
```

`probeFor` picks the most strongly expressed probe of a gene, `fitted` gives a
probe's fitted cosine at time `t`, and `rhythmPlot` draws a gene's data with its
fitted cosine:

```wl
probeFor[gene_] := First[MaximalBy[Flatten[Position[names, gene]], Mean[expressed[[#]]] &]];
fitted[i_, t_] := rhythm["Mesor"][[i]] + rhythm["Amplitude"][[i]] Cos[2 Pi (t - rhythm["Peak"][[i]])/24];
rhythmPlot[gene_] := With[{i = probeFor[gene]},
    Show[ListPlot[Transpose[{times, expressed[[i]]}], PlotStyle -> okabeIto[[5]], Prolog -> subjectiveNight, Frame -> True, PlotLabel -> gene,
            FrameLabel -> {"CT (hours)", "log2 signal"}],
        Plot[fitted[i, t], {t, 18, 65}, PlotStyle -> okabeIto[[6]]]]];
```
