import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/login1_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/feed_screen.dart';
import 'services/auth_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AuthService(),
      child: MaterialApp(
        title: 'Great Awareness',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
          textTheme: GoogleFonts.judsonTextTheme(),
        ),
        initialRoute: '/',
        routes: {
          '/': (_) => const SplashScreen(),
          '/welcome': (_) => const WelcomeScreen(),
          '/login': (_) => const LoginScreen(),
          '/login1': (_) => const Login1Screen(),
          '/signup': (_) => const SignupScreen(),
          '/home': (_) => const FeedScreen(),
        },
      ),
    );
  }
}