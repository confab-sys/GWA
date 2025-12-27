DROP TABLE IF EXISTS podcasts;
CREATE TABLE podcasts (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  subtitle TEXT,
  description TEXT,
  category TEXT,
  object_key TEXT NOT NULL,
  created_at TEXT NOT NULL,
  file_size INTEGER,
  content_type TEXT,
  duration TEXT,
  original_name TEXT,
  thumbnail_url TEXT,
  signed_url TEXT,
  signed_url_expires_at TEXT,
  view_count INTEGER DEFAULT 0
);
