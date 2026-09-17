import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/brutalist_theme.dart';
import 'firebase_options.dart';
import 'presentation/navigation/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (fail-safe on desktop/testing)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('Firebase initialization notice: $e (Running in offline/local mode)');
    }
  }

  // Set immersive dark status bar / navigation bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0C0C0E),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    const ProviderScope(
      child: GroovdApp(),
    ),
  );
}

class GroovdApp extends StatelessWidget {
  const GroovdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Groovd // Music Critique',
      debugShowCheckedModeBanner: false,
      theme: BrutalistTheme.darkTheme,
      home: const MainNavigationScreen(),
    );
  }
}

@Preview()
Widget mainScreenPreview() {
  return const ProviderScope(
    child: MaterialApp(
      home: MainNavigationScreen(),
    ),
  );
}