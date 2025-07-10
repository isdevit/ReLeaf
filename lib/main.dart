import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ReLeafApp());
}

class ReLeafApp extends StatelessWidget {
  const ReLeafApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReLeaf',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF6FDF6),
        primaryColor: const Color(0xFF4CAF50),
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme,
        ),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: const Color(0xFF81C784),
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
