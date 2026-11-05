WOLFRAMSCRIPT ?= wolframscript
PYTHON ?= python3
.DEFAULT_GOAL := help
.PHONY: help all check test python-tests h5ad-tests download-tests documentation-tests lint-docs bootstrap notebooks site build check-publish publish hooks catalog-update sources-update example-data hero clean

help:
	@printf 'make check | test [FILES="..."] | python-tests | lint-docs\nmake h5ad-tests [BIODATALINK_PYTHON set] | download-tests\nmake documentation-tests | bootstrap | notebooks | site | build | check-publish | all\nmake catalog-update REVISION=<commit> | sources-update | example-data | hero | hooks | publish | clean\n'

all: check test python-tests documentation-tests build

check:
	$(WOLFRAMSCRIPT) -file scripts/check.wls

test:
	$(WOLFRAMSCRIPT) -file scripts/test.wls $(FILES)

python-tests:
	$(PYTHON) -m unittest discover -s scripts/tests -v

# Explicit optional-backend checks. These never install dependencies or contact providers.
h5ad-tests:
	@test -n "$$BIODATALINK_PYTHON" || (echo 'Set BIODATALINK_PYTHON to the configured interpreter' >&2; exit 1)
	"$$BIODATALINK_PYTHON" -m unittest discover -s BioDataLink/Tests/Python -v
	$(WOLFRAMSCRIPT) -file BioDataLink/Tests/Integration/AnnData.wls

download-tests:
	WOLFRAMSCRIPT="$(WOLFRAMSCRIPT)" $(PYTHON) BioDataLink/Tests/Integration/download_transport.py

documentation-tests:
	$(WOLFRAMSCRIPT) -file BioDataLink/Tests/Integration/tutorial_initialization.wls

lint-docs:
	$(WOLFRAMSCRIPT) -file scripts/check.wls docs

bootstrap:
	$(PYTHON) scripts/bootstrap.py

notebooks:
	$(WOLFRAMSCRIPT) -file scripts/docs.wls notebooks

site:
	$(WOLFRAMSCRIPT) -file scripts/docs.wls site

build:
	$(WOLFRAMSCRIPT) -file scripts/docs.wls build

check-publish: build

publish:
	$(WOLFRAMSCRIPT) -file scripts/docs.wls publish

catalog-update:
	@test -n "$(REVISION)" || (echo "Set REVISION to a full upstream Git commit" >&2; exit 1)
	$(PYTHON) scripts/updateCatalog.py "$(REVISION)"

sources-update:
	$(PYTHON) scripts/updateSources.py

# Rebuild the real-data example assets from pinned downloads (network; maintainer use).
example-data:
	$(WOLFRAMSCRIPT) -file scripts/exampleData.wls

# Rebuild docs/Hero.png, the resource page image, from the bundled source directory (offline).
hero:
	$(WOLFRAMSCRIPT) -file scripts/hero.wls

hooks:
	git config --local core.hooksPath .githooks

clean:
	rm -rf build dist BioDataLink/build BioDataLink/ResourceDefinition.nb
	find BioDataLink/Documentation -name '*.nb' -delete
