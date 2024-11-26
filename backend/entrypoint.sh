#!/bin/bash
set -e

# Wait for database
echo "Waiting for database..."
for i in {1..30}; do
    if pg_isready -h database -U postgres; then
        echo "Database is ready!"
        break
    fi
    echo "Waiting for database... $i/30"
    sleep 2
done

# Initialize database with proper app context
python -c "
from app import app, db
with app.app_context():
    try:
        db.create_all()
        from models import InventoryItem
        if not InventoryItem.query.first():
            test_item = InventoryItem(
                el_nummer_id='TEST123',
                beskrivelse='Test Item',
                antall=10,
                kategori='Test',
                kostnad=100.0,
                status='Active'
            )
            db.session.add(test_item)
            db.session.commit()
            print('Test record inserted successfully!')
    except Exception as e:
        print('Database setup error:', e)
        db.session.rollback()
"

# Start the application with proper workers
exec gunicorn --bind 0.0.0.0:5000 --workers 4 app:app