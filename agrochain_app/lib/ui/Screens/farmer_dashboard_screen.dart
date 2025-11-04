import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class FarmerDashboardScreen extends StatefulWidget {
  const FarmerDashboardScreen({super.key});

  @override
  State<FarmerDashboardScreen> createState() => _FarmerDashboardScreenState();
}

class _FarmerDashboardScreenState extends State<FarmerDashboardScreen> {
  bool isBlockchainConnected = false;
  List<Map<String, dynamic>> crops = [];
  double totalWeight = 0;
  double expectedRevenue = 0;

  final TextEditingController cropNameController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9), // Light background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        title: const Text(
          "Farmer Dashboard",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Blockchain Connection Bar
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
                    style: const TextStyle(color: Colors.black87, fontSize: 14),
                  ),
                ]),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() => isBlockchainConnected = !isBlockchainConnected);
                  },
                  icon: const Icon(Icons.link),
                  label: const Text("Connect Wallet"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                )
              ],
            ),

            const SizedBox(height: 24),

            // Stat Cards
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatCard("Total Crops", crops.length.toString(),
                    Icons.grass, Colors.green.shade600),
                _buildStatCard("Total Weight", "$totalWeight kg", Icons.scale,
                    Colors.blue.shade600),
                _buildStatCard("Expected Revenue", "₹$expectedRevenue",
                    Icons.currency_rupee, Colors.orange.shade700),
              ],
            ),

            const SizedBox(height: 24),

            // Add Crop Section
            Card(
              elevation: 3,
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      "Add Crop",
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInputField(cropNameController, "Crop Name"),
                    _buildInputField(weightController, "Weight (kg)",
                        inputType: TextInputType.number),
                    _buildInputField(priceController, "Expected Price (₹/kg)",
                        inputType: TextInputType.number),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (cropNameController.text.isEmpty ||
                            weightController.text.isEmpty ||
                            priceController.text.isEmpty) return;

                        setState(() {
                          final weight = double.parse(weightController.text);
                          final price = double.parse(priceController.text);
                          crops.add({
                            'name': cropNameController.text,
                            'weight': weight,
                            'price': price,
                          });
                          totalWeight += weight;
                          expectedRevenue += weight * price;
                          cropNameController.clear();
                          weightController.clear();
                          priceController.clear();
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: const Text("Add Crop"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
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

            // // Market Price Chart
            // Card(
            //   elevation: 3,
            //   color: Colors.white,
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
            //             leftTitles: AxisTitles(
            //               sideTitles: SideTitles(showTitles: false),
            //             ),
            //           ),
            //           barGroups: [
            //             BarChartGroupData(x: 0, barRods: [
            //               BarChartRodData(toY: 28, color: Colors.green.shade400)
            //             ]),
            //             BarChartGroupData(x: 1, barRods: [
            //               BarChartRodData(toY: 32, color: Colors.orange.shade400)
            //             ]),
            //             BarChartGroupData(x: 2, barRods: [
            //               BarChartRodData(toY: 22, color: Colors.blue.shade400)
            //             ]),
            //             BarChartGroupData(x: 3, barRods: [
            //               BarChartRodData(toY: 45, color: Colors.teal.shade400)
            //             ]),
            //           ],
            //         ),
            //       ),
            //     ),
            //   ),
            // ),

            const SizedBox(height: 24),

            // Crop List
            if (crops.isNotEmpty)
              Card(
                elevation: 3,
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Crops List",
                        style: TextStyle(
                            color: Colors.black87,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ...crops.map(
                        (crop) => ListTile(
                          leading: const Icon(Icons.eco, color: Colors.green),
                          title: Text(
                            crop['name'],
                            style: const TextStyle(color: Colors.black87),
                          ),
                          subtitle: Text(
                            "Weight: ${crop['weight']} kg | Price: ₹${crop['price']}/kg",
                            style: const TextStyle(color: Colors.black54),
                          ),
                          trailing:
                              const Icon(Icons.qr_code, color: Colors.green),
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

  Widget _buildStatCard(
      String title, String value, IconData icon, Color iconColor) {
    return Expanded(
      child: Card(
        elevation: 3,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: iconColor, size: 28),
              const SizedBox(height: 8),
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

  Widget _buildInputField(TextEditingController controller, String label,
      {TextInputType inputType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: inputType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.grey)),
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
      ),
    );
  }
}
