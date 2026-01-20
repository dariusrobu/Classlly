-- SUPABASE DATABASE INDEXES
-- Run these commands in your Supabase SQL Editor to improve query performance.

-- 1. Index 'user_id' on all tables (CRITICAL for RLS performance)
CREATE INDEX idx_notes_user_id ON notes(user_id);
CREATE INDEX idx_tasks_user_id ON tasks(user_id);
CREATE INDEX idx_courses_user_id ON courses(user_id);
CREATE INDEX idx_folders_user_id ON folders(user_id);
CREATE INDEX idx_grades_user_id ON grades(user_id);
CREATE INDEX idx_attendance_user_id ON attendance(user_id);
CREATE INDEX idx_academic_periods_user_id ON academic_periods(user_id);
CREATE INDEX idx_academic_events_user_id ON academic_events(user_id);
CREATE INDEX idx_student_profiles_user_id ON student_profiles(user_id);

-- 2. Index 'is_deleted' for efficient filtering of active items
CREATE INDEX idx_notes_is_deleted ON notes(is_deleted);
CREATE INDEX idx_tasks_is_deleted ON tasks(is_deleted);
CREATE INDEX idx_folders_is_deleted ON folders(is_deleted);

-- 3. Index 'updated_at' for efficient sorting and sync queries
CREATE INDEX idx_notes_updated_at ON notes(updated_at DESC);
CREATE INDEX idx_tasks_updated_at ON tasks(updated_at DESC);
CREATE INDEX idx_courses_updated_at ON courses(updated_at DESC);

-- 4. Specific Indexes for common queries
-- Tasks by due date (for Calendar/Agenda views)
CREATE INDEX idx_tasks_due_date ON tasks(due_date);

-- Notes by folder (for Folder views)
CREATE INDEX idx_notes_parent_id ON notes(parent_id);
CREATE INDEX idx_folders_parent_id ON folders(parent_id);
