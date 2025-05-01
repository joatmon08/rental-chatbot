import os
import random

import pandas
import hvac

from faker import Faker

NUMBER_OF_BOOKINGS = 1000
ENCRYPTED_LISTINGS_FILE = "./data/listings.csv"
BOOKINGS_FILE = "./data/bookings.csv"

client = hvac.Client(
    url=os.environ["VAULT_ADDR"],
    token=os.environ["VAULT_TOKEN"],
    namespace=os.getenv("VAULT_NAMESPACE"),
)

dataframe = pandas.read_csv(ENCRYPTED_LISTINGS_FILE)
fake = Faker()


def get_listing():
    record = dataframe["id"].sample(n=1)
    return record.values[0].item()


def encode_address(address):
    encode_response = client.secrets.transform.encode(
        mount_point="transform/rentals",
        role_name="bookings",
        value=address,
        transformation="address",
    )
    return encode_response['data']['encoded_value']


def encode_credit_card_number(ccn):
    encode_response = client.secrets.transform.encode(
        mount_point="transform/rentals",
        role_name="bookings",
        value=ccn,
        transformation="ccn",
    )
    return encode_response['data']['encoded_value']


def generate_data(number_of_records):
    bookings = []
    for _ in range(0, number_of_records):
        booking = {}
        booking["name"] = fake.name()
        booking["listing_id"] = get_listing()
        booking["credit_card"] = encode_credit_card_number(fake.credit_card_number())
        booking["billing_street_address"] = encode_address(fake.street_address())
        booking["billing_city"] = fake.city()
        booking["billing_zip_code"] = fake.postcode()
        booking["start_date"] = fake.date()
        booking["number_of_nights"] = random.randint(1, 30)
        bookings.append(booking)
    return bookings


def create_csv(bookings):
    df = pandas.DataFrame(bookings)
    df.to_csv(BOOKINGS_FILE, index=False)


def main():
    bookings = generate_data(NUMBER_OF_BOOKINGS)
    create_csv(bookings)


if __name__ == "__main__":
    main()
