deploy-local:
	pip install -r requirements.txt
	mkdocs serve

deploy-github:
	cd ../kloud-native-ondarox.github.io/
	mkdocs gh-deploy --config-file ../knotes/mkdocs.yml
