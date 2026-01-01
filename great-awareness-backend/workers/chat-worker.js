
export class ChatRoom {
  constructor(state, env) {
    this.state = state;
    this.env = env;
    this.sessions = [];
  }

  async fetch(request) {
    const url = new URL(request.url);

    // Handle WebSocket upgrade
    if (request.headers.get("Upgrade") === "websocket") {
      const pair = new WebSocketPair();
      const [client, server] = Object.values(pair);

      await this.handleSession(server);

      return new Response(null, { status: 101, webSocket: client });
    }

    // Handle history fetch (HTTP)
    if (url.pathname.endsWith("/history")) {
      // Fetch from D1
      const messages = await this.env.GWA_CHAT_DB.prepare(
        "SELECT * FROM chat_messages WHERE room_id = ? ORDER BY created_at DESC LIMIT 50"
      ).bind(this.state.id.toString()).all();
      
      return new Response(JSON.stringify(messages.results.reverse()), {
        headers: { 
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Methods": "GET, OPTIONS",
        }
      });
    }

    return new Response("Expected Upgrade: websocket", { status: 426 });
  }

  async handleSession(webSocket) {
    webSocket.accept();
    const session = { webSocket, user: null };
    this.sessions.push(session);

    webSocket.addEventListener("message", async (msg) => {
      try {
        const data = JSON.parse(msg.data);
        
        if (data.type === 'join') {
           // Tag session with user info
           session.user = data.user; // { id, name, alias, profilePictureUrl }
           this.broadcastPresence();
        } else if (data.type === 'typing_start') {
           this.broadcast(JSON.stringify({
             type: 'typing_start',
             userId: session.user?.id,
             userName: session.user?.name || "Someone"
           }), webSocket); // Exclude sender
        } else if (data.type === 'typing_stop') {
           this.broadcast(JSON.stringify({
             type: 'typing_stop',
             userId: session.user?.id
           }), webSocket); // Exclude sender
        } else if (data.type === 'message') {
           // Broadcast
           const user = session.user || { name: 'Anonymous' };
           
           const messageEntry = {
             id: crypto.randomUUID(),
             room_id: this.state.id.toString(),
             user_name: user.name || user.alias || "Anonymous",
             user_id: user.id || null,
             user_avatar: user.profilePictureUrl || null,
             content: data.content,
             created_at: Date.now() // Server-generated timestamp
           };

           // 1. Broadcast to all open connections
           this.broadcast(JSON.stringify({
             type: 'new_message',
             message: messageEntry
           }));

           // 2. Persist to D1 (fire and forget to not block)
           this.env.GWA_CHAT_DB.prepare(
             "INSERT INTO chat_messages (id, room_id, user_name, content, created_at, user_id, user_avatar) VALUES (?, ?, ?, ?, ?, ?, ?)"
           ).bind(messageEntry.id, messageEntry.room_id, messageEntry.user_name, messageEntry.content, messageEntry.created_at, messageEntry.user_id, messageEntry.user_avatar).run().catch(e => console.error(e));

           // 3. Trigger Global Notification (fire and forget)
           fetch("https://gwa-notifications-worker.aashardcustomz.workers.dev/notifications/broadcast", {
             method: "POST",
             headers: { "Content-Type": "application/json" },
             body: JSON.stringify({
               title: "New Wellness Chat",
               body: `${messageEntry.user_name}: ${messageEntry.content}`,
               type: "chat",
               excludeUserId: messageEntry.user_id,
               metadata: { 
                 roomId: "wellness", // Or extract from path if possible, but "wellness" is the main one
                 messageId: messageEntry.id 
               }
             })
           }).catch(e => console.error("Failed to trigger notification:", e));
        }
      } catch (err) {
        console.error("Error handling message", err);
      }
    });

    webSocket.addEventListener("close", () => {
      this.sessions = this.sessions.filter((s) => s !== session);
      if (session.user) {
        this.broadcastPresence();
      }
    });
  }

  broadcastPresence() {
    const onlineUsers = this.sessions
      .filter(s => s.user)
      .map(s => s.user);
      
    // Deduplicate by ID
    const uniqueUsers = Array.from(new Map(onlineUsers.map(u => [u.id, u])).values());

    this.broadcast(JSON.stringify({
      type: 'presence_update',
      count: uniqueUsers.length,
      users: uniqueUsers
    }));
  }

  broadcast(message, excludeSocket = null) {
    this.sessions = this.sessions.filter((session) => {
      if (excludeSocket && session.webSocket === excludeSocket) return true;
      try {
        session.webSocket.send(message);
        return true;
      } catch (err) {
        return false;
      }
    });
  }
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    
    // Extract room name from path: /room/NAME or /room/NAME/history
    // Default to 'global' if not found
    let roomName = 'global';
    const pathParts = url.pathname.split('/');
    if (pathParts[1] === 'room' && pathParts[2]) {
      roomName = pathParts[2];
    }
    
    // Create ID from room name (consistent for both WS and HTTP)
    const id = env.CHAT_ROOM.idFromName(roomName); 
    const obj = env.CHAT_ROOM.get(id);
    return obj.fetch(request);
  }
};
