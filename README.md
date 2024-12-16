#  Lambda MongoDB Backup
## Summary
AWS Lambda functions for MongoDB database backups
## Environment variables
| Key               | comment                        |
|-------------------|--------------------------------|
| CONNECTION_STRING | your MongoDB connection string |
| S3_BUCKET         | S3 bucket name                 |
| S3_REGION         | S3 bucket Region               |
## To deploy new version
```sh
mkdir -p pachage/python
cp src/lambda_function.py package
poetry run pip freeze > requirements.txt
poetry run pip install -r requirements.txt --target=package/python
terraform apply
```

## Author
[@mihamieat](https://github.com/mihamieat)
