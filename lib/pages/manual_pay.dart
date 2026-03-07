import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class ManualPay extends StatefulWidget {
  const ManualPay({super.key});

  @override
  State<ManualPay> createState() => _ManualPayState();
}

class _ManualPayState extends State<ManualPay>
    with SingleTickerProviderStateMixin {
  bool _copied = false;
  bool _isLoading = true;
  String _errorMessage = '';
  String _upiId = '';
  String _whatsappNumber = '';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(); // ✅ Added

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  static const Color _dark = Color(0xFF0A1628);
  static const Color _surface = Color(0xFF162040);
  static const Color _cardBg = Color(0xFF1A2940);
  static const Color _gold = Color(0xFFD4A843);
  static const Color _goldLight = Color(0xFFF0C860);
  static const Color _green = Color(0xFF27AE60);
  static const Color _textPrimary = Color(0xFFF0F4FF);
  static const Color _textSecondary = Color(0xFF8A9BB5);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fetchUserDetails();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      // ✅ Read token from secure storage
      final token = await _storage.read(key: 'auth_token');

      if (token == null || token.isEmpty) {
        setState(() {
          _errorMessage = 'Not logged in. Please sign in again.';
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('https://api.ekadantaa.in/api/user/69a44e9b33b9207fc0985ac2'),
        headers: {
          'Authorization': 'Bearer $token', // ✅ Token added
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _upiId = data['upi'] ?? '';
          _whatsappNumber = data['waNumber']?.replaceAll('+', '') ?? '';
          _isLoading = false;
        });
        _fadeController.forward();
      } else {
        setState(() {
          _errorMessage = 'Failed to load UPI ID. (${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection error.';
        _isLoading = false;
      });
    }
  }

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: _upiId));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text('UPI ID copied!'),
          ],
        ),
        backgroundColor: _green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openWhatsApp() async {
    if (_whatsappNumber.isEmpty) return;
    final Uri waUri = Uri.parse(
      "whatsapp://send?phone=+$_whatsappNumber&text=Hi%20I%20need%20help",
    );
    final Uri waWeb = Uri.parse(
      "https://wa.me/$_whatsappNumber?text=Hi%20I%20need%20help",
    );
    try {
      await launchUrl(waUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      try {
        await launchUrl(waWeb, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _dark,
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(_gold),
                strokeWidth: 2,
              ),
            )
          : _errorMessage.isNotEmpty
          ? _buildError()
          : FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildUpiCard(),
                    const SizedBox(height: 16),
                    _buildInstructionsCard(),
                    const SizedBox(height: 16),
                    _buildCopyAllButton(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded, color: _textSecondary, size: 48),
          const SizedBox(height: 12),
          Text(
            _errorMessage,
            style: const TextStyle(color: _textSecondary, fontSize: 15),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _fetchUserDetails,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _gold,
              foregroundColor: _dark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpiCard() {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _gold.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_gold.withOpacity(0.12), _gold.withOpacity(0.04)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_gold, _goldLight]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.payment_rounded,
                    color: _dark,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Payment Details',
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: Colors.white.withOpacity(0.06)),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'UPI ID',
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 12,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: _dark.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _gold.withOpacity(0.25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.alternate_email_rounded,
                        color: _gold,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _upiId,
                          style: const TextStyle(
                            color: _textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _copyToClipboard,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _copied
                                ? _green.withOpacity(0.15)
                                : _gold.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _copied ? Icons.check_rounded : Icons.copy_rounded,
                            color: _copied ? _green : _gold,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _openWhatsApp,
                    icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 18),
                    label: const Text(
                      'Send Screenshot on WhatsApp',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
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

  Widget _buildInstructionsCard() {
    final steps = [
      (Icons.content_copy_rounded, 'Copy the UPI ID shown above'),
      (Icons.open_in_new_rounded, 'Open any UPI app (GPay, PhonePe, Paytm)'),
      (Icons.send_rounded, 'Transfer your desired amount'),
      (
        Icons.screenshot_monitor_rounded,
        'Take screenshot of payment confirmation',
      ),
      (
        Icons.transfer_within_a_station_outlined,
        'Send screenshot via WhatsApp button',
      ),
      (
        Icons.account_balance_wallet_rounded,
        'Wallet will be credited immediately',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.info_outline_rounded,
                    color: Colors.blueAccent,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'How to Add Funds',
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(height: 1, color: Colors.white.withOpacity(0.06)),
            const SizedBox(height: 16),
            ...steps.asMap().entries.map(
              (e) => _buildStep(e.key + 1, e.value.$1, e.value.$2),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _gold.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _gold.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: _gold,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Always verify payment with our support team',
                      style: TextStyle(
                        color: _gold.withOpacity(0.9),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(int number, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_gold, _goldLight]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  color: _dark,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, color: _textSecondary, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: _textPrimary, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCopyAllButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: _upiId.isEmpty
            ? null
            : () {
                Clipboard.setData(ClipboardData(text: 'UPI ID: $_upiId'));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Text('All details copied!'),
                      ],
                    ),
                    backgroundColor: _green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              },
        icon: const Icon(Icons.copy_all_rounded, size: 18),
        label: const Text(
          'Copy All Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: _gold,
          side: BorderSide(color: _gold.withOpacity(0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
