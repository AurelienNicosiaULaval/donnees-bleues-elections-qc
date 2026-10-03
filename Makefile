.PHONY: all offline update results weekly test discover finances
all:
	Rscript pipeline.R
offline:
	Rscript pipeline.R --offline
update:
	Rscript pipeline.R --refresh --daily
results:
	Rscript pipeline.R --refresh --results
weekly:
	Rscript scripts/discover/discover.R
	Rscript pipeline.R --refresh --weekly
test:
	Rscript tests/run_tests.R
	python3 tests/test_results_final.py
discover:
	Rscript scripts/discover/discover.R
finances:
	python3 scripts/transform/financial_documents.py
