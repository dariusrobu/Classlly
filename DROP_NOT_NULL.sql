-- Run this script in your Supabase SQL Editor to fix the "violates not-null constraint" errors.
-- It removes the NOT NULL requirement from all columns except the essential ones (id, user_id, created_at, updated_at).

DO $$
DECLARE
    t_name text;
    c_name text;
BEGIN
    FOR t_name, c_name IN 
        SELECT table_name, column_name 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
          AND table_name IN ('tasks', 'courses', 'notes', 'folders', 'grades', 'attendance', 'student_profiles')
          AND column_name NOT IN ('id', 'user_id', 'created_at', 'updated_at', 'data')
          AND is_nullable = 'NO'
    LOOP
        EXECUTE format('ALTER TABLE public.%I ALTER COLUMN %I DROP NOT NULL;', t_name, c_name);
    END LOOP;
END $$;
