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

(* Keep description headings and lists as ordinary text cells: the front end groups section
   styles, and the resource page turns those groups into accordions. Each list occupies one cell. *)
descriptionBlocks[markdown_String] := Module[{blocks = BioDataLinkDocs`litParse[Import[markdown, "Text"]]["Blocks"], start, selected},
    start = FirstPosition[blocks, KeyValuePattern[{"Type" -> "Heading", "Level" -> 2, "Text" -> "Basic Description"}], None, {1}];
    If[start === None, fail["no Basic Description in " <> markdown]];
    selected = TakeWhile[Drop[blocks, First[start]], !(#["Type"] === "Heading" && #["Level"] <= 2) &];
    If[!AllTrue[selected, MemberQ[{"Prose", "List"}, #["Type"]] || (#["Type"] === "Heading" && #["Level"] === 3) &],
        fail["the Basic Description supports paragraphs, level-3 headings and lists"]];
    selected
];
descriptionCells[markdown_String] := Map[Switch[#["Type"],
    "Prose", Cell[TextData[BioDataLinkDocs`inlineTextData[#["Text"]]], "Text"],
    "Heading", Cell[TextData[{StyleBox[ToUpperCase[#["Text"]], FontWeight -> "Bold"]}], "Text"],
    "List", Cell[TextData[Flatten[Riffle[BioDataLinkDocs`inlineTextData /@ #["Items"], "\n"]]], "Text", LineSpacing -> {1.4, 0}]
] &, descriptionBlocks[markdown]];

(* The native web exporter discards row styling. Render only this description as semantic HTML;
   the surrounding resource page, hero and documentation keep their standard publisher layout. *)
$resourceDescriptionCSS = Import[FileNameJoin[{DirectoryName[$InputFileName], "resource-description.css"}], "Text"];
descriptionInline[""] := {};
descriptionInline[text_String] := Module[{xml, paragraphs},
    xml = DeployedResourceShingle`Private`resourceSystemTransmogrify["Paclet", "WolframInstitute/BioDataLink",
        Notebook[{Cell[TextData[BioDataLinkDocs`inlineTextData[text]], "Text"]}]];
    paragraphs = Cases[xml, XMLElement["p", _, contents_List] :> contents, Infinity];
    If[Length[paragraphs] =!= 1, fail["could not render description text: " <> text]];
    First[paragraphs]
];
descriptionRow[text_String] := Module[{rowSeparator = StringPosition[text, ": ", 1], rowLabel, rowDetail},
    If[rowSeparator === {}, fail["description list items must use Label: detail"]];
    {rowLabel, rowDetail} = {StringTake[text, rowSeparator[[1, 1]] - 1], StringDrop[text, rowSeparator[[1, 2]]]};
    If[StringTrim[rowLabel] === "" || StringTrim[rowDetail] === "", fail["description rows need a label and detail"]];
    XMLElement["div", {"class" -> "biodatalink-description-row"}, {
        XMLElement["dt", {}, descriptionInline[rowLabel]], XMLElement["dd", {}, descriptionInline[rowDetail]]}]
];
resourceDescriptionHTML[markdown_String] := Module[{elements},
    Needs["PacletResource`"];
    Needs["ResourceSystemClient`"];
    ResourceSystemClient`Private`loadDeployResourceShingle[];
    If[!StringQ[$resourceDescriptionCSS], fail["missing resource-description.css"]];
    elements = Map[Switch[#["Type"],
        "Prose", XMLElement["p", {"class" -> "biodatalink-description-intro"}, descriptionInline[#["Text"]]],
        "Heading", XMLElement["h3", {"class" -> "biodatalink-description-heading"}, descriptionInline[#["Text"]]],
        "List", XMLElement["dl", {}, descriptionRow /@ #["Items"]]
    ] &, descriptionBlocks[markdown]];
    ExportString[XMLElement["div", {"class" -> "biodatalink-description"},
        Prepend[elements, XMLElement["style", {}, {$resourceDescriptionCSS}]]],
        "XML", "Annotations" -> {}, "AttributeQuoting" -> "\"", "ElementFormatting" -> None]
];
SetAttributes[withResourceDescription, HoldRest];
withResourceDescription[markdown_String, expression_] := With[{html = resourceDescriptionHTML[markdown]},
    If[DownValues[PacletResource`Private`moreDescriptionHTML] === {}, fail["resource description renderer unavailable"]];
    Internal`InheritedBlock[{PacletResource`Private`moreDescriptionHTML},
        PrependTo[DownValues[PacletResource`Private`moreDescriptionHTML],
            HoldPattern[PacletResource`Private`moreDescriptionHTML[
                as_?(AssociationQ[#] && Lookup[#, "Name", None] === "WolframInstitute/BioDataLink" &), cells_]] :> html];
        expression
    ]
];
$descriptionHead = Cell[_, "Subsection", ___, CellTags -> {___, "LongDescription", ___}, ___];
restoreResourceDescription[notebook_String, markdown_String] := Module[{cells = descriptionCells[markdown], definition},
    If[Length[cells] > 10, fail["the Basic Description makes " <> ToString[Length[cells]] <> " cells; the resource hints suggest at most 10"]];
    definition = Get[notebook];
    If[Count[definition, Cell[CellGroupData[{$descriptionHead, ___}, _], ___], Infinity] =!= 1, fail["unexpected definition notebook: " <> notebook]];
    Put[definition /. Cell[CellGroupData[{head : $descriptionHead, ___}, state_], options___] :>
        Cell[CellGroupData[Prepend[cells, head], state], options], notebook]
];
