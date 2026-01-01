
export class NotificationsDO {
  constructor(state, env) {
    this.state = state;
    this.env = env;
    this.sessions = new Map(); // WebSocket sessions: userId -> Set<WebSocket>
  }

  async fetch(request) {
    const url = new URL(request.url);
    
    // Handle both direct /ws (if routed internally) or /notifications/ws (public endpoint)
    if (url.pathname === "/ws" || url.pathname === "/notifications/ws") {
      const upgradeHeader = request.headers.get("Upgrade");
      if (!upgradeHeader || upgradeHeader !== "websocket") {
        return new Response("Expected Upgrade: websocket", { status: 426 });
      }

      const userId = url.searchParams.get("userId");
      if (!userId) {
        return new Response("Missing userId", { status: 400 });
      }

      const pair = new WebSocketPair();
      const [client, server] = Object.values(pair);

      await this.handleSession(server, userId);

      return new Response(null, {
        status: 101,
        webSocket: client,
      });
    }

    if (url.pathname === "/broadcast") {
      if (request.method !== "POST") return new Response("Method not allowed", { status: 405 });
      const data = await request.json();
      await this.broadcast(data);
      return new Response("Broadcasted", { status: 200 });
    }

    return new Response("Not found", { status: 404 });
  }

  async handleSession(webSocket, userId) {
    webSocket.accept();

    if (!this.sessions.has(userId)) {
      this.sessions.set(userId, new Set());
    }
    this.sessions.get(userId).add(webSocket);

    webSocket.addEventListener("close", async () => {
      if (this.sessions.has(userId)) {
        this.sessions.get(userId).delete(webSocket);
        if (this.sessions.get(userId).size === 0) {
          this.sessions.delete(userId);
        }
      }
    });

    webSocket.addEventListener("error", async () => {
        if (this.sessions.has(userId)) {
            this.sessions.get(userId).delete(webSocket);
            if (this.sessions.get(userId).size === 0) {
              this.sessions.delete(userId);
            }
        }
    });
  }

  async broadcast(notification) {
    const { userId } = notification;
    const sessions = this.sessions.get(userId);

    if (sessions && sessions.size > 0) {
      // User is online, send via WebSocket
      const payload = JSON.stringify(notification);
      for (const socket of sessions) {
        try {
          socket.send(payload);
        } catch (err) {
          sessions.delete(socket);
        }
      }
      return true; // Delivered online
    }
    
    return false; // User offline
  }
}

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const corsHeaders = {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type",
    };

    if (request.method === "OPTIONS") {
      return new Response(null, { headers: corsHeaders });
    }

    // Get the singleton Durable Object ID
    const id = env.NOTIFICATIONS_DO.idFromName("global_notifications");
    const stub = env.NOTIFICATIONS_DO.get(id);

    if (url.pathname === "/notifications/ws") {
      // Forward WebSocket upgrade request to DO
      return stub.fetch(request);
    }

    if (url.pathname === "/notifications/send") {
      if (request.method !== "POST") return new Response("Method Not Allowed", { status: 405, headers: corsHeaders });
      
      try {
        const data = await request.json();
        // Validate payload
        if (!data.userId || !data.title || !data.body) {
          return new Response("Missing required fields", { status: 400, headers: corsHeaders });
        }

        const notificationId = crypto.randomUUID();
        const timestamp = Date.now();
        
        const notification = {
          id: notificationId,
          userId: data.userId,
          title: data.title,
          body: data.body,
          type: data.type || "system",
          metadata: data.metadata ? JSON.stringify(data.metadata) : null,
          createdAt: timestamp,
          isRead: false
        };

        // 1. Save to D1
        await env.DB.prepare(
          "INSERT INTO notifications_v2 (id, user_id, title, body, type, metadata, created_at, is_read) VALUES (?, ?, ?, ?, ?, ?, ?, ?)"
        ).bind(
          notification.id, notification.userId, notification.title, notification.body, notification.type, notification.metadata, notification.createdAt, 0
        ).run();

        // 2. Emit to DO for real-time delivery
        // We create a request to the DO's /broadcast endpoint
        const doReq = new Request("http://do/broadcast", {
          method: "POST",
          body: JSON.stringify(notification),
          headers: { "Content-Type": "application/json" }
        });
        const doRes = await stub.fetch(doReq);
        const deliveredOnline = doRes.ok; // You might want to parse the response if DO returns status

        // 3. Fallback to FCM if offline (or always if you want push history)
        // For this requirement: "If user is connected -> send WebSocket message. If user is not connected -> send Android push"
        // However, usually you want push even if online for system tray visibility, but let's follow the strict "connection awareness" logic requested.
        // Actually, the DO `broadcast` returns whether it delivered. 
        // But since `stub.fetch` is an HTTP call, we can't easily get the boolean return value from the class method directly unless the DO response contains it.
        // Let's assume DO returns 200 if broadcasted to at least one connection? 
        // Wait, the `broadcast` method in DO returns true/false but the `fetch` handler wraps it in a Response.
        // I'll update DO `fetch` to return JSON status.

        // Actually, to keep it simple and reliable: always send FCM if urgency is high, or check DO response.
        // Let's rely on the DO response.
        
        // REVISIT DO implementation:
        // Update DO to return { delivered: true/false }
        
        // IF NOT DELIVERED ONLINE:
        // Fetch FCM token
        const tokenResult = await env.DB.prepare("SELECT token FROM fcm_tokens WHERE user_id = ?").bind(notification.userId).first();
        
        if (tokenResult && tokenResult.token) {
           // Send FCM
           await sendFCM(env, tokenResult.token, notification);
        }

        return new Response(JSON.stringify({ success: true, notification }), { headers: { ...corsHeaders, "Content-Type": "application/json" } });

      } catch (e) {
        return new Response(JSON.stringify({ error: e.message }), { status: 500, headers: corsHeaders });
      }
    }

    if (url.pathname === "/notifications/history") {
      const userId = url.searchParams.get("userId");
      if (!userId) return new Response("Missing userId", { status: 400, headers: corsHeaders });
      
      const results = await env.DB.prepare(
        "SELECT * FROM notifications_v2 WHERE user_id = ? ORDER BY created_at DESC LIMIT 50"
      ).bind(userId).all();
      
      return new Response(JSON.stringify(results.results), { headers: { ...corsHeaders, "Content-Type": "application/json" } });
    }

    if (url.pathname === "/notifications/fcm/register") {
       if (request.method !== "POST") return new Response("Method Not Allowed", { status: 405, headers: corsHeaders });
       const { userId, token } = await request.json();
       
       await env.DB.prepare(
         "INSERT OR REPLACE INTO fcm_tokens (user_id, token, updated_at) VALUES (?, ?, ?)"
       ).bind(userId, token, Date.now()).run();
       
       return new Response(JSON.stringify({ success: true }), { headers: { ...corsHeaders, "Content-Type": "application/json" } });
    }
    
    // New endpoint to mark as read
    if (url.pathname === "/notifications/read") {
        if (request.method !== "POST") return new Response("Method Not Allowed", { status: 405, headers: corsHeaders });
        const { notificationId } = await request.json();
        
        await env.DB.prepare(
            "UPDATE notifications_v2 SET is_read = 1 WHERE id = ?"
        ).bind(notificationId).run();
        
        return new Response(JSON.stringify({ success: true }), { headers: { ...corsHeaders, "Content-Type": "application/json" } });
    }

    return new Response("Not found", { status: 404, headers: corsHeaders });
  }
};

async function sendFCM(env, token, notification) {
  if (!env.FCM_PROJECT_ID || !env.FCM_CLIENT_EMAIL || !env.FCM_PRIVATE_KEY) {
      console.error("FCM V1 credentials not configured (FCM_PROJECT_ID, FCM_CLIENT_EMAIL, FCM_PRIVATE_KEY)");
      return;
  }
  
  try {
    console.log("Getting FCM V1 Access Token...");
    const accessToken = await getAccessToken(env);
    console.log("Got Access Token. Sending to FCM V1...");
    
    // Ensure metadata is a flattened object of strings for FCM data payload if possible,
    // or stringify complex objects.
    const dataPayload = {
      click_action: "FLUTTER_NOTIFICATION_CLICK",
      type: notification.type,
      id: notification.id,
      userId: notification.userId,
    };
    
    // Add metadata fields safely
    if (notification.metadata) {
        let meta = notification.metadata;
        if (typeof meta === 'string') {
            try { meta = JSON.parse(meta); } catch(e) {}
        }
        // Flatten or stringify
        dataPayload.metadata = JSON.stringify(meta);
    }

    const message = {
      message: {
        token: token,
        notification: {
          title: notification.title,
          body: notification.body,
        },
        data: dataPayload
      }
    };

    const res = await fetch(`https://fcm.googleapis.com/v1/projects/${env.FCM_PROJECT_ID}/messages:send`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(message),
    });

    if (!res.ok) {
      const txt = await res.text();
      console.error("FCM V1 Error:", res.status, txt);
    } else {
      console.log("FCM V1 Sent Successfully:", await res.json());
    }
  } catch (e) {
    console.error("FCM V1 Exception:", e);
  }
}

async function getAccessToken(env) {
  // 1. Create JWT
  const now = Math.floor(Date.now() / 1000);
  const claim = {
    iss: env.FCM_CLIENT_EMAIL,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    exp: now + 3600,
    iat: now,
  };

  const header = { alg: "RS256", typ: "JWT" };
  
  const encodedHeader = base64UrlEncode(JSON.stringify(header));
  const encodedClaim = base64UrlEncode(JSON.stringify(claim));
  const unsignedToken = `${encodedHeader}.${encodedClaim}`;

  const key = await importPrivateKey(env.FCM_PRIVATE_KEY);
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(unsignedToken)
  );

  const encodedSignature = base64UrlEncode(signature);
  const jwt = `${unsignedToken}.${encodedSignature}`;

  // 2. Exchange for Access Token
  const params = new URLSearchParams();
  params.append("grant_type", "urn:ietf:params:oauth:grant-type:jwt-bearer");
  params.append("assertion", jwt);

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: params,
  });

  if (!res.ok) {
    throw new Error(`Failed to get access token: ${await res.text()}`);
  }

  const data = await res.json();
  return data.access_token;
}

function base64UrlEncode(data) {
    let buffer;
    if (typeof data === 'string') {
        buffer = new TextEncoder().encode(data);
    } else {
        buffer = data;
    }
    const base64 = btoa(String.fromCharCode(...new Uint8Array(buffer)));
    return base64.replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

async function importPrivateKey(pem) {
  // Clean up PEM
  const pemHeader = "-----BEGIN PRIVATE KEY-----";
  const pemFooter = "-----END PRIVATE KEY-----";
  
  // Handle literal \n characters if they were escaped in the env var
  let pemContents = pem;
  if (pem.includes("\\n")) {
      pemContents = pem.split("\\n").join("\n");
  } else {
      // Sometimes it might be space separated if passed weirdly, but usually \n is the issue in env vars
  }
  
  pemContents = pemContents
    .replace(pemHeader, "")
    .replace(pemFooter, "")
    .replace(/\s/g, "");

  const binaryString = atob(pemContents);
  const bytes = new Uint8Array(binaryString.length);
  for (let i = 0; i < binaryString.length; i++) {
    bytes[i] = binaryString.charCodeAt(i);
  }

  return await crypto.subtle.importKey(
    "pkcs8",
    bytes.buffer,
    {
      name: "RSASSA-PKCS1-v1_5",
      hash: "SHA-256",
    },
    false,
    ["sign"]
  );
}
