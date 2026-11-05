#!/usr/bin/env wolframscript
(* Rebuild docs/Hero.png, the image on the paclet's resource page: the active namespaces of the
   bundled Identifiers.org directory as a word cloud around the BioDataLink mark. Word size grows
   with a namespace's registered access endpoints; color marks a subject domain matched by
   keywords. Offline. Rerun after make sources-update changes the directory. *)
root = DirectoryName[$InputFileName, 2];
PacletDirectoryLoad[FileNameJoin[{root, "BioDataLink"}]];
Needs["WolframInstitute`BioDataLink`"];
target = FileNameJoin[{root, "docs", "Hero.png"}];
fail[text_] := (Print["ERROR: ", text]; Exit[1]);

(* Domain keywords, tried in order on the name and prefix, then on the description. *)
domains = {
    "Disease & phenotype" -> "disease|phenotyp|clinical|patient|cancer|\\btraits?\\b",
    "Chemicals & drugs" -> "chemical|compound|metabolit|\\bdrugs?\\b|ligand|lipid|glycan|small molecule",
    "Proteins & structures" -> "protein|structur|enzyme|antibod|peptide",
    "Genes & genomes" -> "\\bgenes?\\b|genom|sequenc|nucleotide|\\bdna\\b|\\brna\\b|transcript|\\bvariants?\\b|\\bsnps?\\b|chromosom",
    "Pathways & interactions" -> "pathway|interaction|reaction",
    "Organisms & biodiversity" -> "taxonom|species|organism|strain|biodivers|specimen|\\bplants?\\b|microb|fung|animal",
    "Cells, tissues & samples" -> "\\bcells?\\b|tissue|\\bsamples?\\b|anatom|imag|assay|experiment|expression",
    "Ontologies & literature" -> "ontolog|vocabular|terminolog|literature|publication|article"};
(* Paul Tol's muted scheme for the eight domains, gray for the rest *)
palette = AssociationThread[Append[Keys[domains], "Other sources"], Append[
    RGBColor /@ {"#CC6677", "#332288", "#DDCC77", "#117733", "#88CCEE", "#882255", "#44AA99", "#999933"}, GrayLevel[0.6]]];
keywordDomain[words_String] := First[SelectFirst[domains, StringContainsQ[ToLowerCase[words], RegularExpression[Last[#]]] &, {None}]];
keywordDomain[_] := None;
domain[source_Association] := Replace[keywordDomain[source["Name"] <> " " <> source["Prefix"]],
    None :> Replace[keywordDomain[source["Description"]], None -> "Other sources"]];

sources = Normal[BioDataSourceSearch[]];
If[!MatchQ[sources, {__Association}], fail["no active namespaces in the bundled source directory"]];
counts = Counts[domain /@ sources];

(* The mark: two interlocking stadium-shaped links, the left one redrawn over the upper crossing. *)
stadium[c_, a_, r_] := With[{points = Table[c + If[t < Pi, {a, 0} + r {Sin[t], -Cos[t]}, {-a, 0} + r {-Sin[t - Pi], Cos[t - Pi]}],
        {t, 0, 2 Pi, 2 Pi/240}]},
    Append[points, First[points]]];
mark[c_, s_] := With[{left = stadium[c + s {-0.42, 0}, 0.36 s, 0.25 s], right = stadium[c + s {0.42, 0}, 0.36 s, 0.25 s],
        blue = RGBColor["#0072B2"], vermillion = RGBColor["#D55E00"]},
    {CapForm["Round"], JoinForm["Round"], AbsoluteThickness[6], blue, Line[left], vermillion, Line[right],
        blue, Line[Select[left, #[[1]] > c[[1]] && #[[2]] > c[[2]] &]]}];

styled[s_, size_, color_, weight_ : Plain] := Style[s, FontFamily -> "Helvetica", FontSize -> size, FontColor -> color, FontWeight -> weight];
(* The words fill the white ring of the mask and leave its center for the mark. *)
ring = Rasterize[Graphics[{White, Disk[{0, 0}, {1.9, 1}], Black, Disk[{0, 0}, {0.88, 0.46}]},
    PlotRange -> {{-1.9, 1.9}, {-1, 1}}, Background -> Black, ImageSize -> 1900], ImageSize -> 1900];
cloud = Rasterize[WordCloud[Association[Style[#Prefix, palette[domain[#]]] -> #ResourceCount^1.6 & /@ sources], ring,
    FontFamily -> "Helvetica", WordOrientation -> {{0}, {Pi/2}}, RandomSeeding -> 4, ImageSize -> 1140, AspectRatio -> 1/1.9],
    ImageResolution -> 144, Background -> White];
legend = Grid[Partition[KeyValueMap[Row[{Graphics[{#2, Disk[]}, ImageSize -> 10], " ", styled[#1, 11, GrayLevel[0.2]],
    styled[" " <> ToString[Lookup[counts, #1, 0]], 11, GrayLevel[0.5]]}] &, palette], UpTo[5]], Alignment -> Left, Spacings -> {2.5, 0.8}];
caption = Pane[styled["prefixes from the " <> ToString[Length[sources]] <> " active namespaces in the bundled Identifiers.org directory; " <>
    "word size grows with the number of registered access endpoints, and color marks a keyword-based domain", 9, GrayLevel[0.45]],
    ImageSize -> {760, Automatic}];
hero = Column[{
    Graphics[{Inset[cloud, {0, 0}, Center, 3.8], mark[{0, 0.07}, 0.5], Text[styled["BioDataLink", 15, GrayLevel[0.2], Bold], {0, -0.17}]},
        PlotRange -> {{-1.9, 1.9}, {-1, 1}}, ImageSize -> 1140],
    legend, caption}, Alignment -> Center, Spacings -> 1, Background -> White];

(* PNG files record their creation time, so an unchanged image is left as it is. *)
image = UsingFrontEnd[Rasterize[hero, ImageResolution -> 144]];
If[!ImageQ[image], fail["could not render the image"]];
Which[
    FileExistsQ[target] && ImageData[Import[target], "Byte"] === ImageData[image, "Byte"], Print["Unchanged ", target],
    StringQ[Export[target, image, "PNG"]], Print["Wrote ", target, ": ", ImageDimensions[image], " pixels"],
    True, fail["could not write " <> target]];
Print[Length[sources], " namespaces: ", ReverseSort[counts]];
