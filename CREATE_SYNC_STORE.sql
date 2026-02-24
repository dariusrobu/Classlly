-- Unified Sync Architecture: CREATE_SYNC_STORE.sql
-- This table replaces the need to insert JSONB data directly into rigid legacy tables.

CREATE TABLE IF NOT EXISTS public.sync_store (
    id TEXT NOT NULL,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    collection TEXT NOT NULL, -- e.g., 'tasks', 'courses', 'notes'
    data JSONB NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    PRIMARY KEY (id, collection)
);

-- Enable Row Level Security
ALTER TABLE public.sync_store ENABLE ROW LEVEL SECURITY;

-- Create Security Policies (Idempotent)
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'sync_store' AND policyname = 'Users can insert their own sync data.') THEN
        CREATE POLICY "Users can insert their own sync data." ON public.sync_store FOR INSERT WITH CHECK (auth.uid() = user_id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'sync_store' AND policyname = 'Users can select their own sync data.') THEN
        CREATE POLICY "Users can select their own sync data." ON public.sync_store FOR SELECT USING (auth.uid() = user_id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'sync_store' AND policyname = 'Users can update their own sync data.') THEN
        CREATE POLICY "Users can update their own sync data." ON public.sync_store FOR UPDATE USING (auth.uid() = user_id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'sync_store' AND policyname = 'Users can delete their own sync data.') THEN
        CREATE POLICY "Users can delete their own sync data." ON public.sync_store FOR DELETE USING (auth.uid() = user_id);
    END IF;
END $$;

-- Create an index to speed up collection queries
CREATE INDEX IF NOT EXISTS sync_store_user_collection_idx ON public.sync_store (user_id, collection);
