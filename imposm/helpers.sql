CREATE OR REPLACE FUNCTION publish_data()
RETURNS VOID AS $$
DECLARE
    rec RECORD;
BEGIN
    -- clear tables from backup schema
    FOR rec IN SELECT *
        FROM pg_tables
        WHERE schemaname = 'backup'
        AND (tablename like 'i_%' OR tablename like 'd_%' )
    loop
        execute format('DROP TABLE backup.%I;', rec.tablename);
    END LOOP;
    -- move public to backup
    FOR rec IN SELECT *
        FROM pg_tables
        WHERE schemaname = 'public'
        AND (tablename like 'i_%' OR tablename like 'd_%' )
    loop
        execute format('ALTER TABLE public.%I SET SCHEMA backup;', rec.tablename);
    END LOOP;
    -- move import to public
    FOR rec IN SELECT *
        FROM pg_tables
        WHERE schemaname = 'import'
        AND (tablename like 'i_%' OR tablename like 'd_%' )
    loop
        execute format('ALTER TABLE import.%I SET SCHEMA public;', rec.tablename);
    END LOOP;

END;
$$ LANGUAGE plpgsql;
