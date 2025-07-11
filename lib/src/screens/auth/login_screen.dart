import 'package:flutter/material.dart';
import 'package:school_management_system/src/services/auth_service.dart';
import 'registration_screen.dart'; // For Institution Admin registration
import 'password_reset_screen.dart'; // For password reset

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _loginIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailControllerForAdmin = TextEditingController();


  bool _isLoading = false;
  bool _isSuperAdminLogin = false; // Toggle for Super Admin email login

  Future<void> _loginUser() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      if (_isSuperAdminLogin) {
        await _authService.signInWithEmailPassword(
          _emailControllerForAdmin.text.trim(),
          _passwordController.text.trim(),
        );
      } else {
        await _authService.signInWithCustomIdPassword(
          _loginIdController.text.trim(),
          _passwordController.text.trim(),
        );
      }
      // Navigation is handled by AuthWrapper on successful login
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login Failed: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _loginIdController.dispose();
    _passwordController.dispose();
    _emailControllerForAdmin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _isSuperAdminLogin = !_isSuperAdminLogin;
              });
            },
            child: Text(
              _isSuperAdminLogin ? 'User Login' : 'Super Admin Login',
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
            ),
          )
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  _isSuperAdminLogin ? 'Super Admin Login' : 'School Portal Login',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 30),
                if (_isSuperAdminLogin)
                  TextFormField(
                    controller: _emailControllerForAdmin,
                    decoration: const InputDecoration(labelText: 'Admin Email', border: OutlineInputBorder()),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) => value == null || value.isEmpty || !value.contains('@') ? 'Enter a valid email' : null,
                  )
                else
                  TextFormField(
                    controller: _loginIdController,
                    decoration: const InputDecoration(labelText: 'Login ID (e.g., Student/Staff ID)', border: OutlineInputBorder()),
                    validator: (value) => value == null || value.isEmpty ? 'Login ID is required' : null,
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                  obscureText: true,
                  validator: (value) => value == null || value.isEmpty ? 'Password is required' : null,
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _loginUser,
                        style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                        child: const Text('Login'),
                      ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _isLoading ? null : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PasswordResetScreen()),
                    );
                  },
                  child: const Text('Forgot Password?'),
                ),
                if (!_isSuperAdminLogin) // Institution Admin Registration only for non-SuperAdmin login view
                  TextButton(
                    onPressed: _isLoading ? null : () {
                       Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegistrationScreen()), // For Institution Admin
                      );
                    },
                    child: const Text('Institution Admin? Register Here'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
