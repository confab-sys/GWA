
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const method = request.method;
    const path = url.pathname;

    try {
      // CORS Handling
      if (method === "OPTIONS") {
        return new Response(null, {
          headers: {
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
            "Access-Control-Allow-Headers": "Content-Type, Authorization, X-User-ID",
          },
        });
      }

      // Router
      if (method === "POST" && path === "/upload") {
        return await handleUpload(request, env);
      } else if (method === "GET" && path.match(/^\/download\/.+/)) {
        const id = path.split("/")[2];
        return await handleDownload(id, request, env);
      } else if (method === "GET" && path.match(/^\/stream\/.+/)) {
        const id = path.split("/")[2];
        return await handleStream(id, request, env);
      } else if (method === "POST" && path === "/progress") {
        return await handleProgress(request, env);
      } else if (method === "GET" && path.match(/^\/books\/.+/)) {
        const id = path.split("/")[2];
        return await handleGetBook(id, env);
      }

      return new Response("Not Found", { status: 404 });
    } catch (err) {
      return new Response(JSON.stringify({ error: err.message }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      });
    }
  },
};

// --- Handlers ---

async function handleUpload(request, env) {
  const formData = await request.formData();
  
  const file = formData.get("file");
  const cover = formData.get("cover_image");
  const metadata = {
    title: formData.get("title"),
    author: formData.get("author"),
    category: formData.get("category"),
    description: formData.get("description"),
    page_count: parseInt(formData.get("page_count") || 0),
    language: formData.get("language"),
    estimated_read_time_minutes: parseInt(formData.get("estimated_read_time_minutes") || 0),
    access_level: formData.get("access_level") || "free",
    download_allowed: formData.get("download_allowed") === "true" ? 1 : 0,
    stream_read_allowed: formData.get("stream_read_allowed") === "true" ? 1 : 0,
    status: "active",
  };

  if (!file || !cover) {
    return new Response("Missing file or cover image", { status: 400 });
  }

  // Generate IDs and Keys
  const bookId = crypto.randomUUID();
  const fileExtension = file.name.split('.').pop();
  const coverExtension = cover.name.split('.').pop();
  const fileKey = `books/files/${bookId}.${fileExtension}`;
  const coverKey = `books/covers/${bookId}.${coverExtension}`;

  // Calculate Checksum
  const fileBuffer = await file.arrayBuffer();
  const fileHashBuffer = await crypto.subtle.digest("SHA-256", fileBuffer);
  const fileHashArray = Array.from(new Uint8Array(fileHashBuffer));
  const checksum = fileHashArray.map(b => b.toString(16).padStart(2, '0')).join('');

  // Upload to R2
  await env.GWA_BOOKS_BUCKET.put(fileKey, fileBuffer);
  await env.GWA_BOOKS_BUCKET.put(coverKey, await cover.arrayBuffer());

  // Insert into D1
  const query = `
    INSERT INTO books (
      id, title, author, category, description, cover_image_url, 
      file_key, file_type, file_size, page_count, language, 
      estimated_read_time_minutes, access_level, download_allowed, 
      stream_read_allowed, checksum, status, created_at, updated_at
    ) VALUES (
      ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
    )
  `;

  await env.GWA_BOOKS_DB.prepare(query)
    .bind(
      bookId, metadata.title, metadata.author, metadata.category, metadata.description,
      coverKey, fileKey, file.type, file.size, metadata.page_count,
      metadata.language, metadata.estimated_read_time_minutes, metadata.access_level,
      metadata.download_allowed, metadata.stream_read_allowed, checksum, metadata.status
    )
    .run();

  return new Response(JSON.stringify({ message: "Book uploaded successfully", bookId }), {
    headers: { "Content-Type": "application/json" },
  });
}

async function handleDownload(id, request, env) {
  // 1. Get Book Metadata
  const book = await env.GWA_BOOKS_DB.prepare("SELECT * FROM books WHERE id = ?").bind(id).first();
  
  if (!book) return new Response("Book not found", { status: 404 });
  if (!book.download_allowed) return new Response("Download not allowed", { status: 403 });

  // 2. Check Access Level (Simplified)
  const userId = request.headers.get("X-User-ID");
  if (!checkAccess(userId, book.access_level)) {
    return new Response("Access denied", { status: 403 });
  }

  // 3. Serve from R2
  const object = await env.GWA_BOOKS_BUCKET.get(book.file_key);
  if (!object) return new Response("File not found in storage", { status: 404 });

  const headers = new Headers();
  object.writeHttpMetadata(headers);
  headers.set("etag", object.httpEtag);
  headers.set("Content-Disposition", `attachment; filename="${book.title}.${book.file_type.split('/')[1] || 'bin'}"`);

  return new Response(object.body, { headers });
}

async function handleStream(id, request, env) {
  const book = await env.GWA_BOOKS_DB.prepare("SELECT * FROM books WHERE id = ?").bind(id).first();
  
  if (!book) return new Response("Book not found", { status: 404 });
  if (!book.stream_read_allowed) return new Response("Streaming not allowed", { status: 403 });

  const userId = request.headers.get("X-User-ID");
  if (!checkAccess(userId, book.access_level)) {
    return new Response("Access denied", { status: 403 });
  }

  const object = await env.GWA_BOOKS_BUCKET.get(book.file_key, {
    range: request.headers.get("range"),
  });

  if (!object) return new Response("File not found in storage", { status: 404 });

  const headers = new Headers();
  object.writeHttpMetadata(headers);
  headers.set("etag", object.httpEtag);
  
  // R2 get() handles range requests automatically if we pass the range header,
  // but we need to return the correct status and Content-Range.
  // The 'object' returned by get() with range has the correct body/range.
  
  return new Response(object.body, {
    headers,
    status: object.body ? (request.headers.get("range") ? 206 : 200) : 304,
  });
}

async function handleProgress(request, env) {
  const { user_id, book_id, current_page, progress_percent, completed } = await request.json();

  if (!user_id || !book_id) {
    return new Response("Missing user_id or book_id", { status: 400 });
  }

  const completed_at = completed ? new Date().toISOString() : null;

  // Check if progress exists
  const existing = await env.GWA_BOOKS_DB.prepare("SELECT id FROM user_book_progress WHERE user_id = ? AND book_id = ?")
    .bind(user_id, book_id)
    .first();

  if (existing) {
    await env.GWA_BOOKS_DB.prepare(`
      UPDATE user_book_progress 
      SET current_page = ?, progress_percent = ?, last_read_at = CURRENT_TIMESTAMP, completed_at = COALESCE(completed_at, ?)
      WHERE id = ?
    `).bind(current_page, progress_percent, completed_at, existing.id).run();
  } else {
    await env.GWA_BOOKS_DB.prepare(`
      INSERT INTO user_book_progress (id, user_id, book_id, current_page, progress_percent, last_read_at, completed_at)
      VALUES (?, ?, ?, ?, ?, CURRENT_TIMESTAMP, ?)
    `).bind(crypto.randomUUID(), user_id, book_id, current_page, progress_percent, completed_at).run();
  }

  return new Response(JSON.stringify({ success: true }), {
    headers: { "Content-Type": "application/json" },
  });
}

async function handleGetBook(id, env) {
    const book = await env.GWA_BOOKS_DB.prepare("SELECT * FROM books WHERE id = ?").bind(id).first();
    if (!book) return new Response("Book not found", { status: 404 });
    return new Response(JSON.stringify(book), { headers: { "Content-Type": "application/json" } });
}

// Helper: Access Control Logic (Placeholder)
function checkAccess(userId, accessLevel) {
  // In a real app, you'd check the user's subscription or purchase against the book's access level.
  // For now, we assume if a User-ID is present, they have access to 'free' content.
  // Implementing full auth verification is outside the scope of this snippet without more context.
  if (!userId) return false;
  if (accessLevel === 'free') return true;
  // if (accessLevel === 'premium') return checkPremium(userId);
  return true; // Default to allow for testing
}
