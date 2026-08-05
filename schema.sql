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

-- 2. Row Level Security
-- WICHTIG: Seit der Umstellung auf echten Supabase-Auth-Login (Login-Screen ruft
-- auth.signInWithPassword auf) läuft die App unter der Rolle "authenticated", NICHT
-- "anon". Der Zugriff wird daher bewusst NUR für "authenticated" freigegeben — eine
-- zusätzliche anon-Policy würde den Login-Screen wirkungslos machen, da der im
-- Frontend sichtbare publishable/anon-Key dann direkten REST-Zugriff ohne Passwort
-- erlauben würde. (Historie: genau das war früher der Fall, siehe
-- migration_2026-08-05_harden-rls-drop-anon-policies.sql für die Bereinigung auf
-- einem bestehenden Projekt.)
ALTER TABLE fahrzeuge ENABLE ROW LEVEL SECURITY;

CREATE POLICY "authenticated_full_access" ON fahrzeuge
  FOR ALL TO authenticated
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
-- Lesen bleibt öffentlich (bucket ist public:true, z.B. für direkte Bild-/PDF-Links
-- in der UI) — Schreiben/Ändern/Löschen ist auf eingeloggte Nutzer beschränkt.
CREATE POLICY "fuhrpark_public_read"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'fuhrpark');

CREATE POLICY "fuhrpark_authenticated_upload"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'fuhrpark');

CREATE POLICY "fuhrpark_authenticated_update"
  ON storage.objects FOR UPDATE TO authenticated
  USING (bucket_id = 'fuhrpark');

CREATE POLICY "fuhrpark_authenticated_delete"
  ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'fuhrpark');
