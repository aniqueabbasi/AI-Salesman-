import 'package:flutter/material.dart';
import 'package:prac/AppScreens/Seller/SellerDashboard.dart';
import 'package:prac/Authentication/SignUp.dart';
import 'package:prac/services/api_service.dart';
import 'package:prac/services/auth_service.dart';
import 'ResetPassword.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final navigator = Navigator.of(context);

    try {
      // ApiService.login stores the token and role for us.
      await ApiService.login(
          _emailController.text.trim(), _passwordController.text);

      if (await AuthService.isSeller()) {
        // Sellers get their own home screen instead of the storefront.
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SellerDashboard()),
          (route) => false,
        );
      } else {
        // Customers return to whatever sent them here (e.g. checkout).
        navigator.pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox(
        height: MediaQuery.of(context).size.height, // Full height of the screen
        width: MediaQuery.of(context).size.width, // Full width of the screen
        child: Stack(
          children: [
            // Background Image

            Positioned.fill(
              child: Image.asset(
                'assets/images/bk9.jpg', // Replace with your background image path
                fit: BoxFit.cover, // Ensures the image covers the whole screen
              ),
            ),

            // Content on top of the background
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    height: 120,
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 20),
                    child: Text(
                      "Login",
                      style:
                          TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 22),
                    child: Text(
                      'Good to see you back!',
                      style: TextStyle(color: Colors.black54, fontSize: 17),
                    ),
                  ),
                  const SizedBox(
                    height: 40,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        hintText: "Email",
                        hintStyle: const TextStyle(color: Colors.white),
                        filled: true,
                        fillColor: Colors.black,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: "Password",
                        hintStyle: const TextStyle(color: Colors.white),
                        filled: true,
                        fillColor: Colors.black,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  const SizedBox(
                    height: 30,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28)),
                          backgroundColor: const Color.fromARGB(255, 94, 50, 251),
                          minimumSize: const Size(420, 50)),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Login",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white70),
                            ),
                    ),
                  ),
                  const SizedBox(
                    height: 40,
                  ),
                  Center(
                      child: InkWell(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const ResetPassword()));
                          },
                          child: const Text(
                            'Forgot your password',
                            style:
                                TextStyle(color: Colors.black54, fontSize: 17),
                          ))),
                  const SizedBox(
                    height: 15,
                  ),
                  Center(
                      child: InkWell(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const SignUp()));
                          },
                          child: const Text(
                            'Create an Account',
                            style:
                                TextStyle(color: Colors.black54, fontSize: 17),
                          ))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
