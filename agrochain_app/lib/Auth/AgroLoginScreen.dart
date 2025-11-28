// import 'package:flutter/material.dart';

// // Define your color constants
// const kBackgroundColor = Color(0xFFF5F5F5);
// const kPrimaryGreen = Color(0xFF2E7D32);

// class AgroLoginScreen extends StatelessWidget {
//   final String? role; // ✅ Optional role parameter added

//   const AgroLoginScreen({super.key, this.role});

//   @override
//   Widget build(BuildContext context) {
//     // ✅ Prefer constructor role, fallback to route arguments, else default to 'User'
//     final String effectiveRole =
//         role ?? (ModalRoute.of(context)?.settings.arguments as String?) ?? 'User';

//     final screenHeight = MediaQuery.of(context).size.height;

//     // ✅ Auto redirect if role == Consumer
//     if (effectiveRole.toLowerCase() == 'consumer') {
//       Future.microtask(() {
//         Navigator.pushReplacementNamed(context, '/consumerDashboard');
//       });
//       return const Scaffold(
//         backgroundColor: kBackgroundColor,
//         body: Center(
//           child: CircularProgressIndicator(color: kPrimaryGreen),
//         ),
//       );
//     }

//     // ✅ Show login screen for other roles only
//     return Scaffold(
//       backgroundColor: kBackgroundColor,
//       body: SingleChildScrollView(
//         child: Container(
//           height: screenHeight,
//           padding: const EdgeInsets.all(30.0),
//           decoration: const BoxDecoration(
//             gradient: LinearGradient(
//               colors: [kBackgroundColor, Color(0xFFE0E0E0)],
//               begin: Alignment.topCenter,
//               end: Alignment.bottomCenter,
//             ),
//           ),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: <Widget>[
//               SizedBox(height: screenHeight * 0.05),

//               const Icon(Icons.account_tree_outlined,
//                   color: kPrimaryGreen, size: 80.0),
//               const SizedBox(height: 10),

//               Text(
//                 '$effectiveRole Login',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   fontSize: 26,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.green[800],
//                 ),
//               ),
//               const SizedBox(height: 8),
//               const Text(
//                 'Access your secure AgroChain account',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(fontSize: 14, color: Colors.grey),
//               ),
//               const SizedBox(height: 40),

//               _AgroTextField(
//                 label: '$effectiveRole ID or Email',
//                 icon: Icons.person_outline,
//                 keyboardType: TextInputType.emailAddress,
//               ),
//               const SizedBox(height: 20),
//               const _AgroTextField(
//                 label: 'Password',
//                 icon: Icons.lock_outline,
//                 obscureText: true,
//               ),
//               const SizedBox(height: 10),

//               Align(
//                 alignment: Alignment.centerRight,
//                 child: TextButton(
//                   onPressed: () {},
//                   child: const Text(
//                     'Forgot Password?',
//                     style: TextStyle(color: kPrimaryGreen),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 30),

//               SizedBox(
//                 height: 50,
//                 child: ElevatedButton(
//                   onPressed: () {
//                     print('Logging in as $effectiveRole...');

//                     // ✅ Role-based Navigation
//                     switch (effectiveRole.toLowerCase()) {
//                       case 'farmer':
//                         Navigator.pushReplacementNamed(
//                             context, '/farmerDashboard');
//                         break;
//                       case 'distributor':
//                         Navigator.pushReplacementNamed(
//                             context, '/distributorDashboard');
//                         break;
//                       case 'retailer':
//                         Navigator.pushReplacementNamed(
//                             context, '/retailerDashboard');
//                         break;
//                       default:
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           SnackBar(
//                             content: Text(
//                                 'Login for $effectiveRole not implemented yet'),
//                           ),
//                         );
//                     }
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: kPrimaryGreen,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                   ),
//                   child: Text(
//                     'LOGIN AS $effectiveRole',
//                     style: const TextStyle(
//                       fontSize: 18,
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ),

//               const SizedBox(height: 20),

//               // ✅ Sign Up section
//               Center(
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Text(
//                       "Don't have an account? ",
//                       style: TextStyle(color: Colors.grey),
//                     ),
//                     GestureDetector(
//                       onTap: () {
//                         Navigator.pushNamed(
//                           context,
//                           '/signup',
//                           arguments: {'role': effectiveRole},
//                         );
//                       },
//                       child: const Text(
//                         "Sign Up",
//                         style: TextStyle(
//                           color: kPrimaryGreen,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// /// Custom text field widget
// class _AgroTextField extends StatelessWidget {
//   final String label;
//   final IconData icon;
//   final bool obscureText;
//   final TextInputType? keyboardType;

//   const _AgroTextField({
//     required this.label,
//     required this.icon,
//     this.obscureText = false,
//     this.keyboardType,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return TextField(
//       obscureText: obscureText,
//       keyboardType: keyboardType,
//       decoration: InputDecoration(
//         labelText: label,
//         prefixIcon: Icon(icon, color: kPrimaryGreen),
//         filled: true,
//         fillColor: Colors.white,
//         contentPadding:
//             const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: const BorderSide(color: kPrimaryGreen),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: const BorderSide(color: kPrimaryGreen, width: 2),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

const kBackgroundColor = Color(0xFFF5F5F5);
const kPrimaryGreen = Color(0xFF2E7D32);

class AgroLoginScreen extends StatefulWidget {
  final String? role;

  const AgroLoginScreen({super.key, this.role});

  @override
  State<AgroLoginScreen> createState() => _AgroLoginScreenState();
}

class _AgroLoginScreenState extends State<AgroLoginScreen> {
  late FirebaseAuth _auth;

  @override
  void initState() {
    super.initState();
    _auth = FirebaseAuth.instance;
  }

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final String effectiveRole =
        widget.role ??
        (ModalRoute.of(context)?.settings.arguments as String?) ??
        'User';
    final screenHeight = MediaQuery.of(context).size.height;

    if (effectiveRole.toLowerCase() == 'consumer') {
      Future.microtask(() {
        Navigator.pushReplacementNamed(context, '/consumerDashboard');
      });
      return const Scaffold(
        backgroundColor: kBackgroundColor,
        body: Center(child: CircularProgressIndicator(color: kPrimaryGreen)),
      );
    }

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SingleChildScrollView(
        child: Container(
          height: screenHeight,
          padding: const EdgeInsets.all(30.0),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [kBackgroundColor, Color(0xFFE0E0E0)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Icon(
                Icons.account_tree_outlined,
                color: kPrimaryGreen,
                size: 80.0,
              ),
              const SizedBox(height: 10),

              Text(
                '$effectiveRole Login',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Access your secure AgroChain account',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 40),

              _AgroTextField(
                controller: _emailController,
                label: '$effectiveRole Email',
                icon: Icons.person_outline,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              _AgroTextField(
                controller: _passwordController,
                label: 'Password',
                icon: Icons.lock_outline,
                obscureText: true,
              ),
              const SizedBox(height: 10),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(color: kPrimaryGreen),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: kPrimaryGreen),
                    )
                  : SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => _loginUser(effectiveRole),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'LOGIN AS $effectiveRole',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
              const SizedBox(height: 20),

              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account? ",
                      style: TextStyle(color: Colors.grey),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/signup',
                          arguments: {'role': effectiveRole},
                        );
                      },
                      child: const Text(
                        "Sign Up",
                        style: TextStyle(
                          color: kPrimaryGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loginUser(String role) async {
    setState(() => _isLoading = true);
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Login Successful')));

      switch (role.toLowerCase()) {
        case 'farmer':
          Navigator.pushReplacementNamed(context, '/farmerDashboard');
          break;
        case 'distributor':
          Navigator.pushReplacementNamed(context, '/distributorDashboard');
          break;
        case 'retailer':
          Navigator.pushReplacementNamed(context, '/retailerDashboard');
          break;
        default:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No dashboard for role: $role')),
          );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? 'Login failed')));
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

class _AgroTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;

  const _AgroTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: kPrimaryGreen),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kPrimaryGreen),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kPrimaryGreen, width: 2),
        ),
      ),
    );
  }
}
