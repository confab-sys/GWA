
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
    this.sessions.push({ webSocket });

    webSocket.addEventListener("message", async (msg) => {
      try {
        const data = JSON.parse(msg.data);
        
        if (data.type === 'join') {
           // Tag session with user info
           const session = this.sessions.find(s => s.webSocket === webSocket);
           if (session) {
             session.user = data.user; // { id, name, alias }
           }
           // Optionally broadcast join? Prompt says "Handle join/leave events gracefully" but also "No reaction spam".
           // Maybe just silent join or subtle.
        } else if (data.type === 'message') {
           // Broadcast
           const session = this.sessions.find(s => s.webSocket === webSocket);
           const user = session?.user || { name: 'Anonymous' };
           
           const messageEntry = {
             id: crypto.randomUUID(),
             room_id: this.state.id.toString(),
             user_name: user.name || user.alias || "Anonymous",
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
             "INSERT INTO chat_messages (id, room_id, user_name, content, created_at) VALUES (?, ?, ?, ?, ?)"
           ).bind(messageEntry.id, messageEntry.room_id, messageEntry.user_name, messageEntry.content, messageEntry.created_at).run().catch(e => console.error(e));
        }
      } catch (err) {
        console.error("Error handling message", err);
      }
    });

    webSocket.addEventListener("close", () => {
      this.sessions = this.sessions.filter((session) => session.webSocket !== webSocket);
    });
  }

  broadcast(message) {
    this.sessions = this.sessions.filter((session) => {
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
