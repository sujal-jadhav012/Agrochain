import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RetailerDashboardScreen extends StatefulWidget {
  const RetailerDashboardScreen({super.key});

  @override
  State<RetailerDashboardScreen> createState() =>
      _RetailerDashboardScreenState();
}

class _RetailerDashboardScreenState extends State<RetailerDashboardScreen> {
  bool isBlockchainConnected = false;

  // Use weight (kg) and pricePerKg (₹) for each purchase
  final List<Map<String, dynamic>> purchases = [
    {"product": "Fertilizer", "weight": 50.0, "pricePerKg": 100.0},
    {"product": "Seeds", "weight": 30.0, "pricePerKg": 100.0},
    {"product": "Pesticides", "weight": 20.0, "pricePerKg": 100.0},
  ];

  // Controllers for adding purchase
  final TextEditingController _produceIdController = TextEditingController(); // optional
  final TextEditingController _productController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  // Retailer margin controller (per kg)
  final TextEditingController _marginController = TextEditingController();

  // Firestore + Auth
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _loading = false; // for fetch and add actions

  // State for fetched produce pricing
  double? _fetchedFarmerPricePerKg;
  double _fetchedDistributorTotal = 0.0; // total distributor charges (INR)
  double? _baseRetailPricePerKg; // computed farmer + distributor-per-kg

  // Build dynamic pie data: revenue per product (weight * pricePerKg)
  List<PieChartSectionData> get _dynamicPieData {
    if (purchases.isEmpty) return [];

    final Map<String, double> revenueTotals = {};
    for (var item in purchases) {
      final product = item['product'] as String;
      final weight = (item['weight'] as num).toDouble();
      final pricePerKg = (item['pricePerKg'] as num).toDouble();
      final revenue = weight * pricePerKg;
      revenueTotals[product] = (revenueTotals[product] ?? 0) + revenue;
    }

    final double totalRevenue =
        revenueTotals.values.fold(0.0, (s, v) => s + v).toDouble();
    final colors = [
      Colors.greenAccent,
      Colors.teal,
      Colors.lightGreen,
      Colors.orangeAccent,
      Colors.blueAccent,
      Colors.purpleAccent,
    ];

    int i = 0;
    return revenueTotals.entries.map((e) {
      final percent =
          totalRevenue > 0 ? (e.value / totalRevenue * 100).toStringAsFixed(1) : '0';
      final section = PieChartSectionData(
        value: e.value,
        title: '${e.key}\n$percent%',
        color: colors[i % colors.length],
        radius: 60,
        titleStyle: const TextStyle(
          color: Colors.black87,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      );
      i++;
      return section;
    }).toList();
  }

  // -------------------------
  // Fetch produce and compute base retail price = farmerPrice + distributorCharges/qty
  // -------------------------
  Future<void> _fetchProduceById(String id) async {
    if (id.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter Produce ID')));
      return;
    }

    setState(() {
      _loading = true;
      _fetchedFarmerPricePerKg = null;
      _fetchedDistributorTotal = 0.0;
      _baseRetailPricePerKg = null;
    });

    try {
      final docRef = _firestore.collection('produces').doc(id.trim());
      final doc = await docRef.get();

      if (!doc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Produce not found')));
        setState(() => _loading = false);
        return;
      }

      final data = doc.data()!;
      final name = data['produceType'] ?? '';
      final quantity = (data['quantity'] is num) ? (data['quantity'] as num).toDouble() : double.tryParse(data['quantity']?.toString() ?? '0') ?? 0.0;
      final farmerPrice = (data['pricePerKg'] is num) ? (data['pricePerKg'] as num).toDouble() : double.tryParse(data['pricePerKg']?.toString() ?? '0') ?? 0.0;

      // Sum distributor charges
      double distributorTotal = 0.0;
      final distEntriesSnap = await docRef
          .collection('addedCharges')
          .doc('distributor')
          .collection('entries')
          .get();

      for (var d in distEntriesSnap.docs) {
        final t = d.data()['total'];
        if (t is num) {
          distributorTotal += (t).toDouble();
        } else if (t is String) distributorTotal += double.tryParse(t) ?? 0.0;
      }

      // Compute distributor per-kg (safe divide)
      final distributorPerKg = (quantity > 0) ? (distributorTotal / quantity) : 0.0;
      final baseRetail = farmerPrice + distributorPerKg;

      setState(() {
        _productController.text = name.toString();
        _weightController.text = quantity.toString();
        _fetchedFarmerPricePerKg = farmerPrice;
        _fetchedDistributorTotal = distributorTotal;
        _baseRetailPricePerKg = baseRetail;
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Produce data loaded')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching produce: $e')));
    }

    setState(() => _loading = false);
  }

  // -------------------------
  // Add purchase: compute finalPricePerKg = baseRetailPricePerKg + retailerMargin
  // then write retailer margin entry + event + update produce currentHolder/status
  // -------------------------
  Future<void> _addPurchase() async {
    final product = _productController.text.trim();
    final weightText = _weightController.text.trim();

    if (product.isEmpty || weightText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Please fill product & weight (or fetch produce)')),
      );
      return;
    }

    final weight = double.tryParse(weightText);
    if (weight == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Enter valid number for weight')),
      );
      return;
    }

    final prodId = _produceIdController.text.trim().isEmpty ? null : _produceIdController.text.trim();

    // Retailer margin per kg required
    final margin = double.tryParse(_marginController.text.trim()) ?? 0.0;

    if (prodId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide Produce ID to compute price automatically')));
      return;
    }

    if (_baseRetailPricePerKg == null || _fetchedFarmerPricePerKg == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fetch produce first to compute price')));
      return;
    }

    final finalPricePerKg = _baseRetailPricePerKg! + margin;
    final totalMarginAmount = margin * weight;

    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sign in first')));
      return;
    }

    setState(() => _loading = true);

    final docRef = _firestore.collection('produces').doc(prodId);

    try {
      await _firestore.runTransaction((txn) async {
        final snap = await txn.get(docRef);
        if (!snap.exists) throw Exception('Produce not found');

        // Update produce holder/status
        txn.update(docRef, {
          'currentHolder': {'role': 'retailer', 'id': user.uid, 'name': user.displayName ?? 'Retailer'},
          'status': 'with_retailer',
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        // Add retailer margin entry: produces/{id}/addedCharges/retailer/entries/{id}
        final chargesRef = docRef
            .collection('addedCharges')
            .doc('retailer')
            .collection('entries')
            .doc();

        txn.set(chargesRef, {
          'retailerMarginPerKg': margin,
          'total': totalMarginAmount,
          'actorId': user.uid,
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Add event
        final eventRef = docRef.collection('events').doc();
        txn.set(eventRef, {
          'actorId': user.uid,
          'actorRole': 'retailer',
          'action': 'received',
          'retailerMarginPerKg': margin,
          'finalPricePerKg': finalPricePerKg,
          'notes': 'Received by retailer',
          'timestamp': FieldValue.serverTimestamp(),
        });
      });

      // Add to local purchases (used for chart & totals)
      setState(() {
        purchases.add({
          'product': product,
          'weight': weight,
          'pricePerKg': finalPricePerKg,
        });

        // clear form fields
        _productController.clear();
        _weightController.clear();
        _produceIdController.clear();
        _marginController.clear();
        _fetchedFarmerPricePerKg = null;
        _fetchedDistributorTotal = 0.0;
        _baseRetailPricePerKg = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Purchase added and retailer update saved')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving retailer update: $e')));
    }

    setState(() => _loading = false);
  }

  double _calculateTotalSales() {
    return purchases.fold(0.0, (sum, item) {
      final weight = (item['weight'] as num).toDouble();
      final price = (item['pricePerKg'] as num).toDouble();
      return sum + (weight * price);
    }).toDouble();
  }

  double _calculateTotalWeight() {
    return purchases.fold(0.0, (sum, item) => sum + (item['weight'] as num).toDouble())
        .toDouble();
  }

  @override
  void dispose() {
    _produceIdController.dispose();
    _productController.dispose();
    _weightController.dispose();
    _marginController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          "Retailer Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black87),
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Blockchain connection toggle (mock)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.circle,
                      color: isBlockchainConnected ? Colors.green : Colors.red,
                      size: 12,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isBlockchainConnected
                          ? "Blockchain: Connected"
                          : "Blockchain: Disconnected",
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      isBlockchainConnected = !isBlockchainConnected;
                    });
                  },
                  icon: const Icon(Icons.link),
                  label: Text(isBlockchainConnected ? "Disconnect" : "Connect Wallet"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 20),

            // Summary Cards: Total Products, Total Weight, Total Sales
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatCard("Total Products", "${purchases.length}",
                    Icons.store, Colors.green),
                _buildStatCard("Total Weight", "${_calculateTotalWeight().toStringAsFixed(1)} kg",
                    Icons.scale, Colors.teal),
                _buildStatCard("Total Sales", "₹${_calculateTotalSales().toStringAsFixed(2)}",
                    Icons.attach_money, Colors.orange),
              ],
            ),
            const SizedBox(height: 24),

            // Add Purchase Section
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      "Add Purchase",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 16),

                    // Produce ID + Fetch
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _produceIdController,
                            decoration: _inputDecoration("Produce ID (required for auto price)"),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _loading ? null : () => _fetchProduceById(_produceIdController.text.trim()),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          child: _loading ? const SizedBox(width:18,height:18,child:CircularProgressIndicator(color:Colors.white,strokeWidth:2)) : const Text("Fetch"),
                        )
                      ],
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: _productController,
                      decoration: _inputDecoration("Product Name"),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _weightController,
                      decoration: _inputDecoration("Weight (kg)"),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 10),

                    // Retailer Margin per kg (new)
                    TextField(
                      controller: _marginController,
                      decoration: _inputDecoration("Retailer Margin (₹ per kg)"),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),

                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loading ? null : () => _addPurchase(),
                      icon: const Icon(Icons.add),
                      label: const Text("Add Purchase"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    if (_baseRetailPricePerKg != null)
                      Text(
                        'Base (Farmer + Distributor/ kg): ₹${_baseRetailPricePerKg!.toStringAsFixed(2)} (Distributor total ₹${_fetchedDistributorTotal.toStringAsFixed(2)})',
                        style: const TextStyle(color: Colors.black54),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Dynamic Pie Chart: Revenue Distribution
            _buildChartCard(
              "Revenue Distribution",
              PieChart(
                PieChartData(
                  sections: _dynamicPieData,
                  centerSpaceRadius: 40,
                  sectionsSpace: 3,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Purchase History Table
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Purchase History",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor:
                            WidgetStateProperty.all(Colors.green.withOpacity(0.1)),
                        columns: const [
                          DataColumn(label: Text("Product")),
                          DataColumn(label: Text("Weight (kg)")),
                          DataColumn(label: Text("Price/ kg (₹)")),
                          DataColumn(label: Text("Total (₹)")),
                        ],
                        rows: purchases
                            .map((item) {
                              final weight = (item['weight'] as num).toDouble();
                              final pricePerKg = (item['pricePerKg'] as num).toDouble();
                              final total = weight * pricePerKg;
                              return DataRow(cells: [
                                DataCell(Text(item["product"].toString())),
                                DataCell(Text(weight.toStringAsFixed(2))),
                                DataCell(Text(pricePerKg.toStringAsFixed(2))),
                                DataCell(Text(total.toStringAsFixed(2))),
                              ]);
                            })
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper UI components
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 6),
              Text(title,
                  style: const TextStyle(color: Colors.black54, fontSize: 14)),
              Text(value,
                  style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartCard(String title, Widget chart) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black87)),
            const SizedBox(height: 12),
            SizedBox(height: 200, child: chart),
          ],
        ),
      ),
    );
  }
}

