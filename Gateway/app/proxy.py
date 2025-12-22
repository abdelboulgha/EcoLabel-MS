import requests
from fastapi import Request, Response
from consul_client import discover_service

async def proxy_request(service_name: str, path: str, request: Request):
    base_url = discover_service(service_name)
    target_url = f"{base_url}/{path}"
    body = await request.body()
    response = requests.request(
        method=request.method,
        url=target_url,
        headers=dict(request.headers),
        params=dict(request.query_params),
        data=body,
        timeout=5
    )

    return Response(
        content=response.content,
        status_code=response.status_code,
        headers=response.headers
    )
