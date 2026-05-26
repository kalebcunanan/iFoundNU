import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/feed_provider.dart'; // WAG KALIMUTAN ITO!
import 'screens/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        // FeedProvider!
        ChangeNotifierProvider(create: (context) => FeedProvider()),
      ],
      child: const NULostAndFoundApp(),
    ),
  );
}

class NULostAndFoundApp extends StatelessWidget {
  const NULostAndFoundApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NU Clark Lost & Found',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        primaryColor: const Color(0xFF3772FF),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3772FF)),
        textTheme: GoogleFonts.firaSansTextTheme(Theme.of(context).textTheme),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}