(* Copy to benchmarks/reproduction/<Area>/<Slug>/reproduce.wls.
   Register claims in case.md before running. Fill requiredSymbols and add
   runClaim calls below. The unconfigured template exits with status 2.
   Comparison expectations come from the source, not the implementation.
   Apply a process-level timeout when launching this probe. *)

requiredSymbols = {};
If[requiredSymbols === {},
    Print["ABORT configure requiredSymbols and registered claim calls first"];
    Exit[2]
];

$probeRepoRoot = Nest[ParentDirectory, DirectoryName[$InputFileName], 4];
$probePacletDirectory = FileNameJoin[{$probeRepoRoot, "BioDataLink"}];
PacletDirectoryLoad[$probePacletDirectory];
Needs["WolframInstitute`BioDataLink`"];
$probePaclet = PacletObject["WolframInstitute/BioDataLink"];
If[!PacletObjectQ[$probePaclet] ||
        ExpandFileName[$probePaclet["Location"]] =!= ExpandFileName[$probePacletDirectory],
    Print["ABORT source checkout did not resolve"];
    Exit[2]
];
If[AnyTrue[requiredSymbols, Names["WolframInstitute`BioDataLink`" <> #] === {} &],
    Print["ABORT required exported symbols did not resolve"];
    Exit[2]
];

$claimBudget = 120;
$claimVerdicts = <||>;

(* Give a real result-shape predicate, such as IntegerQ, and a registered
   comparison predicate. For approximate values, state the tolerance in case.md.
   HoldComplete keeps the public computation unevaluated until timing begins. *)
runClaim[id_String, held_HoldComplete, expected_, validResultTest_, comparisonTest_] :=
    Module[{elapsed, got, verdict, detail},
        If[KeyExistsQ[$claimVerdicts, id],
            Print["ABORT duplicate claim identifier: ", id]; Exit[2]];
        {elapsed, got} = AbsoluteTiming[
            Quiet[Check[TimeConstrained[ReleaseHold[held], $claimBudget, $TimedOut], $Failed]]];
        {verdict, detail} = Which[
            got === $TimedOut, {"INCONCLUSIVE", "time budget exceeded"},
            got === $Failed || got === $Aborted || FailureQ[got],
                {"INCONCLUSIVE", "failed evaluation: " <> ToString[got, InputForm]},
            !TrueQ[validResultTest[got]],
                {"INCONCLUSIVE", "unexpected or unevaluated result: " <> ToString[got, InputForm]},
            TrueQ[comparisonTest[got, expected]], {"HIT", ToString[got, InputForm]},
            True, {"MISS", "got " <> ToString[got, InputForm] <>
                "; expected " <> ToString[expected, InputForm]}
        ];
        AssociateTo[$claimVerdicts, id -> verdict];
        Print["STAKE ", id, " ", verdict, " ", Round[1000 elapsed], " ms: ", detail]
    ];

(* Add registered calls here, for example:
   runClaim["S1", HoldComplete[publicComputation], expectedValue, IntegerQ, SameQ];
   A provisional MISS needs input/convention checks and an independent route
   before the final case record treats it as a defect. *)

If[$claimVerdicts === <||>, Print["ABORT no claims executed"]; Exit[2]];
Exit[If[AllTrue[Values[$claimVerdicts], # === "HIT" &], 0, 1]];
