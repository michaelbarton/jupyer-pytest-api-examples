# Makefile to convert notebook into a blog post

NOTEBOOK = src/pytest_api_examples.ipynb
BUILD = out/pytest_api_examples.md

${BUILD}: ${NOTEBOOK} src/jupyter_nbconvert_config.py fmt
	mkdir -p $(dir $@)
	poetry run jupyter nbconvert \
		--output-dir=$(dir $@) \
		--config=src/jupyter_nbconvert_config.py \
		$<
	docker-compose run --rm prettier \
		npx prettier \
			--write /mnt/pytest_api_examples.md \
			--prose-wrap always

up:
	poetry run jupyter-notebook ${NOTEBOOK}

preview: ${BUILD}
	poetry run python -m rich.markdown $< | less

fmt:
	poetry run jupytext --pipe black src/pytest_api_examples.ipynb

clean:
	rm -r out
