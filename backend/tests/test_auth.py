"""
Tests for authentication endpoints.
"""


def test_register_user(client):
    """Register a new user and verify the response."""
    response = client.post("/api/v1/auth/register", json={
        "email": "test@example.com",
        "password": "password123",
        "first_name": "Test",
        "last_name": "User",
    })
    assert response.status_code == 201
    data = response.json()
    assert data["email"] == "test@example.com"
    assert data["first_name"] == "Test"
    assert "id" in data


def test_register_duplicate_email(client):
    """Registering with an existing email should fail with 400."""
    payload = {
        "email": "duplicate@example.com",
        "password": "password123",
        "first_name": "A",
        "last_name": "B",
    }
    client.post("/api/v1/auth/register", json=payload)
    response = client.post("/api/v1/auth/register", json=payload)
    assert response.status_code == 400


def test_login(client):
    """Login with valid credentials should return a JWT token."""
    client.post("/api/v1/auth/register", json={
        "email": "login@example.com",
        "password": "password123",
        "first_name": "Login",
        "last_name": "User",
    })
    response = client.post("/api/v1/auth/token", data={
        "username": "login@example.com",
        "password": "password123",
    })
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert data["token_type"] == "bearer"


def test_login_wrong_password(client):
    """Login with wrong password should return 401."""
    client.post("/api/v1/auth/register", json={
        "email": "wrongpw@example.com",
        "password": "correct_password",
        "first_name": "A",
        "last_name": "B",
    })
    response = client.post("/api/v1/auth/token", data={
        "username": "wrongpw@example.com",
        "password": "wrong_password",
    })
    assert response.status_code == 401
