PROJECT := kmais-app-ios.xcodeproj
SCHEME := kmais-app-ios
TEST_TARGET := kmais-app-iosTests
DERIVED_DATA := .build/DerivedData
RESULT_BUNDLE := .build/TestResults.xcresult
BASE ?= origin/main
MIN_COVERAGE ?= 80

DESTINATION = platform=iOS Simulator,id=$(shell scripts/simulator-id.sh)
XCODEBUILD = set -o pipefail && xcodebuild \
	-project $(PROJECT) \
	-scheme $(SCHEME) \
	-destination '$(DESTINATION)' \
	-derivedDataPath $(DERIVED_DATA) \
	-enableCodeCoverage YES \
	CODE_SIGNING_ALLOWED=NO
PRETTY = $(if $(shell command -v xcbeautify),| xcbeautify $(XCBEAUTIFY_FLAGS),)

SHELL := /bin/bash

.PHONY: ci lint format format-check build test coverage clean

ci: lint format-check build test coverage

lint:
	swiftlint lint --strict --config .swiftlint.yml

format:
	swiftformat .

format-check:
	swiftformat --lint .

build:
	$(XCODEBUILD) build-for-testing $(PRETTY)

test:
	rm -rf $(RESULT_BUNDLE)
	$(XCODEBUILD) test-without-building -only-testing:$(TEST_TARGET) -resultBundlePath $(RESULT_BUNDLE) $(PRETTY)

coverage:
	python3 scripts/diff_coverage.py --xcresult $(RESULT_BUNDLE) --base $(BASE) --min $(MIN_COVERAGE)

clean:
	rm -rf .build
