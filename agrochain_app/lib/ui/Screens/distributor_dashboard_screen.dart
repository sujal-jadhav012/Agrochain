import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DistributorDashboardScreen extends StatefulWidget {
  const DistributorDashboardScreen({super.key});

  @override
  State<DistributorDashboardScreen> createState() =>
      _DistributorDashboardScreenState();
}

class _DistributorDashboardScreenState
    extends State<DistributorDashboardScreen> {
  bool isBlockchainConnected = false;

  final TextEditingController produceIdController = TextEditingController();
  final TextEditingController handlingController = TextEditingController();
  final TextEditingController transportController = TextEditingController();

  bool loading = false;

  Map<String, dynamic>? produceData;
  String? produceId;

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    produceIdController.dispose();
    handlingController.dispose();
    transportController.dispose();
    super.dispose();
  }

  // FETCH PRODUCE
  Future<void> fetchProduce() async {
    final id = produceIdController.text.trim();
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Enter Produce ID")));
      return;
    }

    setState(() => loading = true);

    try {
      final doc =
          await _firestore.collection('produces').doc(id).get();

      if (!doc.exists) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Produce not found")));
        return;
      }

      setState(() {
        produceId = id;
        produceData = doc.data();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching produce: $e")));
    }

    setState(() => loading = false);
  }

  // SUM DISTRIBUTOR CHARGES
  Future<double> sumDistributorCharges(String id) async {
    final chargesSnap = await _firestore
        .collection('produces')
        .doc(id)
        .collection('addedCharges')
        .doc('distributor')
        .collection('entries')
        .get();

    double total = 0;
    for (var d in chargesSnap.docs) {
      total += (d['total'] ?? 0).toDouble();
    }
    return total;
  }

  // APPLY UPDATE
  Future<void> applyDistributorUpdate() async {
    if (produceId == null || produceData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Fetch a produce first")));
      return;
    }

    final user = _auth.currentUser;
    if (user == null) return;

    final handling =
        double.tryParse(handlingController.text.trim()) ?? 0;
    final transport =
        double.tryParse(transportController.text.trim()) ?? 0;

    final total = handling + transport;

    setState(() => loading = true);

    final docRef = _firestore.collection('produces').doc(produceId);

    try {
      await _firestore.runTransaction((txn) async {
        final snap = await txn.get(docRef);
        if (!snap.exists) throw Exception("Produce missing");

        final summary = snap.data()!;

        txn.update(docRef, {
          "currentHolder": {
            "role": "distributor",
            "id": user.uid,
            "name": user.displayName ?? "Distributor"
          },
          "status": "with_distributor",
          "lastUpdated": FieldValue.serverTimestamp(),
        });

        // Add charges entry
        final chargesRef = docRef
            .collection('addedCharges')
            .doc('distributor')
            .collection('entries')
            .doc();

        txn.set(chargesRef, {
          "handling": handling,
          "transport": transport,
          "total": total,
          "timestamp": FieldValue.serverTimestamp(),
          "actorId": user.uid,
        });

        // Add event
        final eventRef = docRef.collection('events').doc();
        txn.set(eventRef, {
          "actorId": user.uid,
          "actorRole": "distributor",
          "action": "handled",
          "handling": handling,
          "transport": transport,
          "totalCharges": total,
          "timestamp": FieldValue.serverTimestamp(),
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Charges Updated")));

      handlingController.clear();
      transportController.clear();
      await fetchProduce();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    setState(() => loading = false);
  }

  // PRODUCE DISPLAY CARD
  Widget produceCard() {
    if (produceData == null) return const SizedBox.shrink();

    final basePrice = (produceData!['pricePerKg'] ?? 0).toDouble();
    final qty = (produceData!['quantity'] ?? 0).toDouble();

    return FutureBuilder<double>(
      future: sumDistributorCharges(produceId!),
      builder: (context, snap) {
        final added = snap.data ?? 0;

        final finalPrice = basePrice + (added / (qty > 0 ? qty : 1));
        final finalRevenue = qty * finalPrice;

        return Card(
          elevation: 3,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Produce ID: $produceId",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text("Type: ${produceData!['produceType']}"),
                Text("Quantity: $qty kg"),
                Text("Farmer Base Price/kg: ₹$basePrice"),
                Text("Distributor Charges: ₹${added.toStringAsFixed(2)}"),
                Text("Final Price/kg: ₹${finalPrice.toStringAsFixed(2)}"),
                Text("Final Expected Revenue: ₹${finalRevenue.toStringAsFixed(2)}"),
                const SizedBox(height: 6),
                Text("Status: ${produceData!['status']}"),
              ],
            ),
          ),
        );
      },
    );
  }

  // UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.green[600],
        title: const Text("Distributor Dashboard",
            style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
              onPressed: () => Navigator.pushReplacementNamed(context, "/login"),
              icon: const Icon(Icons.logout, color: Colors.white))
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Blockchain bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Icon(Icons.circle,
                      color: isBlockchainConnected ? Colors.green : Colors.red,
                      size: 12),
                  const SizedBox(width: 6),
                  Text(isBlockchainConnected
                      ? "Blockchain: Connected"
                      : "Blockchain: Disconnected"),
                ]),
                ElevatedButton(
                  onPressed: () => setState(() =>
                      isBlockchainConnected = !isBlockchainConnected),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600]),
                  child: const Text("Connect Wallet",
                      style: TextStyle(color: Colors.white)),
                )
              ],
            ),

            const SizedBox(height: 20),

            // PRODUCE INPUT
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: produceIdController,
                    decoration: const InputDecoration(
                      labelText: "Enter Produce ID",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: loading ? null : fetchProduce,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600]),
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Fetch",
                          style: TextStyle(color: Colors.white)),
                )
              ],
            ),

            const SizedBox(height: 20),

            produceCard(),

            const SizedBox(height: 20),

            // Charges Input
            Card(
              elevation: 3,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  const Text("Add Charges",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                      controller: handlingController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: "Handling Charge (₹)",
                          border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(
                      controller: transportController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: "Transport Charge (₹)",
                          border: OutlineInputBorder())),
                  const SizedBox(height: 20),
                  ElevatedButton(
                      onPressed: loading ? null : applyDistributorUpdate,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          minimumSize: const Size(double.infinity, 50)),
                      child: loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Apply Update",
                              style: TextStyle(color: Colors.white))),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
