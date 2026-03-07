import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:share_plus/share_plus.dart';

import 'package:ekdant/components/bottom_screen.dart';
import 'package:ekdant/components/win_calculation.dart';
import 'package:ekdant/pages/bid_history.dart';
import 'package:ekdant/pages/game_rate_screen.dart';
import 'package:ekdant/pages/notification_screen.dart';
import 'package:ekdant/pages/profile_screen.dart';
import 'package:ekdant/pages/transaction_history.dart';
import 'package:ekdant/pages/withdraw_request_screen.dart';

class AppDrawer extends StatelessWidget {
  final String userName;
  final double walletAmount;
  final VoidCallback onLogout;
  final Function(BuildContext, Widget) onNavigate;
  final bool isHomeSelected;

  // Theme — matches HomeScreen exactly
  static const Color _dark = Color(0xFF0A1628);
  static const Color _surface = Color(0xFF162040);
  static const Color _cardBg = Color(0xFF1A2940);
  static const Color _gold = Color(0xFFD4A843);
  static const Color _goldLight = Color(0xFFF0C860);
  static const Color _green = Color(0xFF27AE60);
  static const Color _textPrimary = Color(0xFFF0F4FF);
  static const Color _textSecondary = Color(0xFF8A9BB5);

  const AppDrawer({
    super.key,
    required this.userName,
    required this.walletAmount,
    required this.onLogout,
    required this.onNavigate,
    this.isHomeSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.80,
      elevation: 24,
      shadowColor: Colors.black.withOpacity(0.6),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_dark, _surface, _cardBg],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Column(
          children: [
            _buildDrawerHeader(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildSectionLabel('MAIN'),
                  _buildDrawerItem(
                    context: context,
                    icon: FontAwesomeIcons.house,
                    title: 'Home',
                    isSelected: isHomeSelected,
                    onTap: () => onNavigate(context, const BottomScreen()),
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: FontAwesomeIcons.wallet,
                    title: 'Withdraw Request',
                    onTap: () =>
                        onNavigate(context, const WithdrawalRequestScreen()),
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: FontAwesomeIcons.user,
                    title: 'My Profile',
                    onTap: () => onNavigate(context, const ProfileScreen()),
                  ),

                  const SizedBox(height: 8),
                  _buildSectionLabel('HISTORY'),
                  _buildDrawerItem(
                    context: context,
                    icon: FontAwesomeIcons.clockRotateLeft,
                    title: 'Bid History',
                    onTap: () => onNavigate(context, const BidHistory()),
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: FontAwesomeIcons.fileInvoiceDollar,
                    title: 'Transaction History',
                    onTap: () =>
                        onNavigate(context, const TransactionHistory()),
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: FontAwesomeIcons.trophy,
                    title: 'Win History',
                    accent: _gold,
                    onTap: () => onNavigate(context, const WinningBidsScreen()),
                  ),

                  const SizedBox(height: 8),
                  _buildSectionLabel('MORE'),
                  _buildDrawerItem(
                    context: context,
                    icon: FontAwesomeIcons.chartBar,
                    title: 'Games Rates',
                    onTap: () => onNavigate(context, const GameRateScreen()),
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: FontAwesomeIcons.bell,
                    title: 'Notification',
                    onTap: () => onNavigate(context, NotificationScreen()),
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: FontAwesomeIcons.shareNodes,
                    title: 'Share App',
                    onTap: () {
                      Share.share(
                        '🚀 Check out Ekadantaa App!\n\nDownload now: https://ekadantaa.in',
                        subject: 'Ekadantaa App - Fast & Secure',
                      );
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),

            // Logout at bottom
            _buildLogoutButton(context),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      decoration: BoxDecoration(
        color: _dark,
        border: Border(
          bottom: BorderSide(color: _gold.withOpacity(0.2), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Decorative circles
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [_gold, _goldLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _gold.withOpacity(0.4),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: FaIcon(FontAwesomeIcons.user, size: 28, color: _dark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            userName.isNotEmpty ? userName : 'Guest',
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          // Wallet pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: _gold.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _gold.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: _gold,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  '₹${walletAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: _gold,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      child: Text(
        label,
        style: TextStyle(
          color: _textSecondary.withOpacity(0.5),
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    bool isSelected = false,
    Color? accent,
    VoidCallback? onTap,
  }) {
    final itemColor = isSelected ? _gold : (accent ?? _textSecondary);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? _gold.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isSelected ? Border.all(color: _gold.withOpacity(0.25)) : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: itemColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Center(child: FaIcon(icon, color: itemColor, size: 15)),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? _textPrimary : _textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        trailing: isSelected
            ? Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: _gold,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: onTap ?? () {},
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: GestureDetector(
        onTap: onLogout,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: const Color(0xFFE74C3C).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE74C3C).withOpacity(0.3)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(
                FontAwesomeIcons.rightFromBracket,
                color: Color(0xFFE74C3C),
                size: 15,
              ),
              SizedBox(width: 10),
              Text(
                'Log Out',
                style: TextStyle(
                  color: Color(0xFFE74C3C),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
