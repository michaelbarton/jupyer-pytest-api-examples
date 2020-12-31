# Makefile to convert notebook into a blog post

NOTEBOOK = src/pytest_api_examples.ipynb
BUILD = out/pytest_api_examples.md

build: ${BUILD}

${BUILD}: ${NOTEBOOK} src/jupyter_nbconvert_config.py sync
	mkdir -p $(dir $@)
	poetry run jupyter nbconvert \
		--output-dir=$(dir $@) \
		--config=src/jupyter_nbconvert_config.py \
		$<

sync: fmt
	poetry run jupytext --sync ${NOTEBOOK}

up: sync
	poetry run jupyter-notebook ${NOTEBOOK}

preview: ${BUILD}
	poetry run python -m rich.markdown $<

fmt:
	poetry run jupytext --pipe black src/pytest_api_examples.ipynb
	docker-compose run --rm prettier \
		npx prettier \
			--write /mnt/pytest_api_examples.md \
			--prose-wrap always

clean:
	rm -r out
