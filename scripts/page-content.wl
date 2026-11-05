(* Page content the pinned converter drops. It embeds a Markdown image in a tutorial but drops one
   from a guide, and its page cache does not see image files: staging gives each local image a name
   that changes with its content, so a changed image converts its page again, and records the
   images in guide abstracts, which restoreGuideImages inserts after their paragraphs. It keeps only
   the prose of the resource definition's Basic Description, which the resource page shows beside
   its image: restoreResourceDescription rebuilds that section. Each restore runs on every build,
   including cache hits. Never change the source or dependency checkout. *)
guideImagePlans = <||>;
addressedPath[path_String, file_String] := With[{extension = FileExtension[path]},
    StringDrop[path, -StringLength[extension] - 1] <> "-" <> StringTake[FileHash[file, "SHA256", "HexString"], 12] <> "." <> extension];
stagePageImages[source_String] := (guideImagePlans = <||>; Scan[stagePageImage, FileNames["*.md", source, Infinity]]);
stagePageImage[file_String] := Module[{text = Import[file, "Text"], parsed, images, section = None, paragraphs = 0, plan = {}},
    parsed = BioDataLinkDocs`litParse[text];
    images = Select[parsed["Blocks"], #["Type"] === "Image" && !StringStartsQ[#["Path"], {"http://", "https://"}] &];
    If[images === {}, Return[Null]];
    Do[With[{image = FileNameJoin[{DirectoryName[file], path}]},
        If[!FileExistsQ[image], fail["missing image " <> path <> " in " <> file]];
        CopyFile[image, FileNameJoin[{DirectoryName[file], addressedPath[path, image]}], OverwriteTarget -> True];
        text = StringReplace[text, "](" <> path -> "](" <> addressedPath[path, image]]],
        {path, DeleteDuplicates[Lookup[images, "Path"]]}];
    Export[file, text, "Text"];
    If[Lookup[parsed["Metadata"], "Template", ""] =!= "Guide", Return[Null]];
    Do[Switch[block["Type"],
        "Heading", If[block["Level"] === 2, section = block["Text"]],
        "Prose", If[section === "Abstract", paragraphs++],
        "Image", If[section =!= "Abstract", fail["a guide image must follow an Abstract paragraph: " <> file]];
            AppendTo[plan, <|"After" -> paragraphs, "File" -> FileNameJoin[{DirectoryName[file], block["Path"]}], "Effect" -> block["Effect"]|>]],
        {block, parsed["Blocks"]}];
    guideImagePlans[Last[StringSplit[parsed["Metadata"]["URI"], "/"]]] = plan
];
restoreGuideImages[file_String] := Module[{plan, notebook, abstracts},
    If[FileNameTake[DirectoryName[file], -1] =!= "Guides", Return[Null]];
    plan = Lookup[guideImagePlans, FileBaseName[file], {}];
    If[plan === {}, Return[Null]];
    (* PacletPage copies the cached conversion to this file on every build, so images are inserted once *)
    notebook = Get[file];
    abstracts = Position[notebook, Cell[_, "GuideAbstract", ___]];
    If[abstracts === {} || Max[Lookup[plan, "After"]] > Length[abstracts], fail["unexpected guide abstract: " <> file]];
    (* the last image first, so the positions of earlier paragraphs stay valid *)
    Scan[Function[image, notebook = Insert[notebook,
        BioDataLinkDocs`imageCell[<|"Image" -> Import[image["File"]], "Effect" -> image["Effect"]|>],
        If[image["After"] === 0, First[abstracts], MapAt[# + 1 &, abstracts[[image["After"]]], -1]]]], Reverse[plan]];
    Put[notebook, file]
];

(* Basic Description paragraphs become Text cells, level-3 headings Subsubsection cells and list
   items Item cells, which the resource page renders as paragraphs, small headings and items. The
   definition notebook's hints suggest at most 10 cells in the section. *)
descriptionCells[markdown_String] := Module[{blocks = BioDataLinkDocs`litParse[Import[markdown, "Text"]]["Blocks"], start},
    start = FirstPosition[blocks, KeyValuePattern[{"Type" -> "Heading", "Level" -> 2, "Text" -> "Basic Description"}], None, {1}];
    If[start === None, fail["no Basic Description in " <> markdown]];
    Catenate[Replace[TakeWhile[Drop[blocks, First[start]], !(#["Type"] === "Heading" && #["Level"] <= 2) &], {
        block : KeyValuePattern["Type" -> "Prose"] :> {Cell[TextData[BioDataLinkDocs`inlineTextData[block["Text"]]], "Text"]},
        block : KeyValuePattern[{"Type" -> "Heading", "Level" -> 3}] :> {Cell[block["Text"], "Subsubsection"]},
        block : KeyValuePattern["Type" -> "List"] :> (Cell[TextData[BioDataLinkDocs`inlineTextData[#]], "Item"] & /@ block["Items"]),
        block_ :> fail["the Basic Description supports paragraphs, level-3 headings and lists, not " <> block["Type"]]}, {1}]]
];
$descriptionHead = Cell[_, "Subsection", ___, CellTags -> {___, "LongDescription", ___}, ___];
restoreResourceDescription[notebook_String, markdown_String] := Module[{cells = descriptionCells[markdown], definition},
    If[Length[cells] > 10, fail["the Basic Description makes " <> ToString[Length[cells]] <> " cells; the resource hints suggest at most 10"]];
    definition = Get[notebook];
    If[Count[definition, Cell[CellGroupData[{$descriptionHead, ___}, _], ___], Infinity] =!= 1, fail["unexpected definition notebook: " <> notebook]];
    Put[definition /. Cell[CellGroupData[{head : $descriptionHead, ___}, state_], options___] :>
        Cell[CellGroupData[Prepend[cells, head], state], options], notebook]
];
