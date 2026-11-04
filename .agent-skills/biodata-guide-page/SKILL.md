---
name: biodata-guide-page
description: Author or revise a BioDataLink topic guide under docs/en/Guides, with task-oriented navigation, verified capability descriptions, and links to implemented symbols.
---

# Author a topic guide

Read [Documentation](../../GUIDE.md#documentation), the relevant design record
and neighboring pages. Write `docs/en/Guides/<Area>/<Topic>.md` in the area that
owns the task. Other guides may cross-link the symbol; keep one implementation.

Settle tasks such as discovery, metadata inspection, import and comparison
before writing the abstract. Check existing paclet, built-in and Function
Repository coverage by behavior. Keep proposed APIs in design records until
implemented. Mark external functions WL or WFR and describe the difference
when the paclet adds a capability.

Use the MarkdownToNotebook `Guide` template:

```yaml
---
Template: Guide
Name: TopicName
Title: Readable Topic Name
Context: WolframInstitute`BioDataLink`
Paclet: WolframInstitute/BioDataLink
URI: WolframInstitute/BioDataLink/guide/TopicName
Description: A concrete description of the data tasks covered
Keywords: [biological data]
RelatedGuides: [BioDataLink]
RelatedTutorials: []
---
```

Add Abstract and Functions sections. Group by user task; list implemented
paclet symbols before external links, alphabetically within each group. Use
short descriptions of results. State which providers or formats the task
currently supports and link to references for detailed limits.

Check that the hub reaches the guide, related pages exist, and filename,
metadata and URI agree. Use destination titles for related-page links and one
entry per destination. Run `make lint-docs`, build with `make notebooks`, and
inspect output. Record a source-only page as a draft if notebook verification
could not run.
