/**
 * Cloudflare Worker for Video Management
 * Handles video uploads to R2, metadata storage in D1, and signed URL generation
 */

export default {
  async fetch(request, env, ctx) {
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      'Access-Control-Max-Age': '86400',
    };

    // Handle CORS preflight requests
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    try {
      const url = new URL(request.url);
      const path = url.pathname;
      const method = request.method;

      // Route requests based on path and method
      if (path === '/api/videos/upload' && method === 'POST') {
        return await handleVideoUpload(request, env, corsHeaders);
      } else if (path === '/api/videos' && method === 'GET') {
        return await handleListVideos(request, env, corsHeaders);
      } else if (path.startsWith('/api/videos/') && path.endsWith('/signed-url') && method === 'GET') {
        return await handleSignedUrl(request, env, corsHeaders);
      } else if (path.startsWith('/api/videos/') && method === 'GET') {
        return await handleGetVideo(request, env, corsHeaders);
      } else if (path === '/api/debug/schema' && method === 'GET') {
        return await handleDebugSchema(request, env, corsHeaders);
      } else if (path === '/api/debug/migrate' && method === 'POST') {
        return await handleMigrateSchema(request, env, corsHeaders);
      } else {
        return new Response('Not Found', { 
          status: 404, 
          headers: corsHeaders 
        });
      }
    } catch (error) {
      console.error('Worker error:', error);
      return new Response(
        JSON.stringify({ 
          error: 'Internal Server Error', 
          message: error.message 
        }), 
        { 
          status: 500, 
          headers: { 
            ...corsHeaders, 
            'Content-Type': 'application/json' 
          } 
        }
      );
    }
  }
};

/**
 * Handle video file upload
 * Stores file in R2 and metadata in D1
 */
async function handleVideoUpload(request, env, corsHeaders) {
  try {
    const formData = await request.formData();
    const file = formData.get('video');
    const title = formData.get('title');
    const description = formData.get('description') || '';

    if (!file || !title) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: video file and title' }),
        { 
          status: 400, 
          headers: { 
            ...corsHeaders, 
            'Content-Type': 'application/json' 
          } 
        }
      );
    }

    // Validate file type
    const allowedTypes = ['video/mp4', 'video/quicktime', 'video/x-msvideo', 'video/webm'];
    if (!allowedTypes.includes(file.type)) {
      return new Response(
        JSON.stringify({ error: 'Invalid file type. Allowed: MP4, MOV, AVI, WebM' }),
        { 
          status: 400, 
          headers: { 
            ...corsHeaders, 
            'Content-Type': 'application/json' 
          } 
        }
      );
    }

    // Validate file size (100MB limit)
    const maxSize = 100 * 1024 * 1024; // 100MB
    if (file.size > maxSize) {
      return new Response(
        JSON.stringify({ error: 'File too large. Maximum size: 100MB' }),
        { 
          status: 400, 
          headers: { 
            ...corsHeaders, 
            'Content-Type': 'application/json' 
          } 
        }
      );
    }

    // Generate unique object key
    const timestamp = Date.now();
    const fileExtension = file.name.split('.').pop();
    const objectKey = `videos/${timestamp}_${Math.random().toString(36).substr(2, 9)}.${fileExtension}`;

    // Upload to R2
    await env.VIDEO_BUCKET.put(objectKey, file.stream(), {
      httpMetadata: {
        contentType: file.type,
        cacheControl: 'public, max-age=31536000', // 1 year cache
      },
      customMetadata: {
        originalName: file.name,
        title: title,
        description: description,
        uploadedAt: new Date().toISOString(),
      },
    });

    // Store metadata in D1
    const videoId = crypto.randomUUID();
    const createdAt = new Date().toISOString();
    
    await env.DB.prepare(`
      INSERT INTO videos (id, title, description, object_key, created_at, file_size, content_type, original_name, view_count, comment_count)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).bind(
      videoId,
      title,
      description,
      objectKey,
      createdAt,
      file.size,
      file.type,
      file.name,
      0, // view_count
      0  // comment_count
    ).run();

    return new Response(
      JSON.stringify({
        success: true,
        video: {
          id: videoId,
          title: title,
          description: description,
          objectKey: objectKey,
          createdAt: createdAt,
          fileSize: file.size,
          contentType: file.type,
          originalName: file.name,
        }
      }),
      { 
        status: 201, 
        headers: { 
          ...corsHeaders, 
          'Content-Type': 'application/json' 
        } 
      }
    );

  } catch (error) {
    console.error('Upload error:', error);
    return new Response(
      JSON.stringify({ error: 'Upload failed', message: error.message }),
      { 
        status: 500, 
        headers: { 
          ...corsHeaders, 
          'Content-Type': 'application/json' 
        } 
      }
    );
  }
}

/**
 * Migrate database schema to add missing columns
 */
async function handleMigrateSchema(request, env, corsHeaders) {
  try {
    // Add description column
    try {
      await env.DB.prepare(`ALTER TABLE videos ADD COLUMN description TEXT`).run();
    } catch (e) {
      if (!e.message.includes('duplicate column name')) {
        throw e;
      }
    }

    // Add view_count column
    try {
      await env.DB.prepare(`ALTER TABLE videos ADD COLUMN view_count INTEGER DEFAULT 0`).run();
    } catch (e) {
      if (!e.message.includes('duplicate column name')) {
        throw e;
      }
    }

    // Add comment_count column
    try {
      await env.DB.prepare(`ALTER TABLE videos ADD COLUMN comment_count INTEGER DEFAULT 0`).run();
    } catch (e) {
      if (!e.message.includes('duplicate column name')) {
        throw e;
      }
    }

    // Add file_size column
    try {
      await env.DB.prepare(`ALTER TABLE videos ADD COLUMN file_size INTEGER`).run();
    } catch (e) {
      if (!e.message.includes('duplicate column name')) {
        throw e;
      }
    }

    // Add content_type column
    try {
      await env.DB.prepare(`ALTER TABLE videos ADD COLUMN content_type TEXT`).run();
    } catch (e) {
      if (!e.message.includes('duplicate column name')) {
        throw e;
      }
    }

    // Add original_name column
    try {
      await env.DB.prepare(`ALTER TABLE videos ADD COLUMN original_name TEXT`).run();
    } catch (e) {
      if (!e.message.includes('duplicate column name')) {
        throw e;
      }
    }

    return new Response(
      JSON.stringify({ 
        success: true, 
        message: 'Database schema migrated successfully',
        addedColumns: ['description', 'view_count', 'comment_count', 'file_size', 'content_type', 'original_name']
      }),
      { 
        status: 200, 
        headers: { 
          ...corsHeaders, 
          'Content-Type': 'application/json' 
        } 
      }
    );
  } catch (error) {
    console.error('Migration error:', error);
    return new Response(
      JSON.stringify({ 
        error: 'Failed to migrate schema', 
        message: error.message 
      }), 
      { 
        status: 500, 
        headers: { 
          ...corsHeaders, 
          'Content-Type': 'application/json' 
        } 
      }
    );
  }
}

/**
 * Debug endpoint to check database schema
 */
async function handleDebugSchema(request, env, corsHeaders) {
  try {
    // Check if videos table exists
    const tableCheck = await env.DB.prepare(`
      SELECT name FROM sqlite_master WHERE type='table' AND name='videos'
    `).first();
    
    if (!tableCheck) {
      return new Response(
        JSON.stringify({
          error: 'Videos table does not exist',
          schema: null,
          suggestion: 'Create the videos table with: CREATE TABLE videos (id TEXT PRIMARY KEY, title TEXT, description TEXT, object_key TEXT, created_at TEXT, file_size INTEGER, content_type TEXT, original_name TEXT)'
        }),
        { 
          status: 404, 
          headers: { 
            ...corsHeaders, 
            'Content-Type': 'application/json' 
          } 
        }
      );
    }
    
    // Get table schema
    const schema = await env.DB.prepare(`
      PRAGMA table_info(videos)
    `).all();
    
    // Get sample data
    const sample = await env.DB.prepare(`
      SELECT * FROM videos LIMIT 1
    `).first();
    
    return new Response(
      JSON.stringify({
        success: true,
        tableExists: true,
        schema: schema.results || [],
        sampleData: sample,
        totalVideos: (await env.DB.prepare('SELECT COUNT(*) as count FROM videos').first())?.count || 0
      }),
      { 
        status: 200, 
        headers: { 
          ...corsHeaders, 
          'Content-Type': 'application/json' 
        } 
      }
    );
    
  } catch (error) {
    console.error('Schema debug error:', error);
    return new Response(
      JSON.stringify({ 
        error: 'Failed to check schema', 
        message: error.message 
      }), 
      { 
        status: 500, 
        headers: { 
          ...corsHeaders, 
          'Content-Type': 'application/json' 
        } 
      }
    );
  }
}

/**
 * Handle listing all videos
 */
async function handleListVideos(request, env, corsHeaders) {
  try {
    const url = new URL(request.url);
    const limit = parseInt(url.searchParams.get('limit')) || 50;
    const offset = parseInt(url.searchParams.get('offset')) || 0;
    const search = url.searchParams.get('search') || '';

    let countQuery = `
      SELECT COUNT(*) as total
      FROM videos
      WHERE 1=1
    `;
    
    let query = `
      SELECT id, title, description, object_key, created_at, view_count, comment_count
      FROM videos
      WHERE 1=1
    `;
    
    const bindings = [];
    const countBindings = [];
    
    if (search) {
      const searchCondition = ` AND title LIKE ?`;
      query += searchCondition;
      countQuery += searchCondition;
      bindings.push(`%${search}%`);
      countBindings.push(`%${search}%`);
    }
    
    query += ` ORDER BY created_at DESC LIMIT ? OFFSET ?`;
    bindings.push(limit, offset);

    // Get total count
    const countResult = await env.DB.prepare(countQuery).bind(...countBindings).first();
    const total = countResult?.total || 0;

    // Get paginated results
    const result = await env.DB.prepare(query).bind(...bindings).all();

    return new Response(
      JSON.stringify({
        success: true,
        videos: result.results || [],
        total: result.results?.length || 0,
        page: Math.floor(offset / limit) + 1,
        perPage: limit
      }),
      { 
        status: 200, 
        headers: { 
          ...corsHeaders, 
          'Content-Type': 'application/json' 
        }
      }
    );

  } catch (error) {
    console.error('List videos error:', error);
    return new Response(
      JSON.stringify({ error: 'Failed to list videos', message: error.message }),
      { 
        status: 500, 
        headers: { 
          ...corsHeaders, 
          'Content-Type': 'application/json' 
        } 
      }
    );
  }
}

/**
 * Handle generating signed URL for private R2 access
 */
async function handleSignedUrl(request, env, corsHeaders) {
  try {
    const url = new URL(request.url);
    const pathParts = url.pathname.split('/');
    const videoId = pathParts[3]; // /api/videos/{id}/signed-url

    if (!videoId) {
      return new Response(
        JSON.stringify({ error: 'Video ID is required' }),
        { 
          status: 400, 
          headers: { 
            ...corsHeaders, 
            'Content-Type': 'application/json' 
          } 
        }
      );
    }

    // Get video metadata from D1
    const result = await env.DB.prepare(`
      SELECT object_key, title, description, view_count, comment_count
      FROM videos 
      WHERE id = ?
    `).bind(videoId).first();

    if (!result) {
      return new Response(
        JSON.stringify({ error: 'Video not found' }),
        { 
          status: 404, 
          headers: { 
            ...corsHeaders, 
            'Content-Type': 'application/json' 
          } 
        }
      );
    }

    // Generate signed URL valid for 1 hour
    const signedUrl = await getSignedUrl(env.VIDEO_BUCKET, result.object_key, 3600); // 1 hour expiry

    return new Response(
      JSON.stringify({
        success: true,
        signedUrl: signedUrl,
        video: {
          id: videoId,
          title: result.title,
          description: result.description,
          view_count: result.view_count,
          comment_count: result.comment_count,
          expiresIn: 3600,
        }
      }),
      { 
        status: 200, 
        headers: { 
          ...corsHeaders, 
          'Content-Type': 'application/json' 
        } 
      }
    );

  } catch (error) {
    console.error('Signed URL error:', error);
    return new Response(
      JSON.stringify({ error: 'Failed to generate signed URL', message: error.message }),
      { 
        status: 500, 
        headers: { 
          ...corsHeaders, 
          'Content-Type': 'application/json' 
        } 
      }
    );
  }
}

/**
 * Handle getting single video metadata
 */
async function handleGetVideo(request, env, corsHeaders) {
  try {
    const url = new URL(request.url);
    const pathParts = url.pathname.split('/');
    const videoId = pathParts[3]; // /api/videos/{id}

    if (!videoId) {
      return new Response(
        JSON.stringify({ error: 'Video ID is required' }),
        { 
          status: 400, 
          headers: { 
            ...corsHeaders, 
            'Content-Type': 'application/json' 
          } 
        }
      );
    }

    const result = await env.DB.prepare(`
      SELECT id, title, description, object_key, created_at, view_count, comment_count
      FROM videos 
      WHERE id = ?
    `).bind(videoId).first();

    if (!result) {
      return new Response(
        JSON.stringify({ error: 'Video not found' }),
        { 
          status: 404, 
          headers: { 
            ...corsHeaders, 
            'Content-Type': 'application/json' 
          } 
        }
      );
    }

    return new Response(
      JSON.stringify({
        success: true,
        video: result
      }),
      { 
        status: 200, 
        headers: { 
          ...corsHeaders, 
          'Content-Type': 'application/json' 
        } 
      }
    );

  } catch (error) {
    console.error('Get video error:', error);
    return new Response(
      JSON.stringify({ error: 'Failed to get video', message: error.message }),
      { 
        status: 500, 
        headers: { 
          ...corsHeaders, 
          'Content-Type': 'application/json' 
        } 
      }
    );
  }
}

/**
 * Generate signed URL for R2 object
 */
async function getSignedUrl(bucket, objectKey, expirySeconds = 3600) {
  // For Cloudflare R2, we can use presigned URLs or generate temporary access
  // This is a simplified version - you may need to adjust based on your R2 setup
  
  // Option 1: If R2 is public, return direct URL (not recommended for private content)
  // return `https://your-r2-domain.com/${objectKey}`;
  
  // Option 2: Generate presigned URL (recommended for private buckets)
  // This requires setting up R2 with proper access keys and signing
  
  // For now, returning a signed URL pattern that Cloudflare Workers can handle
  const timestamp = Math.floor(Date.now() / 1000);
  const expiry = timestamp + expirySeconds;
  
  // In a real implementation, you'd use AWS SDK v3 or similar to generate presigned URLs
  // For this example, we'll return a URL with expiry parameter
  return `https://your-r2-domain.com/${objectKey}?expiry=${expiry}&signature=generated-signature`;
}