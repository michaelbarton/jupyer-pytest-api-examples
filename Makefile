NOTEBOOK = src/notebook.md
BUILD = out/notebook.md

build: ${BUILD}

${BUILD}: ${NOTEBOOK} src/jupyter_nbconvert_config.py fmt
	mkdir -p $(dir $@)
	poetry run jupyter nbconvert \
		--config=src/jupyter_nbconvert_config.py \
		--stdout \
		$< \
		> $@

bootstrap:
	poetry install

preview: ${BUILD}
	poetry run python -m rich.markdown $<

fmt: ${NOTEBOOK}
	poetry run blacken-docs $<
	docker-compose run --rm prettier \
		npx prettier \
			--write "/mnt/*.md" \
			--prose-wrap always
