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
      backgroundColor: const Color.fromARGB(255, 27, 40, 83),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Farmer Dashboard",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
                    style: const TextStyle(color: Colors.white70),
                  ),
                ]),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() => isBlockchainConnected = !isBlockchainConnected);
                  },
                  icon: const Icon(Icons.link),
                  label: const Text("Connect Wallet"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent[700],
                  ),
                )
              ],
            ),
            const SizedBox(height: 24),

            // Stats Cards
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatCard("Total Crops", crops.length.toString(),
                    Icons.grass, Colors.greenAccent),
                _buildStatCard(
                    "Total Weight", "$totalWeight kg", Icons.scale, Colors.blueAccent),
                _buildStatCard("Expected Revenue", "₹$expectedRevenue",
                    Icons.currency_rupee, Colors.amberAccent),
              ],
            ),

            const SizedBox(height: 24),

            // Add Crop Section
            Card(
              color: Colors.white10,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text("Add Crop",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: cropNameController,
                      decoration: const InputDecoration(
                        labelText: "Crop Name",
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: weightController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Weight (kg)",
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Expected Price (₹/kg)",
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          crops.add({
                            'name': cropNameController.text,
                            'weight': double.parse(weightController.text),
                            'price': double.parse(priceController.text)
                          });
                          totalWeight += double.parse(weightController.text);
                          expectedRevenue += double.parse(weightController.text) *
                              double.parse(priceController.text);
                          cropNameController.clear();
                          weightController.clear();
                          priceController.clear();
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: const Text("Add Crop"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    )
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Market Prices Chart (Mock Data)
            Card(
              color: Colors.white10,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: SizedBox(
                height: 250,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: BarChart(
                    BarChartData(
                      borderData: FlBorderData(show: false),
                      gridData: const FlGridData(show: false),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, _) {
                              const labels = ['Rice', 'Wheat', 'Corn', 'Onion'];
                              return Text(labels[value.toInt()],
                                  style: const TextStyle(color: Colors.white70));
                            },
                          ),
                        ),
                        leftTitles:
                            AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      barGroups: [
                        BarChartGroupData(x: 0, barRods: [
                          BarChartRodData(toY: 28, color: Colors.greenAccent)
                        ]),
                        BarChartGroupData(x: 1, barRods: [
                          BarChartRodData(toY: 32, color: Colors.lightGreen)
                        ]),
                        BarChartGroupData(x: 2, barRods: [
                          BarChartRodData(toY: 22, color: Colors.tealAccent)
                        ]),
                        BarChartGroupData(x: 3, barRods: [
                          BarChartRodData(toY: 45, color: Colors.green)
                        ]),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Crops Table
            if (crops.isNotEmpty)
              Card(
                color: Colors.white10,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Crops List",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      ...crops.map((crop) => ListTile(
                            title: Text(crop['name'],
                                style: const TextStyle(color: Colors.white)),
                            subtitle: Text(
                                "Weight: ${crop['weight']} kg | Price: ₹${crop['price']}/kg",
                                style: const TextStyle(color: Colors.white70)),
                            trailing: const Icon(Icons.qr_code, color: Colors.greenAccent),
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
      String title, String value, IconData icon, Color iconColor) {
    return Expanded(
      child: Card(
        color: Colors.white10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: iconColor, size: 30),
              const SizedBox(height: 8),
              Text(title,
                  style: const TextStyle(color: Colors.white70, fontSize: 14)),
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
