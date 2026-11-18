SHELL := /bin/sh
PREFIX ?= $(HOME)/.local
TOOL = sensible-revamped
SCRIPTS = $(shell git ls-files --cached --others --exclude-standard -- '*.sh' '*.bash' '*.bats' '*.tmux' 'bin/*' 'test/bin/*')
POSIX_SCRIPTS = $(shell git ls-files --cached --others --exclude-standard -- 'bin/*' 'lib/*.sh' '*.tmux' '.github/scripts/*.sh' 'test/*.sh' 'test/bin/*' 'screens/*.sh')
TEST_SCRIPTS = $(shell git ls-files --cached --others --exclude-standard -- 'test/*.bash' 'test/*.bats')

.PHONY: help fmt lint test test-all test-linux coverage check screens install clean

help:
	@echo "targets:"
	@echo "  fmt         format every script with shfmt -i 2"
	@echo "  lint        shfmt, ShellCheck, mandoc, yamllint and actionlint at zero findings"
	@echo "  test        the bats suites under the system sh"
	@echo "  test-all    the bats suites under every installed shell, both builds of bash and zsh on macOS"
	@echo "  test-linux  the bats suites in an Ubuntu container"
	@echo "  coverage    bashcov on this Mac and in the Ubuntu container, merged, gate 100%"
	@echo "  check       lint and test"
	@echo "  screens     the README screens, recorded from the real tool with VHS, on macOS"
	@echo "  install     the tool, its man page and completions under PREFIX, ~/.local by default"
	@echo "  clean       remove the coverage output"

fmt:
	shfmt -i 2 -w $(SCRIPTS)

lint:
	shfmt -i 2 -d $(SCRIPTS)
	shellcheck -x -o all -s sh $(POSIX_SCRIPTS)
	shellcheck -x -o all $(TEST_SCRIPTS) completions/$(TOOL).bash
	zsh -n completions/_$(TOOL)
	mandoc -T lint -W warning man/$(TOOL).1
	yamllint -s -c .yamllint.yml .github .yamllint.yml
	actionlint

test:
	REVAMPED_TEST_SHELLS=sh sh test/run-matrix.sh

test-all:
	sh test/run-matrix.sh

test-linux:
	sh test/linux-container.sh sh test/run-matrix.sh

coverage:
	sh .github/scripts/coverage.sh && cp -f coverage/.resultset.json coverage-macos.json
	sh test/linux-container.sh sh .github/scripts/linux-coverage.sh
	python3 .github/scripts/coverage-gate.py '/(lib/[a-z]+\.sh|bin/[a-z-]+)\Z' 100 coverage-macos.json coverage-linux.json

check: lint test

screens:
	sh screens/record.sh

install:
	mkdir -p "$(PREFIX)/share/$(TOOL)" "$(PREFIX)/bin" "$(PREFIX)/share/man/man1" "$(PREFIX)/share/bash-completion/completions" "$(PREFIX)/share/zsh/site-functions" "$(PREFIX)/share/fish/vendor_completions.d"
	rm -rf "$(PREFIX)/share/$(TOOL)/bin" "$(PREFIX)/share/$(TOOL)/lib"
	cp -R bin lib "$(PREFIX)/share/$(TOOL)/"
	cp -f man/$(TOOL).1 "$(PREFIX)/share/man/man1/$(TOOL).1"
	cp -f completions/$(TOOL).bash "$(PREFIX)/share/bash-completion/completions/$(TOOL)"
	cp -f completions/_$(TOOL) "$(PREFIX)/share/zsh/site-functions/_$(TOOL)"
	cp -f completions/$(TOOL).fish "$(PREFIX)/share/fish/vendor_completions.d/$(TOOL).fish"
	printf '#!/bin/sh\nexec "%s/share/$(TOOL)/bin/$(TOOL)" "$$@"\n' "$(PREFIX)" >"$(PREFIX)/bin/$(TOOL)"
	chmod 755 "$(PREFIX)/bin/$(TOOL)"


clean:
	rm -rf coverage coverage-macos.json coverage-linux.json coverage-linux-warnings.log
