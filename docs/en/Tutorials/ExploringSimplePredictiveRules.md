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

Predict `Iris-virginica` versus the other two Iris labels using petal length
and width. Enumerate simple threshold rules, select one on training data and
evaluate it once on held-out records.

The bundled [UCI Iris file](https://archive.ics.uci.edu/dataset/53/iris)
(CC BY 4.0) preserves UCI's distributed values. The analysis predicts labels
from static measurements; it does not identify developmental mechanisms.
Evaluate **Initialization**, then run the examples in order.

## Check and load the data

```wl
irisFile = FileNameJoin[{PacletObject["WolframInstitute/BioDataLink"]["AssetLocation", "Examples"], "iris.csv"}];
provenance = Import[FileNameJoin[{DirectoryName[irisFile], "iris.provenance.json"}], "RawJSON"];
If[FileHash[irisFile, "SHA256", "HexString"] =!= provenance["SHA256"], Abort[]];
KeyTake[provenance, {"Title", "DOI", "License", "SHA256"}]
```

Columns three and four contain petal measurements in centimetres. Set the
response to 1 for virginica and 0 for the other labels:

```wl
irisRows = DeleteCases[Import[irisFile, "CSV"], {} | {""}];
measurements = irisRows[[All, {3, 4}]];
species = irisRows[[All, 5]];
response = Boole[# === "Iris-virginica"] & /@ species;
Dataset[MapIndexed[<|"SourceRow" -> First[#2], "PetalLengthCm" -> #1[[3]], "PetalWidthCm" -> #1[[4]],
    "Species" -> #1[[5]]|> &, Take[irisRows, 5]]]
```

## Split before selecting a rule

Use 35 records per source species for training and 15 for testing. Retain the
seed, generator and row indices:

```wl
split = BlockRandom[SeedRandom[20261104, Method -> "MersenneTwister"];
    With[{groups = RandomSample /@ Values[KeySort[PositionIndex[species]]]},
        <|"Train" -> Sort[Flatten[Take[#, 35] & /@ groups]], "Test" -> Sort[Flatten[Drop[#, 35] & /@ groups]]|>]];
trainX = measurements[[split["Train"]]];
trainY = response[[split["Train"]]];
Dataset[<|"Records" -> Length[#], "SourceSpeciesCounts" -> Counts[species[[#]]]|> & /@ split]
```

Training has 105 records; testing has 45. Equal error costs give the combined
“rest” class twice virginica's weight. The split does not establish independent
sampling or representativeness of new populations.

## Enumerate threshold rules

Consider constants, a length cutoff, a width cutoff, and their AND/OR
combinations. Use strict `>`; equality follows the false branch. Cutoffs are
midpoints between distinct training values. This is a complete search only
within this increasing-threshold family.

```wl
lengthCuts = midpoints[trainX[[All, 1]]];
widthCuts = midpoints[trainX[[All, 2]]];
lengthPass = Outer[Boole[#2 > #1] &, lengthCuts, trainX[[All, 1]]];
widthPass = Outer[Boole[#2 > #1] &, widthCuts, trainX[[All, 2]]];
lengthErrors = Total[Abs[# - trainY]] & /@ lengthPass;
widthErrors = Total[Abs[# - trainY]] & /@ widthPass;
andErrors = Outer[Total[Abs[#1 #2 - trainY]] &, lengthPass, widthPass, 1];
orErrors = Outer[Plus, lengthErrors, widthErrors] - andErrors;
<|"LengthCutoffs" -> Length[lengthCuts], "WidthCutoffs" -> Length[widthCuts],
    "Programs" -> 2 + Length[lengthCuts] + Length[widthCuts] + 2 Length[lengthCuts] Length[widthCuts]|>
```

Plot training errors for all cutoff pairs. Both panels share an error scale;
cells are equally spaced by index, with cutoff values in centimetres:

```wl
With[{errorRange = MinMax[{andErrors, orErrors}]},
    Legended[Grid[{MapThread[MatrixPlot[#1, DataReversed -> True, PlotLabel -> #2,
        ColorFunction -> (ColorData["GrayTones"][Rescale[#, errorRange]] &), ColorFunctionScaling -> False,
        FrameTicks -> {{cutTicks[lengthCuts], None}, {cutTicks[widthCuts], None}},
        FrameLabel -> {"length cutoff (cm)", "width cutoff (cm)"}] &,
        {{andErrors, orErrors}, {"AND rule", "OR rule"}}]}], BarLegend[{"GrayTones", errorRange}]]]
```

Several rules can fit similarly. A good fit does not identify a unique mechanism.

## Select and freeze one rule

Define complexity as the number of comparisons. Fix the objective to training
errors plus two per comparison, then break ties by fewer comparisons and
enumeration ID:

```wl
programs = candidatePrograms[trainY, lengthCuts, widthCuts, lengthErrors, widthErrors, andErrors, orErrors];
penalty = 2;
scoredPrograms = MapIndexed[Join[#1, <|"ID" -> First[#2],
    "Objective" -> #1["TrainErrors"] + penalty #1["Comparisons"]|>] &, programs];
bestBySize = Table[First[SortBy[Select[scoredPrograms, #["Comparisons"] === size &],
    {#["TrainErrors"] &, #["ID"] &}]], {size, 0, 2}];
Dataset[bestBySize]
```

Select a rule and compare error with complexity:

```wl
chosen = First[SortBy[scoredPrograms, {#["Objective"] &, #["Comparisons"] &, #["ID"] &}]];
ListLinePlot[{Lookup[bestBySize, "TrainErrors"], Lookup[bestBySize, "Objective"]}, DataRange -> {0, 2},
    Ticks -> {{0, 1, 2}, Automatic}, AxesLabel -> {"threshold comparisons", "error-count units"},
    PlotLegends -> {"training errors", "penalized objective"}]
```

Inspect the selected rule:

```wl
Dataset[{chosen}]
```

The selected rule predicts virginica when petal length > 4.95 cm **or** width
> 1.65 cm. It makes three training errors (objective 7); the best single-cutoff
rule makes six (objective 8).

Compare the best training rule at each size on the same domain:

```wl
With[{lengthRange = MinMax[trainX[[All, 1]]] + {-0.4, 0.4}, widthRange = MinMax[trainX[[All, 2]]] + {-0.2, 0.2}},
    GraphicsRow[Table[Show[
        RegionPlot[ruleCondition[program, length, width],
            {length, First[lengthRange], Last[lengthRange]}, {width, First[widthRange], Last[widthRange]}],
        ListPlot[Table[Pick[trainX, trainY, class], {class, {0, 1}}]],
        FrameLabel -> {"petal length (cm)", "petal width (cm)"},
        PlotLabel -> Row[{program["Comparisons"], " comparisons"}]], {program, bestBySize}]]]
```

Keep the grammar and penalty fixed before testing. Choosing them after seeing
test results leaks evaluation data into model selection
([Cawley and Talbot 2010](https://www.jmlr.org/papers/v11/cawley10a.html)).

## Inspect nearby models before opening the test set

Vary the penalty while keeping all training errors fixed. This traces the
tradeoff between fit and complexity without using any held-out labels:

```wl
penalties = Range[0, 8, 1/2];
penaltySelections = Table[First[SortBy[scoredPrograms,
    {#["TrainErrors"] + lambda #["Comparisons"] &, #["Comparisons"] &, #["ID"] &}]], {lambda, penalties}];
GraphicsRow[{
    ListStepPlot[Transpose[{penalties, Lookup[penaltySelections, "Comparisons"]}], Frame -> True,
        FrameLabel -> {"penalty per comparison", "selected comparisons"}],
    ListLinePlot[Transpose[{penalties, Lookup[penaltySelections, "TrainErrors"]}], Frame -> True,
        FrameLabel -> {"penalty per comparison", "training errors"}]}]
```

The declared analysis still uses penalty 2. This curve is a sensitivity
experiment, not permission to choose a penalty after inspecting test outcomes.

Select rules within two objective units of the chosen rule. Show the fraction
predicting virginica over the measurement plane:

```wl
nearbyRules = Select[scoredPrograms, #["Objective"] <= chosen["Objective"] + 2 &];
DensityPlot[Evaluate[Mean[Boole[ruleCondition[#, length, width]] & /@ nearbyRules]],
    {length, 1, 7}, {width, 0, 2.7}, PlotRange -> {0, 1}, PlotLegends -> Automatic,
    FrameLabel -> {"petal length (cm)", "petal width (cm)"}, ColorFunction -> "BlueGreenYellow"]
```

Intermediate values mark disagreement within this selected rule family.
They are not calibrated class probabilities and do not include uncertainty
from unconsidered model forms.

## Compare selection with shuffled training labels

Randomly permute the training labels while preserving their counts. Repeat the
complete search for the smallest training error using the same cutoff grid.
The test labels remain unopened.

```wl
nullBestErrors = BlockRandom[SeedRandom[20261106]; Table[bestTrainingError[RandomSample[trainY]], {40}]];
Histogram[nullBestErrors, Automatic, "Probability", GridLines -> {{Min[Lookup[programs, "TrainErrors"]]}, None},
    Frame -> True, FrameLabel -> {"smallest training error after rule search", "fraction of shuffled-label runs"}]
```

The line is the best observed training error in this family. Repeating selection
inside each shuffled run accounts for the search performed here. This remains
an exploratory null comparison, not an estimate of performance on new plants.

## Test measurement sensitivity of the frozen rule

Add independent Gaussian noise to training predictors while keeping the chosen
rule fixed. Report the fraction whose prediction changes at each assumed
measurement-error scale:

```wl
trainingPredictions = Boole[ruleCondition[chosen, #[[1]], #[[2]]]] & /@ trainX;
measurementNoise = {0.01, 0.03, 0.05, 0.1};
predictionChanges = BlockRandom[SeedRandom[20261107]; Table[Table[
    With[{perturbed = trainX + RandomVariate[NormalDistribution[0, sd], Dimensions[trainX]]},
        Mean[Abs[(Boole[ruleCondition[chosen, #[[1]], #[[2]]]] & /@ perturbed) - trainingPredictions]]],
    {40}], {sd, measurementNoise}]];
BoxWhiskerChart[N[predictionChanges], ChartLabels -> measurementNoise, PlotRange -> {0, 1},
    FrameLabel -> {"assumed measurement SD (cm)", "fraction of predictions changed"}]
```

These are explicit noise scenarios rather than measured instrument errors.
Prediction stability, training fit and held-out accuracy address different
questions. Freeze the analysis before the evaluation below.

## Evaluate once and retain the record

Apply only the frozen rule to held-out measurements:

```wl
testX = measurements[[split["Test"]]];
testY = response[[split["Test"]]];
testPredictions = Boole[ruleCondition[chosen, #[[1]], #[[2]]]] & /@ testX;
With[{errors = Total[Abs[testPredictions - testY]]},
    <|"HeldOutRecords" -> Length[testY], "Errors" -> errors, "Accuracy" -> N[1 - errors/Length[testY]],
        "AlwaysRestAccuracy" -> N[Count[testY, 0]/Length[testY]]|>]
```

It makes zero errors among these 45 records; the always-rest baseline scores
two thirds. Zero observed errors does not imply zero future risk. Identical
feature pairs may occur in both partitions, and this split does not test
transfer across locations, acquisition methods or populations.

Rows of the confusion matrix are observed labels; columns are predictions:

```wl
classNames = {"rest", "virginica"};
confusion = Table[Count[Transpose[{testY, testPredictions}], {observed, predicted}],
    {observed, {0, 1}}, {predicted, {0, 1}}];
MatrixPlot[confusion, PlotLegends -> Automatic, FrameLabel -> {"observed label", "predicted label"},
    FrameTicks -> {{Transpose[{Range[2], classNames}], None}, {Transpose[{Range[2], classNames}], None}}]
```

Record the data split and selected model:

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

Retain source hash, split, search family, cutoffs, penalty, tie rules and the
confusion matrix. Changing the model family after this evaluation requires new
evaluation data or a nested selection procedure. Biological datasets with
multiple observations per donor need splits that respect those groups.

## Initialization

Helpers generate cutoff candidates, express each rule and enumerate its
training score:

```wl
midpoints[values_] := Mean /@ Partition[Union[values], 2, 1];
cutTicks[cuts_] := With[{positions = DeleteDuplicates[Round[Subdivide[1, Length[cuts], 4]]]},
    {#, NumberForm[cuts[[#]], {3, 2}]} & /@ positions];
ruleCondition[rule_, length_, width_] := Switch[rule["Kind"],
    "Constant", rule["Value"] === 1,
    "Length", length > rule["LengthCm"],
    "Width", width > rule["WidthCm"],
    "AND", length > rule["LengthCm"] && width > rule["WidthCm"],
    "OR", length > rule["LengthCm"] || width > rule["WidthCm"]];
candidatePrograms[y_, lengths_, widths_, lengthLosses_, widthLosses_, andLosses_, orLosses_] := Join[
    Table[<|"Kind" -> "Constant", "Value" -> v, "Comparisons" -> 0, "TrainErrors" -> Total[Abs[y - v]]|>, {v, {0, 1}}],
    MapThread[<|"Kind" -> "Length", "LengthCm" -> #1, "Comparisons" -> 1, "TrainErrors" -> #2|> &, {lengths, lengthLosses}],
    MapThread[<|"Kind" -> "Width", "WidthCm" -> #1, "Comparisons" -> 1, "TrainErrors" -> #2|> &, {widths, widthLosses}],
    Flatten[Table[<|"Kind" -> form[[1]], "LengthCm" -> lengths[[i]], "WidthCm" -> widths[[j]], "Comparisons" -> 2,
            "TrainErrors" -> form[[2, i, j]]|>,
        {form, {{"AND", andLosses}, {"OR", orLosses}}}, {i, Length[lengths]}, {j, Length[widths]}]]];
```

```wl
bestTrainingError[y_] := With[{le = Total[Abs[# - y]] & /@ lengthPass,
    we = Total[Abs[# - y]] & /@ widthPass,
    ae = Outer[Total[Abs[#1 #2 - y]] &, lengthPass, widthPass, 1]},
    Min[Join[{Total[y], Length[y] - Total[y]}, le, we, Flatten[ae], Flatten[Outer[Plus, le, we] - ae]]]];
```
