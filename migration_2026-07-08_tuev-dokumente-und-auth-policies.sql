-- ──────────────────────────────────────────────────────────────────────────────
-- Fuhrpark-Manager · Migration 2026-07-08
-- Im SQL-Editor des Projekts bembfesrfepsftragaeq einmalig ausführen
--
-- Diese Migration behebt zwei Dinge:
--   1. Neue Spalte für TÜV-Berichte, die direkt am TÜV-Termin hängen
--      (statt nur über einen "Wartung"-Eintrag hochladbar zu sein).
--   2. Die Storage-Policies (Datei-Upload) sind noch auf die Rolle "anon"
--      beschränkt (siehe schema.sql). Seit der Umstellung auf echten
--      Supabase-Auth-Login (Commit 1031393) läuft der eingeloggte Nutzer
--      aber unter der Rolle "authenticated" — Uploads/Löschungen wurden
--      dadurch vermutlich stillschweigend von der Datenbank abgelehnt.
--      Diese Migration ergänzt "authenticated" bei allen relevanten
--      Policies, ohne "anon" zu entfernen (schadet nicht, falls doch
--      noch irgendwo ohne Login zugegriffen wird).
-- ──────────────────────────────────────────────────────────────────────────────

-- 1. Neue Spalte für TÜV-Dokumente (Format wie 'dokumente' bei Wartungen: jsonb-Liste)
ALTER TABLE fahrzeuge
  ADD COLUMN IF NOT EXISTS tuev_dokumente jsonb DEFAULT '[]'::jsonb;

-- 2. Tabellen-Policy: zusätzlich für eingeloggte Nutzer freigeben
DROP POLICY IF EXISTS "authenticated_full_access" ON fahrzeuge;
CREATE POLICY "authenticated_full_access" ON fahrzeuge
  FOR ALL TO authenticated
  USING (true)
  WITH CHECK (true);

-- 3. Storage-Policies: zusätzlich für eingeloggte Nutzer freigeben
DROP POLICY IF EXISTS "fuhrpark_authenticated_upload" ON storage.objects;
CREATE POLICY "fuhrpark_authenticated_upload"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'fuhrpark');

DROP POLICY IF EXISTS "fuhrpark_authenticated_update" ON storage.objects;
CREATE POLICY "fuhrpark_authenticated_update"
  ON storage.objects FOR UPDATE TO authenticated
  USING (bucket_id = 'fuhrpark');

DROP POLICY IF EXISTS "fuhrpark_authenticated_delete" ON storage.objects;
CREATE POLICY "fuhrpark_authenticated_delete"
  ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'fuhrpark');
