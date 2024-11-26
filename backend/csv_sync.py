import csv
from models import InventoryItem  # Import the InventoryItem model
from flask_sqlalchemy import SQLAlchemy

def export_to_csv(db: SQLAlchemy, file_path: str = "Lager.csv"):
    """
    Export inventory data from the database to a CSV file.
    """
    try:
        # Query all items from the inventory table
        items = db.session.query(InventoryItem).all()
        with open(file_path, mode="w", newline="", encoding="utf-8") as csvfile:
            writer = csv.writer(csvfile)
            # Write headers
            writer.writerow([
                "EL Nummer/ID", "BESKRIVELSE", "QR Kode Link", "QR Kode",
                "Strek kode", "HYLLE", "Kategori", "ENHET",
                "ANTALL", "Anbefalt Minimum", "KOSTNAD", "BEHOLDNINGSVERDI:",
                "Status"
            ])
            # Write inventory rows
            for item in items:
                writer.writerow([
                    item.el_nummer_id, item.beskrivelse, item.qr_kode_link, item.qr_kode,
                    item.strek_kode, item.hylle, item.kategori, item.enhet,
                    item.antall, item.anbefalt_minimum, f"kr {item.kostnad:.2f}".replace('.', ','),
                    f"kr {item.beholdningsverdi:.2f}".replace('.', ','), item.status
                ])
        return {"message": "Data exported successfully!"}
    except Exception as e:
        return {"error": f"Error exporting data: {e}"}

def import_from_csv(db: SQLAlchemy, file_path: str = "Lager.csv"):
    """Import inventory data from a CSV file into the database."""
    try:
        with open(file_path, mode="r", encoding="utf-8") as csvfile:
            csv_reader = csv.DictReader(csvfile)
            
            for row in csv_reader:
                if not row.get("EL Nummer/ID"):
                    continue
                
                existing_item = db.session.query(InventoryItem).filter_by(
                    el_nummer_id=row["EL Nummer/ID"].strip()
                ).first()
                
                # Prepare data with proper formatting
                kostnad = row.get("KOSTNAD", "0")
                beholdningsverdi = row.get("BEHOLDNINGSVERDI", "0")
                
                # Convert currency strings to float
                kostnad = float(str(kostnad).replace("kr ", "").replace(",", "."))
                beholdningsverdi = float(str(beholdningsverdi).replace("kr ", "").replace(",", "."))
                
                if existing_item:
                    existing_item.beskrivelse = row["BESKRIVELSE"].strip()
                    existing_item.qr_kode_link = row.get("QR Kode Link", "").strip()
                    existing_item.qr_kode = row.get("QR Kode", "").strip()
                    existing_item.strek_kode = row.get("Strek kode", "").strip()
                    existing_item.hylle = row.get("HYLLE", "").strip()
                    existing_item.kategori = row["Kategori"].strip()
                    existing_item.enhet = row.get("ENHET", "").strip()
                    existing_item.antall = int(row["ANTALL"])
                    existing_item.anbefalt_minimum = int(row.get("Anbefalt Minimum", 0))
                    existing_item.kostnad = kostnad
                    existing_item.beholdningsverdi = beholdningsverdi
                    existing_item.status = row.get("Status", "").strip()
                else:
                    item = InventoryItem(
                        el_nummer_id=row["EL Nummer/ID"].strip(),
                        beskrivelse=row["BESKRIVELSE"].strip(),
                        qr_kode_link=row.get("QR Kode Link", "").strip(),
                        qr_kode=row.get("QR Kode", "").strip(),
                        strek_kode=row.get("Strek kode", "").strip(),
                        hylle=row.get("HYLLE", "").strip(),
                        kategori=row["Kategori"].strip(),
                        enhet=row.get("ENHET", "").strip(),
                        antall=int(row["ANTALL"]),
                        anbefalt_minimum=int(row.get("Anbefalt Minimum", 0)),
                        kostnad=kostnad,
                        beholdningsverdi=beholdningsverdi,
                        status=row.get("Status", "").strip()
                    )
                    db.session.add(item)
            
            db.session.commit()
        return {"message": "Data imported successfully!"}
    except Exception as e:
        print(f"Import error: {e}")
        db.session.rollback()
        return {"error": f"Error importing data: {e}"}
