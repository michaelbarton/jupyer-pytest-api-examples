# Makefile to convert notebook into a blog post

NOTEBOOK = pytest_api_examples.ipynb

out/pytest_api_examples.md: ${NOTEBOOK}
	mkdir -p $(dir $@)
	poetry run jupyter nbconvert \
		--to markdown \
		--output=$@ \
		$<

up:
	poetry run jupyter-notebook ${NOTEBOOK}

