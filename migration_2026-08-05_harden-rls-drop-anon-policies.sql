-- ──────────────────────────────────────────────────────────────────────────────
-- Fuhrpark-Manager · Sicherheits-Migration 2026-08-05
-- Im SQL-Editor des Projekts bembfesrfepsftragaeq einmalig ausführen
--
-- Hintergrund: schema.sql (Ursprungs-Setup vom 05.06.2026) hat eine Policy
-- "anon_full_access" auf der Tabelle "fahrzeuge" sowie mehrere
-- "fuhrpark_anon_*"-Storage-Policies angelegt, die der Rolle "anon" (also JEDEM,
-- der den im Frontend sichtbaren publishable/anon-Key kennt) vollen Lese-,
-- Schreib- und Löschzugriff geben — VÖLLIG UNABHÄNGIG vom Login-Screen.
--
-- Seit der Umstellung auf echten Supabase-Auth-Login (Commit 1031393,
-- 01.07.2026) läuft die App unter der Rolle "authenticated", nicht mehr "anon".
-- Eine automatisierte Stichprobe (anonymer REST-Query gegen die Live-Tabelle,
-- 05.08.2026) zeigt zwar 0 zurückgegebene Zeilen, was darauf hindeuten könnte,
-- dass die alte anon-Policy bereits manuell entfernt wurde — das ist aber nicht
-- zweifelsfrei aus dem Code/Repo nachvollziehbar, da schema.sql nie aktualisiert
-- wurde. Dieses Skript entfernt die alten anon-Policies daher SICHERHEITSHALBER
-- explizit (idempotent — schadet nicht, falls sie bereits weg sind).
--
-- Nach dieser Migration hat NUR NOCH die Rolle "authenticated" (also: eingeloggte
-- Nutzer über den echten Login-Screen) Schreib-/Lösch-/Lesezugriff auf die
-- Fahrzeugtabelle und auf Uploads/Löschungen im Storage-Bucket "fuhrpark".
-- Downloads/Anzeigen von bereits hochgeladenen Dateien (TÜV-Berichte, Unfallfotos)
-- bleiben bewusst öffentlich lesbar (bucket ist public:true, wird für die
-- Bild-/PDF-Anzeige im Frontend direkt per URL genutzt).
-- ──────────────────────────────────────────────────────────────────────────────

-- 1. Alte anon-Policy auf der Fahrzeugtabelle entfernen
DROP POLICY IF EXISTS "anon_full_access" ON fahrzeuge;

-- 2. Alte anon-Storage-Policies entfernen (Lesen bleibt über
--    "fuhrpark_public_read" weiterhin für alle möglich — das ist gewollt)
DROP POLICY IF EXISTS "fuhrpark_anon_upload" ON storage.objects;
DROP POLICY IF EXISTS "fuhrpark_anon_update" ON storage.objects;
DROP POLICY IF EXISTS "fuhrpark_anon_delete" ON storage.objects;

-- 3. Zur Kontrolle: aktuell bestehende Policies auf "fahrzeuge" anzeigen.
--    Erwartung danach: nur noch "authenticated_full_access" (aus der Migration
--    vom 08.07.2026) sollte übrig sein.
SELECT polname, polroles::regrole[] AS rollen, polcmd
FROM pg_policy
WHERE polrelid = 'public.fahrzeuge'::regclass;
