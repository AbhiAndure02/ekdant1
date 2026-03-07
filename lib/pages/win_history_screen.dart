import 'dart:async';
import 'package:ekdant/data/gameData.dart';
import 'package:ekdant/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:ekdant/models/game_model.dart';
import 'package:ekdant/services/game_service.dart';
import 'package:ekdant/models/bid_model.dart';
import 'package:ekdant/services/bid_service.dart';
import 'package:ekdant/models/result_model.dart';
import 'package:ekdant/services/result_service.dart';
import 'package:intl/intl.dart';

class CombinedListScreen extends StatefulWidget {
  const CombinedListScreen({super.key});

  @override
  State<CombinedListScreen> createState() => _CombinedListScreenState();
}

class _CombinedListScreenState extends State<CombinedListScreen> {
  final GameService _gameService = GameService();
  final BidService _bidService = BidService();
  final ResultService _resultService = ResultService();
  final AuthService _authService = AuthService();

  late Future<GameListResponse> _gamesFuture;
  late Future<List<Bid>> _bidsFuture;
  late Future<List<Result>> _resultsFuture;

  User? currentUser;
  bool _isLoading = true;

  // Theme
  static const Color _dark = Color(0xFF0A1628);
  static const Color _surface = Color(0xFF162040);
  static const Color _cardBg = Color(0xFF1A2940);
  static const Color _gold = Color(0xFFD4A843);
  static const Color _goldLight = Color(0xFFF0C860);
  static const Color _green = Color(0xFF27AE60);
  static const Color _red = Color(0xFFE74C3C);
  static const Color _textPrimary = Color(0xFFF0F4FF);
  static const Color _textSecondary = Color(0xFF8A9BB5);

  // ── Pana-based games — always show bid.pana for these ─────
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

  /// Returns the correct display value based on game type.
  /// Pana games  → always bid.pana
  /// Digit games → bid.digit (fallback to bid.pana if empty)
  String _displayValue(Bid bid, GameResponse game) {
    if (_panaGames.contains(game.gameName)) return bid.pana;
    return bid.digit.isNotEmpty ? bid.digit : bid.pana;
  }

  /// Returns correct label for the value row.
  String _displayLabel(GameResponse game) {
    return _panaGames.contains(game.gameName) ? 'Pana' : 'Digit';
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadAllData();
  }

  Future<void> _loadUserData() async {
    final user = await _authService.getUserData();
    if (user != null && mounted) setState(() => currentUser = user);
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      _gamesFuture = _gameService.getDetailedGameList();
      _bidsFuture = _bidService.getAllBids();
      _resultsFuture = _resultService.getAllResults();
      await Future.wait([_gamesFuture, _bidsFuture, _resultsFuture]);
    } catch (e) {
      debugPrint('Error loading data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: _red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshData() async {
    await _loadUserData();
    await _loadAllData();
  }

  // =========================================================
  // WIN CALCULATION — display only, no wallet changes
  // =========================================================

  Map<String, dynamic> _calculateWinnings(
    Bid bid,
    Result result,
    GameResponse game,
  ) {
    if (bid.marketId != result.marketId || bid.gameId != game.id) {
      return _loss();
    }
    if (bid.session == 'Open') return _calcOpen(bid, result, game);
    if (bid.session == 'Close') return _calcClose(bid, result, game);
    return _loss();
  }

  Map<String, dynamic> _calcOpen(Bid bid, Result result, GameResponse game) {
    final gameName = game.gameName;
    final bidDigit = bid.digit.trim();
    final bidPana = bid.pana.trim();
    final openResult = result.openResult.trim();
    final closeResult = result.closeResult.trim();
    final openPana = result.openPana.trim();
    final closePana = result.closePana.trim();
    final points = double.parse(bid.points);

    if (gameName == 'SINGLE DIGIT') {
      return bidDigit == openResult
          ? _win(points * 9.5, 'Open Single Digit')
          : _loss();
    }
    if (gameName == 'JODI DIGIT') {
      return bidDigit == '$openResult$closeResult'
          ? _win(points * 100, 'Jodi Digit')
          : _loss();
    }
    if (gameName == 'RED JODI FAMILY') {
      return bidDigit == '$openResult$closeResult'
          ? _win(points * 10, 'Red Jodi Family')
          : _loss();
    }
    if (gameName == 'RED JODI') {
      return bidDigit == '$openResult$closeResult'
          ? _win(points * 10, 'Red Jodi')
          : _loss();
    }
    if (gameName == 'JODI FAMILY') {
      return bidDigit == '$openResult$closeResult'
          ? _win(points * 10, 'Jodi Family')
          : _loss();
    }
    if (gameName == 'SINGLE PANNA') {
      return bidPana == openPana
          ? _win(points * 150, 'Open Single Pana')
          : _loss();
    }
    if (gameName == 'DUBBLE PANNA') {
      return bidPana == openPana
          ? _win(points * 300, 'Open Double Pana')
          : _loss();
    }
    if (gameName == 'TRIPLE PANNA') {
      return bidPana == openPana
          ? _win(points * 600, 'Open Triple Pana')
          : _loss();
    }
    if (gameName == 'CYCLE PATTI') {
      return bidPana == openPana
          ? _win(points * 140, 'Open Cycle Patti')
          : _loss();
    }
    if (gameName == 'FAMILY PANNA') {
      return bidPana == openPana
          ? _win(points * 150, 'Open Family Pana')
          : _loss();
    }
    if (gameName == 'SP DP TP') {
      return _calcSpDpTp(bid, openPana);
    }
    if (gameName == 'HALF SANGAM') {
      return bidPana == '$openPana-$closeResult'
          ? _win(points * 1200, 'Half Sangam (Open)')
          : _loss();
    }
    if (gameName == 'FULL SANGAM') {
      return bidPana == '$openPana-$closePana'
          ? _win(points * 12000, 'Full Sangam')
          : _loss();
    }
    return _loss();
  }

  Map<String, dynamic> _calcClose(Bid bid, Result result, GameResponse game) {
    final gameName = game.gameName;
    final bidDigit = bid.digit.trim();
    final bidPana = bid.pana.trim();
    final openResult = result.openResult.trim();
    final closeResult = result.closeResult.trim();
    final closePana = result.closePana.trim();
    final points = double.parse(bid.points);

    if (gameName == 'SINGLE DIGIT') {
      return bidDigit == closeResult
          ? _win(points * 9.5, 'Close Single Digit')
          : _loss();
    }
    if (gameName == 'SINGLE PANNA') {
      return bidPana == closePana
          ? _win(points * 150, 'Close Single Pana')
          : _loss();
    }
    if (gameName == 'DUBBLE PANNA') {
      return bidPana == closePana
          ? _win(points * 300, 'Close Double Pana')
          : _loss();
    }
    if (gameName == 'TRIPLE PANNA') {
      return bidPana == closePana
          ? _win(points * 600, 'Close Triple Pana')
          : _loss();
    }
    if (gameName == 'CYCLE PATTI') {
      return bidPana == closePana
          ? _win(points * 140, 'Close Cycle Patti')
          : _loss();
    }
    if (gameName == 'FAMILY PANNA') {
      return bidPana == closePana
          ? _win(points * 150, 'Close Family Pana')
          : _loss();
    }
    if (gameName == 'SP DP TP') {
      return _calcSpDpTp(bid, closePana);
    }
    if (gameName == 'HALF SANGAM') {
      return bidPana == '$openResult-$closePana'
          ? _win(points * 1200, 'Half Sangam (Close)')
          : _loss();
    }
    return _loss();
  }

  Map<String, dynamic> _calcSpDpTp(Bid bid, String resultPana) {
    final pana = bid.pana.trim();
    if (pana != resultPana.trim()) return _loss();
    if (GameData.triplePanaCombinations.contains(pana)) {
      return _win(double.parse(bid.points) * 600, 'SP DP TP · Triple Pana');
    }
    if (GameData.digitPanaMap.values.any((l) => l.contains(pana))) {
      return _win(double.parse(bid.points) * 300, 'SP DP TP · Double Pana');
    }
    if (GameData.panaCombinations.values.any((l) => l.contains(pana))) {
      return _win(double.parse(bid.points) * 150, 'SP DP TP · Single Pana');
    }
    return _loss();
  }

  double _fallbackMultiplier(String gameName, String pana) {
    switch (gameName) {
      case 'SINGLE DIGIT':
        return 9.5;
      case 'JODI DIGIT':
        return 100;
      case 'RED JODI FAMILY':
      case 'RED JODI':
      case 'JODI FAMILY':
        return 10;
      case 'SINGLE PANNA':
      case 'FAMILY PANNA':
        return 150;
      case 'DUBBLE PANNA':
        return 300;
      case 'TRIPLE PANNA':
        return 600;
      case 'CYCLE PATTI':
        return 140;
      case 'HALF SANGAM':
        return 1200;
      case 'FULL SANGAM':
        return 12000;
      case 'SP DP TP':
        final p = pana.trim();
        if (GameData.triplePanaCombinations.contains(p)) return 600;
        if (GameData.digitPanaMap.values.any((l) => l.contains(p))) return 300;
        if (GameData.panaCombinations.values.any((l) => l.contains(p))) {
          return 150;
        }
        return 150;
      default:
        return 0;
    }
  }

  Map<String, dynamic> _win(double amount, String type) => {
    'isWin': true,
    'winAmount': amount,
    'winType': type,
  };

  Map<String, dynamic> _loss() => {
    'isWin': false,
    'winAmount': 0.0,
    'winType': '',
  };

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _dark,
      appBar: AppBar(
        title: const Text(
          'Bid History',
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
            onPressed: _isLoading ? null : _refreshData,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _gold))
          : RefreshIndicator(
              onRefresh: _refreshData,
              color: _gold,
              backgroundColor: _surface,
              child: FutureBuilder(
                future: Future.wait([
                  _gamesFuture,
                  _bidsFuture,
                  _resultsFuture,
                ]),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 56,
                            color: _red.withOpacity(0.6),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Error: ${snapshot.error}',
                            style: const TextStyle(color: _textSecondary),
                          ),
                        ],
                      ),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(
                      child: Text(
                        'No data available',
                        style: TextStyle(color: _textSecondary),
                      ),
                    );
                  }

                  final games = (snapshot.data![0] as GameListResponse).games;
                  final bids = snapshot.data![1] as List<Bid>;
                  final results = snapshot.data![2] as List<Result>;

                  final userBids =
                      bids.where((b) => b.userId == currentUser?.id).toList()
                        ..sort((a, b) => b.date.compareTo(a.date));

                  if (userBids.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.sports_esports_rounded,
                            size: 64,
                            color: _textSecondary.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No bids found for your account',
                            style: TextStyle(
                              color: _textSecondary,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: userBids.length,
                    itemBuilder: (context, index) {
                      final bid = userBids[index];
                      final formattedDate = DateFormat(
                        'dd MMM yyyy HH:mm',
                      ).format(bid.date);

                      final result = results.firstWhere(
                        (r) => r.marketId == bid.marketId,
                        orElse: () => Result.empty(),
                      );
                      final game = games.firstWhere(
                        (g) => g.id == bid.gameId,
                        orElse: () => GameResponse.empty(),
                      );

                      final winInfo = _calculateWinnings(bid, result, game);
                      double winAmount = winInfo['winAmount'] as double;
                      String winType = winInfo['winType'] as String;

                      // Fallback: backend says win but local calc
                      // couldn't determine amount yet
                      if (bid.win == 'win' && winAmount == 0) {
                        final mult = _fallbackMultiplier(
                          game.gameName,
                          bid.pana.isNotEmpty ? bid.pana : bid.digit,
                        );
                        if (mult > 0) {
                          winAmount = double.parse(bid.points) * mult;
                          winType = game.gameName.isNotEmpty
                              ? game.gameName
                              : 'Win';
                        }
                      }

                      return _buildBidCard(
                        bid: bid,
                        game: game,
                        result: result,
                        formattedDate: formattedDate,
                        winAmount: winAmount,
                        winType: winType,
                      );
                    },
                  );
                },
              ),
            ),
    );
  }

  // =========================================================
  // CARD
  // =========================================================

  Widget _buildBidCard({
    required Bid bid,
    required GameResponse game,
    required Result result,
    required String formattedDate,
    required double winAmount,
    required String winType,
  }) {
    final bool isWin = bid.win == 'win';
    final bool isLoss = bid.win == 'loss';
    final bool isPending = !isWin && !isLoss;

    final Color statusColor = isWin ? _green : (isLoss ? _red : _gold);
    final String statusText = isWin ? 'Won' : (isLoss ? 'Lost' : 'Pending');
    final IconData statusIcon = isWin
        ? Icons.emoji_events_rounded
        : (isLoss ? Icons.cancel_rounded : Icons.hourglass_top_rounded);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(statusIcon, color: statusColor, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          game.gameName.isNotEmpty ? game.gameName : bid.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _textPrimary,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Detail block ─────────────────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  _dataRow('Market', bid.market),
                  const SizedBox(height: 6),
                  _dataRow('Session', bid.session),
                  const SizedBox(height: 6),
                  // ── Correct label & value per game type ─────
                  _dataRow(_displayLabel(game), _displayValue(bid, game)),
                  const SizedBox(height: 6),
                  _dataRow('Points Bet', '₹${bid.points}'),
                  const SizedBox(height: 6),
                  _dataRow('Date', formattedDate),
                  if (result.openResult.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(color: Colors.white10, height: 1),
                    ),
                    _dataRow(
                      'Open Result',
                      result.openResult,
                      valueColor: _goldLight,
                    ),
                  ],
                  if (result.openPana.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _dataRow(
                      'Open Pana',
                      result.openPana,
                      valueColor: _goldLight,
                    ),
                  ],
                  if (result.closeResult.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _dataRow(
                      'Close Result',
                      result.closeResult,
                      valueColor: _goldLight,
                    ),
                  ],
                  if (result.closePana.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _dataRow(
                      'Close Pana',
                      result.closePana,
                      valueColor: _goldLight,
                    ),
                  ],
                ],
              ),
            ),

            // ── Win banner ───────────────────────────────────
            if (isWin) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.emoji_events_rounded,
                      color: _green,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            winAmount > 0
                                ? '₹${winAmount.toStringAsFixed(2)} Won!'
                                : 'You Won!',
                            style: const TextStyle(
                              color: _green,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          if (winType.isNotEmpty)
                            Text(
                              winType,
                              style: const TextStyle(
                                color: _textSecondary,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Loss banner ──────────────────────────────────
            if (isLoss) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _red.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.cancel_rounded,
                      color: _red.withOpacity(0.8),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '₹${bid.points} lost on this bid',
                      style: TextStyle(
                        color: _red.withOpacity(0.8),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Pending banner ───────────────────────────────
            if (isPending) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _gold.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _gold.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.hourglass_top_rounded,
                      color: _gold.withOpacity(0.8),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Result not declared yet',
                      style: TextStyle(
                        color: _gold.withOpacity(0.8),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _dataRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: _textSecondary, fontSize: 12),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? _textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _gameService.dispose();
    _resultService.dispose();
    super.dispose();
  }
}
