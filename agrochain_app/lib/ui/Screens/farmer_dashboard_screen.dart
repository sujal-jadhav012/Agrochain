import 'dart:io';
import 'dart:ui' as ui;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart'; // Clipboard
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart'; // for PdfPageFormat

class FarmerDashboardScreen extends StatefulWidget {
  const FarmerDashboardScreen({super.key});

  @override
  State<FarmerDashboardScreen> createState() => _FarmerDashboardScreenState();
}

class _FarmerDashboardScreenState extends State<FarmerDashboardScreen> {
  bool isBlockchainConnected = false;

  // crops will be loaded from Firestore; each entry contains the docId in 'docId'
  List<Map<String, dynamic>> crops = [];
  double totalWeight = 0;
  double expectedRevenue = 0;

  final TextEditingController cropNameController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String produceUrlPrefix = 'https://example.com/produce/';

  // listener subscription
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _cropsSub;

  @override
  void initState() {
    super.initState();
    _startCropsListener();
  }

  @override
  void dispose() {
    cropNameController.dispose();
    weightController.dispose();
    priceController.dispose();
    _cropsSub?.cancel();
    super.dispose();
  }

  // -----------------------
  // Firestore: listen to user's crops (real-time)
  // -----------------------
  Future<void> _startCropsListener() async {
    final user = _auth.currentUser;
    // if user not signed in yet, wait for auth changes
    if (user == null) {
      // subscribe to auth changes once and then start
      _auth.userChanges().listen((u) {
        if (u != null) _startCropsListener();
      });
      return;
    }

    final uid = user.uid;
    _cropsSub?.cancel();
    _cropsSub = _firestore
        .collection('users')
        .doc(uid)
        .collection('crops')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snap) {
      final docs = snap.docs;
      final newList = <Map<String, dynamic>>[];
      double weightSum = 0;
      double revenueSum = 0;

      for (var d in docs) {
        final data = d.data();
        final name = data['name'] ?? '';
        final weight = (data['weight'] is num) ? (data['weight'] as num).toDouble() : 0.0;
        final price = (data['price'] is num) ? (data['price'] as num).toDouble() : 0.0;
        weightSum += weight;
        revenueSum += weight * price;

        final mapped = {
          'docId': d.id,
          'name': name,
          'weight': weight,
          'price': price,
          // preserve optional produceId if already present
          'produceId': data['produceId'],
        };
        newList.add(mapped);
      }

      setState(() {
        crops = newList;
        totalWeight = weightSum;
        expectedRevenue = revenueSum;
      });
    }, onError: (e) {
      debugPrint('Crops listener error: $e');
    });
  }

  // -----------------------
  // Add crop to Firestore under users/{uid}/crops
  // -----------------------
  Future<void> _addCropToFirestore({
    required String name,
    required double weight,
    required double price,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sign in first')));
      return;
    }

    final uid = user.uid;
    try {
      await _firestore.collection('users').doc(uid).collection('crops').add({
        'name': name,
        'weight': weight,
        'price': price,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // UI feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Crop added')));
      }
    } catch (e) {
      debugPrint('Add crop error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error adding crop: $e')));
      }
    }
  }

  // -----------------------
  // Update crop doc with produceId (so we don't create duplicates)
  // -----------------------
  Future<void> _setCropProduceId(String uid, String cropDocId, String produceId) async {
    final ref = _firestore.collection('users').doc(uid).collection('crops').doc(cropDocId);
    await ref.set({'produceId': produceId}, SetOptions(merge: true));
  }

  // ------------ QR helpers ------------
  Future<Uint8List> _renderQrPngBytes(String data, {double size = 900.0}) async {
    final painter = QrPainter(
      data: data,
      version: QrVersions.auto,
      gapless: true,
      color: const Color(0xff000000),
      emptyColor: const Color(0xffffffff),
    );

    // toImage expects a double
    final ui.Image image = await painter.toImage(size);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<File> _saveBytesToTempFile(Uint8List bytes, String filename) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<void> _downloadQr(Uint8List pngBytes, String productId) async {
    final file = await _saveBytesToTempFile(pngBytes, 'qr_$productId.png');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved to ${file.path}')),
    );
  }

  Future<void> _printQr(Uint8List pngBytes) async {
    final pdf = pw.Document();
    final image = pw.MemoryImage(pngBytes);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context ctx) {
          return pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain));
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  Future<void> _showQrDialog({required String url, required String productId}) async {
    // render once (so download/print use same bytes)
    Uint8List pngBytes;
    try {
      pngBytes = await _renderQrPngBytes(url, size: 900.0);
    } catch (e) {
      debugPrint('QR render error: $e');
      pngBytes = Uint8List(0);
    }

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          backgroundColor: Colors.transparent,
          child: SingleChildScrollView(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // title + close
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Product QR Code',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),

                  // QR square with white background
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(12),
                    child: pngBytes.isNotEmpty
                        ? Image.memory(pngBytes, width: 300, height: 300, fit: BoxFit.contain)
                        : SizedBox(
                            width: 300,
                            height: 300,
                            child: Center(child: QrImageView(data: url, size: 260)),
                          ),
                  ),

                  const SizedBox(height: 12),

                  // Product id with copy button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          'Product ID: $productId',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, color: Colors.white),
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: productId));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(content: Text('Product ID copied')));
                          }
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  const Text('Scan this QR code to track the product',
                      style: TextStyle(color: Colors.white70)),

                  const SizedBox(height: 16),

                  // Download & Print
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                          ),
                          icon: const Icon(Icons.download_rounded),
                          label: const Text('Download'),
                          onPressed: () async {
                            if (pngBytes.isEmpty) {
                              final b = await _renderQrPngBytes(url, size: 500.0);
                              await _downloadQr(b, productId);
                            } else {
                              await _downloadQr(pngBytes, productId);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                          ),
                          icon: const Icon(Icons.print),
                          label: const Text('Print'),
                          onPressed: () async {
                            if (pngBytes.isEmpty) {
                              final b = await _renderQrPngBytes(url, size: 500.0);
                              await _printQr(b);
                            } else {
                              await _printQr(pngBytes);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ------------------------------
  //   CREATE PRODUCE + EVENTS
  // ------------------------------
  Future<void> createProduceAndShowQR(BuildContext ctx, Map<String, dynamic> crop) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('User not signed in')),
        );
        return;
      }

      final uid = user.uid;
      final farmerName = user.displayName ?? 'Farmer';

      // If crop already has produceId, show the QR for that id
      if (crop.containsKey('produceId') && crop['produceId'] != null) {
        final existingUrl = '$produceUrlPrefix${crop['produceId']}';
        await _showQrDialog(url: existingUrl, productId: crop['produceId']);
        return;
      }

      // 1️⃣ Create produce summary document (NO array)
      final docRef = _firestore.collection('produces').doc();
      final serverNow = FieldValue.serverTimestamp();

      final produceSummary = {
        'produceId': docRef.id,
        'farmerId': uid,
        'produceType': crop['name'] ?? 'Unknown',
        'variety': '',
        'quantity': crop['weight'] ?? 0,
        'unit': 'kg',
        'pricePerKg': crop['price'] ?? 0,
        'harvestDate': DateTime.now().toUtc().toIso8601String(),
        'origin': {'farmName': '', 'location': ''},
        'status': 'with_farmer',
        'currentHolder': {
          'role': 'farmer',
          'id': uid,
          'name': farmerName,
        },
        'lastUpdated': serverNow,
      };

      await docRef.set(produceSummary);

      // 2️⃣ Add first event in subcollection (ALLOWED timestamp)
      final eventData = {
        'actorId': uid,
        'actorRole': 'farmer',
        'action': 'created',
        'notes': 'Initial registration',
        'location': '',
        'timestamp': FieldValue.serverTimestamp(), // VALID
      };

      await docRef.collection('events').add(eventData);

      // 3️⃣ Build URL for QR
      final url = '$produceUrlPrefix${docRef.id}';
      final productId = docRef.id;

      // 4️⃣ Store produceId back to the crop document so it's reusable
      final cropDocId = crop['docId'] as String?;
      if (cropDocId != null) {
        await _setCropProduceId(uid, cropDocId, productId);
      }

      // 5️⃣ Show polished QR dialog (download / print / copy)
      if (!mounted) return;
      await _showQrDialog(url: url, productId: productId);
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(ctx)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  // ------------------------
  //       UI PART
  // ------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
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

            // Blockchain bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Icon(Icons.circle,
                      color: isBlockchainConnected ? Colors.green : Colors.red,
                      size: 12),
                  const SizedBox(width: 8),
                  Text(
                    isBlockchainConnected
                        ? "Blockchain: Connected"
                        : "Blockchain: Disconnected",
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
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatCard("Total Crops", crops.length.toString(),
                    Icons.grass, Colors.green.shade600),
                _buildStatCard("Total Weight", "${totalWeight.toStringAsFixed(2)} kg",
                    Icons.scale, Colors.blue.shade600),
                _buildStatCard("Revenue", "₹${expectedRevenue.toStringAsFixed(2)}",
                    Icons.currency_rupee, Colors.orange.shade700),
              ],
            ),

            const SizedBox(height: 24),

            // Add Crop (now persisted)
            Card(
              elevation: 3,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text("Add Crop",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),

                    _buildInputField(cropNameController, "Crop Name"),
                    _buildInputField(weightController, "Weight (kg)",
                        inputType: TextInputType.number),
                    _buildInputField(priceController, "Expected Price (₹/kg)",
                        inputType: TextInputType.number),

                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () async {
                        if (cropNameController.text.isEmpty ||
                            weightController.text.isEmpty ||
                            priceController.text.isEmpty) {
                          return;
                        }

                        // parse
                        final weight = double.tryParse(weightController.text) ?? 0.0;
                        final price = double.tryParse(priceController.text) ?? 0.0;
                        final name = cropNameController.text.trim();

                        await _addCropToFirestore(name: name, weight: weight, price: price);

                        // clear locally (listener will update)
                        cropNameController.clear();
                        weightController.clear();
                        priceController.clear();
                      },
                      icon: const Icon(Icons.add),
                      label: const Text("Add Crop"),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Crop List (populated from Firestore listener)
            if (crops.isNotEmpty)
              Card(
                elevation: 3,
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Crops List",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),

                      // build items
                      ...crops.map(
                        (crop) => ListTile(
                          leading:
                              const Icon(Icons.eco, color: Colors.green),
                          title: Text(crop['name'] ?? ''),
                          subtitle: Text(
                              "Weight: ${crop['weight']} kg | Price: ₹${crop['price']}"),
                          trailing: IconButton(
                            icon: const Icon(Icons.qr_code, color: Colors.green),
                            onPressed: () async => createProduceAndShowQR(context, crop),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // if no crops show friendly message
            if (crops.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('No crops yet. Add a crop to generate QR.')),
              ),
          ],
        ),
      ),
    );
  }

  // ------------------------
  //  UI Helpers
  // ------------------------
  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 3,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(title),
              Text(
                value,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
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
              borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
      ),
    );
  }
}

