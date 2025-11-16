import 'package:flutter/material.dart';
import '../utils/storage.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final token = await Storage.getToken();
    if (!mounted) return;
    final target = token != null && token.isNotEmpty ? '/home' : '/login';
    Navigator.of(context).pushReplacementNamed(target);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Great Awareness',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}