import requests

CONSUL_BASE = "http://localhost:8500/v1/catalog/service"

def discover(service_name: str) -> str:
    response = requests.get(f"{CONSUL_BASE}/{service_name}", timeout=3)
    services = response.json()

    if not services:
        raise RuntimeError(f"Service {service_name} not found in Consul")

    service = services[0]
    return f"http://{service['ServiceAddress']}:{service['ServicePort']}"
