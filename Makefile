WOLFRAMSCRIPT ?= wolframscript
PYTHON ?= python3
.DEFAULT_GOAL := help
.PHONY: help all check test python-tests lint-docs bootstrap notebooks site build check-publish publish hooks catalog-update clean

help:
	@printf 'make check | test [FILES="..."] | python-tests | lint-docs\nmake bootstrap | notebooks | site | build | check-publish | all\nmake catalog-update REVISION=<commit> | hooks | publish | clean\n'

all: check test python-tests build

check:
	$(WOLFRAMSCRIPT) -file scripts/check.wls

test:
	$(WOLFRAMSCRIPT) -file scripts/test.wls $(FILES)

python-tests:
	$(PYTHON) -m unittest discover -s scripts/tests -v

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

hooks:
	git config --local core.hooksPath .githooks

clean:
	rm -rf build dist BioDataLink/build BioDataLink/ResourceDefinition.nb
	find BioDataLink/Documentation -name '*.nb' -delete
