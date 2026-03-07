import 'package:ekdant/games/cycle_patti.dart';
import 'package:ekdant/games/double_pana_screen.dart';
import 'package:ekdant/games/family_screen.dart';
import 'package:ekdant/games/full_sangam_screen.dart';
import 'package:ekdant/games/half_sangam_screen.dart';
import 'package:ekdant/games/jodi_family_screen.dart';
import 'package:ekdant/games/red_jodi_family_screen.dart';
import 'package:ekdant/games/red_jodi_screen.dart';
import 'package:ekdant/games/single_digit_Screen.dart';
import 'package:ekdant/games/jodi_digit_screen.dart';
import 'package:ekdant/games/single_pana_screen.dart';
import 'package:ekdant/games/sp_dp_tp_screen.dart';
import 'package:ekdant/games/tripple_pana_screen.dart';
import 'package:flutter/material.dart';
import 'package:ekdant/models/game_model.dart';
import 'package:ekdant/services/game_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class GameScreen extends StatefulWidget {
  final String marketId;
  final String marketName;
  final String closeTimeOpen;
  final String closeTimeClose;

  const GameScreen({
    super.key,
    required this.marketId,
    required this.marketName,
    required this.closeTimeOpen,
    required this.closeTimeClose,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final GameService _gameService = GameService();
  late Future<GameListResponse> _gamesFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Define game order priority
  static const Map<String, int> _gameOrderPriority = {
    'SINGLE DIGIT': 1,
    'JODI DIGIT': 2,
    'SINGLE PANNA': 3,
    'DOUBLE PANNA': 4,
    'DUBBLE PANNA': 4,
    'TRIPLE PANNA': 5,
    'TRIPPLE PANNA': 5,
    'SP DP TP': 6,
    'CYCLE PATTI': 7,
    'FAMILY PANNA': 8,
    'FAMILY PANA': 8,
    'JODI FAMILY': 8,
    'RED JODI FAMILY': 8,
    'RED JODI': 8,
    'HALF SANGAM': 9,
    'FULL SANGAM': 10,
  };

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

  @override
  void initState() {
    super.initState();
    _loadGames();
  }

  void _loadGames() {
    setState(() {
      _gamesFuture = _gameService.getDetailedGameList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isMarketClosed() {
    try {
      final now = TimeOfDay.now();
      final openTimeParts = widget.closeTimeOpen.split(':');
      final closeTimeParts = widget.closeTimeClose.split(':');
      final openTime = TimeOfDay(
        hour: int.parse(openTimeParts[0]),
        minute: int.parse(openTimeParts[1]),
      );
      final closeTime = TimeOfDay(
        hour: int.parse(closeTimeParts[0]),
        minute: int.parse(closeTimeParts[1]),
      );
      final nowInMinutes = now.hour * 60 + now.minute;
      final openInMinutes = openTime.hour * 60 + openTime.minute;
      final closeInMinutes = closeTime.hour * 60 + closeTime.minute;
      return nowInMinutes >= openInMinutes && nowInMinutes <= closeInMinutes;
    } catch (e) {
      return false;
    }
  }

  int _getGamePriority(String gameName) {
    final upperName = gameName.toUpperCase();

    for (var entry in _gameOrderPriority.entries) {
      if (upperName.contains(entry.key)) {
        return entry.value;
      }
    }

    return 999; // Default priority for unknown games
  }

  // Returns (accentColor, symbol, screen, shouldHide)
  Map<String, dynamic> _getGameTypeInfo(GameResponse game) {
    final n = game.gameName.toLowerCase();
    final closed = _isMarketClosed();

    // IMPORTANT: Put more specific conditions FIRST
    if (n.contains('red jodi family')) {
      return {
        'accent': const Color(0xFFE74C3C), // Red color for red jodi family
        'symbol': '🔴',
        'screen': RedJodiFamilyScreen(
          gameName: game.gameName,
          gameId: game.id,
          marketId: widget.marketId,
          marketName: widget.marketName,
          closeTimeOpen: widget.closeTimeOpen,
          closeTimeClose: widget.closeTimeClose,
        ),
        'shouldHide': closed,
        'priority': 8,
      };
    } else if (n.contains('red jodi')) {
      return {
        'accent': const Color(0xFFE67E22), // Orange color for red jodi
        'symbol': '🔴',
        'screen': RedJodiScreen(
          gameName: game.gameName,
          gameId: game.id,
          marketId: widget.marketId,
          marketName: widget.marketName,
          closeTimeOpen: widget.closeTimeOpen,
          closeTimeClose: widget.closeTimeClose,
        ),
        'shouldHide': closed,
        'priority': 8,
      };
    } else if (n.contains('jodi family')) {
      return {
        'accent': const Color(0xFF9B59B6), // Purple color for jodi family
        'symbol': '👥',
        'screen': JodiFamilyScreen(
          gameName: game.gameName,
          gameId: game.id,
          marketId: widget.marketId,
          marketName: widget.marketName,
          closeTimeOpen: widget.closeTimeOpen,
          closeTimeClose: widget.closeTimeClose,
        ),
        'shouldHide': closed,
        'priority': 8,
      };
    } else if (n.contains('single digit')) {
      return {
        'accent': _red,
        'symbol': '♠',
        'screen': SingleDigitScreen(
          gameName: game.gameName,
          gameId: game.id,
          marketId: widget.marketId,
          marketName: widget.marketName,
          closeTimeOpen: widget.closeTimeOpen,
        ),
        'shouldHide': false,
        'priority': 1,
      };
    } else if (n.contains('jodi digit')) {
      return {
        'accent': _gold,
        'symbol': '♣',
        'screen': JodiDigitScreen(
          gameName: game.gameName,
          gameId: game.id,
          marketId: widget.marketId,
          marketName: widget.marketName,
        ),
        'shouldHide': closed,
        'priority': 2,
      };
    } else if (n.contains('single panna')) {
      return {
        'accent': _green,
        'symbol': '♦',
        'screen': SinglePanaScreen(
          gameName: game.gameName,
          gameId: game.id,
          marketId: widget.marketId,
          marketName: widget.marketName,
          closeTimeOpen: widget.closeTimeOpen,
          closeTimeClose: widget.closeTimeClose,
        ),
        'shouldHide': false,
        'priority': 3,
      };
    } else if (n.contains('double panna') || n.contains('dubble panna')) {
      return {
        'accent': const Color(0xFF3498DB),
        'symbol': '♥',
        'screen': DoublePanaScreen(
          gameName: game.gameName,
          gameId: game.id,
          marketId: widget.marketId,
          marketName: widget.marketName,
          closeTimeOpen: widget.closeTimeOpen,
        ),
        'shouldHide': false,
        'priority': 4,
      };
    } else if (n.contains('triple panna') || n.contains('tripple panna')) {
      return {
        'accent': const Color(0xFF9B59B6),
        'symbol': '♠',
        'screen': TriplePanaScreen(
          gameName: game.gameName,
          gameId: game.id,
          marketId: widget.marketId,
          marketName: widget.marketName,
          closeTimeOpen: widget.closeTimeOpen,
        ),
        'shouldHide': false,
        'priority': 5,
      };
    } else if (n.contains('sp dp tp')) {
      return {
        'accent': _gold,
        'symbol': '♦',
        'screen': SpDpTpScreen(
          gameName: game.gameName,
          gameId: game.id,
          marketId: widget.marketId,
          marketName: widget.marketName,
          closeTimeOpen: widget.closeTimeOpen,
        ),
        'shouldHide': false,
        'priority': 6,
      };
    } else if (n.contains('cycle patti')) {
      return {
        'accent': const Color.fromARGB(255, 50, 215, 35),
        'symbol': '♣',
        'screen': CyclePatti(
          gameName: game.gameName,
          gameId: game.id,
          marketId: widget.marketId,
          marketName: widget.marketName,
          closeTimeOpen: widget.closeTimeOpen,
          closeTimeClose: widget.closeTimeClose,
        ),
        'shouldHide': false,
        'priority': 7,
      };
    } else if (n.contains('family panna') || n.contains('family pana')) {
      return {
        'accent': const Color(0xFFE67E22),
        'symbol': '♣',
        'screen': FamilyScreen(
          gameName: game.gameName,
          gameId: game.id,
          marketId: widget.marketId,
          marketName: widget.marketName,
          closeTimeOpen: widget.closeTimeOpen,
          closeTimeClose: widget.closeTimeClose,
        ),
        'shouldHide': false,
        'priority': 8,
      };
    } else if (n.contains('half sangam')) {
      return {
        'accent': const Color(0xFFE67E22),
        'symbol': '♣',
        'screen': HalfSangamScreen(
          gameName: game.gameName,
          gameId: game.id,
          marketId: widget.marketId,
          marketName: widget.marketName,
          closeTimeOpen: widget.closeTimeOpen,
        ),
        'shouldHide': closed,
        'priority': 9,
      };
    } else if (n.contains('full sangam')) {
      return {
        'accent': _red,
        'symbol': '♥',
        'screen': FullSangamScreen(
          gameName: game.gameName,
          gameId: game.id,
          marketId: widget.marketId,
          marketName: widget.marketName,
        ),
        'shouldHide': closed,
        'priority': 10,
      };
    }

    return {
      'accent': _textSecondary,
      'symbol': '★',
      'screen': null,
      'shouldHide': false,
      'priority': 999,
    };
  }

  void _navigateToGameScreen(BuildContext context, GameResponse game) {
    final gameInfo = _getGameTypeInfo(game);
    if (gameInfo['screen'] != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => gameInfo['screen']),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Game type ${game.gameName} not supported'),
          backgroundColor: _red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isClosed = _isMarketClosed();
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: _dark,
      appBar: AppBar(
        title: Text(
          widget.marketName,
          style: const TextStyle(
            color: _textPrimary,
            fontWeight: FontWeight.bold,
          ),
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
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Container(
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _gold.withOpacity(0.2)),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: _textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search games...',
                  hintStyle: const TextStyle(color: _textSecondary),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: _textSecondary,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear_rounded,
                            color: _textSecondary,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                ),
                onChanged: (value) =>
                    setState(() => _searchQuery = value.toLowerCase()),
              ),
            ),
          ),

          // Market closed warning
          if (isClosed)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE67E22).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE67E22).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      color: Color(0xFFE67E22),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Market closed (${widget.closeTimeOpen} – ${widget.closeTimeClose}). Some games unavailable.',
                        style: const TextStyle(
                          color: Color(0xFFE67E22),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 8),

          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _loadGames(),
              color: _gold,
              backgroundColor: _surface,
              child: FutureBuilder<GameListResponse>(
                future: _gamesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: _gold),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            color: _red.withOpacity(0.6),
                            size: 56,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error: ${snapshot.error}',
                            style: const TextStyle(
                              color: _textSecondary,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _loadGames,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _gold,
                              foregroundColor: _dark,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.games.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            FontAwesomeIcons.circlePlay,
                            size: 48,
                            color: _textSecondary.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No games found',
                            style: TextStyle(
                              color: _textSecondary,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Filter games by search query
                  final allGames = snapshot.data!.games.where((game) {
                    return game.gameName.toLowerCase().contains(_searchQuery) ||
                        game.shortCode.toLowerCase().contains(_searchQuery) ||
                        game.rate.toLowerCase().contains(_searchQuery);
                  }).toList();

                  // Sort games by priority
                  allGames.sort((a, b) {
                    final priorityA = _getGamePriority(a.gameName);
                    final priorityB = _getGamePriority(b.gameName);
                    return priorityA.compareTo(priorityB);
                  });

                  // Filter out hidden games based on market status
                  final games = allGames.where((game) {
                    final gameInfo = _getGameTypeInfo(game);
                    return !(gameInfo['shouldHide'] as bool);
                  }).toList();

                  if (games.isEmpty) {
                    return const Center(
                      child: Text(
                        'No matching games available',
                        style: TextStyle(color: _textSecondary, fontSize: 15),
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: screenWidth > 600 ? 3 : 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: games.length,
                    itemBuilder: (context, index) {
                      final game = games[index];
                      final info = _getGameTypeInfo(game);
                      final accent = info['accent'] as Color;
                      final symbol = info['symbol'] as String;

                      return GestureDetector(
                        onTap: () => _navigateToGameScreen(context, game),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: accent.withOpacity(0.25),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: accent.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              // Priority indicator
                              Positioned(
                                top: 4,
                                left: 4,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: accent.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: accent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Corner symbols
                              Positioned(
                                top: 6,
                                right: 8,
                                child: Text(
                                  symbol,
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: accent.withOpacity(0.5),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),

                              // Content
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Short code
                                      Text(
                                        game.shortCode,
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: accent,
                                          shadows: [
                                            Shadow(
                                              color: accent.withOpacity(0.4),
                                              blurRadius: 6,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 4),

                                      // Game name
                                      Text(
                                        game.gameName,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: _textPrimary,
                                          fontWeight: FontWeight.w600,
                                          height: 1.2,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),

                                      // Rate badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [_gold, _goldLight],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: _gold.withOpacity(0.2),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          '₹${game.rate}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: _dark,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
