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

  final List<Map<String, dynamic>> purchases = [
    {"product": "Fertilizer", "quantity": 50, "price": 5000},
    {"product": "Seeds", "quantity": 30, "price": 3000},
    {"product": "Pesticides", "quantity": 20, "price": 2000},
  ];

  // ✅ Controllers for adding purchase
  final TextEditingController _productController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  // ✅ Compute dynamic pie chart data based on purchases
  List<PieChartSectionData> get _dynamicPieData {
    if (purchases.isEmpty) return [];

    // Aggregate total price per product type
    Map<String, double> totals = {};
    for (var item in purchases) {
      String product = item['product'];
      double price = (item['price'] as num).toDouble();
      totals[product] = (totals[product] ?? 0) + price;
    }

    double total = totals.values.fold(0, (sum, v) => sum + v);
    final List<Color> colors = [
      Colors.greenAccent,
      Colors.teal,
      Colors.lightGreen,
      Colors.orangeAccent,
      Colors.blueAccent
    ];

    int i = 0;
    return totals.entries.map((entry) {
      final percent = (entry.value / total * 100).toStringAsFixed(1);
      return PieChartSectionData(
        value: entry.value,
        title: '${entry.key}\n$percent%',
        color: colors[i++ % colors.length],
        radius: 60,
        titleStyle: const TextStyle(
          color: Colors.black87,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      );
    }).toList();
  }

  void _addPurchase() {
    final String product = _productController.text.trim();
    final String qty = _quantityController.text.trim();
    final String price = _priceController.text.trim();

    if (product.isEmpty || qty.isEmpty || price.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Please fill all fields')),
      );
      return;
    }

    setState(() {
      purchases.add({
        "product": product,
        "quantity": int.tryParse(qty) ?? 0,
        "price": int.tryParse(price) ?? 0,
      });

      _productController.clear();
      _quantityController.clear();
      _priceController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Purchase added successfully!')),
    );
  }

  int _calculateTotalSales() {
    return purchases.fold(0, (sum, item) => sum + (item['price'] as int));
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
            // Blockchain connection
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

            // Summary Cards
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatCard("Total Products", "${purchases.length}",
                    Icons.store, Colors.green),
                _buildStatCard("Total Sales", "₹${_calculateTotalSales()}",
                    Icons.attach_money, Colors.teal),
                _buildStatCard("Avg. Margin", "18%",
                    Icons.trending_up, Colors.orange),
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
                    TextField(
                      controller: _productController,
                      decoration: _inputDecoration("Product Name"),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _quantityController,
                      decoration: _inputDecoration("Quantity"),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _priceController,
                      decoration: _inputDecoration("Price (₹)"),
                      keyboardType: TextInputType.number,
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

            // ✅ Dynamic Pie Chart
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
                          DataColumn(label: Text("Quantity")),
                          DataColumn(label: Text("Price (₹)")),
                        ],
                        rows: purchases
                            .map((item) => DataRow(cells: [
                                  DataCell(Text(item["product"])),
                                  DataCell(Text(item["quantity"].toString())),
                                  DataCell(Text(item["price"].toString())),
                                ]))
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
