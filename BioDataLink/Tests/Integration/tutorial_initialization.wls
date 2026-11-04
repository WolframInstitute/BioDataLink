#!/usr/bin/env wolframscript
(* Local converter regression; requires make bootstrap and a licensed front end. *)
repositoryRoot = DirectoryName[$InputFileName, 4];
fail[text_] := (Print["ERROR: ", text]; Exit[1]);
Scan[PacletDirectoryLoad, {FileNameJoin[{repositoryRoot, "BioDataLink"}],
    FileNameJoin[{repositoryRoot, ".deps", "PacletPage"}],
    FileNameJoin[{repositoryRoot, ".deps", "WolframParser", "Parser"}]}];
Needs["WolframInstitute`PacletPage`"];
Get[FileNameJoin[{repositoryRoot, "scripts", "tutorial-initialization.wl"}]];
converter = FileNameJoin[{repositoryRoot, ".deps", "MarkdownToNotebook", "MarkdownToNotebook.wl"}];
Block[{$Context = "BioDataLinkDocs`", $ContextPath = {"System`"}}, Get[converter]];
root = FileNameJoin[{repositoryRoot, "build", "initialization-tests", CreateUUID[]}];
CreateDirectory[FileNameJoin[{root, "docs", "en", "Tutorials"}], CreateIntermediateDirectories -> True];
source = FileNameJoin[{root, "docs", "en", "Tutorials", "InitializationProbe.md"}];
sentinel = FileNameJoin[{root, "UNEXPECTED-EVALUATION"}];
header = "---\nTemplate: TechNote\nName: InitializationProbe\nTitle: Initialization Probe\nContext: WolframInstitute`BioDataLink`\nPaclet: WolframInstitute/BioDataLink\nURI: WolframInstitute/BioDataLink/tutorial/InitializationProbe\n---\n\n";
body = "The helper appears below the worked example.\n\n## Example\n\n```wl\nbioDataLinkInitializationProbe[3]\n```\n\n";
setup[power_] := "## Initialization\n\n```wl\nbioDataLinkInitializationProbe[x_] := x^" <> ToString[power] <>
    ";\n```\n\n```wl\n#| eval: false\nCreateFile[" <> ToString[sentinel, InputForm] <> "];\n```\n";
writeSource[power_] := Export[source, header <> body <> setup[power], "Text"];
runBuild[] := Module[{staged, converted},
    staged = stageDocumentation[];
    converted = WolframInstitute`PacletPage`BuildPacletDocumentation[
        FileNameJoin[{repositoryRoot, "BioDataLink"}], "Source" -> staged,
        "Target" -> FileNameJoin[{root, "notebooks"}], "Definition" -> None,
        "Converter" -> converter, "Parallel" -> False, "EvaluationKernel" -> None,
        "CacheDirectory" -> FileNameJoin[{root, "cache"}], "TimeConstraint" -> 60,
        "Dependencies" -> {FileNameJoin[{repositoryRoot, ".deps", "WolframParser", "Parser"}]}];
    If[!AssociationQ[converted] || converted["Failed"] =!= {} || converted["Unevaluated"] =!= <||>, fail[converted]];
    Scan[restoreTutorialInitialization, converted["Notebooks"]];
    <|"Build" -> converted, "File" -> First[converted["Notebooks"]], "Notebook" -> Get[First[converted["Notebooks"]]]|>
];
sections[nb_] := Cases[nb, Cell[text_, "Section", ___] :> text, Infinity];
flags[nb_] := Cases[nb, HoldPattern[InitializationCell -> value_] :> value, Infinity];
outputs[nb_] := Cases[nb, Cell[BoxData[text_], "Output", ___] :> text, Infinity];
writeSource[2];
originalHash = FileHash[source, "SHA256"];
first = runBuild[];
second = runBuild[];
Clear[Global`bioDataLinkInitializationProbe];
nativeValue = UsingFrontEnd[
    notebookObject = NotebookOpen[second["File"], Visible -> False];
    WithCleanup[NotebookEvaluate[notebookObject, EvaluationElements -> "InitializationCell"],
        NotebookClose[notebookObject]];
    Global`bioDataLinkInitializationProbe[3]
];
sourcePreserved = FileHash[source, "SHA256"] === originalHash;
writeSource[3];
third = runBuild[];
report = TestReport[{
    VerificationTest[Length[first["Build"]["Converted"]], 1, TestID -> "Initialization-FirstConversion"],
    VerificationTest[outputs[first["Notebook"]], {"9"}, TestID -> "Initialization-HelperEvaluatedBeforeBody"],
    VerificationTest[sections[first["Notebook"]], {"Example", "Initialization"}, TestID -> "Initialization-HelpersDisplayedLast"],
    VerificationTest[flags[first["Notebook"]], {True, True, False}, TestID -> "Initialization-NeedsAndHelperOnly"],
    VerificationTest[Count[first["Notebook"], Cell[_, "Input", ___], Infinity], 4, TestID -> "Initialization-NoDuplicateInputs"],
    VerificationTest[sourcePreserved, True, TestID -> "Initialization-OriginalSourceUnchanged"],
    VerificationTest[{Length[second["Build"]["Cached"]], Length[second["Build"]["Converted"]]}, {1, 0}, TestID -> "Initialization-SecondBuildUsesCache"],
    VerificationTest[{sections[second["Notebook"]], flags[second["Notebook"]], outputs[second["Notebook"]]},
        {{"Example", "Initialization"}, {True, True, False}, {"9"}}, TestID -> "Initialization-CacheHitRestoresNativeCells"],
    VerificationTest[nativeValue, 9, TestID -> "Initialization-NativeInitializationOnlyEvaluation"],
    VerificationTest[FileExistsQ[sentinel], False, TestID -> "Initialization-EvalFalseNeverRuns"],
    VerificationTest[{Length[third["Build"]["Converted"]], outputs[third["Notebook"]]}, {1, {"27"}}, TestID -> "Initialization-HelperChangeInvalidatesCache"],
    VerificationTest[Count[{first["Notebook"], second["Notebook"], third["Notebook"]}, Cell[_, "Message", ___], Infinity], 0, TestID -> "Initialization-NoSavedMessages"]
}];
If[report["TestsFailedCount"] > 0, Print[report]];
Print["Initialization checks: ", report["TestsSucceededCount"], " passed; ", report["TestsFailedCount"], " failed."];
Exit[If[report["TestsFailedCount"] === 0 && report["TestsSucceededCount"] === 12, 0, 1]];
