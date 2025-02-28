import os
import hvac
import base64
import csv

LISTINGS_FILE = "./listings.csv"
KEY_NAME = "listings"

client = hvac.Client(
    url=os.environ["VAULT_ADDR"],
    token=os.environ["VAULT_TOKEN"],
    namespace=os.getenv("VAULT_NAMESPACE"),
)

def encrypt_payload(payload):
    encrypt_data_response = client.secrets.transit.encrypt_data(
        name=KEY_NAME,
        plaintext=base64.encode(payload),
    )
    ciphertext = encrypt_data_response["data"]["ciphertext"]
    return ciphertext

with open(LISTINGS_FILE, newline="") as csvfile:
    listings = csv.reader(csvfile)
    for listing in listings:
        print(encrypt_payload(listing))
