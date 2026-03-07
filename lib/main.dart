import 'package:ekdant/components/bottom_screen.dart';
import 'package:ekdant/pages/add_funds.dart';
import 'package:ekdant/pages/bid_history.dart';
import 'package:ekdant/pages/home_screen.dart';
import 'package:ekdant/pages/login_screen.dart';
import 'package:ekdant/pages/signup_screen.dart';
import 'package:ekdant/pages/transaction_history.dart';
import 'package:ekdant/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Style the system status bar to match our dark theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF162040),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const Color _dark = Color(0xFF0A1628);
  static const Color _gold = Color(0xFFD4A843);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ekdant Matka',
      theme: ThemeData(
        scaffoldBackgroundColor: _dark,
        colorScheme: const ColorScheme.dark(
          primary: _gold,
          surface: Color(0xFF162040),
        ),
        fontFamily: 'Roboto',
      ),
      home: FutureBuilder<bool>(
        future: AuthService().isLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildSplash();
          } else if (snapshot.hasError) {
            return const Scaffold(
              body: Center(
                child: Text(
                  'Error checking login status',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            );
          } else if (snapshot.data == true) {
            return const BottomScreen();
          } else {
            return const LoginScreen();
          }
        },
      ),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/addfund': (context) => const AddFunds(),
        '/bidhistory': (context) => BidHistory(),
        '/transaction_history': (context) => TransactionHistory(),
      },
    );
  }

  Widget _buildSplash() {
    return Scaffold(
      backgroundColor: _dark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Gold logo circle
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [_gold, Color(0xFFF0C860)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _gold.withOpacity(0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'E',
                  style: TextStyle(
                    color: _dark,
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Ekdant Matka',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Play Smart. Win Big.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(_gold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
