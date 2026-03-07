import 'dart:async';
import 'package:ekdant/components/drawer_components.dart';
import 'package:ekdant/components/market_screen.dart';
import 'package:ekdant/pages/add_funds.dart';
import 'package:ekdant/pages/login_screen.dart';
import 'package:ekdant/pages/game_screen.dart';
import 'package:ekdant/pages/withdraw_request_screen.dart';
import 'package:ekdant/services/auth_service.dart';
import 'package:ekdant/services/market_service.dart';
import 'package:ekdant/services/result_service.dart';
import 'package:ekdant/services/wllet_service.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // Keys
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Services
  final MarketService _marketService = MarketService();
  final WalletService _walletService = WalletService();
  final AuthService _authService = AuthService();
  final ResultService _resultService = ResultService();

  // State variables
  double walletAmount = 0.0;
  String userName = '';
  String userNumber = '';
  String userId = '';
  bool _isRefreshing = false;

  // Subscriptions
  late StreamSubscription<double> _walletSubscription;

  // Animations
  late AnimationController _fadeController;
  late AnimationController _walletPulseController;
  late Animation<double> _fadeAnim;
  late Animation<double> _walletPulseAnim;

  // Theme constants
  static const Color _dark = Color(0xFF0A1628);
  static const Color _surface = Color(0xFF162040);
  static const Color _cardBg = Color(0xFF1A2940);
  static const Color _gold = Color(0xFFD4A843);
  static const Color _goldLight = Color(0xFFF0C860);
  static const Color _green = Color(0xFF27AE60);
  static const Color _red = Color(0xFFE74C3C);
  static const Color _textPrimary = Color(0xFFF0F4FF);
  static const Color _textSecondary = Color(0xFF8A9BB5);

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadInitialData();
    _setupWalletUpdates();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _walletPulseController.dispose();
    _walletSubscription.cancel();
    super.dispose();
  }

  // ==================== INITIALIZATION ====================

  void _initializeAnimations() {
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _walletPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _walletPulseAnim = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _walletPulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _loadInitialData() async {
    await _loadUserData();
    if (userId.isNotEmpty) await _refreshWalletBalance();
    _fadeController.forward();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await _authService.getUserData();
      if (user != null && mounted) {
        setState(() {
          userName = user.name;
          userNumber = user.number;
          walletAmount = double.tryParse(user.walletAmount ?? '0.0') ?? 0.0;
          userId = user.id;
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<void> _setupWalletUpdates() {
    _walletSubscription = _authService.walletUpdates.listen((balance) {
      if (mounted) setState(() => walletAmount = balance);
    });
    return Future.value();
  }

  // ==================== REFRESH ====================

  Future<void> _refreshData() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      await Future.wait([
        _loadUserData(),
        if (userId.isNotEmpty) _refreshWalletBalance(),
      ]);
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  Future<void> _refreshWalletBalance() async {
    try {
      final walletResponse = await _walletService.getWallet(userId);
      if (mounted) setState(() => walletAmount = walletResponse.walletAmount);
      await _authService.refreshUserWallet();
    } catch (e) {
      debugPrint('Error refreshing wallet: $e');
    }
  }

  // ==================== NAVIGATION ====================

  Future<void> _handleLogout() async {
    if (_scaffoldKey.currentState!.isDrawerOpen) Navigator.pop(context);

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => _buildLogoutDialog(),
    );

    if (shouldLogout == true) {
      final result = await _authService.logout();
      if (result['success'] == true && mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (r) => false,
        );
      }
    }
  }

  Widget _buildLogoutDialog() {
    return Dialog(
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
                color: _red.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded, color: _red, size: 28),
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
              'You will need to sign in again.',
              style: TextStyle(color: _textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
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
                      backgroundColor: _red,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
    );
  }

  void _navigateToScreen(BuildContext context, Widget screen) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _dark,
      drawer: AppDrawer(
        userName: userName,
        walletAmount: walletAmount,
        onLogout: _handleLogout,
        onNavigate: _navigateToScreen,
        isHomeSelected: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            _buildSliverAppBar(innerBoxIsScrolled),
          ],
          body: RefreshIndicator(
            onRefresh: _refreshData,
            color: _gold,
            backgroundColor: _surface,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _buildQuickActions(),
                  _buildMarketsSection(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(bool innerBoxIsScrolled) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: _dark,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
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
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: _isRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _gold,
                    ),
                  )
                : const Icon(
                    Icons.refresh_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
          ),
          onPressed: _refreshData,
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
          Positioned(
            top: -30,
            right: -30,
            child: _decorCircle(160, _gold.withOpacity(0.05)),
          ),
          Positioned(
            top: 50,
            right: 80,
            child: _decorCircle(60, _gold.withOpacity(0.04)),
          ),
          Positioned(
            bottom: 0,
            left: -20,
            child: _decorCircle(100, _gold.withOpacity(0.04)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName.isNotEmpty ? 'Welcome back,' : 'Welcome',
                            style: TextStyle(
                              color: _textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            userName.isNotEmpty ? userName : 'Player',
                            style: const TextStyle(
                              color: _textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ScaleTransition(
                      scale: _walletPulseAnim,
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AddFunds()),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_gold, _goldLight],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: _gold.withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.account_balance_wallet_rounded,
                                color: _dark,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '₹${walletAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: _dark,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
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

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _quickActionCard(
              icon: FontAwesomeIcons.sackDollar,
              label: 'Add Funds',
              color: _green,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddFunds()),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _quickActionCard(
              icon: FontAwesomeIcons.wallet,
              label: 'Withdraw',
              color: const Color(0xFF3498DB),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const WithdrawalRequestScreen(),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _quickActionCard(
              icon: FontAwesomeIcons.youtube,
              label: 'How to Play',
              color: const Color(0xFFE74C3C),
              onTap: () {
                // TODO: Implement how to play
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: FaIcon(icon, color: color, size: 18)),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarketsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_gold, _goldLight],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Live Markets',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _green.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: _green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'LIVE',
                      style: TextStyle(
                        color: _green,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: MarketListComponent(
            marketService: _marketService,
            resultService: _resultService,
            onMarketTap: (market) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GameScreen(
                    marketId: market.id,
                    marketName: market.name,
                    closeTimeOpen: market.closeTimeOpen,
                    closeTimeClose: market.closeTimeClose,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
