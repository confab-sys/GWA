export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const method = request.method;
    const corsHeaders = {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET, HEAD, POST, PUT, DELETE, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type, Authorization",
    };

    if (method === "OPTIONS") {
      return new Response(null, { headers: corsHeaders });
    }

    try {
      if (url.pathname === "/api/health") {
        return new Response("OK", { headers: corsHeaders });
      }

      // --- Users Endpoints ---
      if (url.pathname === "/api/users" && method === "GET") {
        const { results } = await env.DB.prepare("SELECT * FROM users").all();
        return Response.json(results, { headers: corsHeaders });
      }

      // User Authentication
      if (url.pathname === "/api/auth/signup" && method === "POST") {
        return await handleSignup(request, env, corsHeaders);
      }

      if (url.pathname === "/api/auth/login" && method === "POST") {
        return await handleLogin(request, env, corsHeaders);
      }

      if (url.pathname === "/api/auth/change-password" && method === "POST") {
        return await handleChangePassword(request, env, corsHeaders);
      }
      
      // Upload Profile Image
      if (url.pathname === "/api/users/upload-profile" && method === "POST") {
        return await handleUploadProfileImage(request, env, corsHeaders);
      }
      
      // Serve Profile Image
      if (url.pathname.startsWith("/api/images/profile/") && method === "GET") {
        const key = url.pathname.split("/").pop();
        return await handleServeImage(env.GWA_USERS_BUCKET, key, corsHeaders);
      }

      // --- Contents Endpoints ---
      // Initialize DB (Helper)
      if (url.pathname === "/api/db/init-users" && method === "POST") {
        await env.DB.prepare(`
          CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT NOT NULL UNIQUE,
            email TEXT NOT NULL UNIQUE,
            password_hash TEXT NOT NULL,
            profile_image TEXT,
            device_id TEXT,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
          )
        `).run();
        
        // Add device_id column if it doesn't exist (migration)
        try {
          await env.DB.prepare("ALTER TABLE users ADD COLUMN device_id TEXT").run();
        } catch (e) {
          // Column likely already exists
        }
        
        return new Response("Users table initialized/updated", { headers: corsHeaders });
      }

      if (url.pathname === "/api/db/init-likes" && method === "POST") {
        await env.DB.prepare(`
          CREATE TABLE IF NOT EXISTS content_likes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            content_id INTEGER NOT NULL,
            user_id INTEGER NOT NULL,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (content_id) REFERENCES contents(id),
            FOREIGN KEY (user_id) REFERENCES users(id),
            UNIQUE(content_id, user_id)
          )
        `).run();
        return new Response("Likes table created", { headers: corsHeaders });
      }

      if (url.pathname === "/api/db/init-contents" && method === "POST") {
        await env.DB.prepare(`
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
          )
        `).run();
        return new Response("Contents table created", { headers: corsHeaders });
      }

      if (url.pathname === "/api/db/init-comments" && method === "POST") {
        await env.DB.prepare(`
          CREATE TABLE IF NOT EXISTS comments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            content_id INTEGER NOT NULL,
            user_id INTEGER NOT NULL,
            text TEXT NOT NULL,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (content_id) REFERENCES contents(id),
            FOREIGN KEY (user_id) REFERENCES users(id)
          )
        `).run();
        return new Response("Comments table created", { headers: corsHeaders });
      }

      if (url.pathname === "/api/contents" && method === "GET") {
        const { results } = await env.DB.prepare("SELECT * FROM contents ORDER BY created_at DESC").all();
        return Response.json(results, { headers: corsHeaders });
      }
      
      // Get Single Content
      const contentIdMatch = url.pathname.match(/^\/api\/contents\/(\d+)$/);
      if (contentIdMatch && method === "GET") {
        const id = contentIdMatch[1];
        const userId = url.searchParams.get("user_id");
        
        let query = "SELECT * FROM contents WHERE id = ?";
        let params = [id];
        
        // If user_id is provided, check like status
        if (userId) {
           query = `
             SELECT c.*, 
               CASE WHEN cl.id IS NOT NULL THEN 1 ELSE 0 END as is_liked 
             FROM contents c 
             LEFT JOIN content_likes cl ON c.id = cl.content_id AND cl.user_id = ? 
             WHERE c.id = ?
           `;
           params = [userId, id];
        }

        const result = await env.DB.prepare(query).bind(...params).first();
        if (!result) return new Response("Not Found", { status: 404, headers: corsHeaders });
        
        // Ensure is_liked is boolean
        if (result.is_liked !== undefined) {
          result.is_liked = result.is_liked === 1;
        }
        
        return Response.json(result, { headers: corsHeaders });
      }

      // Like/Unlike Content
      const likeMatch = url.pathname.match(/^\/api\/contents\/(\d+)\/like$/);
      if (likeMatch && method === "POST") {
        const id = likeMatch[1];
        const { user_id } = await request.json();
        
        if (!user_id) return new Response("Missing user_id", { status: 400, headers: corsHeaders });

        // Check if liked
        const existing = await env.DB.prepare(
          "SELECT id FROM content_likes WHERE content_id = ? AND user_id = ?"
        ).bind(id, user_id).first();

        let is_liked = false;
        if (existing) {
          // Unlike
          await env.DB.prepare(
            "DELETE FROM content_likes WHERE id = ?"
          ).bind(existing.id).run();
          
          await env.DB.prepare(
            "UPDATE contents SET likes_count = MAX(0, likes_count - 1) WHERE id = ?"
          ).bind(id).run();
          is_liked = false;
        } else {
          // Like
          await env.DB.prepare(
            "INSERT INTO content_likes (content_id, user_id) VALUES (?, ?)"
          ).bind(id, user_id).run();
          
          await env.DB.prepare(
            "UPDATE contents SET likes_count = likes_count + 1 WHERE id = ?"
          ).bind(id).run();
          is_liked = true;
        }
        
        // Get updated count
        const { likes_count } = await env.DB.prepare("SELECT likes_count FROM contents WHERE id = ?").bind(id).first();
        
        return Response.json({ success: true, likes_count, is_liked }, { headers: corsHeaders });
      }

      // Get Content Comments
      const commentsMatch = url.pathname.match(/^\/api\/contents\/(\d+)\/comments$/);
      if (commentsMatch && method === "GET") {
        const id = commentsMatch[1];
        const { results } = await env.DB.prepare(`
          SELECT c.*, u.username, u.profile_image 
          FROM comments c 
          LEFT JOIN users u ON c.user_id = u.id 
          WHERE c.content_id = ? 
          ORDER BY c.created_at DESC
        `).bind(id).all();
        
        // Format to match frontend expectation (items array)
        const formatted = results.map(r => ({
          id: r.id,
          text: r.text,
          user: {
            username: r.username || 'Anonymous',
            profile_image: r.profile_image
          },
          created_at: r.created_at,
          is_anonymous: false
        }));
        
        return Response.json({ items: formatted }, { headers: corsHeaders });
      }

      // Add Comment
      if (commentsMatch && method === "POST") {
        const id = commentsMatch[1];
        const { user_id, text } = await request.json();
        
        if (!user_id || !text) return new Response("Missing fields", { status: 400, headers: corsHeaders });

        const { success } = await env.DB.prepare(
          "INSERT INTO comments (content_id, user_id, text) VALUES (?, ?, ?)"
        ).bind(id, user_id, text).run();

        if (success) {
           await env.DB.prepare(
            "UPDATE contents SET comments_count = comments_count + 1 WHERE id = ?"
          ).bind(id).run();
          
          // Return the new comment (enriched with user info)
          const newComment = await env.DB.prepare(`
            SELECT c.*, u.username, u.profile_image 
            FROM comments c 
            LEFT JOIN users u ON c.user_id = u.id 
            WHERE c.content_id = ? AND c.user_id = ? 
            ORDER BY c.created_at DESC LIMIT 1
          `).bind(id, user_id).first();
          
           // Format
          const formatted = {
            id: newComment.id,
            text: newComment.text,
            user: {
              username: newComment.username || 'Anonymous',
              profile_image: newComment.profile_image
            },
            created_at: newComment.created_at,
            is_anonymous: false
          };
          
          return Response.json({ success: true, comment: formatted }, { headers: corsHeaders });
        }
        return new Response("Failed to add comment", { status: 500, headers: corsHeaders });
      }

      if (url.pathname === "/api/contents" && method === "POST") {
        const data = await request.json();
        // Insert content with all fields
        const { success } = await env.DB.prepare(
          `INSERT INTO contents (title, body, topic, post_type, author_name, image_path, is_text_only, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?)`
        ).bind(
          data.title, 
          data.body, 
          data.topic, 
          data.post_type || 'text', 
          data.author_name || 'Admin',
          data.image_path || null,
          data.is_text_only ? 1 : 0,
          data.status || 'published'
        ).run();
        return Response.json({ success }, { headers: corsHeaders });
      }

      // Upload Content Image
      if (url.pathname === "/api/contents/upload-image" && method === "POST") {
        return await handleUploadContentImage(request, env, corsHeaders);
      }

      // Serve Content Image
      if (url.pathname.startsWith("/api/images/content/") && method === "GET") {
        const key = url.pathname.split("/").pop();
        return await handleServeImage(env.GWA_CONTENT_BUCKET, key, corsHeaders);
      }

      // --- Questions Endpoints ---
      if (url.pathname === "/api/db/init-questions" && method === "POST") {
        await env.DB.prepare(`
          CREATE TABLE IF NOT EXISTS questions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            category TEXT,
            title TEXT,
            content TEXT,
            author_name TEXT,
            user_id INTEGER,
            is_anonymous INTEGER DEFAULT 0,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            likes_count INTEGER DEFAULT 0,
            comments_count INTEGER DEFAULT 0,
            has_image INTEGER DEFAULT 0,
            image_path TEXT,
            is_liked INTEGER DEFAULT 0,
            is_saved INTEGER DEFAULT 0
          )
        `).run();
        return new Response("Questions table created", { headers: corsHeaders });
      }

      if (url.pathname === "/api/questions" && method === "GET") {
        const skip = parseInt(url.searchParams.get("skip") || "0");
        const category = url.searchParams.get("category");
        const limit = 20;

        let query = "SELECT * FROM questions";
        let params = [];

        if (category && category !== "All") {
          query += " WHERE category = ?";
          params.push(category);
        }

        query += " ORDER BY created_at DESC LIMIT ? OFFSET ?";
        params.push(limit, skip);

        const { results } = await env.DB.prepare(query).bind(...params).all();
        return Response.json(results, { headers: corsHeaders });
      }

      if (url.pathname === "/api/questions" && method === "POST") {
        const { title, content, category, image_path, is_anonymous, user_id, author_name } = await request.json();
        
        if (!title || !content) return new Response("Missing fields", { status: 400, headers: corsHeaders });

        const { success } = await env.DB.prepare(
          `INSERT INTO questions (title, content, category, image_path, is_anonymous, user_id, author_name) VALUES (?, ?, ?, ?, ?, ?, ?)`
        ).bind(
          title, 
          content, 
          category || 'General', 
          image_path || null, 
          is_anonymous ? 1 : 0,
          user_id,
          author_name || 'Anonymous'
        ).run();
        
        return Response.json({ success }, { headers: corsHeaders });
      }

      // Get Single Question
      const questionIdMatch = url.pathname.match(/^\/api\/questions\/(\d+)$/);
      if (questionIdMatch && method === "GET") {
        const id = questionIdMatch[1];
        const result = await env.DB.prepare("SELECT * FROM questions WHERE id = ?").bind(id).first();
        if (!result) return new Response("Not Found", { status: 404, headers: corsHeaders });
        return Response.json(result, { headers: corsHeaders });
      }

      return new Response("Not Found", { status: 404, headers: corsHeaders });
    } catch (e) {
      return Response.json({ error: e.message }, { status: 500, headers: corsHeaders });
    }
  }
};

// --- Handlers ---

async function handleChangePassword(request, env, corsHeaders) {
  try {
    const { email, old_password, new_password } = await request.json();

    if (!email || !old_password || !new_password) {
      return new Response(JSON.stringify({ error: "Missing fields" }), { status: 400, headers: corsHeaders });
    }

    const user = await env.DB.prepare("SELECT * FROM users WHERE email = ?").bind(email).first();
    if (!user) {
      return new Response(JSON.stringify({ error: "User not found" }), { status: 404, headers: corsHeaders });
    }

    const [saltHex, hashHex] = user.password_hash.split(":");
    const salt = fromHex(saltHex);
    const hash = await hashPassword(old_password, salt);
    
    if (toHex(hash) !== hashHex) {
      return new Response(JSON.stringify({ error: "Invalid old password" }), { status: 401, headers: corsHeaders });
    }

    // Hash new password
    const newSalt = crypto.getRandomValues(new Uint8Array(16));
    const newHash = await hashPassword(new_password, newSalt);
    const newStoredHash = `${toHex(newSalt)}:${toHex(newHash)}`;

    // Update password
    const { success } = await env.DB.prepare("UPDATE users SET password_hash = ? WHERE id = ?").bind(newStoredHash, user.id).run();

    if (!success) throw new Error("Failed to update password");

    return new Response(JSON.stringify({ message: "Password updated successfully" }), { headers: corsHeaders });
  } catch (e) {
    return new Response(JSON.stringify({ error: e.message }), { status: 500, headers: corsHeaders });
  }
}

async function handleUploadProfileImage(request, env, corsHeaders) {
  const formData = await request.formData();
  const file = formData.get("file");
  const userId = formData.get("user_id"); // Optional: if we want to associate immediately or name it by user ID

  if (!file) {
    return new Response(JSON.stringify({ error: "No file provided" }), { status: 400, headers: corsHeaders });
  }

  // Generate unique key
  const fileExtension = file.name.split('.').pop() || 'jpg';
  const key = userId ? `${userId}-${Date.now()}.${fileExtension}` : `${crypto.randomUUID()}.${fileExtension}`;
  
  await env.GWA_USERS_BUCKET.put(key, await file.arrayBuffer(), {
    httpMetadata: { contentType: file.type }
  });

  return new Response(JSON.stringify({ 
    message: "Profile image uploaded successfully", 
    key: key,
    url: `/api/images/profile/${key}` 
  }), {
    headers: { "Content-Type": "application/json", ...corsHeaders },
  });
}

async function handleUploadContentImage(request, env, corsHeaders) {
  const formData = await request.formData();
  const file = formData.get("file");

  if (!file) {
    return new Response(JSON.stringify({ error: "No file provided" }), { status: 400, headers: corsHeaders });
  }

  // Generate unique key
  const fileExtension = file.name.split('.').pop() || 'jpg';
  const key = `${crypto.randomUUID()}.${fileExtension}`;
  
  await env.GWA_CONTENT_BUCKET.put(key, await file.arrayBuffer(), {
    httpMetadata: { contentType: file.type }
  });

  return new Response(JSON.stringify({ 
    message: "Content image uploaded successfully", 
    key: key,
    url: `/api/images/content/${key}` 
  }), {
    headers: { "Content-Type": "application/json", ...corsHeaders },
  });
}

async function handleServeImage(bucket, key, corsHeaders) {
  const object = await bucket.get(key);

  if (!object) {
    return new Response("Image not found", { status: 404, headers: corsHeaders });
  }

  const headers = new Headers();
  object.writeHttpMetadata(headers);
  headers.set("etag", object.httpEtag);
  
  // Add CORS headers
  for (const [k, v] of Object.entries(corsHeaders)) {
    headers.set(k, v);
  }

  return new Response(object.body, { headers });
}

// --- Auth Helpers ---

async function handleSignup(request, env, corsHeaders) {
  try {
    const { username, email, password, device_id_hash } = await request.json();

    if (!username || !email || !password) {
      return new Response(JSON.stringify({ error: "Missing fields" }), { status: 400, headers: corsHeaders });
    }

    // Check existing
    const existing = await env.DB.prepare("SELECT id FROM users WHERE email = ? OR username = ?").bind(email, username).first();
    if (existing) {
      return new Response(JSON.stringify({ error: "User already exists" }), { status: 409, headers: corsHeaders });
    }

    // Hash password
    const salt = crypto.getRandomValues(new Uint8Array(16));
    const hash = await hashPassword(password, salt);
    const storedHash = `${toHex(salt)}:${toHex(hash)}`;

    // Insert user
    const { success } = await env.DB.prepare(
      `INSERT INTO users (username, email, password_hash, device_id) VALUES (?, ?, ?, ?)`
    ).bind(username, email, storedHash, device_id_hash || null).run();

    if (!success) throw new Error("Failed to create user");

    return new Response(JSON.stringify({ message: "User created successfully" }), { headers: corsHeaders });
  } catch (e) {
    return new Response(JSON.stringify({ error: e.message }), { status: 500, headers: corsHeaders });
  }
}

async function handleLogin(request, env, corsHeaders) {
  try {
    const { email, password } = await request.json();

    if (!email || !password) {
      return new Response(JSON.stringify({ error: "Missing fields" }), { status: 400, headers: corsHeaders });
    }

    const user = await env.DB.prepare("SELECT * FROM users WHERE email = ?").bind(email).first();
    if (!user) {
      return new Response(JSON.stringify({ error: "User not found" }), { status: 401, headers: corsHeaders });
    }

    // Verify password
    const [saltHex, hashHex] = user.password_hash.split(":");
    const salt = fromHex(saltHex);
    const hash = await hashPassword(password, salt);
    
    if (toHex(hash) !== hashHex) {
      return new Response(JSON.stringify({ error: "Invalid password" }), { status: 401, headers: corsHeaders });
    }

    // In a real app, generate JWT here. For now, returning user info.
    // NOTE: DO NOT return password_hash
    const { password_hash, ...userInfo } = user;

    // Map DB fields to frontend expected fields
    const responseUser = {
      ...userInfo,
      id: user.id, // Explicitly include ID
      name: user.username, // Map username to name
      device_id: user.device_id,
    };

    return new Response(JSON.stringify({ 
      message: "Login successful", 
      user: responseUser,
      token: "dummy-jwt-token-placeholder" // TODO: Implement JWT signing
    }), { headers: corsHeaders });

  } catch (e) {
    return new Response(JSON.stringify({ error: e.message }), { status: 500, headers: corsHeaders });
  }
}

// Crypto Helpers
async function hashPassword(password, salt) {
  const enc = new TextEncoder();
  const keyMaterial = await crypto.subtle.importKey(
    "raw", enc.encode(password), { name: "PBKDF2" }, false, ["deriveBits", "deriveKey"]
  );
  const key = await crypto.subtle.deriveKey(
    {
      name: "PBKDF2",
      salt: salt,
      iterations: 100000,
      hash: "SHA-256"
    },
    keyMaterial,
    { name: "AES-GCM", length: 256 },
    true,
    ["encrypt", "decrypt"]
  );
  // We export the key to get the raw bytes as the hash
  return new Uint8Array(await crypto.subtle.exportKey("raw", key));
}

function toHex(buffer) {
  return Array.from(buffer).map(b => b.toString(16).padStart(2, "0")).join("");
}

function fromHex(hexString) {
  return new Uint8Array(hexString.match(/.{1,2}/g).map(byte => parseInt(byte, 16)));
}
