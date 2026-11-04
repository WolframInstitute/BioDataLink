# Identifiers.org source registry

`identifiers.json` contains the complete namespace records returned by the
[Identifiers.org registry API](https://docs.identifiers.org/pages/api.html).
The registry describes identifier namespaces and their provider locations.
These are not counts of distinct biological databases or verified download
adapters. Its coverage includes other scientific domains as well as biology.

The data is provided by the Identifiers.org team at EMBL-EBI under
[Creative Commons Attribution 4.0 International](https://creativecommons.org/licenses/by/4.0/),
as stated in the [Identifiers.org terms](https://docs.identifiers.org/pages/terms_of_use.html).
BioDataLink preserves complete namespace and nested resource records, sorts
namespaces by prefix, and adds provenance and separately named coverage counts.
The software's MIT license does not replace this metadata license or the terms
of the databases linked by the registry.

The snapshot records its source URL, API version, UTC retrieval time and SHA-256
of the exact downloaded bytes. The live service does not supply a Git revision;
retrieval time and byte hash identify this snapshot. `Counts` distinguishes
namespaces, provider resources, deprecated namespaces, deprecated resources
and resources marked as protected. Deprecation and access-help fields are
preserved, including null values and unknown future fields. A resource not
marked protected has not thereby been verified to allow unrestricted access.

Refresh explicitly from the repository root with `make sources-update`.
This reads a single metadata response, capped at 4 MiB with a 30-second socket
timeout, validates it, and atomically replaces the snapshot. It does not visit
registered provider URLs or retrieve biological files. Default tests and
builds do not refresh the registry.

Identifier patterns are source annotations and can lag current provider
accessions. Preserve `namespaceEmbeddedInLui` when interpreting patterns such
as Gene Ontology identifiers. Registry URL patterns describe links; they do
not establish a supported search API, import format or scientific validation.
