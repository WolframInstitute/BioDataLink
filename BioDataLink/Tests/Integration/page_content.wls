#!/usr/bin/env wolframscript
(* Local converter regression for page images and the resource description; requires make bootstrap
   and a licensed front end. *)
repositoryRoot = DirectoryName[$InputFileName, 4];
fail[text_] := (Print["ERROR: ", text]; Exit[1]);
Scan[PacletDirectoryLoad, {FileNameJoin[{repositoryRoot, "BioDataLink"}],
    FileNameJoin[{repositoryRoot, ".deps", "PacletPage"}],
    FileNameJoin[{repositoryRoot, ".deps", "WolframParser", "Parser"}]}];
Needs["WolframInstitute`PacletPage`"];
Get[FileNameJoin[{repositoryRoot, "scripts", "tutorial-initialization.wl"}]];
Get[FileNameJoin[{repositoryRoot, "scripts", "page-content.wl"}]];
converter = FileNameJoin[{repositoryRoot, ".deps", "MarkdownToNotebook", "MarkdownToNotebook.wl"}];
Block[{$Context = "BioDataLinkDocs`", $ContextPath = {"System`"}}, Get[converter]];
root = FileNameJoin[{repositoryRoot, "build", "page-image-tests", CreateUUID[]}];
Scan[CreateDirectory[FileNameJoin[{root, "docs", "en", #}], CreateIntermediateDirectories -> True] &, {"Guides", "Tutorials", "Images"}];
image = FileNameJoin[{root, "docs", "en", "Images", "Probe.png"}];
writeImage[width_] := Export[image, Image[ConstantArray[{0.2, 0.4, 0.8}, {12, width}]], "PNG"];
front[template_, name_, kind_] := "---\nTemplate: " <> template <> "\nName: " <> name <> "\nTitle: " <> name <>
    "\nContext: WolframInstitute`BioDataLink`\nPaclet: WolframInstitute/BioDataLink\nURI: WolframInstitute/BioDataLink/" <> kind <> "/" <> name <> "\n";
guide = FileNameJoin[{root, "docs", "en", "Guides", "ImageProbe.md"}];
tutorial = FileNameJoin[{root, "docs", "en", "Tutorials", "ImageProbeTutorial.md"}];
Export[guide, front["Guide", "ImageProbe", "guide"] <> "Description: Probe\n---\n\n## Abstract\n\nFirst paragraph.\n\n" <>
    "![probe](../Images/Probe.png \"ExampleImage\")\n\nSecond paragraph.\n\n## Functions\n\n### Probe\n\n- `BioDataURL` construct a resolver URL\n", "Text"];
Export[tutorial, front["TechNote", "ImageProbeTutorial", "tutorial"] <> "---\n\nIntroduction.\n\n![probe](../Images/Probe.png \"ExampleImage\")\n\n" <>
    "## Example\n\n```wl\n1 + 1\n```\n", "Text"];
sources = {guide, tutorial};
runBuild[] := Module[{staged, converted, files},
    staged = stageDocumentation[];
    stagePageImages[staged];
    converted = WolframInstitute`PacletPage`BuildPacletDocumentation[
        FileNameJoin[{repositoryRoot, "BioDataLink"}], "Source" -> staged,
        "Target" -> FileNameJoin[{root, "notebooks"}], "Definition" -> None,
        "Converter" -> converter, "Parallel" -> False, "EvaluationKernel" -> None,
        "CacheDirectory" -> FileNameJoin[{root, "cache"}], "TimeConstraint" -> 60,
        "Dependencies" -> {FileNameJoin[{repositoryRoot, ".deps", "WolframParser", "Parser"}]}];
    If[!AssociationQ[converted] || converted["Failed"] =!= {} || converted["Unevaluated"] =!= <||>, fail[converted]];
    Scan[restoreTutorialInitialization, converted["Notebooks"]];
    Scan[restoreGuideImages, converted["Notebooks"]];
    files = AssociationMap[SelectFirst[converted["Notebooks"], Function[file, FileBaseName[file] === #]] &, {"ImageProbe", "ImageProbeTutorial"}];
    <|"Build" -> converted, "Guide" -> Get[files["ImageProbe"]], "Tutorial" -> Get[files["ImageProbeTutorial"]]|>
];
imageSizes[nb_] := ImageDimensions /@ Select[Cases[nb, Cell[BoxData[boxes_], "ExampleImage", ___] :> ToExpression[boxes], Infinity], ImageQ];
abstractStyles[nb_] := Cases[nb, Cell[_, style : "GuideAbstract" | "ExampleImage" | "Output", ___] :> style, Infinity];
writeImage[20];
hashes = FileHash[#, "SHA256"] & /@ sources;
first = runBuild[];
second = runBuild[];
writeImage[30];
third = runBuild[];
sourcePreserved = (FileHash[#, "SHA256"] & /@ sources) === hashes;
Scan[Export[#, StringDelete[Import[#, "Text"], "![probe](../Images/Probe.png \"ExampleImage\")\n\n"], "Text"] &, sources];
fourth = runBuild[];
(* the resource description: the converter keeps one paragraph; the restore rebuilds the section *)
definitionSource = FileNameJoin[{root, "docs", "ResourceDefinition.md"}];
Export[definitionSource, "---\nTemplate: Paclet\nResourceType: Paclet\nName: WolframInstitute/BioDataLink\nContext: WolframInstitute`BioDataLink`\n" <>
    "Paclet: WolframInstitute/BioDataLink\nDescription: Probe\n---\n\n## Basic Description\n\nA *probe* paragraph.\n\n### Probe heading\n\n" <>
    "- First item: <tag> & detail\n- Second item: Another detail\n\n## Details & Options\n\n- A detail\n", "Text"];
definition = FileNameJoin[{root, "ResourceDefinition.nb"}];
Put[UsingFrontEnd[BioDataLinkDocs`MarkdownToNotebook[definitionSource]], definition];
descriptionCellsIn[nb_] := First[Cases[nb, Cell[CellGroupData[{$descriptionHead, rest___}, _], ___] :> {rest}, Infinity]];
converterStyles = descriptionCellsIn[Get[definition]][[All, 2]];
restoreResourceDescription[definition, definitionSource];
once = Get[definition];
restoreResourceDescription[definition, definitionSource];
twice = Get[definition];
Needs["PacletResource`"];
Needs["ResourceSystemClient`"];
Quiet[Get["ResourceSystemClient`WebpageDeployment`DeployedResourceShingle`"]];
opened = UsingFrontEnd[Module[{notebook = NotebookOpen[definition, Visible -> False]},
    WithCleanup[NotebookGet[notebook], NotebookClose[notebook]]]];
rendererBefore = DownValues[PacletResource`Private`moreDescriptionHTML];
html = UsingFrontEnd[withResourceDescription[definitionSource,
    PacletResource`Private`moreDescriptionHTML[<|"Name" -> "WolframInstitute/BioDataLink"|>, descriptionCellsIn[opened]]]];
rendererRestored = DownValues[PacletResource`Private`moreDescriptionHTML] === rendererBefore;
report = TestReport[{
    VerificationTest[abstractStyles[first["Guide"]], {"GuideAbstract", "ExampleImage", "GuideAbstract"}, TestID -> "PageImages-GuideImageBetweenAbstractParagraphs"],
    VerificationTest[{imageSizes[first["Guide"]], imageSizes[first["Tutorial"]]}, {{{20, 12}}, {{20, 12}}}, TestID -> "PageImages-ImageReachesGuideAndTutorial"],
    VerificationTest[Length[second["Build"]["Cached"]], 2, TestID -> "PageImages-SecondBuildUsesCache"],
    VerificationTest[{abstractStyles[second["Guide"]], imageSizes[second["Guide"]], imageSizes[second["Tutorial"]]},
        {{"GuideAbstract", "ExampleImage", "GuideAbstract"}, {{20, 12}}, {{20, 12}}}, TestID -> "PageImages-CacheHitKeepsOneImage"],
    VerificationTest[{imageSizes[third["Guide"]], imageSizes[third["Tutorial"]]}, {{{30, 12}}, {{30, 12}}}, TestID -> "PageImages-ChangedImageReachesCachedPages"],
    VerificationTest[MemberQ[FileBaseName /@ third["Build"]["Converted"], "ImageProbeTutorial"], True, TestID -> "PageImages-ChangedImageConvertsTutorialAgain"],
    VerificationTest[sourcePreserved, True, TestID -> "PageImages-OriginalSourcesUnchanged"],
    VerificationTest[{imageSizes[fourth["Guide"]], imageSizes[fourth["Tutorial"]]}, {{}, {}}, TestID -> "PageImages-RemovedImagesStayRemoved"],
    VerificationTest[Count[{first, second, third, fourth}, Cell[_, "Message", ___], Infinity], 0, TestID -> "PageImages-NoSavedMessages"],
    VerificationTest[converterStyles, {"Text"}, TestID -> "ResourceDescription-ConverterKeepsOnlyProse"],
    VerificationTest[descriptionCellsIn[once][[All, 2]], {"Text", "Text", "Text"}, TestID -> "ResourceDescription-SectionRebuilt"],
    VerificationTest[once === twice, True, TestID -> "ResourceDescription-RestoreIsRepeatable"],
    VerificationTest[{StringContainsQ[html, "<h3 class=\"biodatalink-description-heading\">Probe heading</h3>"],
        StringCount[html, "class=\"biodatalink-description-row\""], StringContainsQ[html, "<i class=\"ti\">probe</i>"]},
        {True, 2, True}, TestID -> "ResourceDescription-RendersAsResourcePageHTML"],
    VerificationTest[{FreeQ[descriptionCellsIn[opened], _CellGroupData], StringFreeQ[html, {"cell-group", "nb-collapse"}]},
        {True, True}, TestID -> "ResourceDescription-NoAccordionAfterFrontEndGrouping"],
    VerificationTest[rendererRestored, True, TestID -> "ResourceDescription-RendererOverrideIsScoped"],
    VerificationTest[StringContainsQ[html, "&lt;tag&gt; &amp; detail"], True, TestID -> "ResourceDescription-EscapesLiteralText"]
}];
If[report["TestsFailedCount"] > 0, Print[report]; Print[{abstractStyles /@ {first["Guide"], third["Guide"]}, imageSizes /@ {third["Guide"], third["Tutorial"]},
    Keys[third["Build"]]}]];
Print["Page content checks: ", report["TestsSucceededCount"], " passed; ", report["TestsFailedCount"], " failed."];
Exit[If[report["TestsFailedCount"] === 0 && report["TestsSucceededCount"] === 16, 0, 1]];
