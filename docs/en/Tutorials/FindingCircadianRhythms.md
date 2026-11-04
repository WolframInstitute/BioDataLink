---
Template: TechNote
Name: FindingCircadianRhythms
Title: Finding Circadian Rhythms in Gene Expression
Context: WolframInstitute`BioDataLink`
Paclet: WolframInstitute/BioDataLink
URI: WolframInstitute/BioDataLink/tutorial/FindingCircadianRhythms
Keywords: [application, circadian clock, time series, cosinor, false discovery rate, phase, mouse liver, GEO]
RelatedGuides: [BioDataLink, ComputationalExplorations, Providers]
---

Screen mouse liver expression for a fitted 24-hour rhythm using
[GSE11923](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE11923)
([Hughes et al. 2009](https://doi.org/10.1371/journal.pgen.1000442)).
Male C57BL/6J mice were sampled hourly in constant darkness, from circadian
time (CT) 18 to 65. CT 0 starts the subjective day. Each array pools 3–5 mice;
there is one array per time point.

The subset contains probes for 19 clock genes plus 2,000 randomly selected
probe sets. It preserves deposited MAS5 signals. The paper used GCRMA estimates
and MAS5 presence calls; this tutorial does not reproduce that preprocessing.

Evaluate **Initialization**, then run the examples in order.

## Load and filter expression

Read the bundled table and provenance:

```wl
liver = Import[FileNameJoin[{PacletObject["WolframInstitute/BioDataLink"]["AssetLocation", "Examples"], "LiverCircadian", "GSE11923-liver-subset.tsv.gz"}], "TSV", "MissingValuePattern" -> None];
liver[[;; 4, ;; 6]]
```

Inspect the study design and measurement scale:

```wl
KeyTake[Import[FileNameJoin[{PacletObject["WolframInstitute/BioDataLink"]["AssetLocation", "Examples"], "LiverCircadian", "provenance.json"}], "RawJSON"], {"Accession", "Design", "Values"}]
```

Rows are probe sets, not unique genes. Convert the 48 signals to log2 units;
a difference of one then represents a twofold ratio:

```wl
times = Range[18, 65];
expression = Log2[liver[[2 ;;, 3 ;;]]];
Dimensions[expression]
```

Keep mean log2 signal ≥ 7. This exploratory intensity filter is not a
presence/absence test.

```wl
keep = Flatten[Position[Mean /@ expression, m_ /; m >= 7]];
expressed = expression[[keep]];
names = liver[[2 ;;, 2]][[keep]];
Length[keep]
```

## Fit a 24-hour rhythm

A cosinor fit estimates a mean, amplitude and peak time using sine and cosine
terms. Compare it with a constant mean using an F-test with 2 and 45 degrees
of freedom. The test assumes independent normal errors with constant variance.

```wl
rhythm = cosinor[expressed, times];
Keys[rhythm]
```

Show six clock genes. Gray bands indicate subjective night, not actual changes
in lighting:

```wl
GraphicsGrid[Partition[rhythmPlot[#] & /@ {"Arntl", "Clock", "Nr1d1", "Dbp", "Per2", "Cry1"}, 3], ImageSize -> Large]
```

Peaks refer to the fitted 24-hour component, not necessarily the largest
observed hourly value.

## Select rhythms and compare phases

Apply [Benjamini–Hochberg adjustment](https://doi.org/10.1111/j.2517-6161.1995.tb02031.x)
across all 880 retained probe sets. Select adjusted p-value `q < 0.05` and
fitted peak-to-trough ratio ≥ 1.5:

```wl
q = benjaminiHochberg[rhythm["P"]];
rhythmic = Flatten[Position[Transpose[{q, rhythm["Amplitude"]}], {qi_, a_} /; qi < 0.05 && 2 a >= Log2[1.5]]];
Length[rhythmic]
```

Here 163 of 880 probes pass. Because clock genes were deliberately included,
this fraction does not estimate transcriptome-wide prevalence.

For each clock gene, use its most strongly expressed probe:

```wl
clockProbes = Select[DeleteDuplicates[probeFor /@ Intersection[clockGenes, names]], MemberQ[rhythmic, #] &];
names[[clockProbes]]
```

Plot fitted amplitudes and adjusted p-values:

```wl
With[{points = Transpose[{rhythm["Amplitude"], -Log10[Clip[q, {10^-16, 1}]]}]},
    ListPlot[{points, Callout[points[[#]], names[[#]]] & /@ clockProbes}, PlotStyle -> {GrayLevel[0.7], okabeIto[[6]]}, PlotRange -> All,
        Frame -> True, FrameLabel -> {"amplitude (log2)", "-log10 q"}, GridLines -> {{Log2[1.5]/2}, {-Log10[0.05]}}]]
```

The grid lines show the selection thresholds. Values of `q` below 10<sup>−16</sup>
are plotted at 16; adjusted p-values are not probabilities that individual
findings are false.

Order strong rhythms (at least twofold peak-to-trough) by fitted peak time.
Standardize each probe to mean zero and standard deviation one:

```wl
With[{order = SortBy[Select[rhythmic, rhythm["Amplitude"][[#]] >= 1/2 &], rhythm["Peak"][[#]] &]},
    MatrixPlot[Clip[Standardize /@ expressed[[order]], {-2.5, 2.5}], ColorFunction -> "ThermometerColors", PlotLegends -> Automatic,
        DataRange -> {{18, 65}, {1, Length[order]}}, FrameLabel -> {"probe sets by peak time", "circadian time (hours)"}, AspectRatio -> 1]]
```

Plot clock-gene peak times with radius equal to log2 amplitude:

```wl
ListPolarPlot[Callout[{Pi/2 - 2 Pi rhythm["Peak"][[#]]/24, rhythm["Amplitude"][[#]]}, names[[#]]] & /@ clockProbes, PlotStyle -> okabeIto[[6]],
    PolarAxes -> {True, False}, PolarGridLines -> {None, {1, 2, 3}}, PolarTicks -> {Table[{Pi/2 - 2 Pi h/24, "CT " <> ToString[h]}, {h, 0, 18, 6}], None},
    ImagePadding -> 30]
```

`Arntl` and `Clock` peak near CT 22–24, `Nr1d1` near CT 6, `Dbp` near CT 10
and `Per2` near CT 14. Phase differences alone do not establish regulatory
connections.

## Interpretation

This is a fixed-period screen of two days of pooled samples. It cannot
estimate between-animal variation or establish protein rhythms. Shared
processing, temporal structure and correlated probes may violate test
assumptions; BH plus the amplitude filter is not a verified genome-wide
5% false-discovery guarantee. Confirm candidate rhythms with independent data
and a design that supports replicate-aware uncertainty.

## Initialization

Helpers fit the cosinor model, adjust p-values, select a probe per gene and
plot measured and fitted expression.

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

```wl
probeFor[gene_] := First[MaximalBy[Flatten[Position[names, gene]], Mean[expressed[[#]]] &]];
fitted[i_, t_] := rhythm["Mesor"][[i]] + rhythm["Amplitude"][[i]] Cos[2 Pi (t - rhythm["Peak"][[i]])/24];
rhythmPlot[gene_] := With[{i = probeFor[gene]},
    Show[ListPlot[Transpose[{times, expressed[[i]]}], PlotStyle -> okabeIto[[5]], Prolog -> subjectiveNight, Frame -> True, PlotLabel -> gene,
            FrameLabel -> {"CT (hours)", "log2 signal"}],
        Plot[fitted[i, t], {t, 18, 65}, PlotStyle -> okabeIto[[6]]]]];
```
