import base64
import json
import logging
import os

import boto3
import hvac
import pandas
from botocore.exceptions import ClientError
from langchain_community.document_loaders import CSVLoader

LISTINGS_FILE = "./data/raw/listings.csv"
ENCRYPTED_LISTINGS_FILE = "./data/listings.csv"
MOUNT_POINT = "transit/rentals"
KEY_NAME = "listings"
CONTEXT = json.dumps({"location": "New York City", "field": "host_name"})

client = hvac.Client(
    url=os.environ["VAULT_ADDR"],
    token=os.environ["VAULT_TOKEN"],
    namespace=os.getenv("VAULT_NAMESPACE"),
)

bucket = client.secrets.kv.v2.read_secret_version(
    mount_point="listings", path="bucket"
)

bucket_name = bucket["data"]["data"]["name"]

def encrypt_payload(payload):
    try:
        encrypt_data_response = client.secrets.transit.encrypt_data(
            mount_point=MOUNT_POINT,
            name=KEY_NAME,
            plaintext=base64.b64encode(payload.encode()).decode(),
            context=base64.b64encode(CONTEXT.encode()).decode(),
        )
        ciphertext = encrypt_data_response["data"]["ciphertext"]
        return ciphertext
    except AttributeError:
        return ""


def encrypt_hostnames():
    dataframe = pandas.read_csv(LISTINGS_FILE)
    dataframe["host_name"] = dataframe["host_name"].apply(lambda x: encrypt_payload(x))
    dataframe.to_csv(ENCRYPTED_LISTINGS_FILE, index=False)


def create_documents():
    loader = CSVLoader(ENCRYPTED_LISTINGS_FILE)
    data = loader.load()
    return data


def upload_file(body, bucket, object):
    s3_client = boto3.client("s3")
    try:
        s3_client.put_object(Body=body, Bucket=bucket, Key=object)
    except ClientError as e:
        logging.error(e)
        return False
    return True


def main():
    encrypt_hostnames()
    docs = create_documents()
    for i, doc in enumerate(docs):
        upload_file(doc.page_content, bucket_name, f"listings/{i}")


if __name__ == "__main__":
    main()
