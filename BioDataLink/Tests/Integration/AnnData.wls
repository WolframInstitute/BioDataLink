#!/usr/bin/env wolframscript
(* Explicit optional-backend tests. Ordinary make test never starts Python. *)
pacletDirectory = DirectoryName[$InputFileName, 3];
PacletDirectoryLoad[pacletDirectory];
Needs["WolframInstitute`BioDataLink`"];
python = Environment["BIODATALINK_PYTHON"];
If[!StringQ[python] || python === "", Print["Set BIODATALINK_PYTHON to the optional test interpreter."]; Exit[2]];
fixture = FileNameJoin[{pacletDirectory, "Assets", "Examples", "toy-anndata.h5ad"}];
load[options___Rule] := BioDatasetLoad[File[fixture], "Format" -> "AnnData", "PythonExecutable" -> python, options];
base = load["Cells" -> {1, 2}, "Genes" -> {1, 2, 3}];
report = TestReport[{
    VerificationTest[If[AssociationQ[base], Normal[base["ExpressionMatrix"]], base],
        {{0, 2, 0}, {7, 0, 11}}, TestID -> "H5AD-RealBackendAsymmetricMatrix"],
    VerificationTest[If[AssociationQ[base],
        {Lookup[Normal[base["GeneMetadata"]], "ID"],
            Normal[base["CellMetadata"]][[2]]["Annotations"]["kind"], base["Normalization"], base["ContentHash"]}, base],
        {{"g1", "g1", "g3"}, Missing["NotAvailable"], Missing["NotSpecified"], Missing["NotComputed"]},
        TestID -> "H5AD-RealBackendAxisIdentityMissingnessAndProvenance"],
    VerificationTest[Normal[load["Cells" -> {3, 1}, "Genes" -> {4, 1, 2}]["ExpressionMatrix"]],
        {{17, 9007199254740993, 0}, {5, 0, 2}}, TestID -> "H5AD-RealBackendExactIntegerAndReorderedSlice"],
    VerificationTest[Normal[load["Layer" -> {"Layers", "normalized"}, "Cells" -> {2, 1}, "Genes" -> {3, 2}]["ExpressionMatrix"]],
        {{1.1, 0}, {0, 0.2}}, TestID -> "H5AD-RealBackendSelectedLayer"],
    VerificationTest[With[{raw = load["Layer" -> {"Raw", "X"}, "Cells" -> {3, 1}, "Genes" -> {5, 2}]},
        {Normal[raw["ExpressionMatrix"]], Lookup[Normal[raw["GeneMetadata"]], "ID"], raw["SourceShape"]}],
        {{{29, 0}, {19, 2}}, {"r5", "r2"}, {3, 5}}, TestID -> "H5AD-RealBackendRawUsesItsOwnGeneAxis"],
    VerificationTest[{MatchQ[load["MaxSelectedElements" -> 1], Failure["SelectionTooLarge", _]],
        MatchQ[load["MaxTransferBytes" -> 1000], Failure["TransferTooLarge", _]],
        MatchQ[load["TimeConstraint" -> 0.001], Failure["Timeout", _]]},
        {True, True, True}, TestID -> "H5AD-RealBackendBoundsAndTimeout"]
}];
failed = Select[Values[report["TestResults"]], #["Outcome"] =!= "Success" &];
Scan[Print[{#["TestID"], #["Outcome"], #["ActualOutput"], #["ExpectedOutput"], #["ActualMessages"]}] &, failed];
Print["Optional H5AD: ", Length[report["TestResults"]] - Length[failed], "/", Length[report["TestResults"]]];
Exit[If[failed === {} && report["RuntimeFailures"] === {} && Length[report["TestResults"]] === 6, 0, 1]];
