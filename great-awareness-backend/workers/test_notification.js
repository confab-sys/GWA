const userId = process.argv[2];

if (!userId) {
  console.error("Please provide a userId as an argument.");
  console.error("Usage: node test_notification.js <userId>");
  process.exit(1);
}

const endpoint = "https://gwa-notifications-worker.aashardcustomz.workers.dev/notifications/send";

const notification = {
  userId: userId,
  title: "Test Notification",
  body: "This is a real-time test from the backend! " + new Date().toLocaleTimeString(),
  type: "system",
  metadata: {
    source: "test_script",
    timestamp: Date.now()
  }
};

console.log("Sending notification to:", endpoint);
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
