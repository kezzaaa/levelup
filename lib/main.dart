// ignore_for_file: library_private_types_in_public_api

// Packages
import 'package:flutter/material.dart';
import 'package:levelup/nav.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Files
import 'package:levelup/signupprocess.dart';
import 'utils.dart';

void main() async {
  // Ensure Flutter is initialized before fetching SharedPreferences
  WidgetsFlutterBinding.ensureInitialized(); 
  final prefs = await SharedPreferences.getInstance();
  
  // Clear SharedPreferences for wiping user data and starting from beginning
  // await prefs.clear();
  
  // Create and print user on start
  String? userId = await createGuestUser();
  debugPrint("🆔 Loaded guest user ID: $userId");

  // Toggle if the user has seen the introduction before
  final bool hasSeenIntro = prefs.getBool('hasSeenIntro') ?? false;

  // Run the app and pass whether the user has seen the intro or not
  runApp(MyApp(hasSeenIntro: hasSeenIntro));
}

class MyApp extends StatelessWidget {
  final bool hasSeenIntro;

  const MyApp({super.key, required this.hasSeenIntro});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LevelUp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData().copyWith(
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF212121),
          secondary: Color(0xFF1C1C1C),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
          ),
        ),
        radioTheme: RadioThemeData(
          fillColor: WidgetStateProperty.all(Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            // Normal state (default)
            backgroundColor: const Color(0xFF4CAF50),
            foregroundColor: Colors.black,

            // Disabled state
            disabledBackgroundColor: Color.fromARGB(255, 28, 28, 28),
            disabledForegroundColor: Colors.white,
          ),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.green; // Green fill when selected
            }
            return Colors.transparent; // Transparent fill when unselected
          }),
          checkColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white; // White checkmark when selected
            }
            return null; // No check color when unselected
          }),
        ),
        scaffoldBackgroundColor: Colors.grey.shade900,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 18, color: Colors.white),
          bodyMedium: TextStyle(fontSize: 16, color: Colors.white),
          bodySmall: TextStyle(fontSize: 14, color: Colors.white),
        ),
      ),
      // Show the SplashScreen first, which will decide where to go next
      home: Initialise(hasSeenIntro: hasSeenIntro),
    );
  }
}

// Splash screen that always appears first
class Initialise extends StatefulWidget {
  final bool hasSeenIntro;

  const Initialise({super.key, required this.hasSeenIntro});

  @override
  _InitialiseState createState() => _InitialiseState();
}

class _InitialiseState extends State<Initialise> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
      lowerBound: 0.8,
      upperBound: 1.0,
    )..repeat(reverse: true); // ✅ Loop animation smoothly

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    // ✅ Navigate after 3 seconds, keeping animation active
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          _controller.stop(); // ✅ Stop animation before navigating
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => widget.hasSeenIntro ? const Navigation() : const IntroductionFlow(),
            ),
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose(); // Dispose of the controller to prevent memory leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Theme.of(context).colorScheme.primary,
        child: Center(
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value, // Apply the scaling animation
                child: child,
              );
            },
            child: Image.asset(
              'assets/images/logo.png', // Logo
              width: 150,
              height: 150,
            ),
          ),
        ),
      ),
    );
  }
}
