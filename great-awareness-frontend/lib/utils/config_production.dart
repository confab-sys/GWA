// Production Configuration for Psychology App Frontend
// Update these values after deploying your backend to Render

// Development (local) backend
const String apiBaseUrlDev = 'http://localhost:8000';

// Production (Render) backend - UPDATE THIS with your actual Render URL
const String apiBaseUrlProd = 'https://gwa-enus.onrender.com';

// Current environment - change this to 'production' when ready to deploy
const String currentEnvironment = 'production'; // or 'production'

// Get the appropriate API URL based on environment
String getApiBaseUrl() {
  return currentEnvironment == 'production' ? apiBaseUrlProd : apiBaseUrlDev;
}

// Cloudflare Configuration
const String cloudflareWorkerUrl = 'https://video-worker-prod.aashardcustomz.workers.dev';
const String cloudflarePublicUrl = 'https://pub-1c8c879e41fe4ff48de96ceabce671a2.r2.dev'; // Deprecated - use Worker API instead

// App Configuration
const String appName = 'Psychology App';
const String appVersion = '1.0.0';