import base64
import json
import os

import hvac
import pandas

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
    dataframe = pandas.read_csv(LISTINGS_FILE, nrows=1000)
    dataframe["host_name"] = dataframe["host_name"].apply(lambda x: encrypt_payload(x))
    dataframe = dataframe.rename(columns={"id": "listing_id"})
    dataframe.to_csv(ENCRYPTED_LISTINGS_FILE, index=False)


def main():
    encrypt_hostnames()


if __name__ == "__main__":
    main()
