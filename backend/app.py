from csv_sync import export_to_csv, import_from_csv
from flask import Flask, request, jsonify, make_response
from flask_sqlalchemy import SQLAlchemy
from flask_cors import CORS
from flask_migrate import Migrate
from sqlalchemy import text
import os
import csv
from models import db, InventoryItem  # Move model definitions to models.py
from export_utils import export_inventory_to_csv
from datetime import datetime
import logging

# Initialize Flask app first
app = Flask(__name__)
CORS(app, resources={r"/api/*": {"origins": "*"}})  # Adjust origins as needed
app.config['SQLALCHEMY_DATABASE_URI'] = os.environ.get('DATABASE_URL')
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db = SQLAlchemy(app)

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

API_PREFIX = '/api'

# Database Model
class InventoryItem(db.Model):
    __tablename__ = 'inventory_items'
    
    el_nummer_id = db.Column(db.String, primary_key=True)
    beskrivelse = db.Column(db.String, nullable=False)
    kategori = db.Column(db.String, nullable=False)
    hylle = db.Column(db.String, nullable=False)
    enhet = db.Column(db.String, nullable=False)
    antall = db.Column(db.Integer, nullable=False)
    anbefalt_minimum = db.Column(db.Integer, nullable=False)
    
    def to_dict(self):
        return {
            'el_nummer_id': self.el_nummer_id,
            'beskrivelse': self.beskrivelse,
            'kategori': self.kategori,
            'hylle': self.hylle,
            'enhet': self.enhet,
            'antall': self.antall,
            'anbefalt_minimum': self.anbefalt_minimum
        }

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

        # Validate data types
        if not isinstance(el_nummer_id, str) or not isinstance(antall, int):
            logger.error('Invalid data types for el_nummer_id or antall: %s, %s', type(el_nummer_id), type(antall))
            return jsonify({'error': 'Invalid data types'}), 400

        if antall < 0:
            logger.error('Negative stock value received: %s', antall)
            return jsonify({'error': 'Stock quantity cannot be negative'}), 400

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

@app.route(f'{API_PREFIX}/inventory/<el_nummer_id>', methods=['GET'])
def get_inventory_item(el_nummer_id):
    try:
        item = InventoryItem.query.filter_by(el_nummer_id=el_nummer_id).first()
        if not item:
            logger.error('Item not found: %s', el_nummer_id)
            return jsonify({'error': 'Item not found'}), 404
        return jsonify(item.to_dict()), 200
    except Exception as e:
        logger.exception('Error fetching inventory item: %s', e)
        return jsonify({'error': 'Internal Server Error'}), 500

# Endpoint to check server status
@app.route(f'{API_PREFIX}/test_db', methods=['GET'])
def test_db():
    try:
        db.session.execute('SELECT 1')
        logger.info('Database connection test successful.')
        return jsonify({'status': 'OK'}), 200
    except Exception as e:
        logger.exception('Database connection error: %s', e)
        return jsonify({'error': 'Database connection failed'}), 500

# Locking Mechanism Endpoints (Optional)
@app.route(f'{API_PREFIX}/lock_item', methods=['POST'])
def lock_item():
    try:
        data = request.json
        if not data or 'el_nummer_id' not in data or 'user' not in data:
            logger.error('Invalid lock data format: %s', data)
            return jsonify({'error': 'Invalid data format'}), 400

        el_nummer_id = data['el_nummer_id']
        user = data['user']

        # Implement locking logic here
        # For demonstration, assume lock is successful
        # In production, check if item is already locked

        logger.info('Item locked: %s by user: %s', el_nummer_id, user)
        return jsonify({'message': f'Item {el_nummer_id} locked by {user}'}), 200

    except Exception as e:
        logger.exception('Error locking item: %s', e)
        return jsonify({'error': 'Internal Server Error'}), 500

@app.route(f'{API_PREFIX}/unlock_item', methods=['POST'])
def unlock_item():
    try:
        data = request.json
        if not data or 'el_nummer_id' not in data or 'user' not in data:
            logger.error('Invalid unlock data format: %s', data)
            return jsonify({'error': 'Invalid data format'}), 400

        el_nummer_id = data['el_nummer_id']
        user = data['user']

        # Implement unlocking logic here
        # For demonstration, assume unlock is successful

        logger.info('Item unlocked: %s by user: %s', el_nummer_id, user)
        return jsonify({'message': f'Item {el_nummer_id} unlocked by {user}'}), 200

    except Exception as e:
        logger.exception('Error unlocking item: %s', e)
        return jsonify({'error': 'Internal Server Error'}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
