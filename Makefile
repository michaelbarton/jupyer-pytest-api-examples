# Makefile to convert notebook into a blog post

NOTEBOOK = src/pytest_api_examples.ipynb
BUILD = blog/source/content/tools/pytest-api-examples.mkd

build: ${BUILD}

${BUILD}: ${NOTEBOOK} src/jupyter_nbconvert_config.py sync
	mkdir -p $(dir $@)
	poetry run jupyter nbconvert \
		--config=src/jupyter_nbconvert_config.py \
		--stdout \
		$< \
		| sed 's/```/~~~ /' \
		> $@


sync: fmt
	poetry run jupytext --sync ${NOTEBOOK}

up: sync
	poetry run jupyter-notebook ${NOTEBOOK}

preview: ${BUILD}
	poetry run python -m rich.markdown $<

fmt: ${NOTEBOOK}
	poetry run blacken-docs $<
	docker-compose run --rm prettier \
		npx prettier \
			--write "/mnt/*.md" \
			--prose-wrap always

clean:
	rm -r out
