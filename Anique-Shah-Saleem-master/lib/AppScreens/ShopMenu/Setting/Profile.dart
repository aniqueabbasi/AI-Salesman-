import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  // Controllers for TextFormField
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _passwordVisible = false; // To control password visibility

  // Load saved data when the widget initializes
  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  // Load saved data from SharedPreferences
  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      nameController.text = prefs.getString('name') ?? '';
      emailController.text = prefs.getString('email') ?? '';
      passwordController.text = prefs.getString('password') ?? '';
    });
  }

  // Save data to SharedPreferences
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', nameController.text);
    await prefs.setString('email', emailController.text);
    await prefs.setString('password', passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: const Color.fromARGB(255, 79, 70, 199),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Settings",
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 20),
              ),
              const SizedBox(height: 10),
              const Text(
                "Your Profile",
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 20),

       

              // Admin Panel navigation
              ListTile(
                leading: const Icon(Icons.admin_panel_settings, color: Colors.blueGrey),
                title: const Text('Admin Panel'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Navigator.of(context).pushNamed('/admin'),
              ),

              // Name TextFormField
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Enter your name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 15),

              // Email TextFormField
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Enter your email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 15),

              // Password TextFormField with visibility toggle
              TextFormField(
                controller: passwordController,
                obscureText: !_passwordVisible, // If true, hide the password
                decoration: InputDecoration(
                  labelText: 'Enter your password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _passwordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _passwordVisible = !_passwordVisible;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Save Changes Button
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    // Captured before the await so the success snackbar never
                    // touches a stale BuildContext.
                    final messenger = ScaffoldMessenger.of(context);

                    // Validate fields
                    if (nameController.text.isEmpty ||
                        emailController.text.isEmpty ||
                        passwordController.text.isEmpty) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Please fill in all fields')),
                      );
                      return;
                    }

                    // Save data
                    await _saveData();

                    // Show success message
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Profile updated successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 15), backgroundColor: const Color.fromARGB(255, 79, 70, 199),
                  ),
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
