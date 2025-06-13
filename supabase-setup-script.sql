-- Additional SQL functions for HomeConnect

-- Function to increment election votes
CREATE OR REPLACE FUNCTION increment_election_votes(election_id uuid)
RETURNS void AS $$
BEGIN
  UPDATE elections 
  SET total_votes = total_votes + 1
  WHERE id = election_id;
END;
$$ LANGUAGE plpgsql;

-- Function to get election results
CREATE OR REPLACE FUNCTION get_election_results(election_id uuid)
RETURNS jsonb AS $$
DECLARE
  results jsonb;
BEGIN
  SELECT jsonb_object_agg(candidate_id, vote_count)
  INTO results
  FROM (
    SELECT candidate_id, COUNT(*) as vote_count
    FROM votes
    WHERE election_id = get_election_results.election_id
    GROUP BY candidate_id
  ) candidate_votes;
  
  RETURN COALESCE(results, '{}'::jsonb);
END;
$$ LANGUAGE plpgsql;

-- Update election results trigger
CREATE OR REPLACE FUNCTION update_election_results()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE elections
  SET results = get_election_results(NEW.election_id)
  WHERE id = NEW.election_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to auto-update election results
DROP TRIGGER IF EXISTS trigger_update_election_results ON votes;
CREATE TRIGGER trigger_update_election_results
  AFTER INSERT ON votes
  FOR EACH ROW
  EXECUTE FUNCTION update_election_results();

-- Row Level Security (RLS) policies
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE complaints ENABLE ROW LEVEL SECURITY;
ALTER TABLE buildings ENABLE ROW LEVEL SECURITY;
ALTER TABLE elections ENABLE ROW LEVEL SECURITY;
ALTER TABLE votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE service_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE notices ENABLE ROW LEVEL SECURITY;
ALTER TABLE emergency_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_proofs ENABLE ROW LEVEL SECURITY;

-- Users can read their own data
CREATE POLICY "Users can read own data" ON users
  FOR SELECT USING (auth.uid() = auth_user_id);

-- Users can update their own data
CREATE POLICY "Users can update own data" ON users
  FOR UPDATE USING (auth.uid() = auth_user_id);

-- Admins can read all users
CREATE POLICY "Admins can read all users" ON users
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE auth_user_id = auth.uid() 
      AND role = 'admin' 
      AND is_approved = true
    )
  );

-- Admins can update all users
CREATE POLICY "Admins can update all users" ON users
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE auth_user_id = auth.uid() 
      AND role = 'admin' 
      AND is_approved = true
    )
  );

-- Complaints policies
CREATE POLICY "Users can read own complaints" ON complaints
  FOR SELECT USING (
    user_id::text = (
      SELECT id::text FROM users WHERE auth_user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create complaints" ON complaints
  FOR INSERT WITH CHECK (
    user_id::text = (
      SELECT id::text FROM users WHERE auth_user_id = auth.uid()
    )
  );

-- Admins can read all complaints
CREATE POLICY "Admins can read all complaints" ON complaints
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE auth_user_id = auth.uid() 
      AND role = 'admin' 
      AND is_approved = true
    )
  );

-- Create storage buckets for file uploads
INSERT INTO storage.buckets (id, name, public) 
VALUES ('images', 'images', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public) 
VALUES ('documents', 'documents', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policies for images
CREATE POLICY "Images are publicly accessible" ON storage.objects
  FOR SELECT USING (bucket_id = 'images');

CREATE POLICY "Users can upload images" ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'images' AND auth.role() = 'authenticated');

-- Storage policies for documents
CREATE POLICY "Documents are publicly accessible" ON storage.objects
  FOR SELECT USING (bucket_id = 'documents');

CREATE POLICY "Users can upload documents" ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'documents' AND auth.role() = 'authenticated'); 