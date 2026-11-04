# Artifact and selected-import validation — 2026-11-04

These checks cover the local 0.3 implementation on Wolfram Language 15.0.0 for
Mac OS X ARM64. They establish specific transfer, import and example behavior;
they do not establish universal compatibility with HDF5 files or all remote
data services.

## Download transport

The nine offline download tests passed. Eleven additional checks exercised a
real curl process against temporary local HTTPS servers using a temporary CA
trusted only by the test process. They checked exact byte limits with and
without Content-Length, rejection and cleanup of oversized responses, HTTPS
redirects, URL-query redaction, refusal of an HTTP redirect, preservation of an
existing destination after checksum failure, prompt timeout cleanup, inclusion
of backend discovery in the time budget, and early termination of an oversized
unknown-length response. No request reached the HTTP downgrade target.

Run these explicit local transport checks with `make download-tests`. They
require a supported curl (8.4 or later), OpenSSL, Python and Wolfram Language.
They use loopback servers and do not call a biological provider or change the
machine's trusted certificates. Production transfer retains normal TLS
certificate verification.

A separate HTTPS retrieval of the small UCI Iris file returned 4551 bytes and
SHA-256 `6f608b71a7317216319b4d27b4d9bc84e6abd734eda7872b71a458569e2656c0`.
CSV import returned 150 nonblank records with five fields. This locally
computed digest pins the bytes used by the tutorials; it is not a
publisher-supplied integrity claim. Attribution and the original source URL
are retained in the bundled Iris provenance file.

## Optional AnnData backend

Seven offline Wolfram tests, eleven Python backend tests and six end-to-end
Wolfram import checks passed. The explicit test environment used Python
3.13.9, h5py 3.16.0 and NumPy 2.5.4. The Python tests use AnnData as an
independent fixture writer; production import requires only h5py and NumPy.

Checks cover dense, CSR and CSC selection; requested axis order; X, layer and
raw matrix axes; categorical and nullable annotations; duplicate identifiers;
an integer above 2^53; floating-point values; unsupported encodings; selected
nonfinite values; and external/soft HDF5 links. Transfer and selected-element
limits are checked separately. The JSON transfer bound is not a hard bound on
Python heap allocation or HDF5 chunk reads.

The bundled synthetic file is 64,480 bytes with a 3-by-4 primary matrix. A
2-by-3 selected import took 0.344346 seconds on the first measured call and a
median of 0.122955 seconds across five subsequent calls (range
0.117248–0.128453 seconds). Each call starts a new Python process. These
measurements include native Wolfram conversion and cleanup; they exclude
Wolfram kernel startup and network transfer. Python import process startup
alone had a median of 0.095549 seconds.

This tiny fixture primarily measures process and conversion overhead, not
large-file throughput. The reader avoids a complete whole-file hash and
projects only selected matrix and metadata structures. Its source-file
size, modification time and inode checks detect ordinary changes during the
read but do not provide a cryptographic snapshot. See the
[performance evidence](evidence/2026-11-04-h5ad-performance.json).

## Complete runtime checks

`make test python-tests` passed 61 Wolfram tests and 17 Python automation
tests. `make h5ad-tests` passed the 11 optional Python tests and 6 actual
Wolfram-to-Python imports. `make download-tests` passed all 11 transport
checks. The default tests remain offline and optional-backend setup remains
explicit. The CI configuration includes the optional H5AD checks; this note
records local execution, not a hosted CI run.

## Documentation and packaged artifact

At checkpoint `9f30d85`, PacletPage built 25 documentation notebooks (ten
tutorials, eight symbol references and seven guides), the resource definition
and the 0.3.0 paclet.
Every saved documentation notebook was scanned; none contained Message cells.
Those six new computational tutorials contained 36 figure groups. Their inputs
were executed in fresh kernels, and the figures were inspected, including
representative light/dark notebook appearances. Review corrected clipped
nested legends, heatmap ticks and graph vertex sizes before the build.
Live downloads and optional H5AD examples remain unevaluated in the default
documentation build; the optional H5AD tutorial was run separately with the
configured backend.

The archive passed PacletPage's isolated fresh-kernel load check. An additional
fresh-kernel check of its extracted contents passed eight checks: package
location, source-directory count, catalog count, GO resolver construction,
download URL validation, exact selected H5AD values including an integer above
2^53, selected axis order and the Iris digest. The packaged Python bridge,
requirements and both new example assets match their source bytes. Generated
Python bytecode is excluded from the archive.

## Graph exploration and progressive rule complexity

The subsequent documentation work adds an eleventh tutorial on choosing
measurements to distinguish model predictions. It uses a fully declared
synthetic prediction matrix and bounded-error observation model. Exact Wolfram
and independent Python checks agree on the greedy measurement order, exhaustive
panel comparisons, all interval boundaries and the nontransitivity example.
All eight model vertices are retained as the unresolved-pair graph loses edges.

The predictive tutorial now visualizes the best training rules with zero, one
and two comparisons. Their training errors are 35, 6 and 3; the original
selection criterion and held-out result remain unchanged. The network tutorial
compares raw and standardized distances with identical neighbor-query
conventions, retains source-row tooltips, and reuses stored perturbation edge
sets for stability plots. The raw and standardized graphs have 799 and 787
edges with 582 shared edges; their component sizes are {100, 50} and {150}.
Neither graph has a single edge whose deletion splits a connected component.

The cellular automaton tutorial adds rule-mutation and exact-observation
equivalence graphs, then progresses from radius-zero baselines to three-site
and five-site majority updates. Ten independent checks compare the native
majority implementations with explicit periodic neighbor sums on five seeds
per radius. The larger comparison generates one 32-entry lookup table;
it does not enumerate the 2^32 possible radius-two binary lookup rules.

The seven analytical tutorials now contain 50 figure groups. Source examples
and representative light/dark outputs were inspected after these extensions;
plot endpoint margins were corrected so zero-valued observations and final
coverage drops remain visible. These calculations illustrate stated analysis
and model assumptions, rather than establishing biological mechanisms.

The final collection rebuild passed with 26 documentation notebooks, including
all eleven tutorials. The archive again passed its isolated fresh-kernel load
check. All 26 saved notebooks have zero Message cells. Saved graph galleries,
decision regions, progression plots and the question-led guide were inspected
in light and dark appearances. Their legends, labels and endpoint values
remain visible in the generated documentation style.

Archive inspection confirmed all 24 tracked kernel and asset files match the
checkout byte-for-byte, with no generated Python bytecode included. The
documentation extension changes no runtime contract. The earlier runtime and
transport checks remain applicable; the added numerical and visual checks
specifically cover the new tutorial computations.
