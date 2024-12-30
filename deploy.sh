#!/usr/bin/env bash

mkdir -p package/python
cp src/lambda_function.py package/pyhton
poetry run pip freeze > requirements.txt
poetry run pip install -r requirements.txt --target=package/python
terraform apply -auto-approve
