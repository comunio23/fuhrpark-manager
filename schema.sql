-- ──────────────────────────────────────────────────────────────────────────────
-- Fuhrpark-Manager · Supabase-Schema
-- Einmalig im SQL-Editor des Projekts bembfesrfepsftragaeq ausführen
-- ──────────────────────────────────────────────────────────────────────────────

-- 1. Fahrzeuge-Tabelle
CREATE TABLE IF NOT EXISTS fahrzeuge (
  id                 uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  kennzeichen        text        NOT NULL,
  marke              text        NOT NULL DEFAULT '',
  modell             text        NOT NULL DEFAULT '',
  typ                text        DEFAULT 'PKW',
  farbe              text        DEFAULT '',
  kraftstoff         text        DEFAULT 'Diesel',
  erstzulassung      text        DEFAULT '',        -- Format: YYYY-MM
  kilometerstand     integer     DEFAULT 0,
  naechster_tuev     text        DEFAULT '',        -- Format: YYYY-MM
  naechste_werkstatt text        DEFAULT '',        -- Format: YYYY-MM-DD
  notizen            text        DEFAULT '',
  wartungen          jsonb       DEFAULT '[]'::jsonb,
  reifenwechsel      jsonb       DEFAULT '[]'::jsonb,
  reinigungen        jsonb       DEFAULT '[]'::jsonb,
  unfaelle           jsonb       DEFAULT '[]'::jsonb,
  updated_at         timestamptz DEFAULT now()
);

-- 2. Row Level Security (anonymer Zugriff erlaubt)
ALTER TABLE fahrzeuge ENABLE ROW LEVEL SECURITY;

CREATE POLICY "anon_full_access" ON fahrzeuge
  FOR ALL TO anon
  USING (true)
  WITH CHECK (true);

-- 3. Storage-Bucket für Fotos und Dokumente
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'fuhrpark',
  'fuhrpark',
  true,
  5242880,
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'application/pdf']
)
ON CONFLICT (id) DO NOTHING;

-- 4. Storage-Policies
CREATE POLICY "fuhrpark_public_read"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'fuhrpark');

CREATE POLICY "fuhrpark_anon_upload"
  ON storage.objects FOR INSERT TO anon
  WITH CHECK (bucket_id = 'fuhrpark');

CREATE POLICY "fuhrpark_anon_update"
  ON storage.objects FOR UPDATE TO anon
  USING (bucket_id = 'fuhrpark');

CREATE POLICY "fuhrpark_anon_delete"
  ON storage.objects FOR DELETE TO anon
  USING (bucket_id = 'fuhrpark');
