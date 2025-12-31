DROP TABLE IF EXISTS books;
CREATE TABLE books (
  id TEXT PRIMARY KEY,
  title TEXT,
  author TEXT,
  category TEXT,
  description TEXT,
  cover_image_url TEXT,
  file_key TEXT,
  file_type TEXT,
  file_size INTEGER,
  page_count INTEGER,
  language TEXT,
  estimated_read_time_minutes INTEGER,
  access_level TEXT,
  download_allowed INTEGER,
  stream_read_allowed INTEGER,
  checksum TEXT,
  status TEXT,
  on_sale TEXT DEFAULT 'NO',
  available_to_read TEXT DEFAULT 'NO',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS user_book_progress;
CREATE TABLE user_book_progress (
  id TEXT PRIMARY KEY,
  user_id TEXT,
  book_id TEXT,
  current_page INTEGER,
  progress_percent REAL,
  last_read_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  completed_at TIMESTAMP,
  FOREIGN KEY (book_id) REFERENCES books(id)
);
