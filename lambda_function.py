import os
import datetime
import tarfile
import shutil
from pymongo import MongoClient
import boto3


def lambda_handler(event, context):
    # MongoDB connection details
    MONGO_URI = os.getenv("CONNECTION_STRING", "mongodb+srv://username:password@cluster.mongodb.net")
    BACKUP_DATABASES = None  # Specify databases to back up or leave as None for all
    S3_BUCKET = os.getenv("S3_BUCKET", "your-s3-bucket-name")
    S3_REGION = os.getenv("S3_REGION", "your-s3-region")

    # Use the Lambda /tmp directory for temporary storage
    temp_dir = "/tmp/mongo_backup"

    try:
        backup_filename, backup_filepath = mongo_backup(temp_dir, MONGO_URI, BACKUP_DATABASES)

        s3_upload(S3_REGION, backup_filepath, S3_BUCKET, backup_filename)

        return {
            'statusCode': 200,
            'body': f"Backup completed and uploaded to S3 as backups/{backup_filename}"
        }

    finally:
        # Clean up temporary directory
        if os.path.exists(temp_dir):
            shutil.rmtree(temp_dir)

def mongo_backup(temp_dir, mongo_uri, backup_database):
    """Generate backup file and return file name and file path."""
    # Create the temporary directory
    os.makedirs(temp_dir, exist_ok=True)

    # Connect to MongoDB
    client = MongoClient(mongo_uri)

    # Determine the databases to back up
    db_list = backup_database if backup_database else client.list_database_names()

    # Backup each database
    for db_name in db_list:
        backup_dir = os.path.join(temp_dir, db_name)
        os.makedirs(backup_dir, exist_ok=True)

        # Backup collections in the database
        db = client[db_name]
        for collection_name in db.list_collection_names():
            collection_backup_path = os.path.join(backup_dir, f"{collection_name}.json")
            with open(collection_backup_path, 'w') as f:
                for doc in db[collection_name].find():
                    f.write(str(doc) + '\n')

    # Create a tarball of the backup
    timestamp = datetime.datetime.now().strftime('%Y-%m-%d_%H-%M-%S')
    backup_filename = f"mongodb_backup_{timestamp}.tar.gz"
    backup_filepath = os.path.join(temp_dir, backup_filename)
    with tarfile.open(backup_filepath, "w:gz") as tar:
        tar.add(temp_dir, arcname=os.path.basename(temp_dir))
    return backup_filename, backup_filepath

def s3_upload(region, backup_filepath, bucket_name, backup_filename):
    """Upload file to S3."""
    s3 = boto3.client("s3", region_name=region)
    s3.upload_file(backup_filepath, bucket_name, f"backups/{backup_filename}")
    print(f"Backup uploaded to S3 bucket {bucket_name} as backups/{backup_filename}")
