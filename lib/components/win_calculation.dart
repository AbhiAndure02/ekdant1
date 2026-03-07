import 'package:ekdant/models/bid_model.dart';
import 'package:ekdant/models/game_model.dart';
import 'package:ekdant/models/result_model.dart';
import 'package:ekdant/services/auth_service.dart';
import 'package:ekdant/services/bid_service.dart';
import 'package:ekdant/services/game_service.dart';
import 'package:ekdant/services/result_service.dart';
import 'package:flutter/material.dart';
import 'package:ekdant/models/win_model.dart';
import 'package:ekdant/services/win_service.dart';
import 'package:intl/intl.dart';

// ── Enriched win — win + its associated bid, game, result ──
class _WinDetail {
  final Win win;
  final Bid? bid;
  final GameResponse? game;
  final Result? result;

  _WinDetail({required this.win, this.bid, this.game, this.result});
}

class WinningBidsScreen extends StatefulWidget {
  const WinningBidsScreen({super.key});

  @override
  State<WinningBidsScreen> createState() => _WinningBidsScreenState();
}

class _WinningBidsScreenState extends State<WinningBidsScreen>
    with SingleTickerProviderStateMixin {
  final WinService _winService = WinService();
  final BidService _bidService = BidService();
  final GameService _gameService = GameService();
  final ResultService _resultService = ResultService();
  final AuthService _authService = AuthService();

  User? currentUser;
  bool _isLoading = true;
  List<_WinDetail> _winDetails = [];
  double _totalWon = 0;
  String? _error;

  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy  HH:mm');

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  // ── Theme ────────────────────────────────────────────────
  static const Color _dark = Color(0xFF0A1628);
  static const Color _surface = Color(0xFF162040);
  static const Color _cardBg = Color(0xFF1A2940);
  static const Color _gold = Color(0xFFD4A843);
  static const Color _goldLight = Color(0xFFF0C860);
  static const Color _green = Color(0xFF27AE60);
  static const Color _textPrimary = Color(0xFFF0F4FF);
  static const Color _textSecondary = Color(0xFF8A9BB5);

  // Pana-based games — show pana field, not digit
  static const _panaGames = {
    'SINGLE PANNA',
    'DUBBLE PANNA',
    'TRIPLE PANNA',
    'FAMILY PANNA',
    'CYCLE PATTI',
    'SP DP TP',
    'HALF SANGAM',
    'FULL SANGAM',
  };

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _initializeData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _winService.dispose();
    _gameService.dispose();
    _resultService.dispose();
    super.dispose();
  }

  // =========================================================
  // DATA LOADING
  // =========================================================

  Future<void> _initializeData() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _winDetails = [];
    });

    try {
      currentUser = await _authService.getUserData();
      if (currentUser == null) return;

      // Step 1 — fetch user's win records
      final winResponse = await _winService.getWinsByUser(currentUser!.id);
      _totalWon = winResponse.totalWonDouble;

      // Step 2 — fetch all results once (shared across all wins)
      List<Result> allResults = [];
      try {
        allResults = await _resultService.getAllResults();
      } catch (_) {}

      // Step 3 — enrich each win with its bid + game + result in parallel
      final details = await Future.wait(
        winResponse.wins.map((win) => _enrichWin(win, allResults)),
      );

      if (mounted) setState(() => _winDetails = details);
    } catch (e) {
      _error = e.toString();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading wins: $e'),
            backgroundColor: const Color(0xFFE74C3C),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _fadeController.forward(from: 0);
      }
    }
  }

  /// Fetch bid and game for one win; match result from cached list.
  Future<_WinDetail> _enrichWin(Win win, List<Result> allResults) async {
    Bid? bid;
    GameResponse? game;
    Result? result;

    try {
      if (win.bidId != null) {
        bid = await _bidService.getBidById(win.bidId!);
      }
    } catch (_) {}

    try {
      if (win.gameId != null) {
        game = await _gameService.getGameById(win.gameId!);
      }
    } catch (_) {}

    try {
      if (bid != null && allResults.isNotEmpty) {
        final match = allResults.firstWhere(
          (r) => r.marketId == bid!.marketId,
          orElse: () => Result.empty(),
        );
        if (match.id.isNotEmpty) result = match;
      }
    } catch (_) {}

    return _WinDetail(win: win, bid: bid, game: game, result: result);
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _dark,
      appBar: AppBar(
        title: const Text(
          'My Winning Bids',
          style: TextStyle(color: _textPrimary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: _dark,
        elevation: 0,
        iconTheme: const IconThemeData(color: _textPrimary),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0A1628), Color(0xFF162040)],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _isLoading
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
                      color: _textPrimary,
                      size: 20,
                    ),
            ),
            onPressed: _isLoading ? null : _initializeData,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _gold))
          : FadeTransition(
              opacity: _fadeAnim,
              child: RefreshIndicator(
                onRefresh: _initializeData,
                color: _gold,
                backgroundColor: _surface,
                child: _buildBody(),
              ),
            ),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: const Color(0xFFE74C3C).withOpacity(0.6),
            ),
            const SizedBox(height: 12),
            Text(
              'Error: $_error',
              style: const TextStyle(color: _textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _initializeData,
              icon: const Icon(Icons.refresh_rounded, color: _gold),
              label: const Text('Retry', style: TextStyle(color: _gold)),
            ),
          ],
        ),
      );
    }

    if (_winDetails.isEmpty) return _buildEmptyState();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _winDetails.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildSummaryBanner(_winDetails.length, _totalWon);
        }
        return _buildWinCard(_winDetails[index - 1]);
      },
    );
  }

  // =========================================================
  // WIDGETS
  // =========================================================

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: _gold.withOpacity(0.08),
              shape: BoxShape.circle,
              border: Border.all(color: _gold.withOpacity(0.2)),
            ),
            child: Icon(
              Icons.emoji_events_rounded,
              size: 44,
              color: _gold.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No Winning Bids Yet',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your winning bids will appear here.',
            style: TextStyle(color: _textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBanner(int count, double totalWinnings) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A2940), Color(0xFF162040)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _gold.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: _gold.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_gold, _goldLight]),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: _gold.withOpacity(0.4), blurRadius: 10),
              ],
            ),
            child: const Center(
              child: Icon(Icons.emoji_events_rounded, color: _dark, size: 26),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count Winning ${count == 1 ? 'Bid' : 'Bids'}',
                  style: const TextStyle(
                    color: _textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Total Earnings',
                  style: TextStyle(color: _textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '₹${totalWinnings.toStringAsFixed(2)}',
            style: const TextStyle(
              color: _gold,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWinCard(_WinDetail detail) {
    final win = detail.win;
    final bid = detail.bid;
    final game = detail.game;
    final result = detail.result;

    // Fallback: parse from details string if bid/game not loaded
    // Format: "GAME NAME | MARKET | Session | Points: X"
    final parts = win.details.split(' | ');
    final gameName = game?.gameName ?? (parts.isNotEmpty ? parts[0] : '—');
    final market = bid?.market ?? (parts.length > 1 ? parts[1] : '—');
    final session = bid?.session ?? (parts.length > 2 ? parts[2] : '—');
    final points =
        bid?.points ??
        (parts.length > 3 ? parts[3].replaceAll('Points: ', '') : '—');

    // Pana vs digit
    final isPanaGame = _panaGames.contains(gameName);
    final bidValue = bid != null
        ? (isPanaGame
              ? (bid.pana.isNotEmpty ? bid.pana : '—')
              : (bid.digit.isNotEmpty
                    ? bid.digit
                    : bid.pana.isNotEmpty
                    ? bid.pana
                    : '—'))
        : '—';
    final bidLabel = isPanaGame ? 'Pana' : 'Digit';

    // Result values
    final openDigit = result?.openResult ?? '—';
    final closeDigit = result?.closeResult ?? '—';
    final openPana = result?.openPana ?? '—';
    final closePana = result?.closePana ?? '—';

    final formattedDate = win.date != null
        ? _dateFormat.format(win.date!)
        : '—';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _green.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: _green.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Green accent bar
          Container(
            height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_green.withOpacity(0), _green, _green.withOpacity(0)],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '$market · $session',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _green.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _green.withOpacity(0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: _green,
                            size: 13,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'WON',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Bid info ─────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _infoRow(Icons.sports_esports_rounded, 'Game', gameName),
                      const SizedBox(height: 8),
                      _infoRow(
                        isPanaGame ? Icons.grid_3x3_rounded : Icons.tag_rounded,
                        bidLabel,
                        bidValue,
                      ),
                      const SizedBox(height: 8),
                      _infoRow(
                        Icons.access_time_rounded,
                        'Date',
                        formattedDate,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // ── Result info ──────────────────────────────
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'RESULT',
                        style: TextStyle(
                          color: _textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _resultBox(
                              label: 'Open',
                              digit: openDigit,
                              pana: openPana,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _resultBox(
                              label: 'Close',
                              digit: closeDigit,
                              pana: closePana,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ── Points & win amount ──────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _statBox(
                        label: 'Points',
                        value: points,
                        valueColor: _gold,
                        bgColor: _gold.withOpacity(0.08),
                        borderColor: _gold.withOpacity(0.2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: _statBox(
                        label: 'You Won',
                        value: '₹${win.amountDouble.toStringAsFixed(2)}',
                        valueColor: _green,
                        valueFontSize: 20,
                        bgColor: _green.withOpacity(0.12),
                        borderColor: _green.withOpacity(0.3),
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

  Widget _resultBox({
    required String label,
    required String digit,
    required String pana,
  }) {
    final hasDigit = digit.isNotEmpty && digit != '—';
    final hasPana = pana.isNotEmpty && pana != '—';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _gold.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hasDigit ? digit : '—',
            style: const TextStyle(
              color: _gold,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Text(
            hasPana ? 'Pana: $pana' : 'Pana: —',
            style: const TextStyle(color: _textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _statBox({
    required String label,
    required String value,
    required Color valueColor,
    required Color bgColor,
    required Color borderColor,
    double valueFontSize = 16,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(color: _textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.bold,
              fontSize: valueFontSize,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: _textSecondary),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(color: _textSecondary, fontSize: 12),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
