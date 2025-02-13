// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

void main() async {
  // Ensure Flutter is initialized before fetching SharedPreferences
  WidgetsFlutterBinding.ensureInitialized(); 
  final prefs = await SharedPreferences.getInstance();
  
  // Check if the user has seen the introduction before
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
      theme: ThemeData().copyWith(
        colorScheme: ColorScheme.dark(
          primary: Colors.grey.shade900,
          secondary: Color.fromARGB(255, 28, 28, 28),
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
            backgroundColor: Colors.green,
            foregroundColor: Colors.black,

            // Disabled state
            disabledBackgroundColor: Color.fromARGB(255, 28, 28, 28),
            disabledForegroundColor: Colors.white,
          ),
        ),
        checkboxTheme: CheckboxThemeData(
          checkColor: WidgetStateProperty.all<Color>(Colors.green),
          overlayColor: WidgetStateProperty.all<Color>(Colors.green),
        ),
        scaffoldBackgroundColor: Colors.grey.shade900,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 18, color: Colors.white),
          bodyMedium: TextStyle(fontSize: 16, color: Colors.white),
          bodySmall: TextStyle(fontSize: 14, color: Colors.white),
        ),
      ),
      // Show the SplashScreen first, which will decide where to go next
      home: SplashScreen(hasSeenIntro: hasSeenIntro),
    );
  }
}

// Splash screen that always appears first
class SplashScreen extends StatefulWidget {
  final bool hasSeenIntro;

  const SplashScreen({super.key, required this.hasSeenIntro});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    
    // After a 3-second delay, navigate to the appropriate screen
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        // If user has seen the intro, go straight to login
        // Otherwise, start the introduction flow
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => widget.hasSeenIntro ? const MyHomePage(title: 'Home Page',) : const IntroductionFlow(),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Theme.of(context).colorScheme.primary,
        child: Center(
          child: Image.asset(
            'assets/images/apple.png', // Logo or splash image
            width: 60,
            height: 60,
          ),
        ),
      ),
    );
  }
}

// Introduction flow, shown only once to new users
class IntroductionFlow extends StatefulWidget {
  const IntroductionFlow({super.key});

  @override
  State<IntroductionFlow> createState() => _IntroductionFlowState();
}

class _IntroductionFlowState extends State<IntroductionFlow> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        children: const [
          WelcomeScreen(),
          QuestionScreen(),
          QuestionnaireScreen1(),
          QuestionnaireScreen2(),
          QuestionnaireScreen3(),
          QuestionnaireScreen4(),
          QuestionnaireScreen5(),
          UsernamePasswordScreen(),
          LoginScreen(),
        ],
      ),
    );
  }
}

// Custom page transition with a slide effect
PageRouteBuilder _createSlideTransition(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) {
      return page;
    },
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const offsetBegin = Offset(1.0, 0.0); // Slide from right to left
      const offsetEnd = Offset.zero;
      const curve = Curves.easeInOut;

      var tween = Tween(begin: offsetBegin, end: offsetEnd).chain(CurveTween(curve: curve));
      var offsetAnimation = animation.drive(tween);

      return SlideTransition(position: offsetAnimation, child: child);
    },
  );
}

// A simple welcome prompt for the app
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const QuestionScreen()),
        );
      },
      child: Container(
        color: Theme.of(context).colorScheme.primary,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Welcome to LevelUp!',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              Text(
                'Tap anywhere to continue...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// A simple question screen with a fact and navigation prompt
class QuestionScreen extends StatelessWidget {
  const QuestionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Skip to next screen when tapped
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const QuestionnaireScreen1()),
        );
      },
      child: Container(
        color: Theme.of(context).colorScheme.primary,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Did you know [insert fact here]?',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              Text(
                'Tap anywhere to continue...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QuestionnaireScreen1 extends StatefulWidget {
  const QuestionnaireScreen1({super.key});

  @override
  _QuestionnaireScreen1State createState() => _QuestionnaireScreen1State();
}

class _QuestionnaireScreen1State extends State<QuestionnaireScreen1> {
  String? _selectedGender;

  // Function to save gender and navigate to next questionnaire
  void _saveGenderAndProceed() async {
    if (_selectedGender != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userGender', _selectedGender!);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          _createSlideTransition(const QuestionnaireScreen2()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "What is your gender?",
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          
          RadioListTile<String>(
            title: const Text("Male"),
            value: "Male",
            groupValue: _selectedGender,
            onChanged: (value) {
              setState(() {
                _selectedGender = value;
              });
            },
          ),
          RadioListTile<String>(
            title: const Text("Female"),
            value: "Female",
            groupValue: _selectedGender,
            onChanged: (value) {
              setState(() {
                _selectedGender = value;
              });
            },
          ),
          RadioListTile<String>(
            title: const Text("Other"),
            value: "Other",
            groupValue: _selectedGender,
            onChanged: (value) {
              setState(() {
                _selectedGender = value;
              });
            },
          ),
          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: _selectedGender != null ? _saveGenderAndProceed : null,
            child: const Text("Continue"),
          ),
        ],
      ),
    );
  }
}

class QuestionnaireScreen2 extends StatefulWidget {
  const QuestionnaireScreen2({super.key});

  @override
  _QuestionnaireScreen2State createState() => _QuestionnaireScreen2State();
}

class _QuestionnaireScreen2State extends State<QuestionnaireScreen2> {
  TextEditingController _dateController = TextEditingController();

  // Function to save the selected date and proceed to next screen (Login)
  void _saveBirthDateAndProceed() async {
    if (_dateController.text.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userBirthDate', _dateController.text);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          _createSlideTransition(const QuestionnaireScreen3()),
        );
      }
    }
  }

  // Function to show the date picker
  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate = DateTime.now();
    final DateTime picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    ) ?? initialDate;

    if (picked != initialDate) {
      setState(() {
        _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "What is your birth date?",
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),

          // Date input field with a date picker
          TextFormField(
            controller: _dateController,
            readOnly: true, // Prevent the user from typing in the text field directly
            onTap: () => _selectDate(context),
            decoration: InputDecoration(
              labelText: 'Select Birth Date',
              hintText: 'dd/mm/yyyy',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.calendar_today),
            ),
          ),
          const SizedBox(height: 20),

          // Continue button
          ElevatedButton(
            onPressed: _dateController.text.isNotEmpty ? _saveBirthDateAndProceed : null,
            child: const Text("Continue"),
          ),
        ],
      ),
    );
  }
}

class QuestionnaireScreen3 extends StatefulWidget {
  const QuestionnaireScreen3({super.key});

  @override
  _QuestionnaireScreen3State createState() => _QuestionnaireScreen3State();
}

class _QuestionnaireScreen3State extends State<QuestionnaireScreen3> {
  String? _selectedCountry;

  // Function to save the selected country and proceed
  void _saveCountryAndProceed() async {
    if (_selectedCountry != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userCountry', _selectedCountry!);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          _createSlideTransition(const QuestionnaireScreen4()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "What country are you from?",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            // Use a DropdownButtonFormField instead
            Material(
              color: Colors.transparent, // Ensures no background interference
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8, // Control width here
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedCountry,
                  hint: const Text(
                    "Select Country",
                    style: TextStyle(color: Colors.white),
                  ),
                  items: ['🇺🇸 USA', '🇨🇦 Canada', '🇬🇧 UK', '🇦🇺 Australia']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCountry = value;
                    });
                  },
                  dropdownColor: Theme.of(context).colorScheme.secondary,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.secondary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _selectedCountry != null ? _saveCountryAndProceed : null,
              child: const Text("Continue"),
            ),
          ],
        ),
      ),
    );
  }
}

class QuestionnaireScreen4 extends StatefulWidget {
  const QuestionnaireScreen4({super.key});

  @override
  _QuestionnaireScreen4State createState() => _QuestionnaireScreen4State();
}

class _QuestionnaireScreen4State extends State<QuestionnaireScreen4> {
  String? _selectedGamingSeverity;

  // Function to save the selected gaming severity and proceed
  void _saveGamingSeverityAndProceed() async {
    if (_selectedGamingSeverity != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userGamingSeverity', _selectedGamingSeverity!);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          _createSlideTransition(const QuestionnaireScreen5()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "How severe is your gaming addiction?",
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),

          // Gaming addiction severity options
          RadioListTile<String>(
            title: const Text("Less than 1 hour"),
            value: "Less than 1 hour",
            groupValue: _selectedGamingSeverity,
            onChanged: (value) {
              setState(() {
                _selectedGamingSeverity = value;
              });
            },
          ),
          RadioListTile<String>(
            title: const Text("1-3 hours"),
            value: "1-3 hours",
            groupValue: _selectedGamingSeverity,
            onChanged: (value) {
              setState(() {
                _selectedGamingSeverity = value;
              });
            },
          ),
          RadioListTile<String>(
            title: const Text("3-6 hours"),
            value: "3-6 hours",
            groupValue: _selectedGamingSeverity,
            onChanged: (value) {
              setState(() {
                _selectedGamingSeverity = value;
              });
            },
          ),
          RadioListTile<String>(
            title: const Text("6+ hours"),
            value: "6+ hours",
            groupValue: _selectedGamingSeverity,
            onChanged: (value) {
              setState(() {
                _selectedGamingSeverity = value;
              });
            },
          ),
          const SizedBox(height: 20),

          // Continue button
          ElevatedButton(
            onPressed: _selectedGamingSeverity != null ? _saveGamingSeverityAndProceed : null,
            child: const Text("Continue"),
          ),
        ],
      ),
    );
  }
}

class QuestionnaireScreen5 extends StatefulWidget {
  const QuestionnaireScreen5({super.key});

  @override
  _QuestionnaireScreen5State createState() => _QuestionnaireScreen5State();
}

class _QuestionnaireScreen5State extends State<QuestionnaireScreen5> {
  String? _selectedArea;

  // Function to save the selected focus and proceed to the next screen
  Future<void> _saveAreaAndProceed() async {
    if (_selectedArea != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userFocus', _selectedArea!);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const UsernamePasswordScreen()), // Navigate to account creation screen
        );
      }
    }
  }

  List<String> _selectedAreas = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "What would you like to focus on first?",
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),

          CheckboxListTile(
            title: const Text("Fitness"),
            value: _selectedAreas.contains("Fitness"),
            onChanged: (bool? value) {
              setState(() {
                _selectedAreas = List.from(_selectedAreas);
                value == true ? _selectedAreas.add("Fitness") : _selectedAreas.remove("Fitness");
              });
            },
          ),
          CheckboxListTile(
            title: const Text("Finances"),
            value: _selectedAreas.contains("Finances"),
            onChanged: (bool? value) {
              setState(() {
                _selectedAreas = List.from(_selectedAreas);
                value == true ? _selectedAreas.add("Finances") : _selectedAreas.remove("Finances");
              });
            },
          ),
          CheckboxListTile(
            title: const Text("Diet"),
            value: _selectedAreas.contains("Diet"),
            onChanged: (bool? value) {
              setState(() {
                _selectedAreas = List.from(_selectedAreas);
                value == true ? _selectedAreas.add("Diet") : _selectedAreas.remove("Diet");
              });
            },
          ),
          CheckboxListTile(
            title: const Text("Productivity"),
            value: _selectedAreas.contains("Productivity"),
            onChanged: (bool? value) {
              setState(() {
                _selectedAreas = List.from(_selectedAreas);
                value == true ? _selectedAreas.add("Productivity") : _selectedAreas.remove("Productivity");
              });
            },
          ),
          CheckboxListTile(
            title: const Text("Creativity"),
            value: _selectedAreas.contains("Creativity"),
            onChanged: (bool? value) {
              setState(() {
                _selectedAreas = List.from(_selectedAreas);
                value == true ? _selectedAreas.add("Creativity") : _selectedAreas.remove("Creativity");
              });
            },
          ),
          const SizedBox(height: 20),

          // Continue button
          ElevatedButton(
            onPressed: _selectedAreas.isNotEmpty
                ? () async {
                    await _saveAreaAndProceed();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UsernamePasswordScreen(),
                      ),
                    );
                  }
                : null, // Disable button if no option is selected
            child: const Text("Continue"),
          )
        ],
      ),
    );
  }
}

class UsernamePasswordScreen extends StatefulWidget {
  const UsernamePasswordScreen({super.key});

  @override
  _UsernamePasswordScreenState createState() =>
      _UsernamePasswordScreenState();
}

class _UsernamePasswordScreenState extends State<UsernamePasswordScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  // Function to handle account creation and updating the intro flag
  Future<void> _createAccount() async {
    final username = _usernameController.text;
    final password = _passwordController.text;

    if (username.isNotEmpty && password.isNotEmpty) {
      // Store the username and password (in practice, store encrypted passwords)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', username);
      await prefs.setString('password', password);

      // Mark the introduction as completed
      await _completeIntroduction();  // Await this as it's now Future<void>
    }
  }

  // Mark the introduction as completed and navigate to homepage
  Future<void> _completeIntroduction() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenIntro', true);  // Set hasSeenIntro to true

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const MyHomePage(title: 'Home Page'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "What should we call you?",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),

            // Username TextField
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next, // Move to password field on "next"
              onSubmitted: (_) {
                // Move to password field when user presses enter or next
                FocusScope.of(context).requestFocus(FocusNode());
              },
            ),
            const SizedBox(height: 20),

            // Password TextField (initially hidden)
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
              obscureText: !_isPasswordVisible,
              textInputAction: TextInputAction.done, // "Done" action when submitted
              onSubmitted: (_) => _createAccount(), // Create account on "done"
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _createAccount,
              child: const Text("Create Account"),
            ),
          ],
        ),
      ),
    );
  }
}

// Login or Sign-Up screen
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primary,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Login or Sign Up',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigate to the main home page
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const MyHomePage(title: 'Home Page'),
                  ),
                );
              },
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}

// Main home page after login
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 2; // Default to the home tab

  // Update selected index when a tab is tapped
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Theme.of(context).colorScheme.secondary,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Account',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Social',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_box),
            label: 'Missions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_sharp),
            label: 'Progress',
          ),
        ],
      ),
    );
  }
}
