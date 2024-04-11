import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // Use SplashScreen as the initial route
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => SplashScreen(),
        '/login': (context) => LoginPage(),
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Navigate to LoginPage after 3 seconds
    Timer(Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, '/login');
    });

    return Scaffold(
      body: Center(
        // Display your splash screen image here
        child: Image.asset('assets/mylogo.png'),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  late Database _database; // Define _database

  @override
  void initState() {
    super.initState();
    _initializeDatabase(); // Initialize _database
  }

  Future<void> _initializeDatabase() async {
    _database = await openDatabase(
      join(await getDatabasesPath(), 'user_database.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE users(id INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT, password TEXT)',
        );
      },
      version: 1,
    );
  }

  Future<void> _login(BuildContext context) async {
    final List<Map<String, dynamic>> users = await _database.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [
        _usernameController.text,
        _passwordController.text,
      ],
    );

    if (users.isNotEmpty) {
      // Navigate to the SnowmanGame with isLoggedIn set to true
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SnowmanGame(),
        ),
      );
    } else {
      // Show error message
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Invalid username or password.'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login Page'),
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Password'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _login(context); // Pass the context to _login method
              },
              child: Text('Login'),
            ),
            TextButton(
              onPressed: () {
                // Navigate to signup page
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SignupPage()),
                );
              },
              child: Text('Sign up'),
            ),
          ],
        ),
      ),
    );
  }
}

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Signup Page'),
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Password'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Save signup data to SQLite database
                _saveUser(_usernameController.text, _passwordController.text);
                // Navigate back to login page
                Navigator.pop(context);
              },
              child: Text('Sign up'),
            ),
          ],
        ),
      ),
    );
  }

  // SQLite database functions
  Future<void> _saveUser(String username, String password) async {
    final database = openDatabase(
      join(await getDatabasesPath(), 'user_database.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE users(id INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT, password TEXT)',
        );
      },
      version: 1,
    );

    final Database db = await database;
    await db.insert(
      'users',
      {
        'username': username,
        'password': password,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}

class SnowmanGame extends StatefulWidget {
  @override
  _SnowmanGameState createState() => _SnowmanGameState();
}

class _SnowmanGameState extends State<SnowmanGame> {
  final List<Map<String, String>> wordHints = [
    {'word': 'SNOW', 'hint': 'Frozen precipitation'},
    {'word': 'WINTER', 'hint': 'Season with cold weather'},
    {'word': 'FROST', 'hint': 'Thin layer of ice crystals'},
    {'word': 'CHILL', 'hint': 'Cold sensation'},
    {'word': 'FLURRY', 'hint': 'Brief snowfall'}
  ];

  late String selectedWord;
  late String wordHint;
  late List<bool> guessedLetters;
  int snowmanParts = 0;
  bool gameFinished = false;
  int userScore = 0; // Add user score variable

  // Function to update user score
  void _updateUserScore() {
    setState(() {
      userScore++; // Increment score when user wins
    });
  }

  void _logout() {
    Navigator.of(this.context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  void initState() {
    super.initState();
    _selectWordAndHint();
    guessedLetters = List.generate(selectedWord.length, (index) => false);
  }

  void _selectWordAndHint() {
    final randomIndex = DateTime.now().millisecondsSinceEpoch % wordHints.length;
    selectedWord = wordHints[randomIndex]['word']!;
    wordHint = wordHints[randomIndex]['hint']!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Snowman Game'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
          IconButton(
            icon: Icon(Icons.score), // Icon for viewing score
            onPressed: () => _showScoreDialog(userScore), // Show score on button click
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/Snowman-${snowmanParts + 1}.jpg',
              height: 200,
              width: 200,
            ),
            SizedBox(height: 20),
            Text(
              selectedWord.split('').map((letter) {
                final index = selectedWord.indexOf(letter);
                return guessedLetters[index] ? letter : '_ ';
              }).join(),
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),
            Text(
              'Hint: $wordHint',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(26, (index) {
                final letter = String.fromCharCode(index + 65);
                return ElevatedButton(
                  onPressed: gameFinished ? null : () => _checkLetter(letter),
                  child: Text(letter),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _checkLetter(String letter) {
    bool foundLetter = false;
    for (int i = 0; i < selectedWord.length; i++) {
      if (selectedWord[i] == letter) {
        foundLetter = true;
        setState(() {
          guessedLetters[i] = true;
        });
      }
    }
    if (!foundLetter) {
      setState(() {
        snowmanParts++;
      });
    }
    if (guessedLetters.every((guessed) => guessed)) {
      _updateUserScore(); // Update score when user wins
      _showDialog('WINNER', 'Congratulations! You won the game.');
    } else if (snowmanParts == 6) {
      _showDialog('SORRY, YOU LOSE', 'Better luck next time.');
    }
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: this.context,
      builder: (BuildContext dialogContext) { // Specify the type explicitly
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(this.context).pop(); // Use dialogContext instead of context
                _resetGame();
              },
              child: Text('Play Again'),
            ),
          ],
        );
      },
    );
  }

  void _resetGame() {
    setState(() {
      snowmanParts = 0;
      gameFinished = false;
      _selectWordAndHint();
      guessedLetters = List.generate(selectedWord.length, (index) => false);
    });
  }

  void _showScoreDialog(int score) {
    showDialog(
      context: this.context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Score'),
          content: Text('Your score is $score'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(this.context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }
}