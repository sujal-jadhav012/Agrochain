import 'package:flutter/material.dart';

class ConsumerDashboardScreen extends StatefulWidget {
  const ConsumerDashboardScreen({super.key});

  @override
  State<ConsumerDashboardScreen> createState() => _ConsumerDashboardScreenState();
}

class _ConsumerDashboardScreenState extends State<ConsumerDashboardScreen> {
  final TextEditingController _qrController = TextEditingController();
  bool isLoading = false;
  Map<String, dynamic>? productData;

  final Map<String, dynamic> mockProducts = {
    'QR001': {
      'name': 'Organic Rice',
      'priceFlow': [25, 28, 35],
      'location': 'Village Karad, Satara',
      'harvestDate': '2025-01-15',
      'quality': 'Premium',
      'status': 'Ready for Sale',
    },
    'QR002': {
      'name': 'Fresh Wheat',
      'priceFlow': [30, 32, 40],
      'location': 'Village Vai, Satara',
      'harvestDate': '2025-01-20',
      'quality': 'Grade A',
      'status': 'Ready for Sale',
    },
  };

  void _traceProduct() async {
    setState(() {
      isLoading = true;
    });

    await Future.delayed(const Duration(seconds: 1));

    final qrCode = _qrController.text.trim().toUpperCase();
    if (mockProducts.containsKey(qrCode)) {
      setState(() {
        productData = mockProducts[qrCode];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product not found. Try QR001 or QR002')),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consumer Dashboard'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: productData == null
            ? _buildScannerSection(context)
            : _buildProductDetails(context),
      ),
    );
  }

  Widget _buildScannerSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          '🔍 Scan QR Code',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        const Text(
          'Scan or upload QR code to trace product journey',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Camera access not available in this demo')),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade600,
            minimumSize: const Size(double.infinity, 50),
          ),
          icon: const Icon(Icons.camera_alt),
          label: const Text('Open Camera Scanner'),
        ),
        const SizedBox(height: 10),
        const Text('OR'),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image upload not implemented in demo')),
            );
          },
          icon: const Icon(Icons.upload),
          label: const Text('Upload QR Code Image'),
          style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
        ),
        const SizedBox(height: 10),
        const Text('OR'),
        const SizedBox(height: 10),
        TextField(
          controller: _qrController,
          decoration: InputDecoration(
            labelText: 'Enter QR Code Manually',
            hintText: 'e.g., QR001',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 15),
        ElevatedButton.icon(
          onPressed: isLoading ? null : _traceProduct,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade700,
            minimumSize: const Size(double.infinity, 50),
          ),
          icon: isLoading
              ? const SizedBox(
                  width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
              : const Icon(Icons.qr_code),
          label: Text(isLoading ? 'Loading...' : 'Trace Product'),
        ),
        const SizedBox(height: 20),
        Card(
          color: Colors.blue.shade50,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Row(
                  children: [
                    Icon(Icons.qr_code, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Try Demo Products',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => _qrController.text = 'QR001',
                  child: const Text('🌾 QR001 - Organic Rice (₹25 → ₹28 → ₹35)'),
                ),
                TextButton(
                  onPressed: () => _qrController.text = 'QR002',
                  child: const Text('🌾 QR002 - Fresh Wheat (₹30 → ₹32 → ₹40)'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductDetails(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          onPressed: () => setState(() => productData = null),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade200,
            foregroundColor: Colors.black87,
          ),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Scan Another QR'),
        ),
        const SizedBox(height: 20),
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(productData!['name'],
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(productData!['location'], style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 4),
                Text(
                    "Harvest Date: ${productData!['harvestDate']} • Quality: ${productData!['quality']}"),
                const SizedBox(height: 10),
                Chip(
                  backgroundColor: Colors.green.shade100,
                  label: Text(productData!['status'],
                      style: const TextStyle(color: Colors.green)),
                ),
                const SizedBox(height: 20),
                Text(
                  "Current Price: ₹${productData!['priceFlow'].last}",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          "💹 Price Evolution",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        for (int i = 0; i < productData!['priceFlow'].length; i++)
          ListTile(
            leading: const Icon(Icons.trending_up, color: Colors.green),
            title: Text("Stage ${i + 1}: ₹${productData!['priceFlow'][i]}"),
          ),
        const SizedBox(height: 30),
        Card(
          color: Colors.green.shade50,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.verified, color: Colors.green),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'This product’s authenticity and supply chain trail has been verified on blockchain.',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
