# Makefile for engineering-commandments plugin
# Satisfies: RT-4 (local automation mirror of CI)

.PHONY: test lint validate all

all: lint validate test

lint:
	shellcheck hooks/scripts/*.sh

validate:
	python3 -c "import json; json.load(open('.claude-plugin/plugin.json'))"
	python3 -c "import json; json.load(open('hooks/hooks.json'))"
	python3 -c "import json; json.load(open('.claude-plugin/marketplace.json'))"

test:
	./tests/bats/bin/bats tests/
