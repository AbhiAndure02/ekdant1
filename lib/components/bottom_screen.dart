import 'package:ekdant/pages/add_funds.dart';
import 'package:ekdant/pages/bid_history.dart';
import 'package:ekdant/pages/home_screen.dart';
import 'package:ekdant/pages/transaction_history.dart';
import 'package:ekdant/services/token_helper.dart'; // ✅ Added
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BottomScreen extends StatefulWidget {
  const BottomScreen({super.key});

  @override
  State<BottomScreen> createState() => _BottomScreenState();
}

class _BottomScreenState extends State<BottomScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 2;
  String _whatsappNumber = '';

  static const Color _dark = Color(0xFF0A1628);
  static const Color _surface = Color(0xFF162040);
  static const Color _gold = Color(0xFFD4A843);
  static const Color _goldLight = Color(0xFFF0C860);
  static const Color _textSecondary = Color(0xFF8A9BB5);

  final List<Widget> _pages = [
    const BidHistory(),
    const TransactionHistory(),
    const HomeScreen(),
    const AddFunds(),
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserWhatsapp();
  }

  Future<void> _fetchUserWhatsapp() async {
    try {
      final headers = await TokenHelper.getAuthHeaders(); // ✅ Auth headers
      final response = await http.get(
        Uri.parse('https://api.ekadantaa.in/api/user/69a44e9b33b9207fc0985ac2'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _whatsappNumber = data['waNumber']?.replaceAll('+', '') ?? '';
        });
      }
    } catch (e) {
      debugPrint("Error fetching WhatsApp number: $e");
    }
  }

  void _onItemTapped(int index) async {
    if (index == 4) {
      if (_whatsappNumber.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text("WhatsApp number not available"),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFE74C3C),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        return;
      }
      final Uri waApp = Uri.parse(
        "whatsapp://send?phone=+$_whatsappNumber&text=Hi%20I%20need%20help",
      );
      final Uri waWeb = Uri.parse(
        "https://wa.me/$_whatsappNumber?text=Hi%20I%20need%20help",
      );
      try {
        await launchUrl(waApp, mode: LaunchMode.externalApplication);
      } catch (_) {
        try {
          await launchUrl(waWeb, mode: LaunchMode.externalApplication);
        } catch (_) {}
      }
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _dark,
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(index: 0, icon: FontAwesomeIcons.gavel, label: 'Bids'),
              _navItem(
                index: 1,
                icon: FontAwesomeIcons.clockRotateLeft,
                label: 'History',
              ),
              _homeButton(),
              _navItem(
                index: 3,
                icon: FontAwesomeIcons.buildingColumns,
                label: 'Funds',
              ),
              _navItem(
                index: 4,
                icon: Icons.support_agent_rounded,
                label: 'Help',
                isFa: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required int index,
    required IconData icon,
    required String label,
    bool isFa = true,
  }) {
    final bool selected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _gold.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            isFa
                ? FaIcon(
                    icon,
                    size: 20,
                    color: selected ? _gold : _textSecondary,
                  )
                : Icon(
                    icon,
                    size: 22,
                    color: selected ? _gold : _textSecondary,
                  ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? _gold : _textSecondary,
                fontSize: 11,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _homeButton() {
    final bool selected = _selectedIndex == 2;
    return GestureDetector(
      onTap: () => _onItemTapped(2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.translate(
            offset: const Offset(0, -16),
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_gold, _goldLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _gold.withOpacity(0.45),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: selected
                      ? Colors.white.withOpacity(0.3)
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.home_rounded,
                size: 28,
                color: selected ? _dark : _dark.withOpacity(0.7),
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -12),
            child: Text(
              'Home',
              style: TextStyle(
                color: selected ? _gold : _textSecondary,
                fontSize: 11,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
