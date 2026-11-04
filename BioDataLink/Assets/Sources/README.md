# Identifiers.org source registry

`identifiers.json` retains complete namespace and endpoint records from the
[Identifiers.org registry API](https://docs.identifiers.org/pages/api.html).
Namespaces span biology and other domains; they do not count independent
databases or verified data connections.

EMBL-EBI's Identifiers.org team provides the registry under
[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/), as stated in its
[terms](https://docs.identifiers.org/pages/terms_of_use.html). BioDataLink sorts
namespaces by prefix and adds provenance and coverage counts while preserving
original records, nulls and unknown fields. Linked databases keep their own terms.

Source URL, API version, UTC retrieval time and raw-byte SHA-256 identify the
snapshot; the service supplies no Git revision. `Counts` separates namespaces,
endpoints, deprecated records and endpoints marked protected. Access flags do
not establish permission or availability. Identifier patterns can lag current IDs;
preserve `namespaceEmbeddedInLui` when interpreting them.

Refresh explicitly with `make sources-update`: one metadata response, capped at
4 MiB with a 30-second socket timeout, validated before atomic replacement.
It does not visit provider endpoints or download biological files. Default
tests and builds use the bundled snapshot.
