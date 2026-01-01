
-- Notifications Table V2
CREATE TABLE IF NOT EXISTS notifications_v2 (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    type TEXT NOT NULL, -- 'badge', 'milestone', 'chat', 'event', 'system'
    metadata TEXT, -- JSON string
    created_at INTEGER NOT NULL,
    is_read BOOLEAN DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_notifications_v2_user_id ON notifications_v2(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_v2_created_at ON notifications_v2(created_at);

-- FCM Tokens Table
CREATE TABLE IF NOT EXISTS fcm_tokens (
    user_id TEXT PRIMARY KEY,
    token TEXT NOT NULL,
    updated_at INTEGER NOT NULL
);
