import requests
from config import CONSUL_HOST, CONSUL_PORT

CONSUL_BASE_URL = f"http://{CONSUL_HOST}:{CONSUL_PORT}"

def discover_service(service_name: str) -> str:
    """
    Returns service base URL from Consul
    """
    url = f"{CONSUL_BASE_URL}/v1/catalog/service/{service_name}"
    response = requests.get(url, timeout=5)

    if response.status_code != 200 or not response.json():
        raise Exception(f"Service {service_name} not found in Consul")

    service = response.json()[0]
    return f"http://{service['ServiceAddress']}:{service['ServicePort']}"
