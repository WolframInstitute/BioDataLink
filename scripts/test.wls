#!/usr/bin/env wolframscript
(* Strict offline runner. Isolate test-created Global symbols as in PureMath develop;
   empty files, parse errors, skips, runtime failures and aborts fail the command. *)
Begin["BioDataLinkTestRunner`"];
root = DirectoryName[$InputFileName, 2];
pacletDirectory = FileNameJoin[{root, "BioDataLink"}];
fail[text_] := (Print["ERROR: ", text]; Exit[1]);
CheckAbort[
    PacletDirectoryLoad[pacletDirectory];
    If[PacletObject["WolframInstitute/BioDataLink"]["Location"] =!= pacletDirectory,
        fail["installed paclet shadows checkout"]];
    Needs["WolframInstitute`BioDataLink`"];
    files = If[Length[$ScriptCommandLine] > 1, ExpandFileName /@ Rest[$ScriptCommandLine],
        Join[FileNames["*.wlt", FileNameJoin[{pacletDirectory, "Tests"}], Infinity],
            FileNames["*.wlt", FileNameJoin[{root, "scripts", "tests"}]]]];
    If[files === {}, fail["no test files"]];
    failures = 0; passed = 0;
    Do[
        If[!FileExistsQ[file] || !TrueQ[SyntaxQ[ReadString[file]]], fail[{file, "missing or invalid test file"}]];
        report = Block[{$Context = "Global`", $ContextPath = {"System`", "WolframInstitute`BioDataLink`"}},
            ClearAll["Global`*"];
            TestReport[file]];
        If[Head[report] =!= TestReportObject, fail[{file, "no test report"}]];
        results = Values[report["TestResults"]];
        If[results === {} || !ListQ[results], fail[{file, "no executed tests"}]];
        failed = Select[results, #["Outcome"] =!= "Success" &];
        failures += Length[failed] + Length[report["RuntimeFailures"]];
        passed += Length[results] - Length[failed];
        Print[FileNameTake[file], ": ", Length[results] - Length[failed], "/", Length[results]];
        Scan[Print[{#["TestID"], #["Outcome"], #["ActualOutput"], #["ExpectedOutput"], #["ActualMessages"]}] &, failed],
        {file, files}
    ];
    Print[passed, " passed; ", failures, " failed."],
    fail["test command aborted"]
];
End[];
Exit[If[BioDataLinkTestRunner`failures === 0, 0, 1]];
