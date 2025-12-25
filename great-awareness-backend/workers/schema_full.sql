-- Users Table
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    email TEXT NOT NULL UNIQUE,
    username TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    status TEXT DEFAULT 'active' NOT NULL,
    is_verified INTEGER DEFAULT 0 NOT NULL,
    role TEXT DEFAULT 'user' NOT NULL,
    profile_image TEXT,
    first_name TEXT,
    last_name TEXT,
    phone_number TEXT UNIQUE,
    county TEXT,
    verified_otp TEXT UNIQUE,
    device_id_hash TEXT UNIQUE,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_login TEXT
);

-- Contents Table
CREATE TABLE IF NOT EXISTS contents (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    topic TEXT NOT NULL,
    post_type TEXT DEFAULT 'text' NOT NULL,
    image_path TEXT,
    is_text_only INTEGER DEFAULT 1 NOT NULL,
    author_name TEXT DEFAULT 'Admin' NOT NULL,
    author_avatar TEXT,
    likes_count INTEGER DEFAULT 0 NOT NULL,
    comments_count INTEGER DEFAULT 0 NOT NULL,
    status TEXT DEFAULT 'published' NOT NULL,
    is_featured INTEGER DEFAULT 0 NOT NULL,
    created_by INTEGER,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP NOT NULL,
    published_at TEXT,
    FOREIGN KEY (created_by) REFERENCES users(id)
);

-- Questions Table
CREATE TABLE IF NOT EXISTS questions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    category TEXT NOT NULL,
    content TEXT NOT NULL,
    has_image INTEGER DEFAULT 0 NOT NULL,
    image_path TEXT,
    author_name TEXT NOT NULL,
    is_anonymous INTEGER DEFAULT 0 NOT NULL,
    likes_count INTEGER DEFAULT 0 NOT NULL,
    comments_count INTEGER DEFAULT 0 NOT NULL,
    saves_count INTEGER DEFAULT 0 NOT NULL,
    status TEXT DEFAULT 'published' NOT NULL,
    is_featured INTEGER DEFAULT 0 NOT NULL,
    user_id INTEGER NOT NULL,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Comments Table (for Contents)
CREATE TABLE IF NOT EXISTS comments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    content_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    text TEXT NOT NULL,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (content_id) REFERENCES contents(id),
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Question Comments Table
CREATE TABLE IF NOT EXISTS question_comments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    question_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    text TEXT NOT NULL,
    is_anonymous INTEGER DEFAULT 0 NOT NULL,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (question_id) REFERENCES questions(id),
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Question Likes Table
CREATE TABLE IF NOT EXISTS question_likes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    question_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (question_id) REFERENCES questions(id),
    FOREIGN KEY (user_id) REFERENCES users(id),
    UNIQUE(question_id, user_id)
);

-- Question Saves Table
CREATE TABLE IF NOT EXISTS question_saves (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    question_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (question_id) REFERENCES questions(id),
    FOREIGN KEY (user_id) REFERENCES users(id),
    UNIQUE(question_id, user_id)
);

-- Notifications Table
CREATE TABLE IF NOT EXISTS notifications (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    notification_type TEXT NOT NULL,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    content_id INTEGER,
    question_id INTEGER,
    author_name TEXT NOT NULL,
    author_avatar TEXT,
    user_id INTEGER NOT NULL,
    is_read INTEGER DEFAULT 0 NOT NULL,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP NOT NULL,
    FOREIGN KEY (content_id) REFERENCES contents(id),
    FOREIGN KEY (question_id) REFERENCES questions(id),
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_contents_title ON contents(title);
CREATE INDEX IF NOT EXISTS idx_questions_category ON questions(category);
