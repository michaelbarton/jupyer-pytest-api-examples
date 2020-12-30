# Makefile to convert notebook into a blog post

NOTEBOOK = 'Pytest API with examples.ipynb'

up:
	poetry run jupyter-notebook ${NOTEBOOK}
