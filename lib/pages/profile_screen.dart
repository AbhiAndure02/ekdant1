import 'dart:convert';
import 'package:ekdant/services/wllet_service.dart';
import 'package:flutter/material.dart';
import 'package:ekdant/services/auth_service.dart';
import 'package:ekdant/components/drawer_components.dart';
import 'package:http/http.dart' as http;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AuthService _authService = AuthService();
  final WalletService _walletService = WalletService();

  String userName = '';
  String userNumber = '';
  double walletAmount = 0.0;
  bool _isLoading = true;
  bool _isUpdating = false;
  bool _bankDetailsExpanded = false;

  String? accountNumber;
  String? bankHolderName;
  String? bankName;
  String? ifsc;
  String? upi;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _accountNumberController =
      TextEditingController();
  final TextEditingController _bankHolderNameController =
      TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _ifscController = TextEditingController();
  final TextEditingController _upiController = TextEditingController();

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // Deep navy + gold theme
  static const Color _navy = Color(0xFF0A1628);
  static const Color _navyLight = Color(0xFF162040);
  static const Color _gold = Color(0xFFD4A843);
  static const Color _goldLight = Color(0xFFF0C860);
  static const Color _surface = Color(0xFF1A2940);
  static const Color _textPrimary = Color(0xFFF0F4FF);
  static const Color _textSecondary = Color(0xFF8A9BB5);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );
    _loadUserData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _accountNumberController.dispose();
    _bankHolderNameController.dispose();
    _bankNameController.dispose();
    _ifscController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.getUserData();
      if (user != null && mounted) {
        setState(() {
          userName = user.name;
          userNumber = user.number;
          walletAmount = double.tryParse(user.walletAmount ?? '0.0') ?? 0.0;
          accountNumber = user.accountNumber;
          bankHolderName = user.bankHolderName;
          bankName = user.bankName;
          ifsc = user.ifsc;
          upi = user.upi;
          _accountNumberController.text = accountNumber ?? '';
          _bankHolderNameController.text = bankHolderName ?? '';
          _bankNameController.text = bankName ?? '';
          _ifscController.text = ifsc ?? '';
          _upiController.text = upi ?? '';
        });
        await _refreshWalletBalance(user.id);
        _fadeController.forward();
        _slideController.forward();
      }
    } catch (e) {
      if (mounted) _showSnackbar('Failed to load profile: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshWalletBalance(String userId) async {
    try {
      final walletResponse = await _walletService.getWallet(userId);
      if (mounted) setState(() => walletAmount = walletResponse.walletAmount);
    } catch (_) {}
  }

  Future<void> _updateBankDetails() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isUpdating = true);
    try {
      final user = await _authService.getUserData();
      if (user == null) throw Exception('User not authenticated');

      final response = await http.put(
        Uri.parse('https://api.ekadantaa.in/api/user/${user.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _authService.getToken()}',
        },
        body: json.encode({
          'accountNumber': _accountNumberController.text,
          'bankHolderName': _bankHolderNameController.text,
          'bankName': _bankNameController.text,
          'ifsc': _ifscController.text,
          'upi': _upiController.text,
          'walletAmount': walletAmount.toStringAsFixed(2),
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          accountNumber = _accountNumberController.text;
          bankHolderName = _bankHolderNameController.text;
          bankName = _bankNameController.text;
          ifsc = _ifscController.text;
          upi = _upiController.text;
        });
        await _authService.refreshUserData();
        if (mounted) _showSnackbar('Bank details updated!', isError: false);
      } else {
        throw Exception('Failed: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) _showSnackbar('Update failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  void _showSnackbar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: isError
            ? const Color(0xFFE74C3C)
            : const Color(0xFF27AE60),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFE74C3C).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFE74C3C),
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Log Out?',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You will need to sign in again to access your account.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: _textSecondary.withOpacity(0.3),
                          ),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: _textSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE74C3C),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Log Out',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (shouldLogout == true && mounted) {
      final result = await _authService.logout();
      if (result['success'] == true && mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _navy,
      drawer: AppDrawer(
        userName: userName,
        walletAmount: walletAmount,
        onLogout: _handleLogout,
        onNavigate: (context, screen) {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => screen),
          );
        },
      ),
      body: _isLoading
          ? _buildLoader()
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildSliverAppBar(),
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          _buildStatsRow(),
                          const SizedBox(height: 24),
                          _buildInfoSection(),
                          const SizedBox(height: 16),
                          _buildBankSection(),
                          const SizedBox(height: 24),
                          _buildLogoutButton(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLoader() {
    return Container(
      color: _navy,
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(_gold),
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: _navy,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.menu_rounded, color: Colors.white, size: 20),
        ),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.refresh_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          onPressed: _loadUserData,
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(background: _buildHeroHeader()),
    );
  }

  Widget _buildHeroHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A1628), Color(0xFF162040), Color(0xFF1A2940)],
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -40,
            right: -40,
            child: _decorCircle(180, _gold.withOpacity(0.06)),
          ),
          Positioned(
            top: 40,
            right: 60,
            child: _decorCircle(80, _gold.withOpacity(0.04)),
          ),
          Positioned(
            bottom: -20,
            left: -30,
            child: _decorCircle(120, _gold.withOpacity(0.05)),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Avatar
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
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
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: _navy,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: const Color(0xFF27AE60),
                        shape: BoxShape.circle,
                        border: Border.all(color: _navy, width: 2),
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  userName,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.phone_rounded, color: _textSecondary, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      userNumber,
                      style: const TextStyle(
                        color: _textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _decorCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _surface,
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
        child: Row(
          children: [
            Expanded(
              child: _buildStatItem(
                Icons.account_balance_wallet_rounded,
                'Wallet Balance',
                '₹${walletAmount.toStringAsFixed(2)}',
                _gold,
              ),
            ),
            Container(
              width: 1,
              height: 50,
              color: _textSecondary.withOpacity(0.2),
            ),
            Expanded(
              child: _buildStatItem(
                Icons.verified_user_rounded,
                'Account Status',
                'Active',
                const Color(0xFF27AE60),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: _textSecondary, fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    return _buildCard(
      title: 'Personal Info',
      icon: Icons.person_rounded,
      child: Column(
        children: [
          _buildInfoRow(Icons.badge_rounded, 'Full Name', userName),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.phone_rounded, 'Mobile Number', userNumber),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _gold.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _gold, size: 18),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: _textSecondary, fontSize: 11),
            ),
            Text(
              value.isNotEmpty ? value : '—',
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBankSection() {
    final hasBankDetails =
        accountNumber != null &&
        accountNumber!.trim().isNotEmpty &&
        accountNumber != ' ';

    return _buildCard(
      title: 'Bank Details',
      icon: Icons.account_balance_rounded,
      trailing: GestureDetector(
        onTap: () =>
            setState(() => _bankDetailsExpanded = !_bankDetailsExpanded),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _gold.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _bankDetailsExpanded
                    ? 'Close'
                    : (hasBankDetails ? 'Edit' : 'Add'),
                style: const TextStyle(
                  color: _gold,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                _bankDetailsExpanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: _gold,
                size: 16,
              ),
            ],
          ),
        ),
      ),
      child: Column(
        children: [
          // Show summary if has data and not editing
          if (!_bankDetailsExpanded && hasBankDetails) ...[
            _buildInfoRow(
              Icons.credit_card_rounded,
              'Account Number',
              _maskAccount(accountNumber ?? ''),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.business_rounded, 'Bank', bankName ?? '—'),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.payment_rounded, 'UPI ID', upi ?? '—'),
          ],
          if (!_bankDetailsExpanded && !hasBankDetails)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: _textSecondary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'No bank details added yet',
                    style: TextStyle(color: _textSecondary, fontSize: 14),
                  ),
                ],
              ),
            ),
          // Edit form
          if (_bankDetailsExpanded) ...[
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildTextField(
                    _accountNumberController,
                    'Account Number',
                    Icons.credit_card_rounded,
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Required'
                        : v.length < 9
                        ? 'Enter valid account number'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    _bankHolderNameController,
                    'Account Holder Name',
                    Icons.person_rounded,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    _bankNameController,
                    'Bank Name',
                    Icons.business_rounded,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    _ifscController,
                    'IFSC Code',
                    Icons.tag_rounded,
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Required'
                        : v.length < 8
                        ? 'Enter valid IFSC'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    _upiController,
                    'UPI ID',
                    Icons.payment_rounded,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isUpdating ? null : _updateBankDetails,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _gold,
                        disabledBackgroundColor: _gold.withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: _isUpdating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(_navy),
                              ),
                            )
                          : const Text(
                              'Save Bank Details',
                              style: TextStyle(
                                color: _navy,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _maskAccount(String account) {
    if (account.length <= 4) return account;
    return '${'*' * (account.length - 4)}${account.substring(account.length - 4)}';
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: const TextStyle(color: _textPrimary, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _textSecondary, fontSize: 14),
        prefixIcon: Icon(icon, color: _gold, size: 20),
        filled: true,
        fillColor: _navy.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _textSecondary.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _textSecondary.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _gold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE74C3C)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE74C3C)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _surface,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_gold, _goldLight]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: _navy, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                ?trailing,
              ],
            ),
            const SizedBox(height: 16),
            Container(height: 1, color: Colors.white.withOpacity(0.06)),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton.icon(
          onPressed: _handleLogout,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE74C3C).withOpacity(0.12),
            foregroundColor: const Color(0xFFE74C3C),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE74C3C), width: 1),
            ),
          ),
          icon: const Icon(Icons.logout_rounded, size: 20),
          label: const Text(
            'Log Out',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
