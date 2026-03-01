import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(
    title: 'Tasky',
    theme: ThemeData(
      primarySwatch: Colors.blue,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF8F9FA), // Light greyish white background
    ),
    home: SplashScreen(),
    debugShowCheckedModeBanner: false,
  ));
}

// --- 1. ANIMATED SPLASH SCREEN ---
class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(seconds: 2), vsync: this)..repeat(reverse: true);
    _animation = Tween<double>(begin: 0, end: 20).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    Timer(const Duration(seconds: 3), () async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      if (isLoggedIn) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) => Container(
                  padding: EdgeInsets.only(top: _animation.value),
                  child: const Icon(Icons.check_circle, size: 100, color: Color(0xFF0D47A1)) // Deep Blue
              ),
            ),
            const SizedBox(height: 20),
            const Text("Tasky", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1), letterSpacing: 2)),
            const SizedBox(height: 10),
            const CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF1976D2)),
          ],
        ),
      ),
    );
  }
}

// --- 2. USER STORE ---
class UserStore {
  static Future<void> registerUser(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pass_$email', password);
  }

  static Future<String?> getPassword(String email) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('pass_$email');
  }

  static Future<void> setLoginStatus(bool status, {String? email}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', status);
    if (email != null) await prefs.setString('current_user_email', email);
  }
}

// --- 3. SIGNUP SCREEN ---
class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Account"), backgroundColor: const Color(0xFF0D47A1), foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Icon(Icons.person_add_rounded, size: 80, color: Color(0xFF1976D2)),
              const SizedBox(height: 20),
              _buildTextField(_emailController, "Email", Icons.email, false),
              const SizedBox(height: 15),
              _buildTextField(_passController, "Password", Icons.lock, true),
              const SizedBox(height: 15),
              _buildTextField(_confirmPassController, "Confirm Password", Icons.lock_clock, true),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D47A1), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      if (_passController.text != _confirmPassController.text) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Passwords do not match!")));
                        return;
                      }
                      await UserStore.registerUser(_emailController.text, _passController.text);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Account Created!")));
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("SIGN UP", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, bool isPass) {
    return TextFormField(
      controller: controller,
      obscureText: isPass,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF1976D2)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFBBDEFB), width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0D47A1), width: 2)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (v) => v!.isEmpty ? "Required field" : null,
    );
  }
}

// --- 4. FORGOT PASSWORD SCREEN ---
class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _newPassController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Restore Password"), backgroundColor: const Color(0xFF0D47A1), foregroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          children: [
            const Text("Reset your password securely", style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 25),
            TextField(controller: _emailController, decoration: InputDecoration(labelText: "Email", prefixIcon: const Icon(Icons.email), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 15),
            TextField(controller: _newPassController, obscureText: true, decoration: InputDecoration(labelText: "New Password", prefixIcon: const Icon(Icons.vpn_key), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1976D2), foregroundColor: Colors.white),
                  onPressed: () async {
                    String? existing = await UserStore.getPassword(_emailController.text);
                    if (existing != null) {
                      await UserStore.registerUser(_emailController.text, _newPassController.text);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Success! Password updated.")));
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Email not found!")));
                    }
                  }, child: const Text("UPDATE PASSWORD")),
            )
          ],
        ),
      ),
    );
  }
}

// --- 5. LOGIN SCREEN ---
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            children: [
              const Icon(Icons.check_circle_rounded, size: 100, color: Color(0xFF0D47A1)),
              const Text("Tasky", style: TextStyle(fontSize: 45, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
              const SizedBox(height: 40),
              TextField(controller: _emailController, decoration: InputDecoration(labelText: "Email", prefixIcon: const Icon(Icons.person), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFFBBDEFB))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF0D47A1), width: 2)))),
              const SizedBox(height: 15),
              TextField(controller: _passController, obscureText: true, decoration: InputDecoration(labelText: "Password", prefixIcon: const Icon(Icons.lock), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFFBBDEFB))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF0D47A1), width: 2)))),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D47A1), foregroundColor: Colors.white, elevation: 5, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  onPressed: () async {
                    String? saved = await UserStore.getPassword(_emailController.text);
                    if (saved != null && saved == _passController.text) {
                      await UserStore.setLoginStatus(true, email: _emailController.text);
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid login details!")));
                    }
                  },
                  child: const Text("LOGIN", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => ForgotPasswordScreen())), child: const Text("Forgot Password?", style: TextStyle(color: Color(0xFF1976D2)))),
              const Divider(height: 40),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Text("New User?"), TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => SignupScreen())), child: const Text("Create Account", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))))])
            ],
          ),
        ),
      ),
    );
  }
}

// --- 6. HOME SCREEN (Polished UI) ---
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _tasks = [];
  final TextEditingController _controller = TextEditingController();
  String? _currentUserEmail;

  @override
  void initState() {
    super.initState();
    _initUserAndTasks();
  }

  _initUserAndTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() { _currentUserEmail = prefs.getString('current_user_email'); });
    _loadTasks();
  }

  _loadTasks() async {
    if (_currentUserEmail == null) return;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? taskStrings = prefs.getStringList('tasks_$_currentUserEmail');
    if (taskStrings != null) {
      setState(() { _tasks = taskStrings.map((s) => Map<String, dynamic>.from(json.decode(s))).toList(); });
    }
  }

  _saveTasks() async {
    if (_currentUserEmail == null) return;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> taskStrings = _tasks.map((t) => json.encode(t)).toList();
    await prefs.setStringList('tasks_$_currentUserEmail', taskStrings);
  }

  void _addTask() {
    if (_controller.text.isNotEmpty) {
      setState(() { _tasks.add({'title': _controller.text, 'isDone': false}); _controller.clear(); });
      _saveTasks();
    }
  }

  void _toggleTask(int index) {
    setState(() { _tasks[index]['isDone'] = !_tasks[index]['isDone']; });
    _saveTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tasky ", style: TextStyle(fontWeight: FontWeight.w500,fontSize: 25)),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        elevation: 10,
        toolbarHeight: 70,
        actions: [
          IconButton(icon: const Icon(Icons.logout_rounded), onPressed: () async {
            await UserStore.setLoginStatus(false);
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => LoginScreen()));
          })
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
            child: Row(
              children: [
                Expanded(
                    child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: "What's on your mind?",
                          filled: true,
                          fillColor: const Color(0xFFF1F8FE),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFFBBDEFB))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF0D47A1), width: 2)),
                        )
                    )
                ),
                const SizedBox(width: 10),
                FloatingActionButton(
                    onPressed: _addTask,
                    backgroundColor: const Color(0xFF0D47A1),
                    mini: true,
                    child: const Icon(Icons.add, color: Colors.white)
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 15),
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                final task = _tasks[index];
                bool isDone = task['isDone'];
                return Dismissible(
                  key: UniqueKey(),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 25),
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
                    decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(15)),
                    child: const Icon(Icons.delete_sweep, color: Colors.white, size: 30),
                  ),
                  onDismissed: (_) { setState(() { _tasks.removeAt(index); }); _saveTasks(); },
                  child: Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                      leading: Checkbox(
                          value: isDone,
                          activeColor: const Color(0xFF1976D2),
                          shape: const CircleBorder(),
                          onChanged: (val) => _toggleTask(index)
                      ),
                      title: Text(
                          task['title'],
                          style: TextStyle(
                            fontSize: 17,
                            decoration: isDone ? TextDecoration.lineThrough : TextDecoration.none,
                            color: isDone ? Colors.grey : const Color(0xFF263238),
                            fontWeight: isDone ? FontWeight.normal : FontWeight.w500,
                          )
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}