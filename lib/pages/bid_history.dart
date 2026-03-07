import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ekdant/services/bid_service.dart';
import 'package:ekdant/services/game_service.dart';
import 'package:ekdant/services/auth_service.dart';
import 'package:ekdant/models/bid_model.dart';
import 'package:ekdant/models/game_model.dart';

class BidHistory extends StatefulWidget {
  const BidHistory({super.key});

  @override
  State<BidHistory> createState() => _BidHistoryState();
}

class _BidHistoryState extends State<BidHistory> {
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  bool _showBids = false;
  bool _isLoading = false;
  List<Bid> _bids = [];
  Map<String, GameResponse> _games = {};
  String _currentUserId = '';

  final BidService _bidService = BidService();
  final GameService _gameService = GameService();
  final AuthService _authService = AuthService();

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

  // Game types that should show PANA instead of DIGIT
  final Set<String> _panaGameTypes = {
    'DUBBLE PANNA',
    'TRIPLE PANNA',
    'SP DP TP',
    'FAMILY PANNA',
    'SINGLE PANNA',
    'CYCLE PATTI',
  };

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadGames();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _authService.getUserData();
      if (user != null && mounted) {
        setState(() => _currentUserId = user.id);
      }
    } catch (e) {
      debugPrint('Error loading current user: $e');
    }
  }

  Future<void> _loadGames() async {
    try {
      final gameList = await _gameService.getDetailedGameList();
      final gamesMap = {for (var game in gameList.games) game.id: game};
      setState(() => _games = gamesMap);
    } catch (e) {
      debugPrint('Error loading games: $e');
    }
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: _gold,
            onPrimary: _dark,
            surface: _surface,
            onSurface: _textPrimary,
          ),
          dialogTheme: DialogThemeData(backgroundColor: _cardBg),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        _showBids = false;
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: _gold,
            onPrimary: _dark,
            surface: _surface,
            onSurface: _textPrimary,
          ),
          dialogTheme: DialogThemeData(backgroundColor: _cardBg),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
        _showBids = false;
      });
    }
  }

  Future<void> _fetchBids() async {
    if (_currentUserId.isEmpty) {
      _showSnackbar('User not logged in', _red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      List<Bid> allBids = await _bidService.getAllBids();
      _bids = allBids.where((bid) {
        return bid.userId == _currentUserId &&
            bid.date.isAfter(_startDate.subtract(const Duration(days: 1))) &&
            bid.date.isBefore(_endDate.add(const Duration(days: 1)));
      }).toList();

      setState(() {
        _showBids = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackbar('Failed to fetch bids: $e', _red);
    }
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String _getGameName(String gameId) =>
      _games[gameId]?.gameName ?? 'Unknown Game';

  // Check if the game should show PANA instead of DIGIT
  bool _shouldShowPana(String gameId) {
    final gameName = _getGameName(gameId).toUpperCase();
    return _panaGameTypes.any((type) => gameName.contains(type));
  }

  // Get the display value for the bid (either Pana or Digit)
  String _getDisplayValue(Bid bid) {
    if (_shouldShowPana(bid.gameId)) {
      return bid.pana.isNotEmpty ? 'Pana: ${bid.pana}' : '—';
    } else {
      return bid.digit.isNotEmpty ? 'Digit: ${bid.digit}' : '—';
    }
  }

  // Get the subtitle text based on game type
  String _getSubtitleText(Bid bid) {
    if (_shouldShowPana(bid.gameId)) {
      return bid.digit.isNotEmpty ? 'Digit: ${bid.digit}' : '';
    }
    return '';
  }

  String _getWinStatus(Bid bid) {
    if (bid.win == null || bid.win!.isEmpty) return 'Pending';
    return bid.win == 'win' ? 'Won' : 'Lost';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'won':
        return _green;
      case 'lost':
        return _red;
      default:
        return _gold;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _dark,
      appBar: AppBar(
        title: const Text(
          'My Bid History',
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Date Range Card
            Container(
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _gold.withOpacity(0.15)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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
                        'Select Date Range',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDatePicker(
                          'Start Date',
                          _startDate,
                          () => _selectStartDate(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDatePicker(
                          'End Date',
                          _endDate,
                          () => _selectEndDate(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _fetchBids,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _gold,
                        foregroundColor: _dark,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: _dark,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'SHOW MY BIDS',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_showBids)
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: _gold),
                      )
                    : _bids.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history_rounded,
                              size: 56,
                              color: _textSecondary.withOpacity(0.4),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'No bids found for selected date range',
                              style: TextStyle(
                                color: _textSecondary,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _bids.length,
                        itemBuilder: (context, index) =>
                            _buildBidCard(_bids[index]),
                      ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker(String label, DateTime date, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: _surface,
              border: Border.all(color: _gold.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _dateFormat.format(date),
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Icon(
                  Icons.calendar_month_rounded,
                  color: _gold,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBidCard(Bid bid) {
    final status = _getWinStatus(bid);
    final statusColor = _getStatusColor(status);
    final gameName = _getGameName(bid.gameId);
    final displayValue = _getDisplayValue(bid);
    final subtitle = _getSubtitleText(bid);
    final shouldShowPana = _shouldShowPana(bid.gameId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${bid.market} · ${bid.session}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (shouldShowPana && bid.digit.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'Digit: ${bid.digit}',
                            style: TextStyle(
                              fontSize: 12,
                              color: _textSecondary.withOpacity(0.8),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _infoRow(Icons.sports_esports_rounded, gameName),
            const SizedBox(height: 6),

            // Show Pana or Digit based on game type
            _infoRow(
              shouldShowPana ? Icons.grid_view_rounded : Icons.tag_rounded,
              displayValue,
              highlight: true,
            ),

            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_gold, _goldLight]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '₹${bid.points} pts',
                    style: const TextStyle(
                      color: _dark,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                Text(
                  _dateFormat.format(bid.date),
                  style: const TextStyle(color: _textSecondary, fontSize: 12),
                ),
              ],
            ),

            // Show a small badge indicating the game type
            if (shouldShowPana)
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _gold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _gold.withOpacity(0.2)),
                    ),
                    child: Text(
                      'PANA GAME',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: _gold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, {bool highlight = false}) {
    return Row(
      children: [
        Icon(icon, size: 15, color: _textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: highlight ? _gold : _textSecondary,
              fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
