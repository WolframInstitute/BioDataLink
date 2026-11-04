---
Template: TechNote
Name: ExploringSimplePredictiveRules
Title: Exploring Simple Predictive Rules
Context: WolframInstitute`BioDataLink`
Paclet: WolframInstitute/BioDataLink
URI: WolframInstitute/BioDataLink/tutorial/ExploringSimplePredictiveRules
Keywords: [application, iris, rule enumeration, classification, held-out data, complexity, visualization]
RelatedGuides: [BioDataLink, DataAccess]
RelatedTutorials: [DownloadingBiologicalData]
---

Can a small, readable program predict a species label from floral measurements?
This tutorial enumerates a finite family of threshold rules, measures every
candidate on training records, and evaluates one selected rule on held-out
records. All inputs use the attributed Iris file bundled with BioDataLink;
no network access, Python session or additional paclet is required.

The inspiration is Ruliology's practice of examining a whole finite rule space
and Ruliobiology's separation of rules, states and measurements. Here a rule
maps two measurements to a label. It is not a developmental update rule: the
table contains neither time series nor interventions. A successful prediction
does not identify the mechanism that produced a flower.

## Pin the measurements and the question

The [UCI Iris description](https://archive.ics.uci.edu/dataset/53/iris) specifies
150 plant records, four measurements in centimetres, and three species labels.
It also records differences between the distributed file and Fisher's article.
We retain the distributed values. The bundled provenance records the source,
CC BY 4.0 license, retrieval date and a locally computed content hash.

Load that provenance and check the bytes before interpreting the columns:

```wl
exampleDirectory = FileNameJoin[{
    PacletObject["WolframInstitute/BioDataLink"]["Location"], "Assets", "Examples"}];
irisFile = FileNameJoin[{exampleDirectory, "iris.csv"}];
provenance = Import[FileNameJoin[{exampleDirectory, "iris.provenance.json"}], "RawJSON"];
If[FileHash[irisFile, "SHA256", "HexString"] =!= provenance["SHA256"], Abort[]];
KeyTake[provenance, {"Title", "DOI", "License", "SHA256"}]
```

Read nonblank records. The source file has no header; its variable definitions
assign the third and fourth columns to petal length and width. The response is
1 for `Iris-virginica` and 0 for the other two source labels combined. This
binary question and these two predictors are fixed before the search.

```wl
irisRows = DeleteCases[Import[irisFile, "CSV"], {} | {""}];
measurements = irisRows[[All, {3, 4}]];
species = irisRows[[All, 5]];
response = Boole[# === "Iris-virginica"] & /@ species;
Dataset[MapIndexed[<|"SourceRow" -> First[#2],
    "PetalLengthCm" -> #1[[3]], "PetalWidthCm" -> #1[[4]],
    "Species" -> #1[[5]]|> &, Take[irisRows, 5]]]
```

`SourceRow` is the nonblank record position, not a biological accession.
There is no scaling, imputation or biological normalization in this workflow.

## Separate training from evaluation

Randomly assign 35 records from each original species to training, leaving
15 from each for evaluation. Stratification preserves the supplied species
counts in both partitions. It does not establish independent sampling or
representativeness of an external plant population.

[BlockRandom](https://reference.wolfram.com/language/ref/BlockRandom.html)
isolates the random-generator state. An explicit seed and generator make the
split reproducible in the tested Wolfram Language version. Retain the row
indices as part of an analysis record when sharing results.

```wl
split = BlockRandom[
    SeedRandom[20261104, Method -> "MersenneTwister"];
    shuffledGroups = RandomSample /@
        (Flatten[Position[species, #]] & /@ Sort[DeleteDuplicates[species]]);
    <|"Train" -> Sort[Flatten[Take[#, 35] & /@ shuffledGroups]],
      "Test" -> Sort[Flatten[Drop[#, 35] & /@ shuffledGroups]]|>
];
trainX = measurements[[split["Train"]]];
trainY = response[[split["Train"]]];
Dataset[{
    <|"Partition" -> "training", "Records" -> Length[split["Train"]],
      "SourceSpeciesCounts" -> Counts[species[[split["Train"]]]]|>,
    <|"Partition" -> "held out", "Records" -> Length[split["Test"]],
      "SourceSpeciesCounts" -> Counts[species[[split["Test"]]]]|>
}]
```

The training partition has 105 records; the held-out partition has 45.
Only the training measurements and labels enter the next figures and search.
All mistakes receive equal cost per record, so the two source species merged
into “rest” jointly receive twice the weight of virginica in this split.

```wl
classNames = {"rest", "virginica"};
classColors = ColorData[97] /@ {1, 2};
trainingFigure = ListPlot[
    Table[Pick[trainX, trainY, class], {class, {0, 1}}],
    Frame -> True, FrameLabel -> {"petal length (cm)", "petal width (cm)"},
    PlotStyle -> classColors, PlotMarkers -> Automatic,
    PlotLegends -> classNames, PlotLabel -> "Training records only",
    ImageSize -> 480]
```

The overlapping region is important: a cutoff can make errors even when
measurements and labels are recorded correctly.

## Define a finite program family

Consider five forms: a constant prediction, a length cutoff, a width cutoff,
the AND of both cutoffs, and the OR of both cutoffs. A comparison uses strict
`>`; equality follows the false branch. The family contains only increasing
thresholds. It excludes negative comparisons, additional predictors, oblique
boundaries and longer programs. Enumeration will be complete within this
declared family, not among all possible classifiers.

For each measurement, place candidate thresholds halfway between consecutive
distinct training values. These gaps enumerate the distinct nonconstant
training partitions for a single increasing cutoff. They are not estimated
physical transition points, and other locations within a gap can differ on
new measurements. Constant programs supply the two extreme predictions.

```wl
midpoints[values_] := Mean /@ Partition[Sort[DeleteDuplicates[values]], 2, 1];
lengthCuts = midpoints[trainX[[All, 1]]];
widthCuts = midpoints[trainX[[All, 2]]];
lengthPass = Outer[Boole[#2 > #1] &, lengthCuts, trainX[[All, 1]]];
widthPass = Outer[Boole[#2 > #1] &, widthCuts, trainX[[All, 2]]];
lengthErrors = Total[Abs[# - trainY]] & /@ lengthPass;
widthErrors = Total[Abs[# - trainY]] & /@ widthPass;
andErrors = Outer[Function[{a, b}, Total[Abs[a b - trainY]]],
    lengthPass, widthPass, 1];
orErrors = Outer[Plus, lengthErrors, widthErrors] - andErrors;
<|"LengthCutoffs" -> Length[lengthCuts], "WidthCutoffs" -> Length[widthCuts],
  "Programs" -> 2 + Length[lengthCuts] + Length[widthCuts] +
      2 Length[lengthCuts] Length[widthCuts]|>
```

The rows of `lengthPass` and `widthPass` are binary predictions, calculated
once per cutoff. Multiplication implements AND; `a + b - a b` implements OR
for binary values. The OR error identity reuses the single-cutoff and AND
counts. [Outer](https://reference.wolfram.com/language/ref/Outer.html) evaluates
all pairs without repeating file reads or building a symbolic classifier for
each record. The matrices are small enough to inspect directly.

## Map the rule space

Each heatmap cell is one pair of training-derived cutoffs. The vertical axis
is the length cutoff; the horizontal axis is the width cutoff. Both panels
use the same error scale, and brighter colors mean more training mistakes.
These are discrete candidates; the display does not interpolate a continuous
loss surface.
Cells are equally spaced by cutoff index; the tick labels give the cutoff
values in centimetres, rather than implying equally spaced measurements.

```wl
cutTicks[cuts_] := With[{positions = DeleteDuplicates[
    Round[Subdivide[1, Length[cuts], 4]]]},
    {#, NumberForm[cuts[[#]], {3, 2}]} & /@ positions];
errorRange = MinMax[Flatten[{andErrors, orErrors}]];
ruleSpaceFigure = Legended[GraphicsRow[
    MapThread[MatrixPlot[#1, DataReversed -> True,
        FrameTicks -> {{cutTicks[lengthCuts], None}, {cutTicks[widthCuts], None}},
        FrameLabel -> {{"width cutoff (cm labels)", None}, {"length cutoff (cm labels)", None}},
        ColorFunction -> (ColorData["SolarColors"][Rescale[#, errorRange]] &),
        ColorFunctionScaling -> False, PlotRange -> errorRange,
        PlotLabel -> #2, AspectRatio -> 1, ImageSize -> 340] &,
      {{andErrors, orErrors}, {"AND rule", "OR rule"}}], ImageSize -> 700],
    Placed[BarLegend[{"SolarColors", errorRange}, LegendLabel -> "training errors"], Right]]
```

Broad low-error regions mean several programs fit these training observations
similarly. A sharp minimum does not establish a unique biological mechanism.

## Trade prediction errors against program size

Represent each candidate explicitly. Complexity is the number of threshold
comparisons: 0, 1 or 2. This is a simple, declared description of this grammar,
not a universal program-length measure; AND and OR have equal complexity here.

```wl
programs = Join[
    Table[<|"Kind" -> "Constant", "Value" -> value, "Comparisons" -> 0,
        "TrainErrors" -> Total[Abs[trainY - value]]|>, {value, {0, 1}}],
    MapThread[<|"Kind" -> "Length", "LengthCm" -> #1,
        "Comparisons" -> 1, "TrainErrors" -> #2|> &, {lengthCuts, lengthErrors}],
    MapThread[<|"Kind" -> "Width", "WidthCm" -> #1,
        "Comparisons" -> 1, "TrainErrors" -> #2|> &, {widthCuts, widthErrors}],
    Flatten[Table[<|"Kind" -> "AND", "LengthCm" -> lengthCuts[[i]],
        "WidthCm" -> widthCuts[[j]], "Comparisons" -> 2,
        "TrainErrors" -> andErrors[[i, j]]|>,
        {i, Length[lengthCuts]}, {j, Length[widthCuts]}]],
    Flatten[Table[<|"Kind" -> "OR", "LengthCm" -> lengthCuts[[i]],
        "WidthCm" -> widthCuts[[j]], "Comparisons" -> 2,
        "TrainErrors" -> orErrors[[i, j]]|>,
        {i, Length[lengthCuts]}, {j, Length[widthCuts]}]]
];
penalty = 2;
scoredPrograms = MapIndexed[Join[#1, <|"ID" -> First[#2],
    "Objective" -> #1["TrainErrors"] + penalty #1["Comparisons"]|>] &, programs];
bestBySize = Table[First[SortBy[
    Select[scoredPrograms, #["Comparisons"] === size &],
    {#["TrainErrors"] &, #["ID"] &}]], {size, 0, 2}];
Dataset[bestBySize]
```

Before looking at held-out predictions, fix the objective as training errors
plus two error-count units per comparison. This penalty is an illustrative
preference for shorter programs, not a parameter optimized on these data.
Select the smallest objective; break ties by fewer comparisons and then the
enumeration ID. Changing the grammar or penalty after inspecting evaluation
results would make that evaluation part of model selection.

```wl
chosen = First[SortBy[scoredPrograms,
    {#["Objective"] &, #["Comparisons"] &, #["ID"] &}]];
complexityFigure = ListLinePlot[{
    ({#["Comparisons"], #["TrainErrors"]} & /@ bestBySize),
    ({#["Comparisons"], #["Objective"]} & /@ bestBySize)},
    Frame -> True, FrameLabel -> {"threshold comparisons", "error-count units"},
    PlotMarkers -> Automatic, PlotLegends -> {"training errors", "penalized objective"},
    FrameTicks -> {{Automatic, None}, {{0, 1, 2}, None}}, PlotRange -> All,
    PlotLabel -> "Best training rule at each size", ImageSize -> 500]
```

The plot shows training fit and the fixed complexity cost. It does not show
held-out errors for competing programs. Keeping final evaluation separate
from selection addresses the selection-bias problem discussed by
[Cawley and Talbot (2010)](https://www.jmlr.org/papers/v11/cawley10a.html).

Inspect the frozen rule before opening the evaluation partition:

```wl
Dataset[{chosen}]
```

With this file and split, the selected program predicts virginica when petal
length exceeds 4.95 cm OR petal width exceeds 1.65 cm. It makes three training
errors, giving objective 7. The best one-comparison program makes six training
errors, giving objective 8, so the extra comparison is retained under the
declared penalty.

## Evaluate the frozen rule once

Define the meaning of each program form, then apply only `chosen` to the
held-out measurements. Subsequent figures reuse these predictions.

```wl
ruleCondition[rule_, length_, width_] := Switch[rule["Kind"],
    "Constant", rule["Value"] === 1,
    "Length", length > rule["LengthCm"],
    "Width", width > rule["WidthCm"],
    "AND", length > rule["LengthCm"] && width > rule["WidthCm"],
    "OR", length > rule["LengthCm"] || width > rule["WidthCm"]];
testX = measurements[[split["Test"]]];
testY = response[[split["Test"]]];
testPredictions = Boole[ruleCondition[chosen, #[[1]], #[[2]]]] & /@ testX;
testErrors = Total[Abs[testPredictions - testY]];
<|"HeldOutRecords" -> Length[testY], "Errors" -> testErrors,
  "Accuracy" -> N[1 - testErrors/Length[testY]],
  "AlwaysRestAccuracy" -> N[Count[testY, 0]/Length[testY]]|>
```

The constant “rest” baseline is correct for two thirds of this partition.
The selected program makes no mistakes among these 45 held-out records; zero
observed errors does not imply zero error risk.
Repeated feature pairs can occur in both partitions; this is evaluation on
held-out records, not necessarily on previously unseen measurement pairs.
One held-out result on a small, familiar benchmark is not an estimate of
performance across other locations, acquisition methods or plant populations.
The source does not provide collection groups that would support a separate
group-based split here.

Plot the rule's predicted regions and the held-out observations. Background
colors indicate predictions; point colors and shapes indicate source labels.
Open red circles identify mistakes. The display domain is set from training
ranges plus a fixed margin, before any held-out plotting choices.

```wl
lengthRange = MinMax[trainX[[All, 1]]] + {-0.4, 0.4};
widthRange = MinMax[trainX[[All, 2]]] + {-0.2, 0.2};
predictionRegion = RegionPlot[
    Evaluate[{Not[ruleCondition[chosen, length, width]],
        ruleCondition[chosen, length, width]}],
    {length, First[lengthRange], Last[lengthRange]},
    {width, First[widthRange], Last[widthRange]},
    PlotStyle -> (Directive[Opacity[0.2], #] & /@ classColors),
    BoundaryStyle -> Gray, PlotPoints -> 50, MaxRecursion -> 2,
    FrameLabel -> {"petal length (cm)", "petal width (cm)"}];
wrongPositions = Flatten[Position[MapThread[Unequal, {testPredictions, testY}], True]];
heldOutFigure = Legended[Show[predictionRegion,
    ListPlot[Table[Pick[testX, testY, class], {class, {0, 1}}],
        PlotStyle -> classColors, PlotMarkers -> {{"\[FilledCircle]", 9}, {"\[FilledUpTriangle]", 10}}],
    ListPlot[testX[[wrongPositions]], PlotStyle -> Red, PlotMarkers -> {"\[EmptyCircle]", 18}],
    PlotLabel -> "Frozen rule and held-out records", ImageSize -> 500],
    Placed[PointLegend[classColors, classNames,
        LegendMarkers -> {"\[FilledCircle]", "\[FilledUpTriangle]"}], Below]]
```

Nearby measurements can fall on opposite sides of a threshold. That is a
property of this program family; it does not imply that a plant changes
species when a measured petal width crosses the fitted cutoff.

## Distinguish the two kinds of error

Rows in the confusion matrix are observed labels; columns are predictions.
The upper-right cell counts non-virginica records predicted as virginica.
The lower-left cell counts virginica records predicted as the other class.
The displayed numbers are record counts, not percentages.

```wl
confusion = Table[Count[Transpose[{testY, testPredictions}], {observed, predicted}],
    {observed, {0, 1}}, {predicted, {0, 1}}];
confusionFigure = MatrixPlot[confusion,
    FrameTicks -> {{{{1, "rest"}, {2, "virginica"}}, None},
        {{{1, "rest"}, {2, "virginica"}}, None}},
    FrameLabel -> {{"predicted label", None}, {"observed label", None}},
    ColorFunction -> (ColorData["SolarColors"][#/Max[confusion]] &),
    ColorFunctionScaling -> False, PlotRange -> {0, Max[confusion]},
    Epilog -> Table[Text[Style[confusion[[row, column]], 14,
        If[confusion[[row, column]] < Max[confusion]/2, White, Black]],
        {column - 0.5, 2.5 - row}], {row, 2}, {column, 2}],
    PlotLabel -> "Held-out confusion matrix (records)", ImageSize -> 380]
```

Keep the split, the entire declared search family and the selected rule with
the result, rather than retaining accuracy alone:

```wl
analysisRecord = <|"DataSHA256" -> provenance["SHA256"],
    "WolframVersion" -> $Version, "Seed" -> 20261104,
    "RandomMethod" -> "MersenneTwister", "SourceRows" -> split,
    "Predictors" -> {"PetalLengthCm", "PetalWidthCm"},
    "PositiveLabel" -> "Iris-virginica", "PenaltyPerComparison" -> penalty,
    "ProgramForms" -> {"Constant", "Length", "Width", "AND", "OR"},
    "Comparison" -> ">", "TieBreak" -> {"Comparisons", "ID"},
    "LengthCutoffsCm" -> lengthCuts, "WidthCutoffsCm" -> widthCuts,
    "ProgramCount" -> Length[programs], "SelectedRule" -> chosen,
    "ConfusionRows" -> classNames, "ConfusionColumns" -> classNames,
    "HeldOutConfusionMatrix" -> confusion|>;
KeyTake[analysisRecord, {"ProgramCount", "SelectedRule", "HeldOutConfusionMatrix"}]
```

## What transfers to richer biological data

The transferable workflow is to retain source definitions, declare an
interpretable model family, enumerate it efficiently, and separate choosing a
rule from evaluating it. A next experiment could use grouped training and
evaluation records from a new study, or a predeclared richer grammar. A new
grammar or penalty chosen after seeing these results needs fresh evaluation
data or a properly nested selection procedure.

Ruliology's
[rule-space tutorial](https://www.wolframcloud.com/obj/wolframinstitute/DeployedResources/Paclet/WolframInstitute/Ruliology/Documentation/tutorial/AnalyzingCellularAutomatonRuleSpace.html)
examines compatible update rules and changes between rules. Ruliobiology's
[FiniteCellularAutomaton](https://www.wolframcloud.com/obj/wolframinstitute/DeployedResources/Paclet/WolframInstitute/Ruliobiology/Documentation/ref/FiniteCellularAutomaton.html)
and [AdaptiveCellularAutomaton](https://www.wolframcloud.com/obj/wolframinstitute/DeployedResources/Paclet/WolframInstitute/Ruliobiology/Documentation/ref/AdaptiveCellularAutomaton.html)
simulate specified dynamical systems and search over their behavior. Those
are useful directions when observations include actual state transitions and
the observation process is explicit. Their APIs are not called in this
example, and prediction from a cross-sectional table does not validate a
cellular-automaton model of a plant.

Causal questions require an explicit causal model and supporting assumptions,
as described in [Pearl (2009)](https://ftp.cs.ucla.edu/pub/stat_ser/r350.pdf).
The threshold programs here describe a predictive association only.
