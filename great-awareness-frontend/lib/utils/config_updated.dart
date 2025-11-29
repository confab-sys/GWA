// Configuration for Psychology App Frontend
// Uses conditional imports to load platform-specific configurations

// Conditional imports based on platform
import 'config_stub.dart'
    if (dart.library.io) 'config_io.dart'
    if (dart.library.html) 'config_web_updated.dart';

// Export the platform-specific API URL
export 'config_stub.dart'
    if (dart.library.io) 'config_io.dart'
    if (dart.library.html) 'config_web_updated.dart';

// Cloudflare Configuration (shared across platforms)
const String cloudflarePublicUrl = 'https://pub-1c8c879e41fe4ff48de96ceabce671a2.r2.dev';

// App Configuration (shared across platforms)
const String appName = 'Psychology App';
const String appVersion = '1.0.0';