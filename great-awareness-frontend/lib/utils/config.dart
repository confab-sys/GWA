import 'package:flutter/foundation.dart';

// Configuration for Psychology App Frontend
// Change currentEnvironment to 'production' when deploying to Render

// Development (local) backend
const String apiBaseUrlDev = 'http://localhost:8000';

// Production (Render) backend - UPDATE THIS with your actual Render URL
const String apiBaseUrlProd = 'https://gwa-enus.onrender.com';

// Vercel deployment URL (for web proxy)
const String apiBaseUrlVercel = '/api';

// Current environment - change this to 'production' when ready to deploy
const String currentEnvironment = 'development'; // or 'production'

// Get the appropriate API URL based on environment
String getApiBaseUrl() {
  if (kIsWeb && currentEnvironment == 'production') {
    // For web production, use Vercel proxy to avoid CORS issues
    return apiBaseUrlVercel;
  }
  return currentEnvironment == 'production' ? apiBaseUrlProd : apiBaseUrlDev;
}

// Cloudflare Configuration
const String cloudflarePublicUrl = 'https://pub-1c8c879e41fe4ff48de96ceabce671a2.r2.dev';

// App Configuration
const String appName = 'Psychology App';
const String appVersion = '1.0.0';

// Export the current API URL for use in services
final String apiBaseUrl = getApiBaseUrl(); // Uses environment-based URL