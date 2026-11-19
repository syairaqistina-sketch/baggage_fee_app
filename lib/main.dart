import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// Entry point: runApp() starts the app with BaggageApp as the root widget.
void main() => runApp(const BaggageApp());

//About Page 
const String authorName = 'SYAIRA QISTINA BINTI HUSNI THAMRIN'; 
const String matricNo = '2024410596';
const String course = 'CS2515A';
const String githubUrl = 'https://github.com/syairaqistina-sketch/baggage_fee_app';
// -----------------------------------------------------

// ---------- COLOURS (change here to re-theme the whole app) ----------
const Color kNavy = Color(0xFF0B2545);
const Color kSky = Color(0xFF5B8DB8);
const Color kPaper = Color(0xFFF2F6FA);
const Color kTag = Color(0xFFFFB400);
const Color kLine = Color(0xFFC9D5E1);
const Color kMuted = Color(0xFF52667A);

final BoxDecoration kCardBox = BoxDecoration( 
  color: Colors.white,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: kLine),
);

// ======================= APP ROOT =======================
class BaggageApp extends StatelessWidget {
  const BaggageApp({super.key});

  // MaterialApp sets the app title, theme and first page.
  @override
  Widget build(BuildContext context) {
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kLine),
    );

    return MaterialApp(
      title: 'Excess Baggage Fee Estimator', // shown in task switcher
      debugShowCheckedModeBanner: false, // remove the debug banner
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: kNavy),
        scaffoldBackgroundColor: kPaper,
        appBarTheme: const AppBarTheme(
          backgroundColor: kNavy,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: kPaper,
          prefixIconColor: kSky,
          border: fieldBorder,
          enabledBorder: fieldBorder,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kNavy, width: 2),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: kNavy,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: kNavy,
            minimumSize: const Size(0, 52),
            side: const BorderSide(color: kLine),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
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
  int _index = 0; // 0 = Home, 1 = About

  // setState rebuilds the screen with the new page; pop closes the drawer.
  void _go(int i) {
    setState(() => _index = i); // rebuild the screen with the new page
    Navigator.pop(context); // close the drawer
  }

  // Builds one menu row, so Home and About share the same code.
  Widget _drawerItem(IconData icon, String title, int i) { 
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        selected: _index == i,
        selectedColor: kNavy,
        selectedTileColor: const Color(0xFFFFF1CC),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () => _go(i),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flight_takeoff, color: kTag),
            SizedBox(width: 8),
            Text('Baggage Fee Estimator'), // shown in the app bar
          ],
        ),
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              margin: EdgeInsets.zero,
              decoration: BoxDecoration(
                color: kNavy,
                border: Border(bottom: BorderSide(color: kTag, width: 4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: kTag,
                    child: Icon(Icons.luggage, color: kNavy, size: 28),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Excess Baggage\nFee Estimator',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _drawerItem(Icons.home, 'Home', 0),
            _drawerItem(Icons.info, 'About', 1),
          ],
        ),
      ),
      // The ternary picks the page; the old page is removed, so typed text is lost.
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _index == 0
            ? const HomePage(key: ValueKey('home'))
            : const AboutPage(key: ValueKey('about')),
      ),
    );
  }
}

// Home page
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> { // the stateful page needs to store the text box values and results
  final _weightCtrl = TextEditingController(); // controller for the baggage weight input
  final _rateCtrl = TextEditingController();
  String _ticketClass = 'Economy'; // default selection

  // null = not calculated yet. Every one of these must be reset to null
  // in _showError() and _reset().
  String? _error;
  double? _excessWeight; 
  double? _charge;
  double? _total;
  double? _weight;
  double? _limit;

  // Frees the controllers when the page is removed (avoids a memory leak).
  @override
  void dispose() {
    _weightCtrl.dispose(); // frees the controller when the page is removed
    _rateCtrl.dispose();
    super.dispose();
  }

  // Runs on Calculate: read -> validate -> calculate -> show.
  // Example: Economy, 25 kg, RM10/kg -> excess 5, charge 50, total 54.
  void _calculate() {
    // tryParse gives null for bad input (parse would crash).
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

    // setState saves the results and rebuilds the screen.
    setState(() {
      _error = null;
      _excessWeight = excess;
      _charge = charge;
      _total = total;
      _weight = weight;
      _limit = limit;
    });
  }

  // Stores the message and clears old results.
  void _showError(String msg) { 
    setState(() {
      _error = msg;
      _excessWeight = null;
      _charge = null;
      _total = null;
      _weight = null;
      _limit = null;
    });
  }

  // Clears the text boxes and puts everything back to the start.
  void _reset() {
    setState(() {
      _weightCtrl.clear();
      _rateCtrl.clear();
      _ticketClass = 'Economy';
      _error = null;
      _excessWeight = null;
      _charge = null;
      _total = null;
      _weight = null;
      _limit = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeader(),
        const SizedBox(height: 20),
        _buildInputCard(),
        const SizedBox(height: 16),
        if (_error != null) _buildError(), // only shown when there is an error
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _total == null ? const SizedBox.shrink() : _buildResult(),
        ),
      ],
    );
  }

  Widget _buildHeader() { // The header with the title, allowance info and the dashed line.
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 2, 0, 2),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: kTag, width: 4)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Check your baggage',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: kNavy,
              height: 1.1,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Free allowance: Economy = 20 kg, Business = 40 kg.\n'
            'Note: 8% service tax is included in the total.',
            style: TextStyle(color: kMuted, height: 1.4),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.flight_takeoff, color: kSky, size: 20),
              SizedBox(width: 8),
              Expanded(child: _DashedLine()),
              SizedBox(width: 8),
              Icon(Icons.luggage, color: kSky, size: 20),
            ],
          ),
        ],
      ),
    );
  }

  // The three inputs and the Calculate / Reset buttons.
  Widget _buildInputCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: kCardBox,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Baggage details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: kNavy,
            ),
          ),
          const SizedBox(height: 16),

          // INPUT 1: weight
          TextField(
            controller: _weightCtrl, // controller allows us to read the text later
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Baggage weight (kg)',
              prefixIcon: Icon(Icons.luggage),
            ),
          ),
          const SizedBox(height: 16),

          // INPUT 2: ticket class. Tapping a card changes _ticketClass.
          const Text('Ticket class', style: TextStyle(color: kMuted)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _ClassOption(
                  icon: Icons.airline_seat_recline_normal,
                  title: 'Economy',
                  subtitle: '20 kg free',
                  selected: _ticketClass == 'Economy',
                  onTap: () => setState(() => _ticketClass = 'Economy'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ClassOption(
                  icon: Icons.business_center,
                  title: 'Business',
                  subtitle: '40 kg free',
                  selected: _ticketClass == 'Business',
                  onTap: () => setState(() => _ticketClass = 'Business'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // INPUT 3: rate per kg
          TextField(
            controller: _rateCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Excess baggage rate per kg (RM)',
              prefixIcon: Icon(Icons.attach_money),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                flex: 3,
                child: FilledButton.icon(
                  onPressed: _calculate,
                  icon: const Icon(Icons.calculate),
                  label: const Text('Calculate'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF5B5AE)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: Text(_error!, style: TextStyle(color: Colors.red.shade800)),
          ),
        ],
      ),
    );
  }

  // The result tag: gauge bar, status chip, numbers and the counting total.
  // Only built when _total is not null.
  Widget _buildResult() {
    final over = _excessWeight! > 0;
    final ratio = _weight! / _limit!;
    final barValue = ratio > 1 ? 1.0 : ratio; // the bar cannot go past full
    final statusColor = over ? Colors.red.shade700 : Colors.green.shade700;

    return Container(
      key: ValueKey(_total),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kLine),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: kTag,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: const Row(
              children: [
                Icon(Icons.luggage, color: kNavy),
                SizedBox(width: 8),
                Text(
                  'Result',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: kNavy,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Your bag: ${_weight!.toStringAsFixed(1)} kg',
                        style: const TextStyle(color: kMuted)),
                    Text('Allowance: ${_limit!.toStringAsFixed(0)} kg',
                        style: const TextStyle(color: kMuted)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: barValue,
                    minHeight: 10,
                    backgroundColor: kLine,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: over ? Colors.red.shade50 : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        over ? Icons.warning_amber : Icons.check_circle,
                        size: 16,
                        color: statusColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        over ? 'Overweight' : 'Within allowance',
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _row('Excess baggage weight',
                    '${_excessWeight!.toStringAsFixed(1)} kg'),
                _row('Excess baggage charge',
                    'RM ${_charge!.toStringAsFixed(2)}'),
                const SizedBox(height: 12),
                const _DashedLine(),
                const SizedBox(height: 14),
                // LIVE CHANGE: the "8%" here is typed by hand.
                const Text(
                  'Total amount payable (incl. 8% tax)',
                  style: TextStyle(color: kMuted, fontSize: 14),
                ),
                const SizedBox(height: 2),
                // The total counts up from 0 to the real value.
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: _total!),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) => Text(
                    'RM ${value.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: kNavy,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Builds one result line (label left, value right), reused for each line.
  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(fontSize: 16, color: kMuted)),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: kNavy,
            ),
          ),
        ],
      ),
    );
  }
}

// Our own reusable widget: one tappable ticket-class card.

class _ClassOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _ClassOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? kNavy : kPaper,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? kNavy : kLine, width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? kTag : kSky),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : kNavy,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: selected ? Colors.white70 : kMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Dashed "tear here" line: LayoutBuilder gives the width, then we draw
// as many small dashes as fit.
class _DashedLine extends StatelessWidget {
  const _DashedLine();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = (constraints.maxWidth / 10).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            count,
            (_) => const SizedBox(
              width: 5,
              height: 1.5,
              child: DecoratedBox(decoration: BoxDecoration(color: kLine)),
            ),
          ),
        );
      },
    );
  }
}

// ============================ ABOUT PAGE ============================
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  // Opens the GitHub link. async/await waits for the browser without
  // freezing the app; context.mounted checks the screen still exists.
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

  // One line of author info: small label above a bold value.
  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: kMuted)),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: kNavy,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
            decoration: const BoxDecoration(
              color: kNavy,
              border: Border(bottom: BorderSide(color: kTag, width: 4)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    // Shows assets/icon.png; if it is missing, shows an Icon.
                    child: Image.asset(
                      'assets/icon.png',
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.flight_takeoff,
                        size: 100,
                        color: kNavy,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Excess Baggage Fee Estimator',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Author information
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: kCardBox,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Author Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: kNavy,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _infoRow('Name', authorName),
                      const _DashedLine(),
                      _infoRow('Matric No', matricNo),
                      const _DashedLine(),
                      _infoRow('Course', course),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Clickable GitHub URL: InkWell makes the card tappable.
                Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: kCardBox,
                  child: InkWell(
                    onTap: () => _openUrl(context),
                    child: const Padding(
                      padding: EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Icon(Icons.code, color: kSky, size: 30),
                          SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Source code on GitHub',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: kNavy,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  githubUrl,
                                  style: TextStyle(
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.open_in_new, color: kSky),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Copyright notice ($authorName inserts the constant's value)
                const Text(
                  '© 2026 $authorName. All rights reserved.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: kMuted, fontSize: 12.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}