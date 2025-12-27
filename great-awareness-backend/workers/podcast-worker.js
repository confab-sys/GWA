/**
 * GWA Podcast Worker
 * Handles podcast storage in R2 and metadata in D1
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
      if (pathname === '/api/podcasts' && method === 'GET') {
        return await handleListPodcasts(request, env, CORS_HEADERS);
      } else if (pathname === '/api/podcasts/sync' && method === 'POST') {
        return await handleSyncPodcasts(request, env, CORS_HEADERS);
      } else if (pathname === '/api/podcasts/upload' && method === 'POST') {
        return await handleUploadPodcast(request, env, CORS_HEADERS);
      } else if (pathname.startsWith('/api/podcasts/') && pathname.endsWith('/signed-url') && method === 'GET') {
        const pathParts = pathname.split('/');
        const podcastId = pathParts[3]; // /api/podcasts/{id}/signed-url
        return await handleGetSignedUrl(request, env, CORS_HEADERS, podcastId);
      } else if (pathname.startsWith('/api/podcasts/signed/') && method === 'GET') {
        // Handle direct podcast serving from signed URLs
        const pathParts = pathname.split('/');
        const objectKey = pathParts.slice(4).join('/'); // /api/podcasts/signed/{objectKey}
        return await handleServePodcast(request, env, CORS_HEADERS, objectKey);
      } else if (pathname.startsWith('/api/podcasts/') && method === 'GET') {
        const pathParts = pathname.split('/');
        const podcastId = pathParts[3]; // /api/podcasts/{id}
        return await handleGetPodcast(request, env, CORS_HEADERS, podcastId);
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
      service: 'GWA Podcast Worker',
      timestamp: new Date().toISOString()
    }),
    { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
  );
}

/**
 * List all podcasts with pagination
 */
async function handleListPodcasts(request, env, corsHeaders) {
  const url = new URL(request.url);
  const page = parseInt(url.searchParams.get('page') || '1');
  const limit = parseInt(url.searchParams.get('limit') || '50');
  const offset = (page - 1) * limit;
  const category = url.searchParams.get('category');
  
  try {
    // Build query
    let query = 'SELECT * FROM podcasts';
    let countQuery = 'SELECT COUNT(*) as total FROM podcasts';
    const params = [];
    
    if (category && category !== 'All') {
      query += ' WHERE category = ?';
      countQuery += ' WHERE category = ?';
      params.push(category);
    }
    
    query += ' ORDER BY created_at DESC LIMIT ? OFFSET ?';
    
    // Get total count
    const countResult = await env.GWA_PODCASTS_DB.prepare(countQuery).bind(...params).first();
    
    // Get podcasts with pagination
    const podcastsResult = await env.GWA_PODCASTS_DB.prepare(query)
      .bind(...params, limit, offset)
      .all();
    
    return new Response(
      JSON.stringify({
        success: true,
        podcasts: podcastsResult.results || [],
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
    console.error('List podcasts error:', error);
    return new Response(
      JSON.stringify({ error: 'Failed to list podcasts', message: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
}

/**
 * Get single podcast by ID
 */
async function handleGetPodcast(request, env, corsHeaders, podcastId) {
  try {
    const podcast = await env.GWA_PODCASTS_DB.prepare(`
      SELECT * FROM podcasts WHERE id = ?
    `).bind(podcastId).first();
    
    if (!podcast) {
      return new Response(
        JSON.stringify({ error: 'Podcast not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }
    
    return new Response(
      JSON.stringify({ success: true, podcast }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Get podcast error:', error);
    return new Response(
      JSON.stringify({ error: 'Failed to get podcast', message: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
}

/**
 * Generate signed URL for podcast access
 */
async function handleGetSignedUrl(request, env, corsHeaders, podcastId) {
  try {
    // Get podcast from database
    const podcast = await env.GWA_PODCASTS_DB.prepare(`
      SELECT object_key FROM podcasts WHERE id = ?
    `).bind(podcastId).first();
    
    if (!podcast || !podcast.object_key) {
      return new Response(
        JSON.stringify({ error: 'Podcast not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }
    
    // Generate signed URL (valid for 1 year)
    const expiryTime = 365 * 24 * 3600; 
    const signedUrl = await generateSignedUrl(env.GWA_PODCASTS_BUCKET, podcast.object_key, expiryTime);
    
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
 * Sync podcasts from R2 bucket to database
 */
async function handleSyncPodcasts(request, env, corsHeaders) {
  try {
    console.log('Starting podcast sync from R2 bucket...');
    
    // List all objects in R2 bucket
    const objects = await env.GWA_PODCASTS_BUCKET.list();
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
    const syncedPodcasts = [];
    
    // Process each object
    for (const object of objects.objects) {
      const key = object.key;
      
      // Skip thumbnails folder and non-audio files
      if (key.startsWith('thumbnails/') || !key.match(/\.(mp3|wav|m4a|aac|ogg)$/i)) {
        console.log(`Skipping non-podcast file: ${key}`);
        skippedCount++;
        continue;
      }
      
      try {
        // Check if podcast already exists in database
        const existingPodcast = await env.GWA_PODCASTS_DB.prepare(
          'SELECT id FROM podcasts WHERE object_key = ?'
        ).bind(key).first();
        
        if (existingPodcast) {
          console.log(`Podcast already exists in database: ${key}`);
          skippedCount++;
          continue;
        }
        
        // Generate podcast metadata
        const podcastId = crypto.randomUUID();
        const title = generateTitleFromFilename(key);
        const category = 'Uncategorized';
        const fileSize = parseInt(object.size || 0);
        const contentType = getContentTypeFromExtension(key);
        const description = `Podcast episode: ${title}`;
        const createdAt = new Date(object.uploaded || Date.now()).toISOString();
        
        console.log(`Processing podcast: ${key}, size: ${fileSize}, type: ${contentType}`);
        
        // Generate signed URL (valid for 1 year)
        const expiryTime = 365 * 24 * 3600;
        const signedUrl = await generateSignedUrl(env.GWA_PODCASTS_BUCKET, key, expiryTime);
        const signedUrlExpiresAt = new Date(Date.now() + expiryTime * 1000).toISOString();
        
        // Insert podcast into database
        await env.GWA_PODCASTS_DB.prepare(`
          INSERT INTO podcasts (id, title, description, category, object_key, created_at, file_size, content_type, original_name, signed_url, signed_url_expires_at)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        `).bind(
          podcastId, title, description, category, key, createdAt, fileSize, contentType, key, signedUrl, signedUrlExpiresAt
        ).run();
        
        syncedPodcasts.push({ id: podcastId, title, category, object_key: key });
        syncedCount++;
        console.log(`Successfully synced podcast: ${key} (ID: ${podcastId})`);
        
      } catch (error) {
        console.error(`Error processing podcast ${key}:`, error);
        skippedCount++;
      }
    }
    
    return new Response(
      JSON.stringify({
        success: true,
        message: `Sync completed. Synced: ${syncedCount}, Skipped: ${skippedCount}`,
        synced: syncedCount,
        skipped: skippedCount,
        podcasts: syncedPodcasts
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
    
  } catch (error) {
    console.error('Sync error:', error);
    return new Response(
      JSON.stringify({ error: 'Failed to sync podcasts', message: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
}

/**
 * Upload podcast directly to R2 and save metadata
 */
async function handleUploadPodcast(request, env, corsHeaders) {
  try {
    const formData = await request.formData();
    const file = formData.get('file');
    const title = formData.get('title') || '';
    const subtitle = formData.get('subtitle') || '';
    const description = formData.get('description') || '';
    const category = formData.get('category') || 'Uncategorized';
    const duration = formData.get('duration') || '';
    
    if (!file) {
      return new Response(
        JSON.stringify({ error: 'No file provided' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }
    
    // Validate file type
    if (!file.name.match(/\.(mp3|wav|m4a|aac|ogg)$/i)) {
      return new Response(
        JSON.stringify({ error: 'Invalid file type. Only audio files are allowed.' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }
    
    // Generate unique object key
    const objectKey = `${Date.now()}-${file.name}`;
    
    // Upload to R2
    await env.GWA_PODCASTS_BUCKET.put(objectKey, file.stream(), {
      httpMetadata: {
        contentType: file.type,
      },
      customMetadata: {
        originalName: file.name,
        uploadedAt: new Date().toISOString(),
      },
    });
    
    // Handle thumbnail upload if present
    const thumbnail = formData.get('thumbnail');
    let thumbnailKey = null;
    let thumbnailUrl = null;
    
    if (thumbnail) {
      thumbnailKey = `thumbnails/${Date.now()}-${thumbnail.name}`;
      await env.GWA_PODCASTS_BUCKET.put(thumbnailKey, thumbnail.stream(), {
        httpMetadata: {
          contentType: thumbnail.type,
        },
      });
      
      const thumbExpiryTime = 365 * 24 * 3600; 
      thumbnailUrl = await generateSignedUrl(env.GWA_PODCASTS_BUCKET, thumbnailKey, thumbExpiryTime);
    }

    // Generate signed URL (valid for 1 year)
    const expiryTime = 365 * 24 * 3600;
    const signedUrl = await generateSignedUrl(env.GWA_PODCASTS_BUCKET, objectKey, expiryTime);
    const signedUrlExpiresAt = new Date(Date.now() + expiryTime * 1000).toISOString();
    
    // Save metadata to database
    const podcastId = crypto.randomUUID();
    const createdAt = new Date().toISOString();
    const fileSize = file.size || 0;
    
    await env.GWA_PODCASTS_DB.prepare(`
      INSERT INTO podcasts (id, title, subtitle, description, category, object_key, created_at, file_size, content_type, original_name, duration, thumbnail_url, signed_url, signed_url_expires_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).bind(
      podcastId, title, subtitle, description, category, objectKey, createdAt, fileSize, file.type, file.name, duration, thumbnailUrl, signedUrl, signedUrlExpiresAt
    ).run();
    
    return new Response(
      JSON.stringify({
        success: true,
        message: 'Podcast uploaded successfully',
        podcast: {
          id: podcastId,
          title,
          category,
          thumbnail_url: thumbnailUrl,
          signed_url: signedUrl
        }
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
    
  } catch (error) {
    console.error('Upload error:', error);
    return new Response(
      JSON.stringify({ error: 'Failed to upload podcast', message: error.message }),
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
 * Serve podcast directly from R2 bucket
 */
async function handleServePodcast(request, env, corsHeaders, objectKey) {
  try {
    // Get the podcast object from R2
    const object = await env.GWA_PODCASTS_BUCKET.get(objectKey);
    
    if (!object) {
      return new Response(
        JSON.stringify({ error: 'Podcast not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }
    
    // Set appropriate headers for audio streaming
    const headers = {
      ...corsHeaders,
      'Content-Type': object.httpMetadata?.contentType || 'audio/mpeg',
      'Content-Length': object.size,
      'Cache-Control': 'public, max-age=3600',
      'Accept-Ranges': 'bytes',
    };
    
    // Return the audio stream
    return new Response(object.body, {
      headers,
      status: 200
    });
    
  } catch (error) {
    console.error('Serve podcast error:', error);
    return new Response(
      JSON.stringify({ error: 'Failed to serve podcast', message: error.message }),
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
    'mp3': 'audio/mpeg',
    'wav': 'audio/wav',
    'm4a': 'audio/mp4',
    'aac': 'audio/aac',
    'ogg': 'audio/ogg'
  };
  return contentTypes[ext] || 'audio/mpeg';
}

/**
 * Generate signed URL for R2 object
 */
async function generateSignedUrl(bucket, objectKey, expirySeconds = 3600) {
  const expiry = Date.now() + (expirySeconds * 1000);
  // NOTE: This URL format needs to match your worker's domain
  // Since we are deploying a new worker, we need to know its name
  // Assuming 'gwa-podcast-worker' for now, will update if different
  return `https://gwa-podcast-worker.aashardcustomz.workers.dev/api/podcasts/signed/${objectKey}?expiry=${expiry}`;
}
