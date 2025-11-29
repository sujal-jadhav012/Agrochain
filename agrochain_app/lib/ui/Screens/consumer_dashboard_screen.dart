// consumer_trace_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class ConsumerTraceScreen extends StatefulWidget {
  const ConsumerTraceScreen({super.key});

  @override
  State<ConsumerTraceScreen> createState() => _ConsumerTraceScreenState();
}

class _ConsumerTraceScreenState extends State<ConsumerTraceScreen> {
  final TextEditingController _inputController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _loading = false;
  String? _error;

  Map<String, dynamic>? _produce; // produce summary
  List<Map<String, dynamic>> _events = [];
  double _distributorTotal = 0.0;
  double _retailerTotal = 0.0;

  // helper: accept either a full url or plain id
  String _extractProduceId(String raw) {
    raw = raw.trim();
    if (raw.isEmpty) return '';
    // handle URLs like https://example.com/produce/<id> or /p/<id>
    try {
      final uri = Uri.parse(raw);
      if (uri.pathSegments.isNotEmpty) {
        // pick last segment as id
        return uri.pathSegments.last;
      }
    } catch (_) {}
    // fallback: return raw
    return raw;
  }

  Future<void> _trace() async {
    setState(() {
      _loading = true;
      _error = null;
      _produce = null;
      _events = [];
      _distributorTotal = 0.0;
      _retailerTotal = 0.0;
    });

    final raw = _inputController.text.trim();
    final id = _extractProduceId(raw);
    if (id.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Enter produce ID or a URL containing it';
      });
      return;
    }

    try {
      final docRef = _firestore.collection('produces').doc(id);
      final docSnap = await docRef.get();

      if (!docSnap.exists) {
        setState(() {
          _error = 'Produce not found';
          _loading = false;
        });
        return;
      }

      final data = docSnap.data()!;
      // read summary
      setState(() {
        _produce = Map<String, dynamic>.from(data);
      });

      // read events ordered by timestamp (ascending)
      final eventsSnap = await docRef.collection('events')
          .orderBy('timestamp', descending: false)
          .get();

      final events = eventsSnap.docs.map((d) {
        final m = Map<String, dynamic>.from(d.data());
        m['id'] = d.id;
        return m;
      }).toList();

      // sum distributor addedCharges total amounts
      double distributorTotal = 0.0;
      try {
        final distEntries = await docRef
            .collection('addedCharges')
            .doc('distributor')
            .collection('entries')
            .get();
        for (var d in distEntries.docs) {
          final t = d.data()['total'];
          if (t is num) {
            distributorTotal += (t).toDouble();
          } else if (t is String) distributorTotal += double.tryParse(t) ?? 0.0;
        }
      } catch (_) {
        // collection may not exist -> fine
      }

      // sum retailer addedCharges total amounts
      double retailerTotal = 0.0;
      try {
        final retEntries = await docRef
            .collection('addedCharges')
            .doc('retailer')
            .collection('entries')
            .get();
        for (var d in retEntries.docs) {
          final t = d.data()['total'];
          if (t is num) {
            retailerTotal += (t).toDouble();
          } else if (t is String) retailerTotal += double.tryParse(t) ?? 0.0;
        }
      } catch (_) {}

      setState(() {
        _events = events;
        _distributorTotal = distributorTotal;
        _retailerTotal = retailerTotal;
      });
    } on FirebaseException catch (e) {
      setState(() {
        _error = 'Firestore error: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  // compute per-kg distributor and retailer share (defensive)
  double _perKg(double total, dynamic quantity) {
    double q = 0;
    if (quantity is num) {
      q = (quantity).toDouble();
    } else if (quantity is String) q = double.tryParse(quantity) ?? 0.0;
    if (q <= 0) return 0.0;
    return total / q;
  }

  Widget _buildScannerIntro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text('🔍 Trace Product', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        const Text('Paste the QR URL or Product ID below to view the supply-chain timeline.',
            textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inputController,
                decoration: InputDecoration(
                  labelText: 'QR URL or Produce ID',
                  hintText: 'https://example.com/produce/<id>  or  <id>',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _loading ? null : _trace,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], minimumSize: const Size(90, 56)),
              child: _loading ? const SizedBox(width:18, height:18, child:CircularProgressIndicator(color: Colors.white, strokeWidth:2)) : const Text('Trace'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                // placeholder for camera scanner integration
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Camera scanner not implemented here — plug your scanner package')));
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('Open Camera Scanner'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                // placeholder for upload
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image-upload scanner not implemented')));
              },
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload QR Image'),
            ),
          ),
        ]),
        const SizedBox(height: 18),
      ],
    );
  }

  Widget _buildSummaryCard() {
    if (_produce == null) return const SizedBox.shrink();
    final qty = _produce!['quantity'];
    final farmerPrice = (_produce!['pricePerKg'] is num) ? (_produce!['pricePerKg'] as num).toDouble() : double.tryParse((_produce!['pricePerKg']?.toString() ?? '0')) ?? 0.0;
    final distributorPerKg = _perKg(_distributorTotal, qty);
    final retailerPerKg = _perKg(_retailerTotal, qty);
    final finalPerKg = farmerPrice + distributorPerKg + retailerPerKg;
    final finalRevenue = finalPerKg * (qty is num ? (qty).toDouble() : double.tryParse(qty?.toString() ?? '0') ?? 0.0);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              Expanded(child: Text('${_produce!['produceType'] ?? 'Produce'}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
              IconButton(
                icon: const Icon(Icons.open_in_new),
                onPressed: () {
                  final url = _produce!['externalUrl'] ?? 'https://example.com/produce/${_produce!['produceId'] ?? ''}';
                  launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                },
                tooltip: 'Open web page',
              )
            ],
          ),
          const SizedBox(height: 6),
          Text('Origin: ${(_produce!['origin']?['farmName'] ?? '')} • ${(_produce!['origin']?['location'] ?? '')}', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          Wrap(spacing: 12, runSpacing: 8, children: [
            Chip(label: Text('Status: ${_produce!['status'] ?? 'unknown'}'), backgroundColor: Colors.green.shade50),
            Chip(label: Text('ID: ${_produce!['produceId'] ?? ''}')),
            Chip(label: Text('Qty: ${_produce!['quantity'] ?? ''} kg')),
          ]),
          const SizedBox(height: 12),
          Text('Price breakdown (per kg)', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(child: Text('Farmer base:')),
            Text('₹${farmerPrice.toStringAsFixed(2)}'),
          ]),
          Row(children: [
            Expanded(child: Text('Distributor charges (/kg):')),
            Text('₹${distributorPerKg.toStringAsFixed(2)} (total ₹${_distributorTotal.toStringAsFixed(2)})'),
          ]),
          Row(children: [
            Expanded(child: Text('Retailer margins (/kg):')),
            Text('₹${retailerPerKg.toStringAsFixed(2)} (total ₹${_retailerTotal.toStringAsFixed(2)})'),
          ]),
          const Divider(),
          Row(children: [
            Expanded(child: Text('Final retail / kg', style: const TextStyle(fontWeight: FontWeight.bold))),
            Text('₹${finalPerKg.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 6),
          Text('Estimated total revenue: ₹${finalRevenue.toStringAsFixed(2)}', style: const TextStyle(color: Colors.black54)),
        ]),
      ),
    );
  }

  Widget _buildTimeline() {
    if (_events.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text('Supply chain timeline', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ..._events.reversed.map((e) {
          // show newest first (reverse)
          final actor = e['actorRole'] ?? e['actorId'] ?? 'actor';
          final action = e['action'] ?? 'updated';
          final notes = e['notes'] ?? '';
          String when = '';
          final ts = e['timestamp'];
          if (ts is Timestamp) {
            when = (ts.toDate()).toLocal().toString();
          } else if (ts is Map && ts['_seconds'] != null) {
            when = DateTime.fromMillisecondsSinceEpoch((ts['_seconds'] as int) * 1000).toLocal().toString();
          } else {
            when = '';
          }

          // optional: show handling/transport/total fields if present
          final handling = e['handling'];
          final transport = e['transport'];
          final totalCharges = e['total'] ?? e['totalCharges'];

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: CircleAvatar(backgroundColor: Colors.green.shade100, child: Text((actor as String).substring(0,1).toUpperCase())),
              title: Text('${(actor.toString()[0].toUpperCase() + actor.toString().substring(1))} — ${action.toString()}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (notes != null && notes.toString().isNotEmpty) Text(notes.toString()),
                  if (handling != null) Text('Handling: ₹$handling'),
                  if (transport != null) Text('Transport: ₹$transport'),
                  if (totalCharges != null) Text('Charges: ₹${totalCharges.toString()}'),
                  if (when.isNotEmpty) Text(when, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trace Product'),
        backgroundColor: Colors.green.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildScannerIntro(),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            if (_produce != null) ...[
              _buildSummaryCard(),
              _buildTimeline(),
              const SizedBox(height: 20),
              Card(
                color: Colors.green.shade50,
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.verified, color: Colors.green),
                      SizedBox(width: 10),
                      Expanded(child: Text('Supply chain data is read-only and verified on-chain where applicable.')),
                    ],
                  ),
                ),
              )
            ],
          ],
        ),
      ),
    );
  }
}
