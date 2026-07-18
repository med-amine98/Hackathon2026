"""
Tests for product and recommendation endpoints.
"""


def test_get_products(client):
    """Products endpoint should return a list."""
    response = client.get("/api/v1/products")
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)


def test_get_product_not_found(client):
    """Requesting a non-existent product should return 404."""
    response = client.get("/api/v1/products/99999")
    assert response.status_code == 404
