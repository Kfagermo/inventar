import csv
import io
from flask import send_file
from models import InventoryItem

def export_inventory_to_csv():
    """
    Export inventory data to a CSV file and return it as a Flask response.
    """
    try:
        # Create an in-memory buffer for the CSV
        buffer = io.StringIO()
        writer = csv.writer(buffer)

        # Write CSV headers matching Lager.csv format
        writer.writerow([
            "EL Nummer/ID", "BESKRIVELSE", "QR Kode Link", "QR Kode",
            "Strek kode", "HYLLE", "Kategori", "ENHET",
            "ANTALL", "Anbefalt Minimum", "KOSTNAD", "BEHOLDNINGSVERDI",
            "Status"
        ])

        # Write inventory data rows
        items = InventoryItem.query.all()
        for item in items:
            writer.writerow([
                item.el_nummer_id,
                item.beskrivelse,
                item.qr_kode_link,
                item.qr_kode,
                item.strek_kode,
                item.hylle,
                item.kategori,
                item.enhet,
                item.antall,
                item.anbefalt_minimum,
                f"kr {item.kostnad:.2f}".replace('.', ','),
                f"kr {item.beholdningsverdi:.2f}".replace('.', ','),
                item.status
            ])

        # Reset buffer position to the beginning
        buffer.seek(0)

        # Return the file as a response
        return send_file(
            io.BytesIO(buffer.getvalue().encode()),
            mimetype='text/csv',
            as_attachment=True,
            download_name='inventory_export.csv'
        )
    except Exception as e:
        return {"error": str(e)}, 500
