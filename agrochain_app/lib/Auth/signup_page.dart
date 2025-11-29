// import 'package:flutter/material.dart';

// const kPrimaryGreen = Color(0xFF2E7D32);
// const kBackgroundColor = Color(0xFFF5F5F5);

// class AgroSignupScreen extends StatefulWidget {
//   final String? role; // ✅ made optional so it can read from route arguments too

//   const AgroSignupScreen({super.key, this.role});

//   @override
//   State<AgroSignupScreen> createState() => _AgroSignupScreenState();
// }

// class _AgroSignupScreenState extends State<AgroSignupScreen> {
//   final _formKey = GlobalKey<FormState>();

//   final Map<String, TextEditingController> _controllers = {
//     'name': TextEditingController(),
//     'email': TextEditingController(),
//     'password': TextEditingController(),
//     'mobile': TextEditingController(),
//     'village': TextEditingController(),
//     'state': TextEditingController(),
//     'district': TextEditingController(),
//     'farmArea': TextEditingController(),
//     'warehouseLocation': TextEditingController(),
//     'shopName': TextEditingController(),
//     'shopAddress': TextEditingController(),
//   };

//   @override
//   void dispose() {
//     for (var c in _controllers.values) {
//       c.dispose();
//     }
//     super.dispose();
//   }

//   void _handleSignup(String role) {
//     if (_formKey.currentState!.validate()) {
//       final data = _controllers.map((key, value) => MapEntry(key, value.text));
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Signup successful!')),
//       );

//       // ✅ Navigate to dashboard depending on role
//       if (role.toLowerCase() == 'farmer') {
//         Navigator.pushReplacementNamed(context, '/farmerDashboard');
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Dashboard for $role not implemented yet')),
//         );
//       }
//     }
//   }

//   List<Widget> _buildRoleSpecificFields(String role) {
//     switch (role.toLowerCase()) {
//       case 'farmer':
//         return [
//           _buildField('village', 'Village'),
//           _buildField('state', 'State'),
//           _buildField('district', 'District'),
//           _buildField('farmArea', 'Area of Farm (acres)', inputType: TextInputType.number),
//         ];
//       case 'distributor':
//         return [
//           _buildField('warehouseLocation', 'Warehouse Address'),
//           _buildField('state', 'State'),
//         ];
//       case 'retailer':
//         return [
//           _buildField('shopName', 'Shop Name'),
//           _buildField('shopAddress', 'Shop Address'),
//           _buildField('state', 'State'),
//         ];
//       default:
//         return [];
//     }
//   }

//   Widget _buildField(
//     String key,
//     String label, {
//     bool obscure = false,
//     TextInputType inputType = TextInputType.text,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12.0),
//       child: TextFormField(
//         controller: _controllers[key],
//         obscureText: obscure,
//         keyboardType: inputType,
//         decoration: InputDecoration(
//           labelText: label,
//           prefixIcon: const Icon(Icons.edit, color: kPrimaryGreen),
//           filled: true,
//           fillColor: Colors.white,
//           border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
//         ),
//         validator: (val) => val == null || val.isEmpty ? 'Enter $label' : null,
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     // ✅ Get role from navigation argument (fallback to widget.role or 'User')
//     final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
//     final String role = args?['role'] ?? widget.role ?? 'User';

//     return Scaffold(
//       backgroundColor: kBackgroundColor,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.black87),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: Text(
//           'Signup as ${role[0].toUpperCase()}${role.substring(1)}',
//           style: const TextStyle(color: Colors.black87),
//         ),
//         centerTitle: true,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(20.0),
//         child: Card(
//           elevation: 3,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//           child: Padding(
//             padding: const EdgeInsets.all(20.0),
//             child: Form(
//               key: _formKey,
//               child: Column(
//                 children: [
//                   _buildField('name', 'Name'),
//                   _buildField('mobile', 'Mobile Number', inputType: TextInputType.phone),
//                   _buildField('email', 'Email', inputType: TextInputType.emailAddress),
//                   _buildField('password', 'Password', obscure: true),
//                   ..._buildRoleSpecificFields(role),
//                   const SizedBox(height: 20),
//                   ElevatedButton(
//                     onPressed: () => _handleSignup(role),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: kPrimaryGreen,
//                       padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 40),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                     ),
//                     child: const Text(
//                       'Continue',
//                       style: TextStyle(fontSize: 16, color: Colors.white),
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//                   TextButton(
//                     onPressed: () => Navigator.pushReplacementNamed(
//                       context,
//                       '/login',
//                       arguments: role, // ✅ passes back the same role
//                     ),
//                     child: const Text(
//                       "Already have an account? Login",
//                       style: TextStyle(color: kPrimaryGreen),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const kPrimaryGreen = Color(0xFF2E7D32);
const kBackgroundColor = Color(0xFFF5F5F5);

class AgroSignupScreen extends StatefulWidget {
  final String? role;

  const AgroSignupScreen({super.key, this.role});

  @override
  State<AgroSignupScreen> createState() => _AgroSignupScreenState();
}

class _AgroSignupScreenState extends State<AgroSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final Map<String, TextEditingController> _controllers = {
    'name': TextEditingController(),
    'email': TextEditingController(),
    'password': TextEditingController(),
    'mobile': TextEditingController(),
    'village': TextEditingController(),
    'state': TextEditingController(),
    'district': TextEditingController(),
    'farmArea': TextEditingController(),
    'warehouseLocation': TextEditingController(),
    'shopName': TextEditingController(),
    'shopAddress': TextEditingController(),
  };

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _handleSignup(String role) async {
    if (!_formKey.currentState!.validate()) return;

    // Normalize role
    final String roleLower = role.trim().toLowerCase();

    setState(() => _isLoading = true);
    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _controllers['email']!.text.trim(),
        password: _controllers['password']!.text.trim(),
      );

      final user = credential.user;
      if (user == null) throw Exception('User creation failed');

      final data = {
        'uid': user.uid,
        'name': _controllers['name']!.text.trim(),
        'email': _controllers['email']!.text.trim(),
        'mobile': _controllers['mobile']!.text.trim(),
        'role': roleLower,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (roleLower == 'farmer') {
        data.addAll({
          'village': _controllers['village']!.text.trim(),
          'state': _controllers['state']!.text.trim(),
          'district': _controllers['district']!.text.trim(),
          'farmArea': _controllers['farmArea']!.text.trim(),
        });
      } else if (roleLower == 'distributor') {
        data.addAll({
          'warehouseLocation': _controllers['warehouseLocation']!.text.trim(),
          'state': _controllers['state']!.text.trim(),
        });
      } else if (roleLower == 'retailer') {
        data.addAll({
          'shopName': _controllers['shopName']!.text.trim(),
          'shopAddress': _controllers['shopAddress']!.text.trim(),
          'state': _controllers['state']!.text.trim(),
        });
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(data);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signup successful!')),
      );

      switch (roleLower) {
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
          Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildField(String key, String label,
      {bool obscure = false, TextInputType inputType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: _controllers[key],
        obscureText: obscure,
        keyboardType: inputType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.edit, color: kPrimaryGreen),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator: (val) => val == null || val.isEmpty ? 'Enter $label' : null,
      ),
    );
  }

  List<Widget> _buildRoleSpecificFields(String role) {
    switch (role.toLowerCase()) {
      case 'farmer':
        return [
          _buildField('village', 'Village'),
          _buildField('state', 'State'),
          _buildField('district', 'District'),
          _buildField('farmArea', 'Area of Farm (acres)', inputType: TextInputType.number),
        ];
      case 'distributor':
        return [
          _buildField('warehouseLocation', 'Warehouse Address'),
          _buildField('state', 'State'),
        ];
      case 'retailer':
        return [
          _buildField('shopName', 'Shop Name'),
          _buildField('shopAddress', 'Shop Address'),
          _buildField('state', 'State'),
        ];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final String role = args?['role'] ?? widget.role ?? 'User';

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Signup as ${role[0].toUpperCase()}${role.substring(1)}',
          style: const TextStyle(color: Colors.black87),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),   // ✅ FIXED
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildField('name', 'Name'),
                  _buildField('mobile', 'Mobile Number', inputType: TextInputType.phone),
                  _buildField('email', 'Email', inputType: TextInputType.emailAddress),
                  _buildField('password', 'Password', obscure: true),
                  ..._buildRoleSpecificFields(role),
                  const SizedBox(height: 20),
                  _isLoading
                      ? const CircularProgressIndicator(color: kPrimaryGreen)
                      : ElevatedButton(
                          onPressed: () => _handleSignup(role),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryGreen,
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 40),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Continue',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pushReplacementNamed(
                      context,
                      '/login',
                      arguments: role,
                    ),
                    child: const Text(
                      "Already have an account? Login",
                      style: TextStyle(color: kPrimaryGreen),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
