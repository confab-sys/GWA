
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, HEAD, POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
};

export default {
  async fetch(request, env, ctx) {
    if (request.method === "OPTIONS") {
      return new Response(null, { headers: corsHeaders });
    }

    const url = new URL(request.url);
    const path = url.pathname;

    try {
      // Initialize DB Tables (Run once or check existence)
      if (path === "/api/wellness/init") {
        await env.WELLNESS_DB.prepare(`
          CREATE TABLE IF NOT EXISTS recovery_tracking (
            user_id TEXT PRIMARY KEY,
            addiction_type TEXT,
            start_date TEXT,
            last_reset_date TEXT,
            streak_days INTEGER DEFAULT 0,
            is_active BOOLEAN DEFAULT 1,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
          )
        `).run();

        await env.WELLNESS_DB.prepare(`
          CREATE TABLE IF NOT EXISTS wellness_resources (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL,
            title TEXT NOT NULL,
            subtitle TEXT,
            url TEXT NOT NULL,
            thumbnail_url TEXT,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
          )
        `).run();

        return new Response("Wellness DB Initialized", { headers: corsHeaders });
      }

      // GET /api/wellness/resources
      // Optional query param: type (video, book, podcast, article)
      if (path === "/api/wellness/resources" && request.method === "GET") {
        const type = url.searchParams.get("type");
        let query = "SELECT * FROM wellness_resources ORDER BY created_at DESC";
        
        if (type) {
          query = "SELECT * FROM wellness_resources WHERE type = ? ORDER BY created_at DESC";
        }
        
        const stmt = env.WELLNESS_DB.prepare(query);
        const { results } = type ? await stmt.bind(type).all() : await stmt.all();

        return new Response(JSON.stringify(results), {
          headers: { ...corsHeaders, "Content-Type": "application/json" }
        });
      }

      // POST /api/wellness/resources
      // Body: { type, title, subtitle, url, thumbnail_url }
      if (path === "/api/wellness/resources" && request.method === "POST") {
        const { type, title, subtitle, url, thumbnail_url } = await request.json();
        
        if (!type || !title || !url) {
          return new Response("Missing required fields", { status: 400, headers: corsHeaders });
        }

        const res = await env.WELLNESS_DB.prepare(`
          INSERT INTO wellness_resources (type, title, subtitle, url, thumbnail_url)
          VALUES (?, ?, ?, ?, ?)
        `).bind(type, title, subtitle, url, thumbnail_url).run();

        return new Response(JSON.stringify({ message: "Resource added", id: res.meta.last_row_id }), {
          headers: { ...corsHeaders, "Content-Type": "application/json" }
        });
      }

      // POST /api/wellness/join
      // Body: { user_id, addiction_type }
      if (path === "/api/wellness/join" && request.method === "POST") {
        const { user_id, addiction_type } = await request.json();
        
        if (!user_id || !addiction_type) {
          return new Response("Missing user_id or addiction_type", { status: 400, headers: corsHeaders });
        }

        const now = new Date().toISOString();
        
        // Upsert recovery record
        await env.WELLNESS_DB.prepare(`
          INSERT INTO recovery_tracking (user_id, addiction_type, start_date, last_reset_date, streak_days, is_active)
          VALUES (?, ?, ?, ?, 0, 1)
          ON CONFLICT(user_id) DO UPDATE SET
            addiction_type = excluded.addiction_type,
            start_date = excluded.start_date,
            last_reset_date = excluded.last_reset_date,
            streak_days = 0,
            is_active = 1
        `).bind(user_id, addiction_type, now, now).run();

        return new Response(JSON.stringify({ message: "Joined wellness program", start_date: now }), { 
          headers: { ...corsHeaders, "Content-Type": "application/json" } 
        });
      }

      // POST /api/wellness/reset
      // Body: { user_id }
      if (path === "/api/wellness/reset" && request.method === "POST") {
        const { user_id } = await request.json();
        const now = new Date().toISOString();

        await env.WELLNESS_DB.prepare(`
          UPDATE recovery_tracking 
          SET start_date = ?, last_reset_date = ?, streak_days = 0 
          WHERE user_id = ?
        `).bind(now, now, user_id).run();

        return new Response(JSON.stringify({ message: "Timer reset", start_date: now }), {
          headers: { ...corsHeaders, "Content-Type": "application/json" }
        });
      }

      // GET /api/wellness/status?user_id=...
      if (path === "/api/wellness/status" && request.method === "GET") {
        const userId = url.searchParams.get("user_id");
        if (!userId) return new Response("Missing user_id", { status: 400, headers: corsHeaders });

        const status = await env.WELLNESS_DB.prepare("SELECT * FROM recovery_tracking WHERE user_id = ?").bind(userId).first();
        
        if (!status) {
           return new Response(JSON.stringify({ is_active: false }), { 
             headers: { ...corsHeaders, "Content-Type": "application/json" } 
           });
        }

        return new Response(JSON.stringify(status), { 
          headers: { ...corsHeaders, "Content-Type": "application/json" } 
        });
      }

      // GET /api/wellness/community
      // Returns list of users in wellness program with their names from USERS_DB
      if (path === "/api/wellness/community" && request.method === "GET") {
        // 1. Get all active wellness participants
        const { results: wellnessUsers } = await env.WELLNESS_DB.prepare(
          "SELECT user_id, addiction_type, start_date FROM recovery_tracking WHERE is_active = 1 ORDER BY start_date DESC LIMIT 50"
        ).all();

        if (!wellnessUsers || wellnessUsers.length === 0) {
          return new Response(JSON.stringify([]), { headers: { ...corsHeaders, "Content-Type": "application/json" } });
        }

        // 2. Get details for these users from USERS_DB
        // D1 doesn't support cross-DB joins, so we query manually or use IN clause if list is small
        // For 50 users, we can loop or do a bulk query. Bulk query with IN is better.
        
        const userIds = wellnessUsers.map(u => u.user_id);
        const placeholders = userIds.map(() => '?').join(',');
        
        const { results: userDetails } = await env.USERS_DB.prepare(
          `SELECT id, username, first_name FROM users WHERE id IN (${placeholders})`
        ).bind(...userIds).all();

        // 3. Merge data
        const community = wellnessUsers.map(w => {
          const user = userDetails.find(u => u.id === w.user_id);
          return {
            user_id: w.user_id,
            name: user ? (user.username || user.first_name) : 'Anonymous',
            addiction_type: w.addiction_type,
            start_date: w.start_date
          };
        });

        return new Response(JSON.stringify(community), { 
          headers: { ...corsHeaders, "Content-Type": "application/json" } 
        });
      }

      return new Response("Not Found", { status: 404, headers: corsHeaders });

    } catch (e) {
      return new Response(JSON.stringify({ error: e.message }), { status: 500, headers: corsHeaders });
    }
  }
};
