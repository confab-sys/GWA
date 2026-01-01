
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

        // Initialize Milestone DB Tables
        await env.MILESTONE_DB.prepare(`
          CREATE TABLE IF NOT EXISTS milestones (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            label TEXT NOT NULL,
            duration_seconds INTEGER UNIQUE NOT NULL,
            icon_code INTEGER NOT NULL,
            color_hex TEXT NOT NULL,
            description TEXT NOT NULL,
            badge_image_url TEXT,
            is_active BOOLEAN DEFAULT 1,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
          )
        `).run();

        await env.MILESTONE_DB.prepare(`
          CREATE TABLE IF NOT EXISTS user_milestones (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT NOT NULL,
            milestone_id INTEGER NOT NULL,
            unlocked_at TEXT DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (milestone_id) REFERENCES milestones(id)
          )
        `).run();

        // Initialize Events DB Tables
        await env.EVENTS_DB.prepare(`
          CREATE TABLE IF NOT EXISTS events (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT NOT NULL,
            image_url TEXT,
            location TEXT,
            event_date TEXT NOT NULL,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            created_by TEXT NOT NULL
          )
        `).run();

        await env.EVENTS_DB.prepare(`
          CREATE TABLE IF NOT EXISTS event_participants (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            event_id INTEGER NOT NULL,
            user_id TEXT NOT NULL,
            joined_at TEXT DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (event_id) REFERENCES events(id),
            UNIQUE(event_id, user_id)
          )
        `).run();

        return new Response("Wellness, Milestone & Events DB Initialized", { headers: corsHeaders });
      }

      // --- EVENTS ENDPOINTS ---

      // GET /api/wellness/events
      // Query param: user_id (optional, to check 'is_joined')
      if (path === "/api/wellness/events" && request.method === "GET") {
        const userId = url.searchParams.get("user_id");
        
        // Get all upcoming events (or all events sorted by date)
        const { results: events } = await env.EVENTS_DB.prepare(
          "SELECT * FROM events ORDER BY event_date ASC"
        ).all();

        if (!userId) {
          return new Response(JSON.stringify(events), { 
            headers: { ...corsHeaders, "Content-Type": "application/json" } 
          });
        }

        // Check which events the user has joined
        const { results: joined } = await env.EVENTS_DB.prepare(
          "SELECT event_id FROM event_participants WHERE user_id = ?"
        ).bind(userId).all();
        
        const joinedIds = new Set(joined.map(j => j.event_id));

        // Get participant counts for each event
        // This is a simplified approach; for high scale, store count in events table
        const eventsWithStatus = await Promise.all(events.map(async (e) => {
          const countResult = await env.EVENTS_DB.prepare(
            "SELECT count(*) as count FROM event_participants WHERE event_id = ?"
          ).bind(e.id).first();
          
          return {
            ...e,
            is_joined: joinedIds.has(e.id),
            participant_count: countResult.count
          };
        }));

        return new Response(JSON.stringify(eventsWithStatus), { 
          headers: { ...corsHeaders, "Content-Type": "application/json" } 
        });
      }

      // POST /api/wellness/events
      // Create new event (Admin only - ideally check role, but simplified here)
      // Body: { title, description, image_url, location, event_date, created_by }
      if (path === "/api/wellness/events" && request.method === "POST") {
        const { title, description, image_url, location, event_date, created_by } = await request.json();
        
        if (!title || !event_date || !created_by) {
          return new Response("Missing required fields", { status: 400, headers: corsHeaders });
        }

        const res = await env.EVENTS_DB.prepare(`
          INSERT INTO events (title, description, image_url, location, event_date, created_by)
          VALUES (?, ?, ?, ?, ?, ?)
        `).bind(title, description, image_url, location, event_date, created_by).run();

        return new Response(JSON.stringify({ message: "Event created", id: res.meta.last_row_id }), { 
          headers: { ...corsHeaders, "Content-Type": "application/json" } 
        });
      }

      // POST /api/wellness/events/join
      // Body: { user_id, event_id }
      if (path === "/api/wellness/events/join" && request.method === "POST") {
        const { user_id, event_id } = await request.json();
        
        if (!user_id || !event_id) {
          return new Response("Missing required fields", { status: 400, headers: corsHeaders });
        }

        try {
          await env.EVENTS_DB.prepare(`
            INSERT INTO event_participants (event_id, user_id) VALUES (?, ?)
          `).bind(event_id, user_id).run();
          
          return new Response(JSON.stringify({ message: "Joined event" }), { 
            headers: { ...corsHeaders, "Content-Type": "application/json" } 
          });
        } catch (e) {
          if (e.message.includes("UNIQUE")) {
             return new Response(JSON.stringify({ message: "Already joined" }), { 
              headers: { ...corsHeaders, "Content-Type": "application/json" } 
            });
          }
          throw e;
        }
      }

      // POST /api/wellness/events/leave
      // Body: { user_id, event_id }
      if (path === "/api/wellness/events/leave" && request.method === "POST") {
        const { user_id, event_id } = await request.json();
        
        await env.EVENTS_DB.prepare(`
          DELETE FROM event_participants WHERE event_id = ? AND user_id = ?
        `).bind(event_id, user_id).run();
        
        return new Response(JSON.stringify({ message: "Left event" }), { 
          headers: { ...corsHeaders, "Content-Type": "application/json" } 
        });
      }

      // POST /api/wellness/milestones/seed
      // Populates default milestones
      if (path === "/api/wellness/milestones/seed" && request.method === "POST") {
        const defaults = [
          { label: "24 Hours", duration_seconds: 86400, icon_code: 61943, color_hex: "#4CAF50", description: "First 24 hours complete!", badge_image_url: "https://pub-1c8c879e41fe4ff48de96ceabce671a2.r2.dev/badges/24h.png" },
          { label: "7 Days", duration_seconds: 604800, icon_code: 61769, color_hex: "#8BC34A", description: "One week down.", badge_image_url: "https://pub-1c8c879e41fe4ff48de96ceabce671a2.r2.dev/badges/7d.png" },
          { label: "14 Days", duration_seconds: 1209600, icon_code: 61769, color_hex: "#CDDC39", description: "Two weeks strong.", badge_image_url: "https://pub-1c8c879e41fe4ff48de96ceabce671a2.r2.dev/badges/14d.png" },
          { label: "21 Days", duration_seconds: 1814400, icon_code: 61769, color_hex: "#FFEB3B", description: "Three weeks. Habit forming.", badge_image_url: "https://pub-1c8c879e41fe4ff48de96ceabce671a2.r2.dev/badges/21d.png" },
          { label: "30 Days", duration_seconds: 2592000, icon_code: 61943, color_hex: "#FFC107", description: "One month milestone.", badge_image_url: "https://pub-1c8c879e41fe4ff48de96ceabce671a2.r2.dev/badges/30d.png" },
          { label: "60 Days", duration_seconds: 5184000, icon_code: 61943, color_hex: "#FF9800", description: "Two months of progress.", badge_image_url: "https://pub-1c8c879e41fe4ff48de96ceabce671a2.r2.dev/badges/60d.png" },
          { label: "90 Days", duration_seconds: 7776000, icon_code: 61943, color_hex: "#FF5722", description: "Three months! Quarter year.", badge_image_url: "https://pub-1c8c879e41fe4ff48de96ceabce671a2.r2.dev/badges/90d.png" },
          { label: "180 Days", duration_seconds: 15552000, icon_code: 61943, color_hex: "#F44336", description: "180 days achieved.", badge_image_url: "https://pub-1c8c879e41fe4ff48de96ceabce671a2.r2.dev/badges/180d.png" },
          { label: "6 Months", duration_seconds: 15811200, icon_code: 61943, color_hex: "#E91E63", description: "Half a year of dedication.", badge_image_url: "https://pub-1c8c879e41fe4ff48de96ceabce671a2.r2.dev/badges/6m.png" },
          { label: "9 Months", duration_seconds: 23673600, icon_code: 61943, color_hex: "#9C27B0", description: "Nine months strong.", badge_image_url: "https://pub-1c8c879e41fe4ff48de96ceabce671a2.r2.dev/badges/9m.png" },
          { label: "1 Year", duration_seconds: 31536000, icon_code: 61943, color_hex: "#673AB7", description: "One full year. Incredible.", badge_image_url: "https://pub-1c8c879e41fe4ff48de96ceabce671a2.r2.dev/badges/1y.png" },
          { label: "1.5 Years", duration_seconds: 47304000, icon_code: 61943, color_hex: "#3F51B5", description: "18 months of freedom.", badge_image_url: "https://pub-1c8c879e41fe4ff48de96ceabce671a2.r2.dev/badges/1.5y.png" },
          { label: "2 Years", duration_seconds: 63072000, icon_code: 61943, color_hex: "#2196F3", description: "Two years.", badge_image_url: "https://pub-1c8c879e41fe4ff48de96ceabce671a2.r2.dev/badges/2y.png" },
          { label: "3 Years", duration_seconds: 94608000, icon_code: 61943, color_hex: "#03A9F4", description: "Three years.", badge_image_url: "https://pub-1c8c879e41fe4ff48de96ceabce671a2.r2.dev/badges/3y.png" },
          { label: "5 Years", duration_seconds: 157680000, icon_code: 61943, color_hex: "#00BCD4", description: "Five years.", badge_image_url: "https://pub-1c8c879e41fe4ff48de96ceabce671a2.r2.dev/badges/5y.png" },
          { label: "10 Years+", duration_seconds: 315360000, icon_code: 61943, color_hex: "#009688", description: "A decade of wellness.", badge_image_url: "https://pub-1c8c879e41fe4ff48de96ceabce671a2.r2.dev/badges/10y.png" }
        ];

        let added = 0;
        for (const m of defaults) {
          // Upsert logic to ensure labels match user request
          await env.MILESTONE_DB.prepare(`
            INSERT INTO milestones (label, duration_seconds, icon_code, color_hex, description, badge_image_url)
            VALUES (?, ?, ?, ?, ?, ?)
            ON CONFLICT(duration_seconds) DO UPDATE SET
              label = excluded.label,
              icon_code = excluded.icon_code,
              color_hex = excluded.color_hex,
              description = excluded.description,
              badge_image_url = excluded.badge_image_url
          `).bind(m.label, m.duration_seconds, m.icon_code, m.color_hex, m.description, m.badge_image_url).run();
          added++;
        }
        
        return new Response(JSON.stringify({ message: `Seeded/Updated ${added} milestones` }), { 
          headers: { ...corsHeaders, "Content-Type": "application/json" } 
        });
      }

      // GET /api/wellness/milestones
      // Query param: user_id
      // Automatically checks and unlocks milestones based on current streak
      if (path === "/api/wellness/milestones" && request.method === "GET") {
        const userId = url.searchParams.get("user_id");
        if (!userId) return new Response("Missing user_id", { status: 400, headers: corsHeaders });

        // 1. Get user's current streak/status from WELLNESS_DB
        const status = await env.WELLNESS_DB.prepare(
          "SELECT start_date, is_active FROM recovery_tracking WHERE user_id = ?"
        ).bind(userId).first();

        let currentStreakSeconds = 0;
        if (status && status.is_active) {
          const startTime = new Date(status.start_date).getTime();
          const now = new Date().getTime();
          currentStreakSeconds = Math.floor((now - startTime) / 1000);
        }

        // 2. Get all active milestones
        const { results: milestones } = await env.MILESTONE_DB.prepare(
          "SELECT * FROM milestones WHERE is_active = 1 ORDER BY duration_seconds ASC"
        ).all();

        // 3. Get currently unlocked milestones
        const { results: unlocked } = await env.MILESTONE_DB.prepare(
          "SELECT milestone_id FROM user_milestones WHERE user_id = ?"
        ).bind(userId).all();
        
        const unlockedIds = new Set(unlocked.map(u => u.milestone_id));
        const newUnlocks = [];

        // 4. Check for new unlocks
        for (const m of milestones) {
          if (!unlockedIds.has(m.id) && currentStreakSeconds >= m.duration_seconds) {
            // New milestone achieved!
            await env.MILESTONE_DB.prepare(`
              INSERT INTO user_milestones (user_id, milestone_id) VALUES (?, ?)
            `).bind(userId, m.id).run();
            
            unlockedIds.add(m.id);
            newUnlocks.push(m.label);
          }
        }

        // 5. Return response
        const response = milestones.map(m => ({
          ...m,
          is_unlocked: unlockedIds.has(m.id)
        }));

        return new Response(JSON.stringify({ 
          milestones: response,
          new_unlocks: newUnlocks 
        }), { 
          headers: { ...corsHeaders, "Content-Type": "application/json" } 
        });
      }

      // POST /api/wellness/milestones/unlock
      // Body: { user_id, milestone_id }
      if (path === "/api/wellness/milestones/unlock" && request.method === "POST") {
        const { user_id, milestone_id } = await request.json();
        
        if (!user_id || !milestone_id) {
          return new Response("Missing required fields", { status: 400, headers: corsHeaders });
        }

        // Check if already unlocked
        const existing = await env.MILESTONE_DB.prepare(
          "SELECT id FROM user_milestones WHERE user_id = ? AND milestone_id = ?"
        ).bind(user_id, milestone_id).first();

        if (existing) {
          return new Response(JSON.stringify({ message: "Already unlocked" }), { 
            headers: { ...corsHeaders, "Content-Type": "application/json" } 
          });
        }

        // Unlock
        await env.MILESTONE_DB.prepare(`
          INSERT INTO user_milestones (user_id, milestone_id) VALUES (?, ?)
        `).bind(user_id, milestone_id).run();

        return new Response(JSON.stringify({ message: "Milestone unlocked" }), { 
          headers: { ...corsHeaders, "Content-Type": "application/json" } 
        });
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

      // POST /api/wellness/admin/set-start-date
      // Body: { user_id, start_date }
      if (path === "/api/wellness/admin/set-start-date" && request.method === "POST") {
        const { user_id, start_date } = await request.json();
        
        if (!user_id || !start_date) {
          return new Response("Missing user_id or start_date", { status: 400, headers: corsHeaders });
        }

        // Validate date format
        if (isNaN(Date.parse(start_date))) {
             return new Response("Invalid date format", { status: 400, headers: corsHeaders });
        }

        // Update or Insert
        const startDateObj = new Date(start_date);
        const nowObj = new Date();
        const diffTime = Math.abs(nowObj - startDateObj);
        const streakDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24)); 

        const res = await env.WELLNESS_DB.prepare(`
          UPDATE recovery_tracking 
          SET start_date = ?, is_active = 1, streak_days = ?
          WHERE user_id = ?
        `).bind(start_date, streakDays, user_id).run();

        if (res.meta.changes === 0) {
             // User doesn't exist in wellness DB yet. Insert with default addiction type.
             await env.WELLNESS_DB.prepare(`
                INSERT INTO recovery_tracking (user_id, addiction_type, start_date, is_active, streak_days)
                VALUES (?, 'General', ?, 1, ?)
             `).bind(user_id, start_date, streakDays).run();
        }
        
        return new Response(JSON.stringify({ message: `Start date updated for user ${user_id}` }), { 
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
      // Returns list of users in wellness program with their names from USERS_DB and latest milestone
      if (path === "/api/wellness/community" && request.method === "GET") {
        // 1. Get all active wellness participants
        const { results: wellnessUsers } = await env.WELLNESS_DB.prepare(
          "SELECT user_id, addiction_type, start_date FROM recovery_tracking WHERE is_active = 1 ORDER BY start_date DESC LIMIT 50"
        ).all();

        if (!wellnessUsers || wellnessUsers.length === 0) {
          return new Response(JSON.stringify([]), { headers: { ...corsHeaders, "Content-Type": "application/json" } });
        }

        // 2. Get details for these users from USERS_DB
        const userIds = wellnessUsers.map(u => u.user_id);
        const placeholders = userIds.map(() => '?').join(',');
        
        const { results: userDetails } = await env.USERS_DB.prepare(
          `SELECT id, username, first_name FROM users WHERE id IN (${placeholders})`
        ).bind(...userIds).all();

        // 3. Get latest milestone for these users from MILESTONE_DB
        // We want the milestone with the highest duration_seconds that is unlocked
        // Using a join to get milestone details
        const { results: userMilestones } = await env.MILESTONE_DB.prepare(`
          SELECT um.user_id, m.label, m.icon_code, m.color_hex, m.badge_image_url
          FROM user_milestones um
          JOIN milestones m ON um.milestone_id = m.id
          WHERE um.user_id IN (${placeholders})
          ORDER BY m.duration_seconds DESC
        `).bind(...userIds).all();

        // 4. Merge data
        const community = wellnessUsers.map(w => {
          // Convert IDs to strings for reliable comparison
          const userIdStr = String(w.user_id);
          const user = userDetails.find(u => String(u.id) === userIdStr);
          const latestMilestone = userMilestones.find(m => String(m.user_id) === userIdStr);
          
          return {
            user_id: w.user_id,
            name: user ? (user.username || user.first_name) : 'Anonymous',
            addiction_type: w.addiction_type,
            start_date: w.start_date,
            latest_milestone: latestMilestone ? {
              label: latestMilestone.label,
              icon_code: latestMilestone.icon_code,
              color_hex: latestMilestone.color_hex,
              badge_image_url: latestMilestone.badge_image_url
            } : null
          };
        });

        return new Response(JSON.stringify(community), { 
          headers: { ...corsHeaders, "Content-Type": "application/json" } 
        });
      }

      // GET /api/wellness/images/:key
      // Serve images from R2
      const imageMatch = path.match(/^\/api\/wellness\/images\/(.+)$/);
      if (imageMatch && (request.method === "GET" || request.method === "HEAD")) {
        const key = imageMatch[1];
        console.log(`Attempting to fetch image with key: ${key}`);
        
        try {
          const object = await env.GWA_CONTENT_BUCKET.get(key);
          console.log(`Object found: ${object ? 'yes' : 'no'}`);

          if (!object) {
            console.log(`Image not found in bucket for key: ${key}`);
            return new Response("Image not found", { status: 404, headers: corsHeaders });
          }

          const headers = new Headers();
          object.writeHttpMetadata(headers);
          headers.set("etag", object.httpEtag);
          
          // Add CORS headers
          Object.keys(corsHeaders).forEach(k => headers.set(k, corsHeaders[k]));

          if (request.method === "HEAD") {
             return new Response(null, { headers });
          }

          return new Response(object.body, { headers });
        } catch (err) {
          console.error(`Error fetching image: ${err.message}`);
          return new Response(JSON.stringify({ error: err.message }), { status: 500, headers: corsHeaders });
        }
      }

      return new Response("Not Found", { status: 404, headers: corsHeaders });

    } catch (e) {
      return new Response(JSON.stringify({ error: e.message }), { status: 500, headers: corsHeaders });
    }
  }
};
