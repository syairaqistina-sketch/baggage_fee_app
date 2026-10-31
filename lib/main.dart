import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(const BaggageApp());

// ---------- EDIT THESE FOR YOUR ABOUT PAGE ----------
const String authorName = 'SYAIRA QISTINA BINTI HUSNI THAMRIN';
const String matricNo = '2024410596';
const String course = 'CS2515A';
const String githubUrl = 'https://github.com/syairaqistina-sketch/baggage_fee_app';
// -----------------------------------------------------

class BaggageApp extends StatelessWidget {
  const BaggageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Excess Baggage Fee Estimator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
      ),
      home: const MainPage(),
    );
  }
}

// ======================= MAIN PAGE + DRAWER =======================
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _index = 0;

  void _go(int i) {
    setState(() => _index = i);
    Navigator.pop(context); // close drawer
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flight_takeoff),
            SizedBox(width: 8),
            Text('Baggage Fee Estimator'),
          ],
        ),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.indigo),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'Excess Baggage\nFee Estimator',
                  style: TextStyle(color: Colors.white, fontSize: 22),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              selected: _index == 0,
              onTap: () => _go(0),
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('About'),
              selected: _index == 1,
              onTap: () => _go(1),
            ),
          ],
        ),
      ),
      body: _index == 0 ? const HomePage() : const AboutPage(),
    );
  }
}

// ============================ HOME PAGE ============================
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _weightCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  String _ticketClass = 'Economy';

  String? _error;
  double? _excessWeight;
  double? _charge;
  double? _total;

  @override
  void dispose() {
    _weightCtrl.dispose();
    _rateCtrl.dispose();
    super.dispose();
  }

  void _calculate() {
    final weight = double.tryParse(_weightCtrl.text.trim());
    final rate = double.tryParse(_rateCtrl.text.trim());

    if (weight == null || rate == null) {
      _showError('Please enter valid numbers for weight and rate.');
      return;
    }
    if (weight < 0 || rate < 0) {
      _showError('Weight and rate cannot be negative.');
      return;
    }

    final limit = _ticketClass == 'Economy' ? 20.0 : 40.0;
    final excess = (weight - limit) > 0 ? (weight - limit) : 0.0; // never negative
    final charge = excess * rate;
    final total = charge + (0.08 * charge);

    setState(() {
      _error = null;
      _excessWeight = excess;
      _charge = charge;
      _total = total;
    });
  }

  void _showError(String msg) {
    setState(() {
      _error = msg;
      _excessWeight = null;
      _charge = null;
      _total = null;
    });
  }

  void _reset() {
    setState(() {
      _weightCtrl.clear();
      _rateCtrl.clear();
      _ticketClass = 'Economy';
      _error = null;
      _excessWeight = null;
      _charge = null;
      _total = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Helpful instructions / notice
        Card(
          color: Colors.indigo.shade50,
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'How to use: enter your checked baggage weight, choose your ticket '
              'class and enter the excess rate per kg.\n'
              'Free allowance: Economy = 20 kg, Business = 40 kg.\n'
              'Note: 8% service tax is included in the total.',
            ),
          ),
        ),
        const SizedBox(height: 16),

        // INPUT 1: weight (TextField)
        TextField(
          controller: _weightCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Baggage weight (kg)',
            prefixIcon: Icon(Icons.luggage),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),

        // INPUT 2: ticket class (Dropdown = other widget)
        DropdownButtonFormField<String>(
          value: _ticketClass,
          decoration: const InputDecoration(
            labelText: 'Ticket class',
            prefixIcon: Icon(Icons.airline_seat_recline_normal),
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'Economy', child: Text('Economy (20 kg)')),
            DropdownMenuItem(value: 'Business', child: Text('Business (40 kg)')),
          ],
          onChanged: (v) => setState(() => _ticketClass = v!),
        ),
        const SizedBox(height: 16),

        // INPUT 3: rate (TextField)
        TextField(
          controller: _rateCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Excess baggage rate per kg (RM)',
            prefixIcon: Icon(Icons.attach_money),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _calculate,
                icon: const Icon(Icons.calculate),
                label: const Text('Calculate'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.refresh),
                label: const Text('Reset'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Error message
        if (_error != null)
          Card(
            color: Colors.red.shade50,
            child: ListTile(
              leading: const Icon(Icons.error, color: Colors.red),
              title: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          ),

        // OUTPUTS (formatted)
        if (_total != null)
          Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Result',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Divider(),
                  _row('Excess baggage weight',
                      '${_excessWeight!.toStringAsFixed(1)} kg'),
                  _row('Excess baggage charge',
                      'RM ${_charge!.toStringAsFixed(2)}'),
                  _row('Total amount payable (incl. 8% tax)',
                      'RM ${_total!.toStringAsFixed(2)}',
                      bold: true),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    final style = TextStyle(
      fontSize: 16,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}

// ============================ ABOUT PAGE ============================
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Future<void> _openUrl(BuildContext context) async {
    final ok = await launchUrl(
      Uri.parse(githubUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Application icon
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/icon.png',
                width: 100,
                height: 100,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.flight_takeoff,
                  size: 100,
                  color: Colors.indigo,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Excess Baggage Fee Estimator',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Author information
            const Text('Author Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Name: $authorName'),
            const Text('Matric No: $matricNo'),
            const Text('Course: $course'),
            const SizedBox(height: 24),

            // Clickable GitHub URL
            InkWell(
              onTap: () => _openUrl(context),
              child: const Text(
                githubUrl,
                style: TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),

            // Copyright notice
            const Text(
              '© 2026 $authorName. All rights reserved.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}