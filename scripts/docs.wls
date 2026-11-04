#!/usr/bin/env wolframscript
(* Thin PacletPage entry point. Build tooling is pinned by bootstrap.py, following
   PureMath develop e2dacfa90c526c3bc9902ef7fa24d29932fb3b22. No provider downloads. *)
root = DirectoryName[$InputFileName, 2];
pacletDirectory = FileNameJoin[{root, "BioDataLink"}];
archiveExclusions = {"__pycache__", "*/__pycache__", "*.pyc"};
command = If[Length[$ScriptCommandLine] > 1, $ScriptCommandLine[[2]], "build"];
fail[text_] := (Print["ERROR: ", text]; Exit[1]);
require[result_, label_] := If[AssociationQ[result], result, fail[{label, result}]];
If[!MemberQ[{"build", "notebooks", "site", "publish"}, command], fail["expected build, notebooks, site or publish"]];
CheckAbort[
    manifest = Import[FileNameJoin[{root, "scripts", "build-dependencies.json"}], "RawJSON"];
    Do[
        dependencyDirectory = FileNameJoin[{root, ".deps", dependency["Name"]}];
        If[!DirectoryQ[dependencyDirectory], fail["missing build dependency; run make bootstrap"]];
        commit = RunProcess[{"git", "-C", dependencyDirectory, "rev-parse", "HEAD"}];
        clean = RunProcess[{"git", "-C", dependencyDirectory, "status", "--porcelain"}];
        If[commit["ExitCode"] =!= 0 || StringTrim[commit["StandardOutput"]] =!= dependency["Commit"] ||
                clean["ExitCode"] =!= 0 || StringTrim[clean["StandardOutput"]] =!= "",
            fail["build dependency differs from its pin: " <> dependency["Name"]]];
        If[KeyExistsQ[dependency, "Paclet"],
            PacletDirectoryLoad[FileNameJoin[{dependencyDirectory, dependency["Paclet"]}]]],
        {dependency, manifest["Dependencies"]}
    ];
    Needs["WolframInstitute`PacletPage`"];
    resolved = PacletObject["WolframInstitute/PacletPage"];
    If[ExpandFileName[resolved["Location"]] =!= ExpandFileName[FileNameJoin[{root, ".deps", "PacletPage"}]],
        fail["an installed PacletPage shadows the pinned checkout"]];
    Print["PacletPage ", resolved["Version"], " from ", resolved["Location"]];
    If[command === "publish",
        user = Environment["WOLFRAM_CLOUD_USER"];
        If[!StringQ[user] || user === "", fail["set WOLFRAM_CLOUD_USER to the publishing account"]];
        If[Environment["GITHUB_ACTIONS"] === "true" && !TrueQ[$CloudConnected],
            Quiet[TimeConstrained[CloudConnect[user, Environment["WOLFRAM_CLOUD_PASSWORD"]], 60, $Failed]]];
        If[!TrueQ[$CloudConnected] || !MemberQ[{$WolframID, First[StringSplit[$WolframID, "@"]]}, user],
            fail["the kernel must be authenticated as the configured publishing account"]]
    ];
    converted = require[WolframInstitute`PacletPage`BuildPacletDocumentation[pacletDirectory,
        "Source" -> FileNameJoin[{root, "docs", "en"}],
        "Definition" -> FileNameJoin[{root, "docs", "ResourceDefinition.md"}],
        "Converter" -> FileNameJoin[{root, ".deps", "MarkdownToNotebook", "MarkdownToNotebook.wl"}],
        "Dependencies" -> {FileNameJoin[{root, ".deps", "WolframParser", "Parser"}]},
        "TimeConstraint" -> 240, "Prune" -> True, "Monitor" -> True], "documentation conversion"];
    If[Lookup[converted, "Failed", {"missing result"}] =!= {} ||
            Lookup[converted, "Unevaluated", <||>] =!= <||>, fail[converted]];
    Print["Documentation pages: ", Length[converted["Notebooks"]]];
    If[command === "notebooks", Exit[0]];
    built = require[WolframInstitute`PacletPage`DeployPacletResource[pacletDirectory,
        "DryRun" -> True, "TimeConstraint" -> 300, "MaxFailures" -> 0,
        "Exclude" -> archiveExclusions, "Monitor" -> True], "archive build"];
    If[!StringQ[built["Archive"]] || !FileExistsQ[built["Archive"]], fail["archive missing"]];
    Print["Archive: ", built["Archive"]];
    If[command === "site",
        site = require[WolframInstitute`PacletPage`BuildPacletPageSite[pacletDirectory,
            "Target" -> FileNameJoin[{root, "build", "site"}], "Monitor" -> True], "local site"];
        If[Lookup[site, "Failed", {"missing result"}] =!= {}, fail[site]]
    ];
    If[command === "publish",
        published = require[WolframInstitute`PacletPage`PublishPacletPage[pacletDirectory, "BioDataLink",
            "Account" -> $WolframID, "Build" -> False, "Monitor" -> True,
            "ResourceOptions" -> {"Build" -> False, "Exclude" -> archiveExclusions}], "publication"];
        If[!AllTrue[Lookup[published, {"Resource", "Site", "Check"}, None], AssociationQ],
            fail["publication returned incomplete resource, site or verification records"]];
        publicationRecord = Join[KeyTake[published["Resource"], {"Resource", "Version", "Commit"}],
            <|"ArchiveBytes" -> QuantityMagnitude[UnitConvert[published["Resource"]["ArchiveSize"], "Bytes"]],
                "Site" -> published["Site"]["Site"], "DocumentationPages" -> published["Site"]["Pages"],
                "Verified" -> TrueQ[published["Check"]["OK"]]|>];
        If[!StringQ[Export[FileNameJoin[{pacletDirectory, "build", "publication.json"}], publicationRecord, "RawJSON"]],
            fail["could not save the publication record"]];
        Print["Publication: ", publicationRecord];
        If[!TrueQ[published["Check"]["OK"]], fail["published site checks failed"]]
    ],
    fail["documentation command aborted"]
];
Exit[0];
