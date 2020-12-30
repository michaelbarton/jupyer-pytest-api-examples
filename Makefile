# Makefile to convert notebook into a blog post

NOTEBOOK = src/pytest_api_examples.ipynb

out/pytest_api_examples.md: ${NOTEBOOK} src/jupyter_nbconvert_config.py
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

clean:
	rm -r out
