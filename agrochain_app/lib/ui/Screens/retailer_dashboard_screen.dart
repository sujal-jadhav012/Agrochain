import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

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
  final TextEditingController _productController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _pricePerKgController = TextEditingController();

  // Build dynamic pie data: revenue per product (weight * pricePerKg)
  List<PieChartSectionData> get _dynamicPieData {
    if (purchases.isEmpty) return [];

    // Aggregate revenue per product
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

  // Add purchase: takes product, weight (kg), price per kg (₹)
  void _addPurchase() {
    final product = _productController.text.trim();
    final weightText = _weightController.text.trim();
    final priceText = _pricePerKgController.text.trim();

    if (product.isEmpty || weightText.isEmpty || priceText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Please fill all fields')),
      );
      return;
    }

    final weight = double.tryParse(weightText);
    final pricePerKg = double.tryParse(priceText);

    if (weight == null || pricePerKg == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Enter valid numbers for weight and price')),
      );
      return;
    }

    setState(() {
      purchases.add({
        "product": product,
        "weight": weight,
        "pricePerKg": pricePerKg,
      });

      _productController.clear();
      _weightController.clear();
      _pricePerKgController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Purchase added successfully!')),
    );
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
    _productController.dispose();
    _weightController.dispose();
    _pricePerKgController.dispose();
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

            // Add Purchase Section (Weight kg, Price per kg)
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
                    TextField(
                      controller: _pricePerKgController,
                      decoration: _inputDecoration("Price per kg (₹)"),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _addPurchase,
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
                    )
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
                                DataCell(Text(item["product"])),
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
