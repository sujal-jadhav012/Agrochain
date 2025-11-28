import 'package:flutter/material.dart';

class DistributorDashboardScreen extends StatefulWidget {
  const DistributorDashboardScreen({super.key});

  @override
  State<DistributorDashboardScreen> createState() =>
      _DistributorDashboardScreenState();
}

class _DistributorDashboardScreenState extends State<DistributorDashboardScreen> {
  bool isBlockchainConnected = false;
  List<Map<String, dynamic>> distributions = [];
  double totalWeight = 0;
  double totalRevenue = 0;

  final TextEditingController productController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.green[600],
        elevation: 0,
        title: const Text(
          "Distributor Dashboard",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Blockchain connection bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
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
                ]),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() => isBlockchainConnected = !isBlockchainConnected);
                  },
                  icon: const Icon(Icons.link),
                  label: Text(
                    isBlockchainConnected ? "Disconnect" : "Connect Wallet",
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                )
              ],
            ),
            const SizedBox(height: 20),

            // Stats cards
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatCard("Total Products", distributions.length.toString(),
                    Icons.inventory_2, Colors.blue),
                _buildStatCard("Total Weight", "$totalWeight kg", Icons.scale,
                    Colors.orange),
                _buildStatCard(
                    "Total Revenue", "₹$totalRevenue", Icons.currency_rupee, Colors.green),
              ],
            ),
            const SizedBox(height: 24),

            // Add Distribution Section
            Card(
              color: Colors.white,
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text("Add Distribution",
                        style: TextStyle(
                            color: Colors.black87,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: productController,
                      decoration: const InputDecoration(
                        labelText: "Product Name",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: weightController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Weight (kg)",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Price (₹/kg)",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          distributions.add({
                            'product': productController.text,
                            'weight': double.parse(weightController.text),
                            'price': double.parse(priceController.text),
                          });
                          totalWeight += double.parse(weightController.text);
                          totalRevenue += double.parse(weightController.text) *
                              double.parse(priceController.text);

                          productController.clear();
                          weightController.clear();
                          priceController.clear();
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: const Text("Add Distribution"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // // Bar Chart Section
            // Card(
            //   color: Colors.white,
            //   elevation: 3,
            //   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            //   child: SizedBox(
            //     height: 250,
            //     child: Padding(
            //       padding: const EdgeInsets.all(16),
            //       child: BarChart(
            //         BarChartData(
            //           borderData: FlBorderData(show: false),
            //           gridData: const FlGridData(show: false),
            //           titlesData: FlTitlesData(
            //             bottomTitles: AxisTitles(
            //               sideTitles: SideTitles(
            //                 showTitles: true,
            //                 getTitlesWidget: (value, _) {
            //                   const labels = ['Rice', 'Wheat', 'Corn', 'Onion'];
            //                   return Text(
            //                     labels[value.toInt()],
            //                     style: const TextStyle(color: Colors.black87),
            //                   );
            //                 },
            //               ),
            //             ),
            //             leftTitles:
            //                 AxisTitles(sideTitles: SideTitles(showTitles: false)),
            //           ),
            //           barGroups: [
            //             BarChartGroupData(
            //                 x: 0,
            //                 barRods: [BarChartRodData(toY: 20, color: Colors.green[400])]),
            //             BarChartGroupData(
            //                 x: 1,
            //                 barRods: [BarChartRodData(toY: 35, color: Colors.orange[400])]),
            //             BarChartGroupData(
            //                 x: 2,
            //                 barRods: [BarChartRodData(toY: 28, color: Colors.blue[400])]),
            //             BarChartGroupData(
            //                 x: 3,
            //                 barRods: [BarChartRodData(toY: 40, color: Colors.purple[400])]),
            //           ],
            //         ),
            //       ),
            //     ),
            //   ),
            // ),
            // const SizedBox(height: 24),

            // Distributions Table
            if (distributions.isNotEmpty)
              Card(
                color: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Distribution List",
                          style: TextStyle(
                              color: Colors.black87,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      ...distributions.map((item) => ListTile(
                            title: Text(item['product'],
                                style: const TextStyle(color: Colors.black)),
                            subtitle: Text(
                              "Weight: ${item['weight']} kg | Price: ₹${item['price']}/kg",
                              style: const TextStyle(color: Colors.black54),
                            ),
                            trailing:
                                const Icon(Icons.qr_code, color: Colors.green),
                          )),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        color: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(height: 8),
              Text(title,
                  style: const TextStyle(color: Colors.black54, fontSize: 14)),
              Text(value,
                  style: const TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
