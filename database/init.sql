-- Create postgres user if it doesn't exist
DO
$do$
BEGIN
   IF NOT EXISTS (
      SELECT FROM pg_catalog.pg_roles
      WHERE  rolname = 'postgres') THEN
      CREATE USER postgres WITH SUPERUSER PASSWORD 'postgres';
   END IF;
END
$do$;

-- Create the inventory_items table
CREATE TABLE IF NOT EXISTS inventory_items (
    id SERIAL PRIMARY KEY,
    el_nummer_id VARCHAR(50) UNIQUE NOT NULL,
    beskrivelse VARCHAR(200),
    qr_kode_link VARCHAR(200),
    qr_kode VARCHAR(200),
    strek_kode VARCHAR(200),
    hylle VARCHAR(50),
    kategori VARCHAR(50),
    enhet VARCHAR(20),
    antall INTEGER DEFAULT 0,
    anbefalt_minimum INTEGER DEFAULT 0,
    kostnad FLOAT DEFAULT 0.0,
    beholdningsverdi FLOAT DEFAULT 0.0,
    status VARCHAR(20),
    locked_by VARCHAR(50),
    locked_at TIMESTAMP
);

-- Grant permissions
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO postgres;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO postgres;