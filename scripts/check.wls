#!/usr/bin/env wolframscript
(* Project-specific source checks; PacletPage owns documentation conversion and archive validation. *)
root = DirectoryName[$InputFileName, 2];
pacletDirectory = FileNameJoin[{root, "BioDataLink"}];
errors = 0;
problem[text_] := (errors++; Print["ERROR: ", text]);
docsOnly = MemberQ[Rest[$ScriptCommandLine], "docs"];
CheckAbort[
    If[!docsOnly,
        Needs["PacletTools`"];
        Needs["CodeInspector`"];
        If[!TrueQ[PacletTools`PacletValidate[pacletDirectory]], problem["invalid paclet metadata"]];
        paclet = PacletObject[File[pacletDirectory]];
        PacletDirectoryLoad[pacletDirectory];
        If[PacletObject[paclet["Name"]]["Location"] =!= pacletDirectory, problem["installed paclet shadows checkout"]];
        If[Check[Needs[paclet["PrimaryContext"]]; True, False] =!= True, problem["checkout does not load cleanly"]];
        citation = Import[FileNameJoin[{root, "CITATION.cff"}], "Text"];
        If[!StringContainsQ[citation, "version: " <> paclet["Version"]], problem["CITATION.cff version mismatch"]];
        sources = Join[FileNames[{"*.wl", "*.wlt"}, FileNameJoin[{pacletDirectory, "Kernel"}], Infinity],
            FileNames["*.wlt", FileNameJoin[{pacletDirectory, "Tests"}], Infinity],
            FileNames[{"*.wls", "*.wlt"}, FileNameJoin[{root, "scripts"}], Infinity]];
        Do[
            issues = CodeInspector`CodeInspect[File[file]];
            If[!ListQ[issues], problem[{file, "could not inspect source"}],
                Scan[problem[{file, #}] &, Cases[issues,
                    CodeInspector`InspectionObject[_, _, "Error" | "Fatal", _]]]],
            {file, sources}
        ];
        exports = Flatten[Lookup[Last[#], "Symbols", {}] & /@ PacletTools`PacletExtensions[paclet, "Kernel"]];
        Do[If[!NameQ[name] || !StringQ[ToExpression[name <> "::usage"]], problem[{name, "missing export or usage"}]], {name, exports}];
        Print["Checked ", Length[sources], " source files and ", Length[exports], " exports."]
    ];
    markdown = Join[FileNames["*.md", root], Catenate[
        FileNames["*.md", FileNameJoin[{root, #}], Infinity] & /@ {"docs", ".agent-skills", ".github"}]];
    Do[
        text = Import[file, "Text"];
        cells = StringCases[text, RegularExpression["(?s)```(?:wl|wolfram|mathematica)\\s*\\n(.*?)```"] -> "$1"];
        If[!AllTrue[cells, SyntaxQ], problem[{file, "Wolfram example does not parse"}]];
        prose = StringReplace[text, RegularExpression["(?s)```.*?```"] -> ""];
        links = StringCases[prose, RegularExpression["\\]\\(<?([^\\s)>]+)>?\\)"] -> "$1"];
        Do[If[!StringStartsQ[target, {"http:", "https:", "mailto:", "paclet:", "#"}],
            destination = First[StringSplit[target, "#"]];
            If[!FileExistsQ[FileNameJoin[{DirectoryName[file], destination}]], problem[{file, "missing link", target}]]],
            {target, links}];
        If[StringContainsQ[file, FileNameJoin[{"docs", "en"}]] &&
                !StringContainsQ[text, RegularExpression["(?m)^Template: (Guide|Symbol|TechNote)$"]],
            problem[{file, "missing documentation template"}]],
        {file, markdown}
    ];
    Print["Checked ", Length[markdown], " Markdown sources."],
    problem["source checks aborted"]
];
Exit[If[errors === 0, 0, 1]];
