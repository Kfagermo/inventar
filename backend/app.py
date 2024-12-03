from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from flask_cors import CORS
import os
import logging
from models import db, InventoryItem

# Initialize Flask app
app = Flask(__name__)
CORS(app, resources={r"/api/*": {
    "origins": [
        "https://kfagermo.github.io",     # GitHub Pages domain
        "http://localhost:5000",          # Local development
        "https://152.93.129.206"          # Your server
    ],
    "methods": ["GET", "POST", "OPTIONS"],
    "allow_headers": ["Content-Type"]
}})

# Configure database
app.config['SQLALCHEMY_DATABASE_URI'] = os.environ.get('DATABASE_URL')
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

# Initialize database
db.init_app(app)

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

API_PREFIX = '/api'

@app.route(f'{API_PREFIX}/inventory', methods=['GET'])
def get_inventory():
    try:
        items = InventoryItem.query.all()
        inventory = [item.to_dict() for item in items]
        logger.info('Fetched inventory successfully.')
        return jsonify(inventory), 200
    except Exception as e:
        logger.exception('Error fetching inventory: %s', e)
        return jsonify({'error': 'Internal Server Error'}), 500

@app.route(f'{API_PREFIX}/update_stock', methods=['POST'])
def update_stock():
    try:
        data = request.json
        if not data or 'el_nummer_id' not in data or 'antall' not in data:
            logger.error('Invalid data format: %s', data)
            return jsonify({'error': 'Invalid data format'}), 400

        el_nummer_id = data['el_nummer_id']
        antall = data['antall']

        item = InventoryItem.query.filter_by(el_nummer_id=el_nummer_id).first()
        if not item:
            logger.error('Item not found: %s', el_nummer_id)
            return jsonify({'error': 'Item not found'}), 404

        item.antall = antall
        db.session.commit()
        
        logger.info('Stock updated successfully for item: %s', item.el_nummer_id)
        return jsonify({'message': 'Stock updated successfully'}), 200
        
    except Exception as e:
        db.session.rollback()
        logger.exception('Error updating stock: %s', e)
        return jsonify({'error': 'Internal Server Error'}), 500

@app.route(f'{API_PREFIX}/delete_inventory_item', methods=['POST'])
def delete_inventory_item():
    try:
        data = request.json
        if not data or 'el_nummer_id' not in data:
            return jsonify({'error': 'Invalid data format'}), 400

        el_nummer_id = data['el_nummer_id']
        item = InventoryItem.query.filter_by(el_nummer_id=el_nummer_id).first()
        
        if not item:
            return jsonify({'error': 'Item not found'}), 404
            
        db.session.delete(item)
        db.session.commit()
        
        return jsonify({'message': f'Successfully deleted item {el_nummer_id}'}), 200
        
    except Exception as e:
        logger.error(f'Error deleting inventory item: {str(e)}')
        db.session.rollback()
        return jsonify({'error': 'Internal server error'}), 500

if __name__ == '__main__':
    with app.app_context():
        db.create_all()
    app.run(host='0.0.0.0', port=5000)
