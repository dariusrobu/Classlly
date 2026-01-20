-- SUPABASE SECURITY POLICIES (RLS)
-- Run these commands in your Supabase SQL Editor to secure your production database.

-- 1. Enable RLS on all tables
ALTER TABLE notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE folders ENABLE ROW LEVEL SECURITY;
ALTER TABLE grades ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE academic_periods ENABLE ROW LEVEL SECURITY;
ALTER TABLE academic_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_profiles ENABLE ROW LEVEL SECURITY;

-- 2. Create Policies for User-Specific Data
-- This ensures users can ONLY see and modify their own records.

-- Notes
CREATE POLICY "Users can manage their own notes" ON notes
    FOR ALL USING (auth.uid() = user_id);

-- Tasks
CREATE POLICY "Users can manage their own tasks" ON tasks
    FOR ALL USING (auth.uid() = user_id);

-- Courses
CREATE POLICY "Users can manage their own courses" ON courses
    FOR ALL USING (auth.uid() = user_id);

-- Folders
CREATE POLICY "Users can manage their own folders" ON folders
    FOR ALL USING (auth.uid() = user_id);

-- Grades
CREATE POLICY "Users can manage their own grades" ON grades
    FOR ALL USING (auth.uid() = user_id);

-- Attendance
CREATE POLICY "Users can manage their own attendance" ON attendance
    FOR ALL USING (auth.uid() = user_id);

-- Academic Periods
CREATE POLICY "Users can manage their own academic periods" ON academic_periods
    FOR ALL USING (auth.uid() = user_id);

-- Academic Events
CREATE POLICY "Users can manage their own academic events" ON academic_events
    FOR ALL USING (auth.uid() = user_id);

-- Student Profiles
CREATE POLICY "Users can manage their own profile" ON student_profiles
    FOR ALL USING (auth.uid() = user_id);

-- 3. Storage Policies
-- Create these buckets in the Supabase Dashboard first: 'recordings', 'images'

-- Policy for 'images' bucket
-- Allows users to upload/view/delete images only in their own folder
CREATE POLICY "Users can manage their own images" ON storage.objects
    FOR ALL TO authenticated
    USING (bucket_id = 'images' AND (storage.foldername(name))[1] = auth.uid()::text)
    WITH CHECK (bucket_id = 'images' AND (storage.foldername(name))[1] = auth.uid()::text);

-- Policy for 'recordings' bucket
-- Allows users to manage their own audio recordings
CREATE POLICY "Users can manage their own recordings" ON storage.objects
    FOR ALL TO authenticated
    USING (bucket_id = 'recordings' AND (storage.foldername(name))[1] = auth.uid()::text)
    WITH CHECK (bucket_id = 'recordings' AND (storage.foldername(name))[1] = auth.uid()::text);