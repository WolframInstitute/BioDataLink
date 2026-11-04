#!/usr/bin/env wolframscript
(* Rebuild the real-data example assets from pinned public files. Maintainer use
   only: requires network access and curl 8.4 or later (set BIODATALINK_CURL to
   choose an executable). Documentation builds and tests read the committed
   assets and never run this script. Usage: exampleData.wls [Name ...] *)
root = DirectoryName[$InputFileName, 2];
PacletDirectoryLoad[FileNameJoin[{root, "BioDataLink"}]];
Needs["WolframInstitute`BioDataLink`"];
examples = FileNameJoin[{root, "BioDataLink", "Assets", "Examples"}];
work = CreateDirectory[];
curl = Replace[Environment["BIODATALINK_CURL"], $Failed -> Automatic];
fail[text_] := (Print["ERROR: ", text]; Exit[1]);
ncbiDisclaimer = "NCBI places no restrictions on the use or distribution of GenBank, RefSeq or GEO data; submitters may claim rights in submitted data. See https://www.ncbi.nlm.nih.gov/home/about/policies/";

(* {URL, local name, SHA-256, bytes}; hashes were computed from files retrieved on 2026-11-04. *)
efetch[id_] := "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=" <> id <> "&rettype=fasta&retmode=text";
gff3[id_] := "https://www.ncbi.nlm.nih.gov/sviewer/viewer.cgi?db=nuccore&report=gff3&id=" <> id <> "&retmode=text";
sources = <|
    "PBMC3k" -> {{"https://cf.10xgenomics.com/samples/cell-exp/1.1.0/pbmc3k/pbmc3k_filtered_gene_bc_matrices.tar.gz",
        "pbmc3k_filtered_gene_bc_matrices.tar.gz", "847d6ebd9a1ec9a768f2be7e40ca42cbfe75ebeb6d76a4c24167041699dc28b5", 7621991}},
    "AdenylateKinase" -> {
        {"https://files.rcsb.org/download/4AKE.pdb", "4AKE.pdb", "ff798ee8791878eb58bac1c6bed32042f51b455512ac93b50bda8fa0ff0e7f78", 309339},
        {"https://files.rcsb.org/download/1AKE.pdb", "1AKE.pdb", "651e952f55f1317f50f4e82b7f0e99053397032cd8da5b2896f79d0af9f619a9", 357777}},
    "BorreliaB31" -> {
        {efetch["NC_001318.1"], "NC_001318.1.fasta", "fe3ef476bc7ce076bc388a08162440de10163f49272b0c4f2d2030dfce5ddfae", 923796},
        {gff3["NC_001318.1"], "NC_001318.1.gff3", "d4f774c31a316e7303fb06d038bf663c1e2b66683b4afadadd7d12d4249c960a", 524379}},
    "Coronaviruses" -> {
        {efetch["NC_045512.2"], "NC_045512.2.fasta", "0891c00cc2d503f58e0c600ce5ee64e9c64b939525c70d5486bc46cbc7cb073e", 30429},
        {gff3["NC_045512.2"], "NC_045512.2.gff3", "854bd3e750ccb9a9896a7a4ca1fff66e19e5b6ee07e8bd690d8f994365ec3a63", 14704},
        {efetch["MN996532.2"], "MN996532.2.fasta", "7720fcebd0748fccf231427898517db2066c5c8b46df92776746cab7c2905408", 30335},
        {gff3["MN996532.2"], "MN996532.2.gff3", "69690a431240d14938a23ab5d47d1a002783b8ef3bf163f9e7aae74ad4992390", 3706},
        {efetch["NC_004718.3"], "NC_004718.3.fasta", "af5dd09ebdeafae86b6d431cfc8f57091e0a61bafccaba442ab8baf4e3a93981", 30230},
        {gff3["NC_004718.3"], "NC_004718.3.gff3", "460e968bce0090d22a789fdb934938b45e83d548c3dfa02ebdb4ad66e3d0d694", 11311}},
    "LiverCircadian" -> {
        {"https://ftp.ncbi.nlm.nih.gov/geo/series/GSE11nnn/GSE11923/matrix/GSE11923_series_matrix.txt.gz",
            "GSE11923_series_matrix.txt.gz", "2dd9f79ce8562155e003e43984e49b1ed8d190f4ac197f6d612274d21eab39ab", 4753724},
        {"https://ftp.ncbi.nlm.nih.gov/geo/platforms/GPL1nnn/GPL1261/annot/GPL1261.annot.gz",
            "GPL1261.annot.gz", "394c103cf4ca99500d06369e4fb2b9b9bffc2c10fd3cbeb0b0d64c51c3fc95f8", 8389179}}
|>;

fetch[{url_, name_, sha_, bytes_}] := Module[{result},
    Pause[0.5]; (* stay well inside NCBI's request-rate guidance *)
    result = BioDatasetDownload[url, File[FileNameJoin[{work, name}]], "ExpectedSHA256" -> sha,
        "ExpectedByteCount" -> bytes, "MaxFileBytes" -> 50000000, "TimeConstraint" -> 600, "CurlExecutable" -> curl];
    If[FailureQ[result], fail[{url, result}]];
    <|"SourceURL" -> url, "File" -> name, "SHA256" -> sha, "ByteCount" -> bytes, "RetrievedAt" -> result["RetrievedAt"]|>
];
datasetDirectory[name_] := With[{dir = FileNameJoin[{examples, name}]},
    If[!DirectoryQ[dir], CreateDirectory[dir]]; dir];
gzipCopy[record_, dir_] := Module[{target = FileNameJoin[{dir, record["File"] <> ".gz"}]},
    Export[target, ReadByteArray[FileNameJoin[{work, record["File"]}]], {"GZIP", "Binary"}];
    Append[record, "LocalFile" -> FileNameTake[target]]];
json[expr_, compactQ_] := StringReplace[ExportString[expr, "RawJSON", "Compact" -> compactQ], "\\/" -> "/"];
writeProvenance[dir_, record_] := Export[FileNameJoin[{dir, "provenance.json"}], json[record, False] <> "\n", "Text"];
compact[expr_] := json[expr, True];

(* Analytic Pearson residuals (Lause, Berens and Kobak 2021): theta 100, clipped at Sqrt[cells]. *)
residualVariance[counts_, totals_] := Module[{geneTotals = Normal[Total[counts]], clip = Sqrt[N[Length[totals]]], genes},
    genes = Flatten[Position[geneTotals, _?Positive]];
    AssociationThread[genes, Flatten[Table[
        With[{mu = Outer[Times, N[totals], geneTotals[[chunk]]/Total[totals]]},
            Variance[Clip[(Normal[counts[[All, chunk]]] - mu)/Sqrt[mu + mu^2/100], {-clip, clip}]]],
        {chunk, Partition[genes, UpTo[2000]]}]]]];

buildPBMC3k[] := Module[{record, dir, matrixDir, counts, genes, barcodes, symbols, totals, detected, mito, keep,
        variances, variable, markerSymbols, markers, background, selected, cells, geneRows, rules, provenance},
    record = fetch[First[sources["PBMC3k"]]];
    ExtractArchive[FileNameJoin[{work, record["File"]}], work];
    matrixDir = FileNameJoin[{work, "filtered_gene_bc_matrices", "hg19"}];
    counts = Round[Transpose[Import[FileNameJoin[{matrixDir, "matrix.mtx"}], "MTX"]]];
    genes = Import[FileNameJoin[{matrixDir, "genes.tsv"}], "TSV"];
    barcodes = Flatten[Import[FileNameJoin[{matrixDir, "barcodes.tsv"}], "TSV"]];
    If[Dimensions[counts] =!= {Length[barcodes], Length[genes]}, fail["PBMC3k matrix and axis lengths differ"]];
    symbols = genes[[All, 2]];
    totals = Normal[Total[counts, {2}]];
    detected = Normal[Total[Unitize[counts], {2}]];
    mito = Flatten[Position[symbols, s_String /; StringStartsQ[s, "MT-"]]];
    (* Same thresholds as the tutorial: 200-2500 detected genes and under 5% mitochondrial counts. *)
    keep = Flatten[Position[MapThread[200 <= #1 <= 2500 && #2 < 0.05 &,
        {detected, Normal[Total[counts[[All, mito]], {2}]]/totals}], True]];
    variances = residualVariance[counts[[keep]], totals[[keep]]];
    variable = Take[Keys[ReverseSort[variances]], 300];
    markerSymbols = {"CCR7", "CD14", "CD3E", "CD8A", "CST3", "FCER1A", "FCGR3A", "GNLY", "IL7R", "LYZ",
        "MS4A1", "MS4A7", "NKG7", "PPBP", "S100A4"};
    markers = Flatten[Position[symbols, #] & /@ markerSymbols];
    If[Length[markers] =!= Length[markerSymbols], fail["a PBMC3k marker symbol is absent or duplicated"]];
    background = BlockRandom[SeedRandom[20261104];
        RandomSample[Flatten[Position[Normal[Total[Unitize[counts]]], c_ /; c >= 3]], 200]];
    selected = Union[variable, markers, mito, background];
    cells = MapThread[<|"ID" -> #1, "SourceTotalCounts" -> #2, "SourceGenesDetected" -> #3|> &, {barcodes, totals, detected}];
    geneRows = <|"ID" -> genes[[#, 1]], "Symbol" -> symbols[[#]], "SourceIndex" -> #,
        "HighlyVariable" -> MemberQ[variable, #], "Marker" -> MemberQ[markers, #],
        "Mitochondrial" -> MemberQ[mito, #], "Background" -> MemberQ[background, #]|> & /@ selected;
    rules = SortBy[Most[ArrayRules[counts[[All, selected]]]], First];
    provenance = <|"Source" -> "10x Genomics: 3k PBMCs from a Healthy Donor, Cell Ranger 1.1.0 filtered gene-barcode matrix (hg19)",
        "Citation" -> "10x Genomics (2016). 3k PBMCs from a Healthy Donor [Dataset]. https://www.10xgenomics.com/datasets/3-k-pbm-cs-from-a-healthy-donor-1-standard-1-1-0",
        "License" -> "CC BY 4.0", "SourceURL" -> record["SourceURL"], "SourceSHA256" -> record["SHA256"],
        "RetrievedAt" -> record["RetrievedAt"], "Synthetic" -> False,
        "Selection" -> "All 2700 barcodes; genes are the union of the 300 highest Pearson-residual variances over cells passing the tutorial QC thresholds, 15 listed markers, 13 MT- genes and 200 genes sampled with seed 20261104 among genes detected in at least 3 barcodes. Counts are unchanged."|>;
    dir = datasetDirectory["PBMC3k"];
    Export[FileNameJoin[{dir, "pbmc3k-subset.json"}], StringJoin[
        "{\n\"SchemaVersion\": 1,\n\"Shape\": ", compact[{Length[barcodes], Length[selected]}],
        ",\n\"Normalization\": \"Counts\",\n\"Provenance\": ", compact[provenance],
        ",\n\"Cells\": [\n", StringRiffle[compact /@ cells, ",\n"],
        "\n],\n\"Genes\": [\n", StringRiffle[compact /@ geneRows, ",\n"],
        "\n],\n\"Entries\": [\n", StringRiffle[(compact[Append[#[[1]], #[[2]]]] &) /@ rules, ",\n"], "\n]\n}\n"], "Text"];
    Print["PBMC3k: ", Length[barcodes], " cells, ", Length[selected], " genes, ", Length[rules], " entries"]
];

buildCopies[name_, record_] := Module[{dir = datasetDirectory[name]},
    writeProvenance[dir, Join[record, <|"Files" -> (gzipCopy[fetch[#], dir] & /@ sources[name]),
        "Transformations" -> {"Each upstream file is stored gzip-compressed; decompressed bytes match the recorded SHA-256."}|>]];
    Print[name, ": ", Length[sources[name]], " files"]
];

buildLiverCircadian[] := Module[{matrixRecord, annotationRecord, lines, header, table, annotation, symbols,
        clockGenes, clockProbes, otherProbes, sampled, rows, dir},
    {matrixRecord, annotationRecord} = fetch /@ sources["LiverCircadian"];
    lines = Import[FileNameJoin[{work, matrixRecord["File"]}], "Lines"];
    table = Take[lines, {First[FirstPosition[lines, "!series_matrix_table_begin"]] + 1,
        First[FirstPosition[lines, "!series_matrix_table_end"]] - 1}];
    {header, table} = {StringSplit[First[table], "\t"], StringSplit[#, "\t", All] & /@ Rest[table]};
    If[Length[header] =!= 49 || !AllTrue[table, Length[#] === 49 &], fail["unexpected GSE11923 table shape"]];
    lines = Import[FileNameJoin[{work, annotationRecord["File"]}], "Lines"];
    annotation = StringSplit[#, "\t", All] & /@ Take[lines, {First[FirstPosition[lines, "!platform_table_begin"]] + 2,
        First[FirstPosition[lines, "!platform_table_end"]] - 1}];
    symbols = AssociationThread[annotation[[All, 1]], annotation[[All, 3]]];
    clockGenes = {"Arntl", "Bhlhe40", "Bhlhe41", "Ciart", "Clock", "Cry1", "Cry2", "Dbp", "Hlf", "Nfil3",
        "Npas2", "Nr1d1", "Nr1d2", "Per1", "Per2", "Per3", "Rora", "Rorc", "Tef"};
    rows = {StringTrim[#[[1]], "\""], Lookup[symbols, StringTrim[#[[1]], "\""], ""], Sequence @@ Rest[#]} & /@ table;
    clockProbes = Select[rows, MemberQ[clockGenes, #[[2]]] &];
    otherProbes = Select[rows, !MemberQ[clockGenes, #[[2]]] && !StringStartsQ[#[[1]], "AFFX"] &];
    sampled = BlockRandom[SeedRandom[20261104]; RandomSample[otherProbes, 2000]];
    rows = SortBy[Join[clockProbes, sampled], First];
    dir = datasetDirectory["LiverCircadian"];
    Export[FileNameJoin[{dir, "GSE11923-liver-subset.tsv.gz"}], StringRiffle[StringRiffle[#, "\t"] & /@ Prepend[rows,
        Join[{"ProbeID", "Symbol"}, "CT" <> ToString[#] & /@ Range[18, 65]]], "\n"] <> "\n", {"GZIP", "Text"}];
    writeProvenance[dir, <|"Title" -> "High-temporal resolution profiling of mouse liver (GEO GSE11923)",
        "Citation" -> "Hughes ME, DiTacchio L, Hayes KR, Vollmers C, Pulivarthy S, Baggs JE, Panda S, Hogenesch JB (2009). Harmonics of circadian gene transcription in mammals. PLoS Genetics 5(4): e1000442. https://doi.org/10.1371/journal.pgen.1000442",
        "Accession" -> "GSE11923", "Platform" -> "GPL1261", "License" -> ncbiDisclaimer,
        "Files" -> {matrixRecord, annotationRecord}, "LocalFile" -> "GSE11923-liver-subset.tsv.gz",
        "Design" -> "Male C57BL/6J mouse liver sampled hourly from CT18 to CT65 in constant darkness; each time point pools 3-5 mice and is hybridized to one Affymetrix Mouse 430 2.0 array.",
        "Values" -> "MAS5 signal values copied verbatim from the GEO series matrix; its sample data_processing fields specify Affymetrix Microarray Suite 5.0 expression quantitation. No transformation applied to the bundled values.",
        "PublishedAnalysis" -> "The paper reports GCRMA expression estimates and MAS5 present/absent calls. This subset preserves the deposited MAS5 matrix; it is not a reproduction of the paper's processed analysis.",
        "Transformations" -> {"Kept every probe annotated to " <> StringRiffle[clockGenes, ", "] <> " in GPL1261.annot.",
            "Added 2000 probes sampled with seed 20261104 from the remaining non-AFFX probes.",
            "Rows sorted by probe ID; gene symbols taken from GPL1261.annot; blank symbols mean no annotation."}|>];
    Print["LiverCircadian: ", Length[rows], " probes (", Length[clockProbes], " clock-gene probes)"]
];

metadata = <|
    "AdenylateKinase" -> <|"Title" -> "Escherichia coli adenylate kinase, open (4AKE) and Ap5A-bound closed (1AKE) crystal structures",
        "Citation" -> {"Muller CW, Schlauderer GJ, Reinstein J, Schulz GE (1996). Adenylate kinase motions during catalysis: an energetic counterweight balancing substrate binding. Structure 4: 147-156. https://doi.org/10.1016/S0969-2126(96)00018-4",
            "Muller CW, Schulz GE (1992). Structure of the complex between adenylate kinase from Escherichia coli and the inhibitor Ap5A refined at 1.9 A resolution. A model for a catalytic transition state. Journal of Molecular Biology 224: 159-177. https://doi.org/10.1016/0022-2836(92)90582-5"},
        "License" -> "CC0 1.0 (wwPDB data usage policy, https://www.wwpdb.org/about/usage-policies)"|>,
    "BorreliaB31" -> <|"Title" -> "Borreliella (Borrelia) burgdorferi B31 linear chromosome, RefSeq NC_001318.1",
        "Citation" -> "Fraser CM, Casjens S, Huang WM, et al. (1997). Genomic sequence of a Lyme disease spirochaete, Borrelia burgdorferi. Nature 390: 580-586. https://doi.org/10.1038/37551",
        "License" -> ncbiDisclaimer|>,
    "Coronaviruses" -> <|"Title" -> "SARS-CoV-2 Wuhan-Hu-1 (NC_045512.2), bat coronavirus RaTG13 (MN996532.2) and SARS-CoV Tor2 (NC_004718.3) genomes",
        "Citation" -> {"Wu F, Zhao S, Yu B, et al. (2020). A new coronavirus associated with human respiratory disease in China. Nature 579: 265-269. https://doi.org/10.1038/s41586-020-2008-3",
            "Zhou P, Yang XL, Wang XG, et al. (2020). A pneumonia outbreak associated with a new coronavirus of probable bat origin. Nature 579: 270-273. https://doi.org/10.1038/s41586-020-2012-7",
            "Marra MA, Jones SJM, Astell CR, et al. (2003). The genome sequence of the SARS-associated coronavirus. Science 300: 1399-1404. https://doi.org/10.1126/science.1085953"},
        "License" -> ncbiDisclaimer|>
|>;

requested = Replace[Rest[$ScriptCommandLine], {} -> Keys[sources]];
If[!SubsetQ[Keys[sources], requested], fail["choose from " <> StringRiffle[Keys[sources], ", "]]];
Do[Switch[name,
        "PBMC3k", buildPBMC3k[],
        "LiverCircadian", buildLiverCircadian[],
        _, buildCopies[name, metadata[name]]],
    {name, requested}];
DeleteDirectory[work, DeleteContents -> True];
Exit[0];
