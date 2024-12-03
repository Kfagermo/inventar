# Inventory Management System

A web-based inventory management system with QR code scanning capabilities and Excel integration.

## Features
- Real-time inventory tracking
- QR code scanning for quick item lookup
- Mobile-friendly web interface
- Excel integration for bulk updates
- Docker containerization

## Structure
inventory-system/
├── frontend/ # Web application
├── backend/ # Flask API server
├── excel/ # VBA integration scripts
└── database/ # Database initialization

## Setup

### Backend
1. Install requirements:

bash
cd backend
pip install -r requirements.txt


2. Run with Docker:
bash
docker-compose up -d


### Frontend
Access the web application at: https://[your-github-username].github.io/inventory-system/

### Excel Integration
1. Open your Excel workbook
2. Import the VBA modules from the `excel` directory
3. Configure the server URL in the VBA modules

## Development
- Frontend: HTML5, CSS3, JavaScript
- Backend: Python, Flask, SQLAlchemy
- Database: PostgreSQL
- Containerization: Docker

## License
Open Source
EOL'

## Security Configuration

SSL certificates should be stored securely and mounted to the containers at runtime. 
Do not commit certificates to the repository.

1. Place your certificates in a secure location
2. Update the certificate path in docker-compose.yml
3. Ensure proper permissions on certificate files