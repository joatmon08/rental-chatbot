import os
import requests

from langchain_community.document_loaders import CSVLoader

OPEN_WEBUI_URL='http://127.0.0.1:3000'
OPEN_WEBUI_TOKEN=os.environ['OPEN_WEBUI_TOKEN']

RENTAL_LISTINGS_KNOWLEDGE_BASE = {
    'name': 'Rental Listings',
    'description': 'Airbnb vacation rental listings for New York City'
}
RENTAL_LISTINGS_FILE_PATH = './data/listings.csv'

RENTAL_BOOKINGS_KNOWLEDGE_BASE = {
    'name': 'Rental Bookings',
    'description': 'Bookings for Airbnb vacation rental listings in New York City, including payment information'
}
RENTAL_BOOKINGS_FILE_PATH = './data/bookings_2.csv'

def create_knowledge(name, description):
    url = f'{OPEN_WEBUI_URL}/api/v1/knowledge/create'
    headers = {
        'Authorization': f'Bearer {OPEN_WEBUI_TOKEN}',
        'Content-Type': 'application/json'
    }
    data = {'name': name, 'description': description}
    response = requests.post(url, headers=headers, json=data)
    return response.json()

def upload_file(file_contents):
    url = f'{OPEN_WEBUI_URL}/api/v1/files/'
    headers = {
        'Authorization': f'Bearer {OPEN_WEBUI_TOKEN}',
        'Accept': 'application/json'
    }
    files = {'file': file_contents.encode()}
    response = requests.post(url, headers=headers, files=files)
    return response.json()


def add_file_to_knowledge(knowledge_id, file_id):
    url = f'{OPEN_WEBUI_URL}/api/v1/knowledge/{knowledge_id}/file/add'
    headers = {
        'Authorization': f'Bearer {OPEN_WEBUI_TOKEN}',
        'Content-Type': 'application/json'
    }
    data = {'file_id': file_id}
    response = requests.post(url, headers=headers, json=data)
    return response.json()


def upload_documents(csv_file, knowledge_id):
    loader = CSVLoader(csv_file)
    docs = loader.load()
    for _, doc in enumerate(docs):
        file_response = upload_file(doc.page_content)
        add_file_to_knowledge(knowledge_id, file_response['id'])

def main():
    rental_listings_kb = create_knowledge(RENTAL_LISTINGS_KNOWLEDGE_BASE['name'], RENTAL_LISTINGS_KNOWLEDGE_BASE['description'])
    upload_documents(RENTAL_LISTINGS_FILE_PATH, rental_listings_kb['id'])

    rental_bookings_kb = create_knowledge(RENTAL_BOOKINGS_KNOWLEDGE_BASE['name'], RENTAL_BOOKINGS_KNOWLEDGE_BASE['description'])
    upload_documents(RENTAL_BOOKINGS_FILE_PATH, rental_bookings_kb['id'])

if __name__ == "__main__":
    main()
