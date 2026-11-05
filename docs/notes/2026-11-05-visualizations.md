# Biological visualization contracts

The `Visualizations` kernel area accepts ordinary Wolfram values. It neither
downloads data nor infers measurement units, normalization, biological labels
or molecular correspondence. Native plotting functions remain the first choice
for ribbons, heat maps, networks and time series.

| Function | Added behavior |
| --- | --- |
| `BioEmbeddingPlot` | Join coordinates to annotations by observation ID; preserve category colors and continuous ranges when the full annotation association accompanies a subset; draw high continuous values last |
| `BioExpressionDotPlot` | Aggregate sparse observations by group; encode detection fraction by area and group mean by color; retain denominators in tooltips |
| `BioSequenceCompositionPlot` | Count overlapping DNA words without bridging ambiguous bases, with an explicit quadrant convention and a bounded grid |
| `BioSequenceSkewPlot` | Count selected bases in complete windows; retain one-based midpoints and undefined denominators |
| `BioStructureComparisonPlot` | Match residue IDs, select a noncollinear alignment region, rigidly align traces and retain region colors |

Plot functions return native graphics, optionally wrapped in `Legended`.
Standard native options and `SetOptions` are honored. Options controlling
scientific calculations are explicit, including the detection threshold,
relative versus shared expression colors, DNA word length and alignment IDs.
Plotting does not silently choose missing-value imputation or normalization.

Expression summaries materialize only group-by-feature arrays after sparse
aggregation. Sequence grids are limited to 256 by 256 cells. Coordinates and
annotation associations are validated before plotting. Small asymmetric test
fixtures independently check ID alignment, denominators, word quadrants,
ambiguity handling, window positions and rigid transforms.

The expanded computational essays distinguish descriptive exploration,
synthetic controls and held-out prediction. They keep scientific choices in
visible inputs, short interpretation beside each figure, and reusable analysis
helpers in the final native Initialization section. Dataset revisions and
source licenses remain those in the bundled example records.

## Local performance check

On the development machine with Wolfram Language 15.0, loading the package
offline took 0.239 seconds. Reading the bundled PBMC JSON took 1.701 seconds.
The selected sparse 2,700-by-13 marker matrix occupied 209,944 bytes.
Construction and front-end rasterization were measured separately:

| Operation | First call | Median of five further calls | Render at 600 pixels |
| --- | ---: | ---: | ---: |
| Eight-group expression dot plot | 0.034 s | 0.016 s | 1.746 s |
| ID-aligned embedding of 2,700 observations | 0.013 s | 0.013 s | 0.313 s |

These are local observations, not timing guarantees. They include input
validation and plot construction; JSON conversion and front-end rendering are
reported separately. No data provider was contacted.
