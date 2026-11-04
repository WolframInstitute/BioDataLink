---
Template: Symbol
Name: BioDatasetDownload
Context: WolframInstitute`BioDataLink`
Paclet: WolframInstitute/BioDataLink
URI: WolframInstitute/BioDataLink/ref/BioDatasetDownload
Keywords: [download, HTTPS, data file, checksum, provenance]
SeeAlso: [BioDataURL, BioDatasetInfo, BioDatasetLoad, BioDatasetQuery, FileHash, Import]
RelatedGuides: [BioDataLink, DataAccess, Downloads]
RelatedTutorials: [DownloadingBiologicalData]
---

## Usage

<code>[BioDatasetDownload]()[*url*, File[*path*]]</code> downloads the HTTPS file at *url* to *path*.

## Details & Options

- *url* and *path* are strings. The destination's parent directory must exist.
- URLs must use HTTPS, contain at most 16384 characters and omit credentials, spaces, ASCII controls and backslashes.
- Downloads require curl 8.4 or later. `"CurlExecutable" -> Automatic` searches `PATH`; it does not install curl.
- A download accepts one HTTP 200 response and at most five HTTPS redirects. There is no automatic retry, resume, cache or decompression.
- Files are placed only after validation. `"Overwrite" -> True` allows replacement; a failed transfer preserves the old destination and removes incomplete data.
- The result is an `Association` with the following properties:

| | |
| --- | --- |
| `"File"` | `File` containing the full local destination path |
| `"SourceURL"`, `"ResolvedURL"` | Requested and final source URLs with query and fragment information removed |
| `"RequestURLHash"` | SHA-256 of the exact requested URL's UTF-8 bytes |
| `"ByteCount"`, `"ContentHash"` | Stored file size and computed SHA-256 |
| `"ExpectedByteCount"`, `"ExpectedSHA256"` | Supplied expectations, or `Missing["NotProvided"]` |
| `"Verification"` | `"VerifiedSHA256"` when a supplied digest matched; otherwise `"ComputedSHA256Only"` |
| `"RetrievedAt"`, `"RedirectCount"` | Retrieval time in UTC and number of redirects followed |

- The following options can be given:

| | | |
| --- | --- | --- |
| `"CurlExecutable"` | `Automatic` | Suitable curl on `PATH`, or an absolute executable path |
| `"ExpectedByteCount"` | `Automatic` | Expected stored byte count; a nonnegative integer |
| `"ExpectedSHA256"` | `Automatic` | Expected SHA-256 as a string of 64 hexadecimal characters |
| `"MaxFileBytes"` | `100000000` | Maximum accepted file size; a positive integer below `2^63 - 1` |
| `"Overwrite"` | `False` | Whether a verified result may replace an existing file |
| `"TimeConstraint"` | `60` | Backend discovery, download and verification time in seconds; positive and at most 3600 |

- `Automatic` for an expected size or hash omits that comparison. A computed hash identifies received bytes; an expected hash checks agreement with a supplied digest.
- Hashes do not establish biological validity or reuse terms. Record the origin of an expected digest.
- The time budget covers backend discovery, transfer and verification. Final placement and cleanup can finish later.
- Online examples require internet access and have no saved results.

## Basic Examples

Download the UCI Iris file:

```wl
#| eval: false
BioDatasetDownload["https://archive.ics.uci.edu/ml/machine-learning-databases/iris/iris.data", File[FileNameJoin[{CreateDirectory[], "iris.csv"}]]]
```

## Options

### ExpectedByteCount

Require a file of 4551 bytes:

```wl
#| eval: false
BioDatasetDownload["https://archive.ics.uci.edu/ml/machine-learning-databases/iris/iris.data", File[FileNameJoin[{CreateDirectory[], "iris.csv"}]], "ExpectedByteCount" -> 4551]
```

### ExpectedSHA256

Require the checked example's SHA-256:

```wl
#| eval: false
BioDatasetDownload["https://archive.ics.uci.edu/ml/machine-learning-databases/iris/iris.data", File[FileNameJoin[{CreateDirectory[], "iris.csv"}]],
    "ExpectedSHA256" -> "6f608b71a7317216319b4d27b4d9bc84e6abd734eda7872b71a458569e2656c0"]
```

This digest was computed locally from the UCI file, not supplied by UCI.

### Overwrite

Replace an existing file (substitute the destination path):

```wl
#| eval: false
BioDatasetDownload["https://archive.ics.uci.edu/ml/machine-learning-databases/iris/iris.data", File["/path/to/iris.csv"], "Overwrite" -> True]
```

## Applications

Download and read three CSV records:

```wl
#| eval: false
With[{download = BioDatasetDownload["https://archive.ics.uci.edu/ml/machine-learning-databases/iris/iris.data", File[FileNameJoin[{CreateDirectory[], "iris.csv"}]],
        "ExpectedSHA256" -> "6f608b71a7317216319b4d27b4d9bc84e6abd734eda7872b71a458569e2656c0"]},
    If[FailureQ[download], download, Take[Import[download["File"], "CSV"], 3]]]
```

See [Downloading and Inspecting Biological Data](paclet:WolframInstitute/BioDataLink/tutorial/DownloadingBiologicalData)
for column definitions, units and provenance.

## Possible Issues

HTTP URLs are rejected before transfer:

```wl
BioDatasetDownload["http://example.org/data.csv", File["data.csv"]]
```

---

An expected size cannot exceed the size limit:

```wl
BioDatasetDownload["https://example.org/data.csv", File["data.csv"], "MaxFileBytes" -> 100, "ExpectedByteCount" -> 101]
```

Source errors, timeouts, oversized files and checksum mismatches give `Failure`.
