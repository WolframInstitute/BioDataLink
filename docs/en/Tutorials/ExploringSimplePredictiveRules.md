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

Evaluate the final Initialization group, then load the data below. Later inputs
reuse the named data and analysis results introduced in the text.

## Pin the measurements and the question

The [UCI Iris description](https://archive.ics.uci.edu/dataset/53/iris) specifies
150 plant records, four measurements in centimetres, and three species labels.
It also records differences between the distributed file and Fisher's article.
We retain the distributed values. The bundled provenance records the source,
CC BY 4.0 license, retrieval date and a locally computed content hash.

Load that provenance and check the bytes before interpreting the columns:

```wl
irisFile = FileNameJoin[{PacletObject["WolframInstitute/BioDataLink"]["AssetLocation", "Examples"], "iris.csv"}];
provenance = Import[FileNameJoin[{DirectoryName[irisFile], "iris.provenance.json"}], "RawJSON"];
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
Dataset[MapIndexed[<|"SourceRow" -> First[#2], "PetalLengthCm" -> #1[[3]], "PetalWidthCm" -> #1[[4]],
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
split = BlockRandom[SeedRandom[20261104, Method -> "MersenneTwister"];
    With[{groups = RandomSample /@ Values[KeySort[PositionIndex[species]]]},
        <|"Train" -> Sort[Flatten[Take[#, 35] & /@ groups]], "Test" -> Sort[Flatten[Drop[#, 35] & /@ groups]]|>]];
trainX = measurements[[split["Train"]]];
trainY = response[[split["Train"]]];
Dataset[<|"Records" -> Length[#], "SourceSpeciesCounts" -> Counts[species[[#]]]|> & /@ split]
```

The training partition has 105 records; the held-out partition has 45.
Only the training measurements and labels enter the next figures and search.
All mistakes receive equal cost per record, so the two source species merged
into “rest” jointly receive twice the weight of virginica in this split.

```wl
classNames = {"rest", "virginica"};
ListPlot[Table[Pick[trainX, trainY, class], {class, {0, 1}}],
    AxesLabel -> {"petal length (cm)", "petal width (cm)"}, PlotLegends -> classNames]
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

The rows of `lengthPass` and `widthPass` are binary predictions, calculated
once per cutoff. Multiplication implements AND; `a + b - a b` implements OR
for binary values. The OR error identity reuses the single-cutoff and AND
counts. [Outer](https://reference.wolfram.com/language/ref/Outer.html) evaluates
all pairs without repeating file reads or building a symbolic classifier for
each record. The matrices are small enough to inspect directly.

## Map the rule space

Each heatmap cell is one pair of training-derived cutoffs. The vertical axis
is the length cutoff; the horizontal axis is the width cutoff. Both panels
use the same error scale; their legends count training mistakes.
These are discrete candidates; the display does not interpolate a continuous
loss surface.
Cells are equally spaced by cutoff index; the tick labels give the cutoff
values in centimetres, rather than implying equally spaced measurements.

```wl
With[{errorRange = MinMax[{andErrors, orErrors}]},
    Legended[Grid[{MapThread[MatrixPlot[#1, DataReversed -> True, PlotLabel -> #2,
        ColorFunction -> (ColorData["GrayTones"][Rescale[#, errorRange]] &), ColorFunctionScaling -> False,
        FrameTicks -> {{cutTicks[lengthCuts], None}, {cutTicks[widthCuts], None}},
        FrameLabel -> {"length cutoff (cm)", "width cutoff (cm)"}] &,
        {{andErrors, orErrors}, {"AND rule", "OR rule"}}]}], BarLegend[{"GrayTones", errorRange}]]]
```

Broad low-error regions mean several programs fit these training observations
similarly. A sharp minimum does not establish a unique biological mechanism.

## Trade prediction errors against program size

Represent each candidate explicitly. Complexity is the number of threshold
comparisons: 0, 1 or 2. This is a simple, declared description of this grammar,
not a universal program-length measure; AND and OR have equal complexity here.

```wl
programs = candidatePrograms[trainY, lengthCuts, widthCuts, lengthErrors, widthErrors, andErrors, orErrors];
penalty = 2;
scoredPrograms = MapIndexed[Join[#1, <|"ID" -> First[#2],
    "Objective" -> #1["TrainErrors"] + penalty #1["Comparisons"]|>] &, programs];
bestBySize = Table[First[SortBy[Select[scoredPrograms, #["Comparisons"] === size &],
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
chosen = First[SortBy[scoredPrograms, {#["Objective"] &, #["Comparisons"] &, #["ID"] &}]];
ListLinePlot[{Lookup[bestBySize, "TrainErrors"], Lookup[bestBySize, "Objective"]}, DataRange -> {0, 2},
    Ticks -> {{0, 1, 2}, Automatic}, AxesLabel -> {"threshold comparisons", "error-count units"},
    PlotLegends -> {"training errors", "penalized objective"}]
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

## See what each additional comparison changes

Make the increase in expressiveness concrete before evaluating predictions.
At size zero, a constant rule gives every record the same label. One comparison
cuts the measurement plane with a single horizontal or vertical line. Two
comparisons can combine a length and width condition using AND or OR. In this
grammar that creates a rectangular intersection or an L-shaped union; it does
not permit an arbitrary curved boundary.

Compare the best training program at each size using the helper definitions
in Initialization. All three panels use the same training records, domain,
axes and colors.
No held-out labels enter this comparison. Shading marks predictions of virginica;
point colors distinguish the source labels in their earlier order.

```wl
With[{lengthRange = MinMax[trainX[[All, 1]]] + {-0.4, 0.4}, widthRange = MinMax[trainX[[All, 2]]] + {-0.2, 0.2}},
    GraphicsRow[Table[Show[
        RegionPlot[ruleCondition[program, length, width],
            {length, First[lengthRange], Last[lengthRange]}, {width, First[widthRange], Last[widthRange]}],
        ListPlot[Table[Pick[trainX, trainY, class], {class, {0, 1}}]],
        FrameLabel -> {"petal length (cm)", "petal width (cm)"},
        PlotLabel -> Row[{program["Comparisons"], " comparisons"}]], {program, bestBySize}]]]
```

The constant baseline makes 35 training errors, the best single comparison
makes six, and the best two-comparison rule makes three. The second comparison
adds a specific representational ability and reduces training errors by three;
the previously declared penalty charges two for that addition. This connects
the decision-region pictures to the numerical selection criterion.

Longer formulas or additional predictors would define a larger family. They
would need a fresh training/validation design before interpreting a comparison
as evidence of improved prediction. A more elaborate decision boundary is not
evidence of a more realistic biological mechanism.

## Evaluate the frozen rule once

Apply only `chosen` to the held-out measurements. Subsequent figures reuse
these predictions.

```wl
testX = measurements[[split["Test"]]];
testY = response[[split["Test"]]];
testPredictions = Boole[ruleCondition[chosen, #[[1]], #[[2]]]] & /@ testX;
With[{errors = Total[Abs[testPredictions - testY]]},
    <|"HeldOutRecords" -> Length[testY], "Errors" -> errors, "Accuracy" -> N[1 - errors/Length[testY]],
        "AlwaysRestAccuracy" -> N[Count[testY, 0]/Length[testY]]|>]
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

Plot the region predicted as virginica beside the held-out observations.
Point colors indicate source labels. This split has no mistakes
to highlight. The display domain is set from training
ranges plus a fixed margin, before any held-out plotting choices.

```wl
With[{lengthRange = MinMax[trainX[[All, 1]]] + {-0.4, 0.4}, widthRange = MinMax[trainX[[All, 2]]] + {-0.2, 0.2}},
    Show[RegionPlot[ruleCondition[chosen, length, width],
            {length, First[lengthRange], Last[lengthRange]}, {width, First[widthRange], Last[widthRange]}],
        ListPlot[Table[Pick[testX, testY, class], {class, {0, 1}}], PlotLegends -> classNames],
        FrameLabel -> {"petal length (cm)", "petal width (cm)"}]]
```

Nearby measurements can fall on opposite sides of a threshold. That is a
property of this program family; it does not imply that a plant changes
species when a measured petal width crosses the fitted cutoff.

## Distinguish the two kinds of error

Rows in the confusion matrix are observed labels; columns are predictions.
The upper-right cell counts non-virginica records predicted as virginica.
The lower-left cell counts virginica records predicted as the other class.
The color scale reports record counts, not percentages.

```wl
confusion = Table[Count[Transpose[{testY, testPredictions}], {observed, predicted}],
    {observed, {0, 1}}, {predicted, {0, 1}}];
MatrixPlot[confusion, PlotLegends -> Automatic, FrameLabel -> {"observed label", "predicted label"},
    FrameTicks -> {{Transpose[{Range[2], classNames}], None}, {Transpose[{Range[2], classNames}], None}}]
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

## Initialization

Evaluate these helper definitions before the examples above. The data choices
and analysis parameters remain in the main examples.

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
