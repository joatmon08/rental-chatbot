import os
import random

import pandas
import psycopg2
import hvac

from faker import Faker

NUMBER_OF_BOOKINGS = 1000
ENCRYPTED_LISTINGS_FILE = "./data/listings.csv"

client = hvac.Client(
    url=os.environ["VAULT_ADDR"],
    token=os.environ["VAULT_TOKEN"],
    namespace=os.getenv("VAULT_NAMESPACE"),
)

database_connection = client.secrets.kv.v2.read_secret_version(
    mount_point="payments", path="bedrock"
)

conn = psycopg2.connect(
    database=database_connection["data"]["data"]["db_name"],
    user=database_connection["data"]["data"]["username"],
    password=database_connection["data"]["data"]["password"],
    host=database_connection["data"]["data"]["host"],
    port=database_connection["data"]["data"]["port"],
)

dataframe = pandas.read_csv(ENCRYPTED_LISTINGS_FILE)
fake = Faker()
cursor = conn.cursor()


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


def set_up_database():
    cursor.execute(
        """CREATE TABLE IF NOT EXISTS bedrock_integration.bedrock_kb (id uuid PRIMARY KEY, embedding vector(1024), chunks text, metadata json);"""
    )
    cursor.execute(
        """CREATE INDEX ON bedrock_integration.bedrock_kb USING hnsw (embedding vector_cosine_ops) WITH (ef_construction=256);"""
    )
    cursor.execute(
        """CREATE INDEX ON bedrock_integration.bedrock_kb USING gin (to_tsvector('simple', chunks));"""
    )
    conn.commit()


def add_to_database(bookings):
    cursor.execute(
        """CREATE TABLE IF NOT EXISTS bookings(
        id SERIAL NOT NULL,
        name varchar(255) not null,
        listing_id bigint not null,
        credit_card varchar(20) not null,
        billing_street_address varchar(255) not null,
        billing_city varchar(255) not null,
        billing_zip_code int not null,
        start_date date not null,
        number_of_nights smallint not null
        );"""
    )

    sql = """INSERT into bookings(
                name, listing_id, credit_card,
                billing_street_address, billing_city, billing_zip_code,
                start_date, number_of_nights)
             VALUES (%s, %s, %s, %s, %s, %s, %s, %s)"""
    cursor.executemany(sql, [list(booking.values()) for booking in bookings])
    conn.commit()


def main():
    bookings = generate_data(NUMBER_OF_BOOKINGS)
    set_up_database()
    add_to_database(bookings)


if __name__ == "__main__":
    main()
