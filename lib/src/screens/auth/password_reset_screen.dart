import 'package:flutter/material.dart';
// import '../../services/auth_service.dart'; // Will be used for actual logic

class PasswordResetScreen extends StatelessWidget {
  const PasswordResetScreen({super.key});

  // final AuthService _authService = AuthService(); // Example instantiation

  @override
  Widget build(BuildContext context) {
    // final TextEditingController emailController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Password Reset Screen Placeholder',
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 20),
              // Placeholder for email field
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
                child: const Text('Email Field Placeholder'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // String email = emailController.text.trim();
                  // _authService.sendPasswordResetEmail(email)
                  //   .then((_) {
                  //     // Show success message
                  //     ScaffoldMessenger.of(context).showSnackBar(
                  //       const SnackBar(content: Text('Password reset email sent.')),
                  //     );
                  //     Navigator.of(context).pop(); // Go back
                  //   }).catchError((error) {
                  //     // Show error message
                  //   });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Send Reset Email button pressed (UI Placeholder)')),
                  );
                },
                child: const Text('Send Password Reset Email'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Go back
                },
                child: const Text('Back to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
