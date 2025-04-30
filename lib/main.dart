// ignore_for_file: library_private_types_in_public_api

// Packages
import 'package:flutter/material.dart';
import 'package:levelup/nav.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Files
import 'signupprocess.dart';
import 'userutils.dart';
// import 'progress.dart';

final RouteObserver<ModalRoute> routeObserver = RouteObserver<ModalRoute>();

/// When true, the SocialScreen blur overlay is shown (social features disabled).
ValueNotifier<bool> blurEnabledNotifier = ValueNotifier<bool>(true);

void main() async {
  // Ensure Flutter is initialized before fetching SharedPreferences
  WidgetsFlutterBinding.ensureInitialized(); 
  final prefs = await SharedPreferences.getInstance();
  final bool savedSocialEnabled = prefs.getBool('socialEnabled') ?? false;

  // Set initial blur state (true means blur is ON, so invert it)
  blurEnabledNotifier = ValueNotifier<bool>(!savedSocialEnabled);

  /* ============================================================================
   * DEBUG CONTROL PANEL – SharedPreferences Reset Tools
   * Uncomment any of the following lines to clear data or simulate app states.
   * ========================================================================== */

  // await prefs.clear();                           // Wipe all user data (full reset)

  // await prefs.setInt('userXP', 0);               // Reset XP
  // await prefs.setInt('userLevel', 1);            // Reset Level
  // await prefs.setInt('refreshTokens', 3);        // Reset Refresh Tokens

  // await prefs.remove('completedMissions');       // Clear completed system missions
  // await prefs.remove('activeSystemMissions');    // Clear active missions
  // await prefs.remove('dailyResetTime');          // Clear daily reset timer
  // await prefs.remove('weeklyResetTime');         // Clear weekly reset timer
  // await prefs.remove('monthlyResetTime');        // Clear monthly reset timer

  // await prefs.remove('userFocuses');             // Remove focus area selections
  // await prefs.remove('profilePath');             // Remove saved avatar path

  // await resetAllSkillBars();                     // Reset skill stat percentages

  // await prefs.remove('gamingSessions');          // Clear tracked gaming sessions

  // await prefs.remove('userPreferences');         // Clear user tags/preferences
  // await prefs.remove('answeredQuestions');       // Clear onboarding answers

  // await prefs.remove('trackedAddictions');       // Clear addiction timers
  // await prefs.remove('trackedHabits');           // Clear habit trackers

  /* ========================================================================== */

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
      navigatorObservers: [routeObserver],
      debugShowCheckedModeBanner: false,
      theme: ThemeData().copyWith(
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF212121),
          secondary: const Color(0xFF1C1C1C),
          tertiary: Colors.grey[700],
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF1C1C1C),
        ),
        dialogTheme: DialogTheme(
          backgroundColor: Color(0xFF1C1C1C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.white, width: 1.5),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: TextStyle(color: Colors.white),
          floatingLabelStyle: TextStyle(color: Colors.white),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          filled: true,
          fillColor: const Color(0xFF1C1C1C), // Adjust if needed
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(1),
            borderSide: const BorderSide(color: Colors.white, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.white, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.white, width: 1),
          ),
        ),
        radioTheme: RadioThemeData(
          fillColor: WidgetStateProperty.all(Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            // Normal state (default)
            backgroundColor: const Color(0xFF4CAF50),
            foregroundColor: Colors.white,

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
              return const Color(0xFF212121); // White checkmark when selected
            }
            return null; // No check color when unselected
          }),
        ),
        scaffoldBackgroundColor: Color(0xFF212121),
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

    // Navigate after 3 seconds, keeping animation active
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
              width: 200,
              height: 200,
            ),
          ),
        ),
      ),
    );
  }
}
