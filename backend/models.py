from flask_sqlalchemy import SQLAlchemy
from datetime import datetime

db = SQLAlchemy()

class InventoryItem(db.Model):
    __tablename__ = 'inventory_items'
    
    id = db.Column(db.Integer, primary_key=True)
    el_nummer_id = db.Column(db.String(50), unique=True, nullable=False)
    beskrivelse = db.Column(db.String(200))
    qr_kode_link = db.Column(db.String(200))
    qr_kode = db.Column(db.String(200))
    strek_kode = db.Column(db.String(200))
    hylle = db.Column(db.String(50))
    kategori = db.Column(db.String(50))
    enhet = db.Column(db.String(20))
    antall = db.Column(db.Integer, default=0)
    anbefalt_minimum = db.Column(db.Integer, default=0)
    kostnad = db.Column(db.Float, default=0.0)
    beholdningsverdi = db.Column(db.Float, default=0.0)
    status = db.Column(db.String(20))
    locked_by = db.Column(db.String(50))
    locked_at = db.Column(db.DateTime)

    def to_dict(self):
        return {
            'id': self.id,
            'el_nummer_id': self.el_nummer_id,
            'beskrivelse': self.beskrivelse,
            'qr_kode_link': self.qr_kode_link,
            'qr_kode': self.qr_kode,
            'strek_kode': self.strek_kode,
            'hylle': self.hylle,
            'kategori': self.kategori,
            'enhet': self.enhet,
            'antall': self.antall,
            'anbefalt_minimum': self.anbefalt_minimum,
            'kostnad': self.kostnad,
            'beholdningsverdi': self.beholdningsverdi,
            'status': self.status,
            'locked_by': self.locked_by,
            'locked_at': self.locked_at.isoformat() if self.locked_at else None
        }
