import 'package:flutter/material.dart';

// --- Reuse AgroChain theme colors ---
const kPrimaryGreen = Color(0xFF2E7D32);
const kAccentColor = Color(0xFF8BC34A);
const kBackgroundColor = Color(0xFFF5F5F5);

class FarmerDashboardScreen extends StatelessWidget {
  const FarmerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Farmer Dashboard'),
        backgroundColor: kPrimaryGreen,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.popUntil(context, ModalRoute.withName('/role'));
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          children: [
            _DashboardCard(
              title: 'Add Crops',
              icon: Icons.add_circle_outline,
              color: Colors.green[700]!,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddCropPage()),
                );
              },
            ),
            _DashboardCard(
              title: 'Register Batch',
              icon: Icons.qr_code_2,
              color: Colors.teal[700]!,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RegisterBatchPage()),
                );
              },
            ),
            _DashboardCard(
              title: 'Generate QR',
              icon: Icons.qr_code,
              color: Colors.blue[700]!,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GenerateQRPage()),
                );
              },
            ),
            _DashboardCard(
              title: 'My Products',
              icon: Icons.inventory_2_outlined,
              color: Colors.orange[700]!,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FarmerProductsPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Reusable dashboard card widget
class _DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: color),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ----------------------
/// Sub Screens (Basic placeholders)
/// ----------------------

class AddCropPage extends StatelessWidget {
  const AddCropPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Crop'), backgroundColor: kPrimaryGreen),
      body: const Center(child: Text('Crop adding form goes here 🌱')),
    );
  }
}

class RegisterBatchPage extends StatelessWidget {
  const RegisterBatchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Product Batch'), backgroundColor: kPrimaryGreen),
      body: const Center(child: Text('Batch registration form goes here 📦')),
    );
  }
}

class GenerateQRPage extends StatelessWidget {
  const GenerateQRPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generate QR Code'), backgroundColor: kPrimaryGreen),
      body: const Center(child: Text('QR generation tool goes here 🔗')),
    );
  }
}

class FarmerProductsPage extends StatelessWidget {
  const FarmerProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Products'), backgroundColor: kPrimaryGreen),
      body: const Center(child: Text('Your registered crops and batches 🌾')),
    );
  }
}
