// ignore_for_file: library_private_types_in_public_api

// Packages
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';  

// Files
import 'package:levelup/nav.dart';
import 'avatarcreator.dart';
import 'focusareas.dart';

class IntroductionFlow extends StatefulWidget {
  const IntroductionFlow({super.key});

  @override
  State<IntroductionFlow> createState() => _IntroductionFlowState();
}

class _IntroductionFlowState extends State<IntroductionFlow> {
  late SharedPreferences prefs;
  bool isPrefsLoaded = false; // Flag to check if prefs are loaded

  // Load the SharedPreferences instance
  Future<void> _loadPrefs() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      isPrefsLoaded = true; // Set the flag to true once prefs are loaded
    });
  }

  @override
  void initState() {
    super.initState();
    _loadPrefs(); // Load preferences when the screen is initialized
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isPrefsLoaded
          ? PageView(
              children: [
                const WelcomeScreen(),
                const QuestionScreen(),
                const PreQuestionnaireScreen(),
                const QuestionnaireScreen1(),
                const QuestionnaireScreen2(),
                const QuestionnaireScreen3(),
                const QuestionnaireScreen4(),
                const FocusAreaScreen(),
                const PreAvatarScreen(),
                AvatarCreatorScreen(prefs: prefs), // Pass prefs directly to the screen
                const UsernamePasswordScreen(),
              ],
            )
          : const Center(),
    );
  }
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
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QuestionScreen extends StatelessWidget {
  const QuestionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Skip to next screen when tapped
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PreQuestionnaireScreen()),
        );
      },
      child: Container(
        color: Theme.of(context).colorScheme.primary,
        child: Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8, // Set width to 80% of screen
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Did you know there are approximately 3.3 billion gamers worldwide?',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  "You see, gaming is a widespread hobby, no need to be ashamed. We're just here to help you try and reduce it.",
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text(
                  'Tap anywhere to continue...',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PreQuestionnaireScreen extends StatelessWidget {
  const PreQuestionnaireScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
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
                'But first, tell us a bit more about yourself!',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              Text(
                'Tap anywhere to continue...',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
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

PageRouteBuilder _createSlideTransitionBack(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) {
      return page;
    },
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const offsetBegin = Offset(-1.0, 0.0); // Slide from left to right
      const offsetEnd = Offset.zero;
      const curve = Curves.easeInOut;

      var tween = Tween(begin: offsetBegin, end: offsetEnd).chain(CurveTween(curve: curve));
      var offsetAnimation = animation.drive(tween);

      return SlideTransition(position: offsetAnimation, child: child);
    },
  );
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
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        elevation: 0,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "What is your gender?",
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          
          RadioListTile<String>(
            title: const Text("🚹 Male"),
            value: "Male",
            groupValue: _selectedGender,
            onChanged: (value) {
              setState(() {
                _selectedGender = value;
              });
            },
          ),
          RadioListTile<String>(
            title: const Text("🚺 Female"),
            value: "Female",
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
  final TextEditingController _dateController = TextEditingController();

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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white), // Back arrow
            onPressed: () {
            Navigator.pushReplacement(
              context,
              _createSlideTransitionBack(const QuestionnaireScreen1()),
            );
          },
        ),
        backgroundColor: Theme.of(context).colorScheme.secondary, // Match theme
        elevation: 0, // Optional: remove shadow
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "What is your birth date?",
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),

          // Date input field with a date picker
          Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: TextFormField(
                controller: _dateController,
                readOnly: true, // Prevent manual typing
                onTap: () => _selectDate(context),
                decoration: InputDecoration(
                  labelText: '🎈 Select Birth Date',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.secondary,
                  suffixIcon: Icon(Icons.calendar_today),
                ),
              ),
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
      appBar: AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white), // Back arrow
          onPressed: () {
          Navigator.pushReplacement(
            context,
            _createSlideTransitionBack(const QuestionnaireScreen2()),
          );
        },
      ),
      backgroundColor: Theme.of(context).colorScheme.secondary, // Match theme
      elevation: 0, // Optional: remove shadow
      ),
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
                  items: ['🦅 USA', '🍁 Canada', '☕ UK', '🐊 Australia']
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
                      borderSide: BorderSide(color: Colors.white)
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
          _createSlideTransition(const FocusAreaScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white), // Back arrow
          onPressed: () {
          Navigator.pushReplacement(
            context,
            _createSlideTransitionBack(const QuestionnaireScreen3()),
          );
        },
      ),
      backgroundColor: Theme.of(context).colorScheme.secondary, // Match theme
      elevation: 0, // Optional: remove shadow
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "How often do you play games daily?",
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

class UsernamePasswordScreen extends StatefulWidget {
  const UsernamePasswordScreen({super.key});

  @override
  _UsernamePasswordScreenState createState() => _UsernamePasswordScreenState();
}

class _UsernamePasswordScreenState extends State<UsernamePasswordScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final ValueNotifier<bool> _isButtonEnabled = ValueNotifier(false);
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_validateInputs);
    _passwordController.addListener(_validateInputs);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _isButtonEnabled.dispose();
    super.dispose();
  }

  void _validateInputs() {
    _isButtonEnabled.value =
        _usernameController.text.isNotEmpty && _passwordController.text.isNotEmpty;
  }

  Future<void> _createAccount() async {
    final username = _usernameController.text;
    final password = _passwordController.text;

    if (username.isNotEmpty && password.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', username);
      await prefs.setString('password', password);
      await _completeIntroduction();
    }
  }

  Future<void> _completeIntroduction() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenIntro', true);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const Navigation()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () async {
            final prefs = await SharedPreferences.getInstance();
            if (mounted) {
              Navigator.pushReplacement(
                context,
                _createSlideTransitionBack(AvatarCreatorScreen(prefs: prefs)),
              );
            }
          },
        ),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("What should we call you?", style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 20),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => FocusScope.of(context).nextFocus(),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
              obscureText: !_isPasswordVisible,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 20),
            ValueListenableBuilder<bool>(
              valueListenable: _isButtonEnabled,
              builder: (context, isEnabled, child) {
                return ElevatedButton(
                  onPressed: isEnabled ? _createAccount : null, 
                  child: const Text("Create Account"),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
