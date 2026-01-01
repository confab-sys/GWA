const endpoint = "https://gwa-notifications-worker.aashardcustomz.workers.dev/notifications/broadcast";

const notification = {
  title: "Test Broadcast",
  body: "This is a broadcast test from the backend! " + new Date().toLocaleTimeString(),
  type: "system",
  excludeUserId: "nobody",
  metadata: {
    source: "test_script",
    timestamp: Date.now()
  }
};

console.log("Sending broadcast to:", endpoint);
console.log("Payload:", notification);

fetch(endpoint, {
  method: "POST",
  headers: {
    "Content-Type": "application/json"
  },
  body: JSON.stringify(notification)
})
.then(res => res.text())
.then(text => {
  try {
    const json = JSON.parse(text);
    console.log("Response:", JSON.stringify(json, null, 2));
  } catch (e) {
    console.log("Response (text):", text);
  }
})
.catch(err => console.error("Error:", err));
