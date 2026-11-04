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

<code>[BioDatasetDownload]()[*url*, File[*path*]]</code> downloads an HTTPS data file to the specified local path after checking its byte count and optional expected SHA-256.

## Details & Options

- *url* and *path* are strings. The URL must use HTTPS, contain at most 16384 characters and omit embedded user credentials, spaces, ASCII control characters and backslashes.
- The destination's parent directory must already exist. The function does not create directories automatically.
- The response body is streamed to a temporary sibling file. The destination is created or replaced only after size and checksum checks succeed.
- The function retrieves one complete HTTP 200 response. It follows at most five HTTPS redirects and does not automatically retry, resume, cache, extract or decompress a data file.
- An existing destination is rejected unless `"Overwrite" -> True`. A failed transfer or integrity check preserves the old destination and removes the incomplete temporary file.
- The downloader requires curl 8.4 or later. `Automatic` looks for a suitable executable on `PATH`; an absolute path can be supplied. No installation is attempted.
- The result is an `Association` with these fields:

| | |
| --- | --- |
| `"File"` | `File` containing the full local destination path |
| `"SourceURL"`, `"ResolvedURL"` | Requested and final source URLs with query and fragment information removed |
| `"RequestURLHash"` | SHA-256 of the exact requested URL's UTF-8 bytes |
| `"ByteCount"`, `"ContentHash"` | Stored file size and computed SHA-256 |
| `"ExpectedByteCount"`, `"ExpectedSHA256"` | Supplied expectations, or `Missing["NotProvided"]` |
| `"Verification"` | `"VerifiedSHA256"` when a supplied digest matched; otherwise `"ComputedSHA256Only"` |
| `"RetrievedAt"`, `"RedirectCount"` | Retrieval time in UTC and number of redirects followed |

- A computed hash identifies the retrieved bytes. With `"ExpectedSHA256" -> Automatic`, no independently supplied digest is checked. A supplied byte count is still checked separately.
- Agreement with an expected hash does not establish biological validity, source authenticity or license terms. The caller must retain the origin of that expected value.
- The result does not contain a parsed dataset. Use `Import` or a supported `BioDatasetLoad` format after the download succeeds.
- Options are listed with defaults in the middle column:

| | | |
| --- | --- | --- |
| `"CurlExecutable"` | `Automatic` | Suitable curl on `PATH`, or an absolute executable path |
| `"ExpectedByteCount"` | `Automatic` | Expected stored byte count; a nonnegative integer |
| `"ExpectedSHA256"` | `Automatic` | Expected SHA-256 as a string of 64 hexadecimal characters |
| `"MaxFileBytes"` | `100000000` | Maximum accepted file size; a positive integer below `2^63 - 1` |
| `"Overwrite"` | `False` | Whether a verified result may replace an existing file |
| `"TimeConstraint"` | `60` | Backend discovery, download and verification time in seconds; positive and at most 3600 |

- Final file placement and cleanup may finish beyond the time budget.

## Basic Examples

Download the small public UCI Iris file into a newly created temporary
directory. This online input is not evaluated during documentation generation:

```wl
#| eval: false
BioDatasetDownload[
    "https://archive.ics.uci.edu/ml/machine-learning-databases/iris/iris.data",
    File[FileNameJoin[{CreateDirectory[], "iris.csv"}]],
    "MaxFileBytes" -> 10000]
```

## Options

### ExpectedSHA256

Pin both the size and SHA-256 of the checked example file in an online download:

```wl
#| eval: false
BioDatasetDownload[
    "https://archive.ics.uci.edu/ml/machine-learning-databases/iris/iris.data",
    File[FileNameJoin[{CreateDirectory[], "iris.csv"}]],
    "MaxFileBytes" -> 10000, "ExpectedByteCount" -> 4551,
    "ExpectedSHA256" ->
        "6f608b71a7317216319b4d27b4d9bc84e6abd734eda7872b71a458569e2656c0"]
```

This expected hash was computed from the UCI file checked for the documentation;
it was not published by UCI. A later change in those bytes causes a mismatch
rather than silently substituting a new version.

### Overwrite

Explicitly permit replacement of a chosen existing file after the new transfer
passes its checks. Replace the example path before evaluating this online input:

```wl
#| eval: false
BioDatasetDownload[
    "https://archive.ics.uci.edu/ml/machine-learning-databases/iris/iris.data",
    File["/path/to/iris.csv"], "MaxFileBytes" -> 10000,
    "ExpectedSHA256" ->
        "6f608b71a7317216319b4d27b4d9bc84e6abd734eda7872b71a458569e2656c0",
    "Overwrite" -> True]
```

## Applications

Read a downloaded CSV only after checking that retrieval succeeded. This
online example creates its own temporary directory:

```wl
#| eval: false
With[{result = BioDatasetDownload[
    "https://archive.ics.uci.edu/ml/machine-learning-databases/iris/iris.data",
    File[FileNameJoin[{CreateDirectory[], "iris.csv"}]],
    "MaxFileBytes" -> 10000, "ExpectedByteCount" -> 4551,
    "ExpectedSHA256" ->
        "6f608b71a7317216319b4d27b4d9bc84e6abd734eda7872b71a458569e2656c0"]},
    If[FailureQ[result], result,
        Take[Import[result["File"], "CSV"], 3]]]
```

The file contains four floral measurements in centimetres and a species label,
without a header. The linked tutorial assigns names from UCI's variable
documentation and retains the download evidence before plotting values.

## Possible Issues

An HTTP URL is rejected before any transfer:

```wl
BioDatasetDownload["http://example.org/data.csv", File["data.csv"]]
```

An expected size exceeding the byte limit is rejected before any transfer:

```wl
BioDatasetDownload["https://example.org/data.csv", File["data.csv"],
    "MaxFileBytes" -> 100, "ExpectedByteCount" -> 101]
```

Source failures, timeouts, oversized responses and mismatched checksums produce
`Failure` results. They do not constitute empty datasets or completed local
files. Inspect the failure before retrying; retrying cannot resolve an
incorrect expected checksum or an unsuitable file format.
