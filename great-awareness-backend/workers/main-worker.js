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
      if (url.pathname === "/api/contents" && method === "GET") {
        const { results } = await env.DB.prepare("SELECT * FROM contents ORDER BY created_at DESC").all();
        return Response.json(results, { headers: corsHeaders });
      }
      
      if (url.pathname === "/api/contents" && method === "POST") {
        const data = await request.json();
        // Basic insert example
        const { success } = await env.DB.prepare(
          `INSERT INTO contents (title, body, topic, post_type, author_name) VALUES (?, ?, ?, ?, ?)`
        ).bind(data.title, data.body, data.topic, data.post_type || 'text', data.author_name || 'Admin').run();
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
      if (url.pathname === "/api/questions" && method === "GET") {
        const { results } = await env.DB.prepare("SELECT * FROM questions ORDER BY created_at DESC").all();
        return Response.json(results, { headers: corsHeaders });
      }

      return new Response("Not Found", { status: 404, headers: corsHeaders });
    } catch (e) {
      return Response.json({ error: e.message }, { status: 500, headers: corsHeaders });
    }
  }
};

// --- Handlers ---

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
    const { username, email, password } = await request.json();

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
      `INSERT INTO users (username, email, password_hash) VALUES (?, ?, ?)`
    ).bind(username, email, storedHash).run();

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
      return new Response(JSON.stringify({ error: "Invalid credentials" }), { status: 401, headers: corsHeaders });
    }

    // Verify password
    const [saltHex, hashHex] = user.password_hash.split(":");
    const salt = fromHex(saltHex);
    const hash = await hashPassword(password, salt);
    
    if (toHex(hash) !== hashHex) {
      return new Response(JSON.stringify({ error: "Invalid credentials" }), { status: 401, headers: corsHeaders });
    }

    // In a real app, generate JWT here. For now, returning user info.
    // NOTE: DO NOT return password_hash
    const { password_hash, ...userInfo } = user;

    return new Response(JSON.stringify({ 
      message: "Login successful", 
      user: userInfo,
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
