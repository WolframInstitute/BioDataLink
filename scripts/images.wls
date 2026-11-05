#!/usr/bin/env wolframscript
(* Rebuild the documentation images from bundled data, offline: docs/Hero.png for the resource
   page and docs/en/Images/<Page>.png for guides and tutorials. A tutorial image first runs that
   tutorial's code, so it shows the page's own results; guide images reuse those results.
   Usage: images.wls [Name ...], with image names without ".png"; none rebuilds every image.
   Rerun after a tutorial, the bundled data or the source directory changes. *)
root = DirectoryName[$InputFileName, 2];
PacletDirectoryLoad[FileNameJoin[{root, "BioDataLink"}]];
Needs["WolframInstitute`BioDataLink`"];
$AllowInternet = False;
fail[text_] := (Print["ERROR: ", text]; Exit[1]);

(* ==================== style ==================== *)

font = "Helvetica";
ink = GrayLevel[0.2];
muted = GrayLevel[0.45];
rule = GrayLevel[0.85];
okabeIto = RGBColor /@ {"#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2", "#D55E00", "#CC79A7", "#000000"};
tolMuted = RGBColor /@ {"#CC6677", "#332288", "#DDCC77", "#117733", "#88CCEE", "#882255", "#44AA99", "#999933", "#AA4499"};
(* sequencing-trace colors: A green, C blue, G black, T red *)
baseColor = <|"A" -> okabeIto[[3]], "C" -> okabeIto[[5]], "G" -> GrayLevel[0.1], "T" -> okabeIto[[6]]|>;
styled[s_, size_, color_ : ink, weight_ : Plain] := Style[s, FontFamily -> font, FontSize -> size, FontColor -> color, FontWeight -> weight];
grouped[n_Integer] := ToString[NumberForm[n, DigitBlock -> 3]];
note[s_, width_, size_ : 9] := Pane[TextCell[s, FontFamily -> font, FontSize -> size, FontColor -> muted, LineSpacing -> {1.1, 0}], width];
panel[title_, drawing_, text_, width_] := Column[{styled[title, 11, ink, Bold], drawing, note[text, width]}, Spacings -> {0, {0.3, 0.6}}];
board[panels_List] := Grid[{panels}, Alignment -> {Left, Top}, Spacings -> {3, 0}, Background -> White];
swatches[pairs_] := Row[Riffle[Row[{Graphics[{#2, Disk[]}, ImageSize -> 8, BaselinePosition -> Scaled[0.1]], " ", styled[#1, 8]}] & @@@ pairs, "    "]];
framed[g_] := Framed[g, FrameStyle -> rule, RoundingRadius -> 6, FrameMargins -> 5, Background -> White];
(* a label that stays legible over dense marks *)
tag[s_, position_, size_ : 8] := Text[Framed[styled[s, size], Background -> Directive[White, Opacity[0.8]],
    FrameStyle -> None, FrameMargins -> 1, RoundingRadius -> 2], position];
(* Labels start at their anchors, larger groups first; a label that would overlap one already
   placed steps up or down. unit is data units per printer's point. *)
placeLabels[anchors_Association, unit_, size_ : 8] := Module[{placed = <||>, half, clearQ},
    half[name_] := unit size {0.3 StringLength[name] + 0.4, 0.75};
    clearQ[name_, p_] := NoneTrue[Keys[placed], And @@ Thread[Abs[p - placed[#]] < half[name] + half[#]] &];
    KeyValueMap[Function[{name, anchor}, placed[name] = SelectFirst[
        Table[anchor + {0, 1.6 k unit size}, {k, {0, 1, -1, 2, -2, 3, -3, 4, -4, 5, -5}}], clearQ[name, #] &, anchor]], anchors];
    placed
];
(* axes for plots that carry other drawings beside them; labels sit in the image padding *)
axes[{x0_, x1_}, xticks_, {y0_, y1_}, yticks_, {xlabel_, ylabel_}] := {rule, AbsoluteThickness[0.8],
    Line[{{x0, y0}, {x1, y0}}], Line[{{x0, y0}, {x0, y1}}],
    Line[{{#, y0}, Offset[{0, -3}, {#, y0}]}] & /@ xticks[[All, 1]], Line[{{x0, #}, Offset[{-3, 0}, {x0, #}]}] & /@ yticks[[All, 1]],
    Text[styled[#2, 7, muted], Offset[{0, -10}, {#1, y0}]] & @@@ xticks,
    Text[styled[#2, 7, muted], Offset[{-5, 0}, {x0, #1}], {1, 0}] & @@@ yticks,
    If[xlabel === None, {}, Text[styled[xlabel, 8, muted], Offset[{0, -22}, {(x0 + x1)/2, y0}]]],
    If[ylabel === None, {}, Text[styled[ylabel, 8, muted], Offset[{-27, 0}, {x0, (y0 + y1)/2}], {0, 0}, {0, 1}]]};

(* ==================== tutorial results ==================== *)

(* Run a tutorial's code in a context of its own: the helpers of its final Initialization section
   first, as the documentation build does, then the body in order. Cells marked "#| eval: false"
   are skipped; other "#|" lines are cell options. *)
tutorialContext[name_String] := tutorialContext[name] = Module[{text, parts, cells, context = "BioDataLinkImages`" <> name <> "`"},
    text = Import[FileNameJoin[{root, "docs", "en", "Tutorials", name <> ".md"}], "Text"];
    parts = StringSplit[text, "\n## Initialization\n"];
    If[Length[parts] =!= 2, fail[name <> " needs exactly one final Initialization section"]];
    cells[part_] := StringDelete[Select[StringCases[part, RegularExpression["(?s)```wl\\n(.*?)```"] -> "$1"],
        !StringContainsQ[#, "#| eval: false"] &], RegularExpression["(?m)^#\\|.*$"]];
    Print["Running ", name];
    Block[{$Context = context, $ContextPath = {"WolframInstitute`BioDataLink`", "System`"}},
        Scan[With[{stream = StringToStream[#]}, Get[stream]; Close[stream]] &, Join[cells[Last[parts]], cells[First[parts]]]]];
    context
];
result[name_String, symbol_String] := With[{full = tutorialContext[name] <> symbol},
    If[NameQ[full], Symbol[full], fail[name <> " no longer defines " <> symbol]]];

(* ==================== single cells ==================== *)

singleCell = result["AnalyzingSingleCellExpression", #] &;
(* groups in the tutorial's plotting order, so each keeps the tutorial's color *)
cellGroups[] := cellGroups[] = KeySort[GroupBy[Thread[singleCell["cellType"] -> singleCell["umap"]], First -> Last]];
cellColor[] := AssociationThread[Keys[cellGroups[]], Take[tolMuted, Length[cellGroups[]]]];
cellMap[size_, labeled_ : False] := Module[{groups = cellGroups[], colors = cellColor[], range, unit, anchors, placed},
    range = MinMax /@ Transpose[Catenate[Values[groups]]];
    unit = (range[[1, 2]] - range[[1, 1]])/size;
    anchors = Median /@ KeySortBy[groups, -Length[groups[#]] &];
    placed = placeLabels[anchors, unit];
    Graphics[{KeyValueMap[{colors[#1], Function[point, Disk[point, 2.2 unit]] /@ #2} &, groups],
        If[labeled, {KeyValueMap[If[#2 =!= anchors[#1], {muted, AbsoluteThickness[0.6], Line[{anchors[#1], #2}]}, {}] &, placed],
            KeyValueMap[tag[#1, #2] &, placed]}, {}]},
        AspectRatio -> 1, PlotRange -> range, PlotRangePadding -> Scaled[0.04], ImageSize -> size]
];
(* rows follow the marker sets and columns their genes: dot area is the fraction of a group's cells
   with counts; color is the mean log-scaled expression relative to the other groups *)
markerDots[size_, labeled_ : False] := Module[{sets = singleCell["markerSets"], gene = singleCell["gene"],
        x = singleCell["logExpression"], types = singleCell["cellType"], rows, genes, fraction, level, dy = If[labeled, 1.5, 1]},
    rows = Keys[sets]; genes = DeleteDuplicates[Catenate[Values[sets]]];
    {fraction, level} = Transpose[Table[With[{v = Normal[x[[Flatten[Position[types, t]], gene /@ genes]]]},
        {Mean[Unitize[v]], Mean[v]}], {t, rows}], {2, 1, 3}];
    level = Transpose[Rescale /@ Transpose[level]];
    Graphics[{
        Table[{ColorData["BlueGreenYellow"][level[[i, j]]], Disk[{j, -dy i}, 0.46 Sqrt[fraction[[i, j]]]]}, {i, Length[rows]}, {j, Length[genes]}],
        If[labeled, {
            MapIndexed[{cellColor[][#1], Disk[{0.25, -dy First[#2]}, 0.16], Text[styled[#1, 8], {0, -dy First[#2]}, {1, 0}]} &, rows],
            MapIndexed[Text[styled[#1, 8], {First[#2], 0.3}, {-1, 0}, {0, 1}] &, genes]}, {}]},
        PlotRange -> If[labeled, {{-5.6, Length[genes] + 0.6}, {-dy Length[rows] - 0.7, 2.9}}, All],
        PlotRangePadding -> If[labeled, 0, 0.7], ImageSize -> size]
];

images["AnalyzingSingleCellExpression"] := board[{
    panel["Cell groups", cellMap[320, True],
        grouped[Length[singleCell["cellType"]]] <> " blood cells after quality control, in UMAP coordinates and colored by marker-based label", 320],
    panel["Marker genes", markerDots[370, True],
        "Dot area is the share of cells with counts; color is mean log-scaled expression relative to the other groups.", 370]}];

(* ==================== protein conformations ==================== *)

protein = result["ComparingProteinConformations", #] &;
regionColor[] := protein["domainColor"] /@ protein["domains"];
inhibitorAtoms[] := Flatten[BioMoleculeValue[protein["closed"], "AtomCoordinateValues"]["C"], 1];
conformations[size_] := With[{colors = regionColor[]},
    Graphics3D[{Opacity[0.25], Tube[protein["aligned"], 0.6, VertexColors -> colors],
        Opacity[1], Tube[protein["ca"][[2]], 0.6, VertexColors -> colors], GrayLevel[0.15], Sphere[inhibitorAtoms[], 0.5]},
        Boxed -> False, Lighting -> "Neutral", ViewPoint -> {0.4, -2.6, 1.6}, ImageSize -> size]];
cartoon[size_] := Show[BioMoleculePlot3D[BioMoleculeValue[protein["closed"], "PolymerChains"]["A"]], ImageSize -> size];
(* closed minus open C-alpha distances; residue 1 at the top left, region strips along two edges *)
distanceChange[size_, labeled_ : False] := Module[{change = protein["distances"][[2]] - protein["distances"][[1]], n, colors, ticks},
    n = Length[change]; colors = regionColor[];
    ticks = Join[{1}, Range[50, n, 50]];
    Graphics[{
        Raster[Map[List @@ ColorData["ThermometerColors"][Rescale[#, {-25, 25}]] &, Reverse[change], {2}], {{0, 0}, {n, n}}],
        If[labeled, {
            MapIndexed[{#1, Rectangle[{First[#2] - 1, n + 3}, {First[#2], n + 9}], Rectangle[{-9, n - First[#2]}, {-3, n - First[#2] + 1}]} &, colors],
            Text[styled[ToString[#], 7, muted], {# - 0.5, 0}, {0, 1.4}] & /@ ticks,
            Text[styled["residue", 8, muted], {n/2, 0}, {0, 3.2}]}, {}]},
        PlotRange -> If[labeled, {{-10, n + 1}, {-26, n + 10}}, {{0, n}, {0, n}}], ImageSize -> size]
];
distanceLegend[] := BarLegend[{"ThermometerColors", {-25, 25}}, LegendLabel -> styled["\[CapitalARing]", 8, muted],
    LabelStyle -> Directive[FontFamily -> font, FontSize -> 7, muted], LegendMarkerSize -> {8, 150}];

images["ComparingProteinConformations"] := board[{
    panel["Open and closed", Column[{conformations[{340, 290}],
        swatches[{{"CORE", Gray}, {"NMP-binding", okabeIto[[1]]}, {"LID", okabeIto[[2]]}, {"Ap5A", GrayLevel[0.15]}}]}, Alignment -> Center],
        "4AKE, open and faint, superposed on 1AKE, closed and solid, by the CORE region; the inhibitor Ap5A is bound in 1AKE.", 340],
    panel["Distance change", Row[{distanceChange[290, True], distanceLegend[]}, "  "],
        "Change in C\[Alpha]\[Hyphen]C\[Alpha] distance, closed minus open; blue pairs are closer in the closed structure. Strips mark the regions.", 340]}];

(* ==================== bacterial genome ==================== *)

genome = result["ReadingBacterialGenomeComposition", #] &;
gcSkew[] := gcSkew[] = With[{skew = genome["skew"]}, skew[#, "G", "C"] & /@ StringPartition[genome["genome"], 10000]];
skewBars[skew_, length_] := MapIndexed[{If[#1 >= 0, okabeIto[[5]], okabeIto[[6]]],
    Rectangle[{(First[#2] - 1) 10.^-2, 0}, {Min[First[#2] 10.^-2, length], #1}]} &, skew];
(* GC skew in 10,000-base windows, with the bases around the estimated origin drawn as a helix *)
originView[size_] := Module[{sequence = genome["genome"], origin = genome["origin"]/10.^6, skew = gcSkew[], length, top, tick, bases, x0, x1, y0, amp, xs, turn, strand},
    length = StringLength[sequence]/10.^6; top = Max[Abs[skew]]; tick = 0.05 Floor[top/0.05];
    bases = Characters[StringTake[sequence, {genome["origin"] - 29, genome["origin"] + 30}]];
    {x0, x1} = origin + {-0.33, 0.33}; y0 = 2.1 top; amp = 0.45 top;
    xs = Subdivide[x0, x1, Length[bases] - 1];
    turn[x_] := amp Sin[2 Pi 2.5 (x - x0)/(x1 - x0)];
    strand[s_] := Table[{x, y0 + s turn[x]}, {x, x0, x1, (x1 - x0)/400}];
    Graphics[{
        skewBars[skew, length],
        {ink, AbsoluteThickness[1], Line[{{origin, -top}, {origin, 1.25 top}}]},
        Text[styled["origin", 8, ink], Offset[{-4, 0}, {origin, 1.08 top}], {1, 0}],
        {muted, AbsoluteThickness[0.7], AbsoluteDashing[{2, 2}], Line[{{origin, 1.25 top}, {x0, y0 - 1.3 amp}}], Line[{{origin, 1.25 top}, {x1, y0 - 1.3 amp}}]},
        MapThread[{baseColor[#2], AbsoluteThickness[2], Line[{{#1, y0 + turn[#1]}, {#1, y0 - turn[#1]}}]} &, {xs, bases}],
        {GrayLevel[0.6], AbsoluteThickness[1.6], Line[strand[1]], Line[strand[-1]]},
        Text[Row[Riffle[styled[#, 8, baseColor[#], Bold] & /@ {"A", "C", "G", "T"}, " "]], Offset[{-6, 0}, {x0, y0}], {1, 0}],
        axes[{0, length}, {{0, "0"}, {0.2, "0.2"}, {0.4, "0.4"}, {0.6, "0.6"}, {0.8, "0.8"}}, {-top, top},
            {{-tick, ToString[-tick]}, {0, "0"}, {tick, ToString[tick]}}, {None, "GC skew"}],
        Text[styled["position (Mb)", 8, muted], Offset[{0, -22}, {length, -top}], {1, 0}]},
        PlotRange -> {{0, length}, {-top, y0 + 1.3 amp}}, AspectRatio -> 0.6, ImagePadding -> {{38, 4}, {30, 4}},
        PlotRangeClipping -> False, ImageSize -> size]
];
wordFrequencies[size_, labeled_ : False] := Show[
    ArrayPlot[Log[1. + genome["wordGrid"][genome["genome"], 256]], DataReversed -> True, ColorFunction -> "SunsetColors", Frame -> False, PlotRangePadding -> 0],
    If[labeled, Graphics[MapThread[Text[styled[#1, 9, ink, Bold], #2] &, {{"A", "C", "T", "G"}, {{-8, -8}, {-8, 264}, {264, -8}, {264, 264}}}]], Graphics[{}]],
    PlotRange -> If[labeled, {{-16, 272}, {-16, 272}}, {{0, 256}, {0, 256}}], ImageSize -> size];

images["ReadingBacterialGenomeComposition"] := board[{
    panel["Strand asymmetry", originView[420],
        "GC skew, (G \[Minus] C)/(G + C), in 10,000-base windows changes sign at base " <> grouped[genome["origin"]] <>
            ", the minimum of cumulative G \[Minus] C and a compositional estimate of the replication origin. The helix shows the 60 bases centered there.", 420],
    panel["Sequence words", wordFrequencies[240, True],
        "Counts of all 65,536 eight-base words on a 256 \[Times] 256 grid, log scale; brighter cells are more frequent words, and A/T-rich words occupy the lower region.", 240]}];

(* ==================== coronaviruses ==================== *)

corona = result["ComparingCoronavirusGenomes", #] &;
sharedProfiles[] := sharedProfiles[] = With[{genomes = corona["genomes"], shared = corona["sharedWords"]},
    AssociationMap[shared[genomes["SARS-CoV-2"], genomes[#], 12, 300] &, {"RaTG13", "SARS-CoV"}]];
virusColor = <|"RaTG13" -> okabeIto[[6]], "SARS-CoV" -> okabeIto[[5]]|>;
wordSharing[size_] := Module[{genes = corona["genes"]["SARS-CoV-2"], profiles = sharedProfiles[], length = StringLength[corona["genomes"]["SARS-CoV-2"]]},
    Graphics[{
        MapIndexed[{GrayLevel[If[OddQ[First[#2]], 0.78, 0.87]], EdgeForm[White], Rectangle[{#1[[2, 1]], 1.12}, {#1[[2, 2]], 1.24}],
            If[#1[[2, 2]] - #1[[2, 1]] > 1200, Text[styled[#1[[1]], 7, ink], {Mean[#1[[2]]], 1.18}], {}]} &, List @@@ Normal[genes]],
        KeyValueMap[{#2, AbsoluteThickness[1.4], Line[profiles[#1]],
            Text[styled[#1, 8, #2], Offset[{5, 0}, {length, Mean[Take[profiles[#1], -6][[All, 2]]]}], {-1, 0}]} &, virusColor],
        axes[{0, length}, {{0, "0"}, {10000, "10"}, {20000, "20"}, {30000, "30"}}, {0, 1}, {{0, "0"}, {0.5, "0.5"}, {1, "1"}},
            {"SARS-CoV-2 position (kb)", "shared fraction"}]},
        PlotRange -> {{0, length}, {0, 1.25}}, AspectRatio -> 0.62, ImagePadding -> {{38, 50}, {30, 4}}, PlotRangeClipping -> False, ImageSize -> size]
];
(* log2 relative dinucleotide abundance: rows are base pairs, columns genomes; CG is outlined *)
dinucleotides[size_] := Module[{genomes = corona["genomes"], abundance = corona["relativeAbundance"], pairs = StringJoin /@ Tuples[{"A", "C", "G", "T"}, 2], values, cg},
    values = Log2[Outer[abundance, Values[genomes], pairs]];
    cg = First[FirstPosition[pairs, "CG"]];
    Graphics[{
        Table[{ColorData["ThermometerColors"][Rescale[values[[j, i]], {-1.5, 1.5}]], Rectangle[{j - 1, -i}, {j, 1 - i}]}, {i, Length[pairs]}, {j, Length[genomes]}],
        {FaceForm[], EdgeForm[Directive[ink, AbsoluteThickness[1.2]]], Rectangle[{0, -cg}, {Length[genomes], 1 - cg}]},
        MapIndexed[Text[styled[#1, 7], Offset[{-4, 0}, {0, 0.5 - First[#2]}], {1, 0}] &, pairs],
        MapIndexed[Text[styled[#1, 6.5], Offset[{0, 7}, {First[#2] - 0.5, 0}]] &, Keys[genomes]]},
        PlotRange -> {{0, Length[genomes]}, {-Length[pairs], 0}}, AspectRatio -> 1.7, ImagePadding -> {{20, 2}, {2, 14}},
        PlotRangeClipping -> False, ImageSize -> size]
];
dinucleotideLegend[] := BarLegend[{"ThermometerColors", {-1.5, 1.5}}, LegendLabel -> styled["log2", 8, muted],
    LabelStyle -> Directive[FontFamily -> font, FontSize -> 7, muted], LegendMarkerSize -> {8, 130}];
sharingTile[size_] := With[{profiles = sharedProfiles[], genes = corona["genes"]["SARS-CoV-2"]},
    Graphics[{MapIndexed[{GrayLevel[If[OddQ[First[#2]], 0.78, 0.87]], EdgeForm[White], Rectangle[{#1[[1]], 1.1}, {#1[[2]], 1.2}]} &, Values[genes]],
        KeyValueMap[{#2, AbsoluteThickness[1.3], Line[profiles[#1]]} &, virusColor]},
        AspectRatio -> 1, PlotRange -> {{0, StringLength[corona["genomes"]["SARS-CoV-2"]]}, {0, 1.2}}, PlotRangePadding -> Scaled[0.04], ImageSize -> size]];

images["ComparingCoronavirusGenomes"] := board[{
    panel["Shared sequence words", wordSharing[430],
        "Fraction of the 12-letter words in each 300-base SARS-CoV-2 window found anywhere in the other genome; gray boxes mark SARS-CoV-2 genes. This is not percentage identity.", 430],
    panel["Dinucleotides", Row[{dinucleotides[160], dinucleotideLegend[]}, " "],
        "Relative abundance of each base pair; CG is depleted in all three genomes.", 230]}];

(* ==================== circadian rhythms ==================== *)

circadian = result["FindingCircadianRhythms", #] &;
clockGenes = {"Arntl", "Nr1d1", "Dbp", "Per2", "Cry1"};
nightBands[{y0_, y1_}] := {GrayLevel[0.93], Rectangle[{Max[#, 18], y0}, {Min[# + 12, 65], y1}] & /@ {12, 36, 60}};
(* standardized observations and fitted 24-hour cosines for each clock gene *)
clockWaves[size_, labeled_ : False] := Module[{times = circadian["times"], expressed = circadian["expressed"], probeFor = circadian["probeFor"],
        fitted = circadian["fitted"], peak = circadian["rhythm"]["Peak"], colors = AssociationThread[clockGenes, okabeIto[[{1, 2, 3, 5, 6}]]]},
    Graphics[{
        nightBands[{-2.6, 2.6}],
        KeyValueMap[Function[{gene, color}, With[{i = probeFor[gene]}, With[{m = Mean[expressed[[i]]], s = StandardDeviation[expressed[[i]]]}, {
            color, Opacity[0.6], Disk[#, {0.35, 0.07}] & /@ Transpose[{times, (expressed[[i]] - m)/s}],
            Opacity[1], AbsoluteThickness[1.6], Line[Table[{t, (fitted[i, t] - m)/s}, {t, 18, 65, 0.25}]],
            If[labeled, With[{t = SelectFirst[peak[[i]] + 24 Range[0, 3], 21 <= # <= 62 &]}, Text[styled[gene, 8, color, Bold], {t, (fitted[i, t] - m)/s + 0.32}]], {}]}]]],
            colors],
        If[labeled, axes[{18, 65}, {#, ToString[#]} & /@ {18, 24, 36, 48, 60}, {-2.6, 2.6}, {{-2, "\[Minus]2"}, {0, "0"}, {2, "2"}},
            {"circadian time (hours)", "standardized log2 signal"}], {}]},
        PlotRange -> {{18, 65}, {-2.6, 2.6}}, AspectRatio -> If[labeled, 0.72, 1], PlotRangeClipping -> False,
        ImagePadding -> If[labeled, {{36, 4}, {30, 4}}, Automatic], ImageSize -> size]
];
(* strong rhythms ordered by fitted peak time; each probe set standardized *)
strongRhythms[] := strongRhythms[] = With[{rhythm = circadian["rhythm"]},
    SortBy[Select[circadian["rhythmic"], rhythm["Amplitude"][[#]] >= 1/2 &], rhythm["Peak"][[#]] &]];
phaseMap[size_] := Module[{order = strongRhythms[], values},
    values = Clip[Standardize /@ circadian["expressed"][[order]], {-2.5, 2.5}];
    Graphics[{
        Raster[Map[List @@ ColorData["ThermometerColors"][Rescale[#, {-2.5, 2.5}]] &, Reverse[values], {2}], {{17.5, 0}, {65.5, Length[order]}}],
        nightBands[{Length[order] + 2, Length[order] + 5}] /. Rectangle[{a_, b_}, {c_, d_}] :> Rectangle[{a - 0.5, b}, {c + 0.5, d}],
        Text[styled["night", 7, muted], Offset[{-4, 0}, {17.5, Length[order] + 3.5}], {1, 0}],
        Text[styled["probe sets by peak time", 8, muted], Offset[{-10, 0}, {17.5, Length[order]/2}], {0, 0}, {0, 1}],
        Text[styled[ToString[#], 7, muted], Offset[{0, -9}, {#, 0}]] & /@ {18, 24, 36, 48, 60},
        Text[styled["circadian time (hours)", 8, muted], Offset[{0, -21}, {41.5, 0}]]},
        PlotRange -> {{17.5, 65.5}, {0, Length[order] + 5}}, AspectRatio -> 1, ImagePadding -> {{26, 4}, {28, 4}},
        PlotRangeClipping -> False, ImageSize -> size]
];

images["FindingCircadianRhythms"] := board[{
    panel["Clock genes", clockWaves[360, True],
        "Standardized log2 signal, points, and fitted 24-hour cosines, lines, for five clock genes; gray bands mark subjective night.", 360],
    panel["Rhythmic probe sets", phaseMap[300],
        grouped[Length[circadian["rhythmic"]]] <> " of " <> grouped[Length[circadian["expressed"]]] <> " expressed probe sets pass q < 0.05 and a 1.5-fold peak-to-trough ratio. The " <>
            grouped[Length[strongRhythms[]]] <> " with at least twofold are ordered by fitted peak; color is standardized signal, and gray bars mark subjective night.", 300]}];

(* ==================== guides ==================== *)

(* the BioDataLink mark: two interlocking links, the left one redrawn over the upper crossing *)
stadium[c_, a_, r_] := With[{points = Table[c + If[t < Pi, {a, 0} + r {Sin[t], -Cos[t]}, {-a, 0} + r {-Sin[t - Pi], Cos[t - Pi]}],
        {t, 0, 2 Pi, 2 Pi/240}]},
    Append[points, First[points]]];
mark[c_, s_, thickness_ : 6] := With[{left = stadium[c + s {-0.42, 0}, 0.36 s, 0.25 s], right = stadium[c + s {0.42, 0}, 0.36 s, 0.25 s]},
    {CapForm["Round"], JoinForm["Round"], AbsoluteThickness[thickness], okabeIto[[5]], Line[left], okabeIto[[6]], Line[right],
        okabeIto[[5]], Line[Select[left, #[[1]] > c[[1]] && #[[2]] > c[[2]] &]]}];
tile[g_, name_, size_] := Rasterize[Column[{framed[Show[g, ImageSize -> {size, size}]], styled[name, 9, ink, Bold]}, Alignment -> Center, Spacings -> 0.4],
    ImageResolution -> 144, Background -> White];
views[size_] := {
    {cellMap[size], "Single cells"}, {markerDots[size], "Marker genes"}, {cartoon[size], "Protein structures"}, {conformations[size], "Conformations"},
    {wordFrequencies[size], "Sequence words"}, {Graphics[skewBars[gcSkew[], StringLength[genome["genome"]]/10.^6], AspectRatio -> 1, ImageSize -> size], "Strand asymmetry"},
    {sharingTile[size], "Viral genomes"}, {clockWaves[size], "Rhythms"}};

(* the main guide: the kinds of data in the tutorials, linked to the BioDataLink mark *)
images["BioDataLink"] := Module[{positions = {{-2.55, 0}, {-1.6, 1.05}, {0, 1.05}, {1.6, 1.05}, {2.55, 0}, {1.6, -1.05}, {0, -1.05}, {-1.6, -1.05}}},
    Graphics[{
        {GrayLevel[0.8], AbsoluteThickness[1.2], Line[{{0, 0}, #}] & /@ positions},
        {White, EdgeForm[Directive[rule, AbsoluteThickness[1]]], Disk[{0, 0}, {0.74, 0.38}]},
        mark[{0, 0.08}, 0.6, 5],
        Text[styled["BioDataLink", 12, ink, Bold], {0, -0.2}],
        MapThread[Inset[tile[#1[[1]], #1[[2]], 92], #2, Center, 0.98] &, {views[92][[{1, 3, 5, 7, 8, 2, 4, 6}]], positions}]},
        PlotRange -> {{-3.15, 3.15}, {-1.72, 1.72}}, ImageSize -> 720, Background -> White]
];

(* the explorations guide: one labeled view from each real-data tutorial *)
images["ComputationalExplorations"] := With[{size = 150, cells = grouped[Length[singleCell["cellType"]]]},
    Grid[Partition[MapThread[Column[{framed[Show[#1, ImageSize -> {size, size}]], styled[#2, 10, ink, Bold], note[#3, size + 10, 8]}, Spacings -> 0.35] &,
        {views[size][[All, 1]], views[size][[All, 2]], {
            cells <> " blood cells, grouped by shared neighbors and named by marker genes",
            "12 marker genes across 8 groups; dot area is the share of cells with counts",
            "adenylate kinase in the closed structure, PDB 1AKE, chain A",
            "open 4AKE, faint, and closed 1AKE, solid, superposed by the CORE region",
            "eight-letter word frequencies in the Borrelia burgdorferi chromosome",
            "GC skew in 10,000-base windows changes sign near the estimated replication origin",
            "12-letter words shared along SARS-CoV-2: more with RaTG13, red, than with SARS-CoV, blue",
            "five clock genes in mouse liver, sampled hourly for 48 hours"}}], 4],
        Spacings -> {1.6, 1.4}, Alignment -> {Left, Top}, Background -> White]];

(* ==================== resource page ==================== *)

(* Active Identifiers.org namespaces as a word cloud around the mark. Word size grows with a
   namespace's registered access endpoints; color marks a subject domain matched by keywords, tried
   in order on the name and prefix, then on the description. *)
domains = {
    "Disease & phenotype" -> "disease|phenotyp|clinical|patient|cancer|\\btraits?\\b",
    "Chemicals & drugs" -> "chemical|compound|metabolit|\\bdrugs?\\b|ligand|lipid|glycan|small molecule",
    "Proteins & structures" -> "protein|structur|enzyme|antibod|peptide",
    "Genes & genomes" -> "\\bgenes?\\b|genom|sequenc|nucleotide|\\bdna\\b|\\brna\\b|transcript|\\bvariants?\\b|\\bsnps?\\b|chromosom",
    "Pathways & interactions" -> "pathway|interaction|reaction",
    "Organisms & biodiversity" -> "taxonom|species|organism|strain|biodivers|specimen|\\bplants?\\b|microb|fung|animal",
    "Cells, tissues & samples" -> "\\bcells?\\b|tissue|\\bsamples?\\b|anatom|imag|assay|experiment|expression",
    "Ontologies & literature" -> "ontolog|vocabular|terminolog|literature|publication|article"};
domainPalette = AssociationThread[Append[Keys[domains], "Other sources"], Append[Take[tolMuted, 8], GrayLevel[0.6]]];
keywordDomain[words_String] := First[SelectFirst[domains, StringContainsQ[ToLowerCase[words], RegularExpression[Last[#]]] &, {None}]];
keywordDomain[_] := None;
domain[source_Association] := Replace[keywordDomain[source["Name"] <> " " <> source["Prefix"]],
    None :> Replace[keywordDomain[source["Description"]], None -> "Other sources"]];

images["Hero"] := Module[{sources = Normal[BioDataSourceSearch[]], counts, ring, cloud, legend},
    If[!MatchQ[sources, {__Association}], fail["no active namespaces in the bundled source directory"]];
    counts = Counts[domain /@ sources];
    (* the words fill the white ring of the mask and leave its center for the mark *)
    ring = Rasterize[Graphics[{White, Disk[{0, 0}, {1.9, 1}], Black, Disk[{0, 0}, {0.88, 0.46}]},
        PlotRange -> {{-1.9, 1.9}, {-1, 1}}, Background -> Black, ImageSize -> 1900], ImageSize -> 1900];
    cloud = Rasterize[WordCloud[Association[Style[#Prefix, domainPalette[domain[#]]] -> #ResourceCount^1.6 & /@ sources], ring,
        FontFamily -> font, WordOrientation -> {{0}, {Pi/2}}, RandomSeeding -> 4, ImageSize -> 1140, AspectRatio -> 1/1.9],
        ImageResolution -> 144, Background -> White];
    legend = Grid[Partition[KeyValueMap[Row[{Graphics[{#2, Disk[]}, ImageSize -> 10], " ", styled[#1, 11],
        styled[" " <> ToString[Lookup[counts, #1, 0]], 11, GrayLevel[0.5]]}] &, domainPalette], UpTo[5]], Alignment -> Left, Spacings -> {2.5, 0.8}];
    Column[{
        Graphics[{Inset[cloud, {0, 0}, Center, 3.8], mark[{0, 0.07}, 0.5], Text[styled["BioDataLink", 15, ink, Bold], {0, -0.17}]},
            PlotRange -> {{-1.9, 1.9}, {-1, 1}}, ImageSize -> 1140],
        legend,
        Pane[styled["prefixes from the " <> ToString[Length[sources]] <> " active namespaces in the bundled Identifiers.org directory; " <>
            "word size grows with the number of registered access endpoints, and color marks a keyword-based domain", 9, GrayLevel[0.45]],
            ImageSize -> {760, Automatic}]},
        Alignment -> Center, Spacings -> 1, Background -> White]
];

(* ==================== output ==================== *)

imageNames = {"Hero", "BioDataLink", "ComputationalExplorations", "AnalyzingSingleCellExpression", "ComparingCoronavirusGenomes",
    "ComparingProteinConformations", "FindingCircadianRhythms", "ReadingBacterialGenomeComposition"};
target[name_] := If[name === "Hero", FileNameJoin[{root, "docs", "Hero.png"}], FileNameJoin[{root, "docs", "en", "Images", name <> ".png"}]];
(* PNG files record their creation time, so an unchanged image is left as it is. *)
write[name_] := Module[{file = target[name], image},
    image = UsingFrontEnd[Rasterize[images[name], ImageResolution -> 144]];
    If[!ImageQ[image], fail["could not render " <> name]];
    Which[
        FileExistsQ[file] && ImageData[Import[file], "Byte"] === ImageData[image, "Byte"], Print["Unchanged ", file],
        StringQ[Export[file, image, "PNG"]], Print["Wrote ", file, ": ", ImageDimensions[image], " pixels"],
        True, fail["could not write " <> file]]
];
names = Replace[Rest[$ScriptCommandLine], {} -> imageNames];
If[!SubsetQ[imageNames, names], fail["unknown image: " <> StringRiffle[Complement[names, imageNames], ", "]]];
Scan[write, names];
