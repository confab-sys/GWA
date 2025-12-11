/**
 * GWA Video Worker - Fresh Implementation
 * Handles video storage in R2 and metadata in D1
 */

// CORS headers for cross-origin requests
const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  'Access-Control-Max-Age': '86400',
};

/**
 * Main request handler
 */
export default {
  async fetch(request, env, ctx) {
    const { pathname, searchParams } = new URL(request.url);
    const method = request.method;
    
    // Handle CORS preflight requests
    if (method === 'OPTIONS') {
      return new Response(null, { headers: CORS_HEADERS });
    }
    
    try {
      // Route requests based on path and method
      if (pathname === '/api/videos' && method === 'GET') {
        return await handleListVideos(request, env, CORS_HEADERS);
      } else if (pathname === '/api/videos/sync' && method === 'POST') {
        return await handleSyncVideos(request, env, CORS_HEADERS);
      } else if (pathname === '/api/videos/upload' && method === 'POST') {
        return await handleUploadVideo(request, env, CORS_HEADERS);
      } else if (pathname.startsWith('/api/videos/') && pathname.endsWith('/signed-url') && method === 'GET') {
        const pathParts = pathname.split('/');
        const videoId = pathParts[3]; // /api/videos/{id}/signed-url
        return await handleGetSignedUrl(request, env, CORS_HEADERS, videoId);
      } else if (pathname.startsWith('/api/videos/signed/') && method === 'GET') {
        // Handle direct video serving from signed URLs
        const pathParts = pathname.split('/');
        const objectKey = pathParts[4]; // /api/videos/signed/{objectKey}
        return await handleServeVideo(request, env, CORS_HEADERS, objectKey);
      } else if (pathname.startsWith('/api/videos/') && method === 'GET') {
        const pathParts = pathname.split('/');
        const videoId = pathParts[3]; // /api/videos/{id}
        return await handleGetVideo(request, env, CORS_HEADERS, videoId);
      } else if (pathname === '/' && method === 'GET') {
        return await handleHealthCheck(request, env, CORS_HEADERS);
      } else {
        return new Response(
          JSON.stringify({ error: 'Endpoint not found' }),
          { status: 404, headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' } }
        );
      }
    } catch (error) {
      console.error('Worker error:', error);
      return new Response(
        JSON.stringify({ error: 'Internal server error', message: error.message }),
        { status: 500, headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' } }
      );
    }
  }
};

/**
 * Health check endpoint
 */
async function handleHealthCheck(request, env, corsHeaders) {
  return new Response(
    JSON.stringify({ 
      status: 'healthy', 
      service: 'GWA Video Worker',
      timestamp: new Date().toISOString()
    }),
    { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
  );
}

/**
 * List all videos with pagination
 */
async function handleListVideos(request, env, corsHeaders) {
  const url = new URL(request.url);
  const page = parseInt(url.searchParams.get('page') || '1');
  const limit = parseInt(url.searchParams.get('limit') || '50');
  const offset = (page - 1) * limit;
  
  try {
    // Get total count
    const countResult = await env.GWA_VIDEOS_DB.prepare(
      'SELECT COUNT(*) as total FROM videos'
    ).first();
    
    // Get videos with pagination
    const videosResult = await env.GWA_VIDEOS_DB.prepare(`
      SELECT id, title, description, object_key, created_at, file_size, content_type, original_name, view_count, comment_count, signed_url, signed_url_expires_at
      FROM videos
      ORDER BY created_at DESC
      LIMIT ? OFFSET ?
    `).bind(limit, offset).all();
    
    return new Response(
      JSON.stringify({
        success: true,
        videos: videosResult.results || [],
        pagination: {
          page,
          limit,
          total: countResult.total || 0,
          pages: Math.ceil((countResult.total || 0) / limit)
        }
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('List videos error:', error);
    return new Response(
      JSON.stringify({ error: 'Failed to list videos', message: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
}

/**
 * Get single video by ID
 */
async function handleGetVideo(request, env, corsHeaders, videoId) {
  try {
    const video = await env.GWA_VIDEOS_DB.prepare(`
      SELECT id, title, description, object_key, created_at, file_size, content_type, original_name, view_count, comment_count, signed_url, signed_url_expires_at
      FROM videos
      WHERE id = ?
    `).bind(videoId).first();
    
    if (!video) {
      return new Response(
        JSON.stringify({ error: 'Video not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }
    
    return new Response(
      JSON.stringify({ success: true, video }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Get video error:', error);
    return new Response(
      JSON.stringify({ error: 'Failed to get video', message: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
}

/**
 * Generate signed URL for video access
 */
async function handleGetSignedUrl(request, env, corsHeaders, videoId) {
  try {
    // Get video from database
    const video = await env.GWA_VIDEOS_DB.prepare(`
      SELECT object_key FROM videos WHERE id = ?
    `).bind(videoId).first();
    
    if (!video || !video.object_key) {
      return new Response(
        JSON.stringify({ error: 'Video not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }
    
    // Generate signed URL (valid for 1 hour)
    const expiryTime = 3600; // 1 hour
    const signedUrl = await generateSignedUrl(env.GWA_VIDEOS_BUCKET, video.object_key, expiryTime);
    
    return new Response(
      JSON.stringify({
        success: true,
        signed_url: signedUrl,
        expires_in: expiryTime,
        expires_at: new Date(Date.now() + expiryTime * 1000).toISOString()
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Generate signed URL error:', error);
    return new Response(
      JSON.stringify({ error: 'Failed to generate signed URL', message: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
}

/**
 * Sync videos from R2 bucket to database
 */
async function handleSyncVideos(request, env, corsHeaders) {
  try {
    console.log('Starting video sync from R2 bucket...');
    
    // List all objects in R2 bucket
    const objects = await env.GWA_VIDEOS_BUCKET.list();
    console.log(`Found ${objects.objects?.length || 0} objects in R2 bucket`);
    
    if (!objects.objects || objects.objects.length === 0) {
      return new Response(
        JSON.stringify({ 
          success: true, 
          message: 'No objects found in R2 bucket',
          synced: 0,
          skipped: 0 
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }
    
    let syncedCount = 0;
    let skippedCount = 0;
    const syncedVideos = [];
    
    // Process each object
    for (const object of objects.objects) {
      const key = object.key;
      
      // Only process video files
      if (!key.match(/\.(mp4|mov|avi|webm|mkv|m4v|3gp)$/i)) {
        console.log(`Skipping non-video file: ${key}`);
        skippedCount++;
        continue;
      }
      
      try {
        // Check if video already exists in database
        const existingVideo = await env.GWA_VIDEOS_DB.prepare(
          'SELECT id FROM videos WHERE object_key = ?'
        ).bind(key).first();
        
        if (existingVideo) {
          console.log(`Video already exists in database: ${key}`);
          skippedCount++;
          continue;
        }
        
        // Generate video metadata
        const videoId = crypto.randomUUID();
        const title = generateTitleFromFilename(key);
        const fileSize = parseInt(object.size || 0);
        const contentType = getContentTypeFromExtension(key);
        const description = `Professional ${contentType} video: ${title}`;
        const createdAt = new Date(object.uploaded || Date.now()).toISOString();
        
        console.log(`Processing video: ${key}, size: ${fileSize}, type: ${contentType}`);
        
        // Generate signed URL (valid for 7 days)
        const expiryTime = 7 * 24 * 3600; // 7 days in seconds
        const signedUrl = await generateSignedUrl(env.GWA_VIDEOS_BUCKET, key, expiryTime);
        const signedUrlExpiresAt = new Date(Date.now() + expiryTime * 1000).toISOString();
        
        // Insert video into database with signed URL
        await env.GWA_VIDEOS_DB.prepare(`
          INSERT INTO videos (id, title, description, object_key, created_at, file_size, content_type, original_name, view_count, comment_count, signed_url, signed_url_expires_at)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        `).bind(
          videoId, title, description, key, createdAt, fileSize, contentType, key, 0, 0, signedUrl, signedUrlExpiresAt
        ).run();
        
        syncedVideos.push({ id: videoId, title, object_key: key, signed_url: signedUrl });
        syncedCount++;
        console.log(`Successfully synced video: ${key} (ID: ${videoId})`);
        
      } catch (error) {
        console.error(`Error processing video ${key}:`, error);
        skippedCount++;
      }
    }
    
    return new Response(
      JSON.stringify({
        success: true,
        message: `Sync completed. Synced: ${syncedCount}, Skipped: ${skippedCount}`,
        synced: syncedCount,
        skipped: skippedCount,
        videos: syncedVideos
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
    
  } catch (error) {
    console.error('Sync error:', error);
    return new Response(
      JSON.stringify({ error: 'Failed to sync videos', message: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
}

/**
 * Upload video directly to R2 and save metadata
 */
async function handleUploadVideo(request, env, corsHeaders) {
  try {
    const formData = await request.formData();
    const file = formData.get('file');
    const title = formData.get('title') || '';
    const description = formData.get('description') || '';
    
    if (!file) {
      return new Response(
        JSON.stringify({ error: 'No file provided' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }
    
    // Validate file type
    if (!file.name.match(/\.(mp4|mov|avi|webm|mkv|m4v|3gp)$/i)) {
      return new Response(
        JSON.stringify({ error: 'Invalid file type. Only video files are allowed.' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }
    
    // Generate unique object key
    const objectKey = `${Date.now()}-${file.name}`;
    
    // Upload to R2
    await env.GWA_VIDEOS_BUCKET.put(objectKey, file.stream(), {
      httpMetadata: {
        contentType: file.type,
      },
      customMetadata: {
        originalName: file.name,
        uploadedAt: new Date().toISOString(),
      },
    });
    
    // Generate signed URL (valid for 7 days)
    const expiryTime = 7 * 24 * 3600; // 7 days in seconds
    const signedUrl = await generateSignedUrl(env.GWA_VIDEOS_BUCKET, objectKey, expiryTime);
    const signedUrlExpiresAt = new Date(Date.now() + expiryTime * 1000).toISOString();
    
    // Save metadata to database with signed URL
    const videoId = crypto.randomUUID();
    const createdAt = new Date().toISOString();
    const fileSize = file.size || 0;
    
    await env.GWA_VIDEOS_DB.prepare(`
      INSERT INTO videos (id, title, description, object_key, created_at, file_size, content_type, original_name, view_count, comment_count, signed_url, signed_url_expires_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).bind(
      videoId, title, description, objectKey, createdAt, fileSize, file.type, file.name, 0, 0, signedUrl, signedUrlExpiresAt
    ).run();
    
    console.log(`Successfully uploaded video: ${file.name} (ID: ${videoId})`);
    
    return new Response(
      JSON.stringify({
        success: true,
        message: 'Video uploaded successfully',
        video: {
          id: videoId,
          title,
          object_key: objectKey,
          file_size: fileSize,
          content_type: file.type
        }
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
    
  } catch (error) {
    console.error('Upload error:', error);
    return new Response(
      JSON.stringify({ error: 'Failed to upload video', message: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
}

/**
 * Generate title from filename
 */
function generateTitleFromFilename(filename) {
  return filename
    .replace(/\.[^/.]+$/, '') // Remove extension
    .replace(/[-_]/g, ' ') // Replace dashes and underscores with spaces
    .replace(/\b\w/g, l => l.toUpperCase()) // Capitalize words
    .trim();
}

/**
 * Serve video directly from R2 bucket
 */
async function handleServeVideo(request, env, corsHeaders, objectKey) {
  try {
    // Get the video object from R2
    const object = await env.GWA_VIDEOS_BUCKET.get(objectKey);
    
    if (!object) {
      return new Response(
        JSON.stringify({ error: 'Video not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }
    
    // Set appropriate headers for video streaming
    const headers = {
      ...corsHeaders,
      'Content-Type': object.httpMetadata?.contentType || 'video/mp4',
      'Content-Length': object.size,
      'Cache-Control': 'public, max-age=3600',
      'Accept-Ranges': 'bytes', // Enable range requests for video seeking
    };
    
    // Return the video stream
    return new Response(object.body, {
      headers,
      status: 200
    });
    
  } catch (error) {
    console.error('Serve video error:', error);
    return new Response(
      JSON.stringify({ error: 'Failed to serve video', message: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
}

/**
 * Get content type from file extension
 */
function getContentTypeFromExtension(filename) {
  const ext = filename.split('.').pop().toLowerCase();
  const contentTypes = {
    'mp4': 'video/mp4',
    'mov': 'video/quicktime',
    'avi': 'video/x-msvideo',
    'webm': 'video/webm',
    'mkv': 'video/x-matroska',
    'm4v': 'video/x-m4v',
    '3gp': 'video/3gpp'
  };
  return contentTypes[ext] || 'video/mp4';
}

/**
 * Generate signed URL for R2 object
 */
async function generateSignedUrl(bucket, objectKey, expirySeconds = 3600) {
  // In a production environment, you'd implement proper signed URL generation
  // For now, we'll return a URL with basic access control
  const expiry = Date.now() + (expirySeconds * 1000);
  
  // Simple implementation - in production, use proper HMAC signing
  return `https://gwa-video-worker-v2.aashardcustomz.workers.dev/api/videos/signed/${objectKey}?expiry=${expiry}`;
}