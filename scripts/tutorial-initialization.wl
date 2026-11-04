(* The pinned converter evaluates TechNotes in source order and does not implement
   initialization cells. Stage helpers first for evaluation, then restore their
   final section and native flags. Never change the source or dependency checkout. *)
$tutorialBodyMarker = "BioDataLink generated tutorial body boundary";
stageTutorial[file_String] := Module[{text, parsed, lines, headings = {}, fence = 0,
        width, start, front, initialization, blocks, flags, contexts, staged},
    text = Import[file, "Text"];
    parsed = BioDataLinkDocs`litParse[text];
    If[Lookup[parsed["Metadata"], "Template", ""] =!= "TechNote", Return[Nothing]];
    lines = StringSplit[text, "\n", All];
    Do[
        If[BioDataLinkDocs`fenceQ[lines[[i]]],
            width = BioDataLinkDocs`fenceLen[lines[[i]]];
            fence = If[fence === 0, width, If[width >= fence, 0, fence]],
            If[fence === 0 && StringStartsQ[lines[[i]], "## "], AppendTo[headings, i]]],
        {i, Length[lines]}];
    initialization = Select[headings, StringTrim[lines[[#]]] === "## Initialization" &];
    If[initialization === {}, Return[Nothing]];
    If[Length[initialization] =!= 1 || First[initialization] =!= Last[headings],
        fail["Initialization must be the final level-two section: " <> file]];
    If[StringContainsQ[text, $tutorialBodyMarker], fail["reserved tutorial boundary in " <> file]];
    start = First[initialization];
    front = Replace[FirstPosition[Rest[lines], "---"], {{n_Integer} :> n + 1, _ -> 0}];
    If[front < 2 || front >= start, fail["missing tutorial frontmatter: " <> file]];
    blocks = BioDataLinkDocs`litParse[StringRiffle[Drop[lines, start - 1], "\n"]]["Blocks"];
    blocks = Select[blocks, #["Type"] === "Code" && MemberQ[{"wl", "wolfram", "mathematica"}, #["Lang"]] &];
    If[AnyTrue[blocks, BioDataLinkDocs`executableQ[#] && Lookup[#["Options"], "input", True] === False &],
        fail["Initialization helpers must retain their input cells: " <> file]];
    flags = BioDataLinkDocs`executableQ /@ blocks;
    contexts = BioDataLinkDocs`loadedContexts[parsed["Metadata"]];
    staged = StringRiffle[Join[Take[lines, front], {""}, Drop[lines, start - 1],
        {"", "## " <> $tutorialBodyMarker, ""}, Take[lines, {front + 1, start - 1}]], "\n"];
    Export[file, staged, "Text"];
    <|"Name" -> Last[StringSplit[parsed["Metadata"]["URI"], "/"]], "Flags" -> flags,
        "NeedsBoxes" -> If[contexts === {}, None,
            BioDataLinkDocs`inputBoxes[BioDataLinkDocs`exampleInitCode[parsed["Metadata"]]]]|>
];
stageDocumentation[] := Module[{stage = FileNameJoin[{root, "build", "documentation-source"}]},
    If[DirectoryQ[stage], DeleteDirectory[stage, DeleteContents -> True]];
    If[!DirectoryQ[DirectoryName[stage]], CreateDirectory[DirectoryName[stage], CreateIntermediateDirectories -> True]];
    CopyDirectory[FileNameJoin[{root, "docs"}], stage];
    initializationPlans = Association @ Map[#Name -> # &,
        stageTutorial /@ FileNames["*.md", FileNameJoin[{stage, "en", "Tutorials"}], Infinity]];
    FileNameJoin[{stage, "en"}]
];
restoreTutorialCells[cells_List, plan_Association] := Module[{first, boundary, links, initialization, inputs, flags, index = 0},
    first = Replace[FirstPosition[cells, Cell["Initialization", "Section", ___], None, {1}], {n_Integer} :> n];
    boundary = Replace[FirstPosition[cells, Cell[$tutorialBodyMarker, "Section", ___], None, {1}], {n_Integer} :> n];
    links = Replace[FirstPosition[cells,
        Cell[_, "TutorialMoreAboutSection" | "RelatedTutorialsSection", ___] |
            Cell[CellGroupData[{Cell[_, "TutorialMoreAboutSection" | "RelatedTutorialsSection", ___], ___}, _], ___],
        None, {1}], {n_Integer} :> n];
    If[!MatchQ[{first, boundary, links}, {_Integer, _Integer, _Integer}] || !(first < boundary < links),
        fail["unexpected tutorial layout: " <> plan["Name"]]];
    initialization = Take[cells, {first, boundary - 1}];
    inputs = Cases[initialization, Cell[boxes_, "Input", ___] :> boxes, Infinity];
    flags = plan["Flags"];
    If[Length[inputs] === Length[flags] + 1 && plan["NeedsBoxes"] =!= None &&
            First[inputs] === BoxData[plan["NeedsBoxes"]], flags = Prepend[flags, True]];
    If[Length[inputs] =!= Length[flags], fail["unexpected initialization inputs: " <> plan["Name"]]];
    initialization = initialization /. Cell[boxes_, "Input", options___] :>
        Cell[boxes, "Input", Sequence @@ DeleteCases[{options}, HoldPattern[InitializationCell -> _]],
            InitializationCell -> flags[[++index]]];
    initialization[[1]] = initialization[[1]] /. Cell[title_, "Section", options___] :>
        Cell[title, "Section", Sequence @@ DeleteCases[{options}, HoldPattern[ShowGroupOpener -> _]],
            ShowGroupOpener -> True];
    (* One closed group: readers see the heading and can open it to inspect the helpers. *)
    Join[Take[cells, first - 1], Take[cells, {boundary + 1, links - 1}],
        {Cell[CellGroupData[initialization, Closed]]}, Drop[cells, links - 1]]
];
restoreTutorialInitialization[file_String] := Module[{plan, notebook},
    plan = Lookup[initializationPlans, FileBaseName[file], None];
    If[plan === None, Return[Null]];
    (* PacletPage copies the original cached conversion to this file on every
       build, including cache hits; restoration never modifies that cache. *)
    notebook = Get[file];
    If[Count[notebook, Cell[CellGroupData[{Cell[_, "Title", ___], ___}, _], ___], Infinity] =!= 1,
        fail["unexpected tutorial title group: " <> plan["Name"]]];
    notebook = notebook /. Cell[CellGroupData[cells : {Cell[_, "Title", ___], ___}, state_], options___] :>
        Cell[CellGroupData[restoreTutorialCells[cells, plan], state], options];
    notebook = notebook /. Notebook[cells_, options___] :>
        Notebook[cells, Sequence @@ DeleteCases[{options}, HoldPattern[InitializationCellEvaluation -> _]],
            InitializationCellEvaluation -> True];
    Put[notebook, file]
];
