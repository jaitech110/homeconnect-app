class SupabaseConfig {
  // 🔥 REPLACE THESE WITH YOUR ACTUAL SUPABASE VALUES
  // Get these from your Supabase project Settings > API
  
  static const String supabaseUrl = 'https://uuwjlshvftmrfhslcxvi.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV1d2psc2h2ZnRtcmZoc2xjeHZpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzQ5NjE1ODEsImV4cCI6MjA1MDUzNzU4MX0.h5SgdlmJmHV9k-MIIBrUHhUPbYLPZD41K0J5qgtfYuc';
  
  // Storage bucket names
  static const String imagesBucket = 'images';
  static const String documentsBucket = 'documents';
  
  // File upload limits
  static const int maxFileSize = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'gif'];
  static const List<String> allowedDocumentTypes = ['pdf', 'doc', 'docx', 'txt'];
}

// 📝 SETUP INSTRUCTIONS:
// 
// 1. Go to your Supabase project dashboard
// 2. Navigate to Settings > API
// 3. Copy your Project URL and replace 'https://your-project-id.supabase.co'
// 4. Copy your anon/public key and replace 'your-anon-key-here'
// 5. Save this file
// 
// Example:
// static const String supabaseUrl = 'https://abcdefgh12345678.supabase.co';
// static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRlc3QiLCJyb2xlIjoiYW5vbiIsImlhdCI6MTY0NjA2NzI1MCwiZXhwIjoxOTYxNjQzMjUwfQ.abc123xyz...'; 