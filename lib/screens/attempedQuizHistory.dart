import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:tazaquiznew/API/api_client.dart';
import 'package:tazaquiznew/authentication/AuthRepository.dart';
import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/models/login_response_model.dart';
import 'package:tazaquiznew/models/quiz_history_modal.dart';
import 'package:tazaquiznew/screens/leaderboard_page.dart';
import 'package:tazaquiznew/screens/quiz_review_page.dart';
import 'package:tazaquiznew/utils/session_manager.dart';

class QuizHistoryPage extends StatefulWidget {
  final int pageType; // 0 for history, 1 for leaderboard
  const QuizHistoryPage({Key? key, required this.pageType}) : super(key: key);
  @override
  _QuizHistoryPageState createState() => _QuizHistoryPageState();
}

class _QuizHistoryPageState extends State<QuizHistoryPage> {
  String _selectedFilter = 'all';
  bool _isLoading = true;
  List<QuizAttemptItem> _allQuizzes = [];
  QuizHistoryStats? _stats;
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  Future<void> _getUserData() async {
    _user = await SessionManager.getUser();
    setState(() {});
    if (_user != null) await _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);
    try {
      Authrepository auth = Authrepository(Api_Client.dio);
     
      final response = await auth.fetch_Quiz_performanceApi({
        'user_id': _user!.id.toString(),
        'pageType': widget.pageType.toString(),
      });
     
     
      if (response.statusCode == 200) {
        final parsed = QuizHistoryResponse.fromJson(response.data);
        setState(() {
          _allQuizzes = parsed.data;
          _stats = parsed.stats;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error: $e');
      setState(() => _isLoading = false);
    }
  }

  List<QuizAttemptItem> get _filtered {
    switch (_selectedFilter) {
      case 'passed':
        return _allQuizzes.where((q) => q.passed).toList();
      case 'failed':
        return _allQuizzes.where((q) => !q.passed && q.status == 'completed').toList();
      case 'ongoing':
        return _allQuizzes.where((q) => q.status == 'in_progress').toList();
      default:
        return _allQuizzes;
    }
  }

  // ─── BUILD ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      appBar: _buildAppBar(),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.tealGreen)))
              : RefreshIndicator(
                onRefresh: _fetchHistory,
                color: AppColors.tealGreen,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildSummaryCards()),
                    SliverToBoxAdapter(child: _buildProgressSection()),
                    SliverToBoxAdapter(child: _buildFilterRow()),
                    SliverToBoxAdapter(child: const SizedBox(height: 8)),
                    _filtered.isEmpty
                        ? SliverFillRemaining(child: _buildEmptyState())
                        : SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (ctx, i) => _buildCard(_filtered[i]),
                              childCount: _filtered.length,
                            ),
                          ),
                        ),
                  ],
                ),
              ),
    );
  }

  // ─── APP BAR ─────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: AppColors.darkNavy,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'My Performance',
        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'Poppins'),
      ),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.darkNavy, AppColors.tealGreen],
          ),
        ),
      ),
    );
  }

  // ─── SUMMARY CARDS ───────────────────────────────────────────────────────

  Widget _buildSummaryCards() {
    final total = _stats?.totalQuizzes ?? 0;
    final wins = _stats?.totalWins ?? 0;
    final avg = _stats?.averageScore ?? 0.0;
    final failed = total - wins;
    final winRate = total > 0 ? ((wins / total) * 100).toStringAsFixed(0) : '0';

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.darkNavy, Color(0xFF0D4B3B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.darkNavy.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: [
          // Top — avg score + win rate
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overall Score',
                      style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${avg.toStringAsFixed(1)}',
                          style: const TextStyle(
                            fontSize: 36,
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Poppins',
                            height: 1,
                          ),
                        ),
                        const Text(
                          '%',
                          style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _performanceLabel(avg),
                  ],
                ),
              ),

              // Win rate circle
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.tealGreen.withOpacity(0.5), width: 2),
                  color: Colors.white.withOpacity(0.05),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$winRate%',
                      style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w900),
                    ),
                    Text(
                      'Pass Rate',
                      style: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Divider(color: Colors.white.withOpacity(0.12), height: 1),
          const SizedBox(height: 16),

          // Bottom 3 stats
          Row(
            children: [
              Expanded(child: _topStat('${total}', 'Attempted', Icons.quiz_outlined, Colors.white)),
              _vDivider(),
              Expanded(child: _topStat('${wins}', 'Passed', Icons.check_circle_outline, AppColors.tealGreen)),
              _vDivider(),
              Expanded(child: _topStat('${failed}', 'Failed', Icons.cancel_outlined, Colors.redAccent)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _performanceLabel(double avg) {
    String label;
    Color color;
    if (avg >= 80) {
      label = '🔥 Excellent';
      color = AppColors.tealGreen;
    } else if (avg >= 60) {
      label = '👍 Good';
      color = Colors.lightGreen;
    } else if (avg >= 40) {
      label = '📈 Average';
      color = Colors.orange;
    } else {
      label = '💪 Keep Going';
      color = Colors.redAccent;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
    );
  }

  Widget _topStat(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.65), fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _vDivider() => Container(width: 1, height: 40, color: Colors.white.withOpacity(0.15));

  // ─── PROGRESS SECTION ────────────────────────────────────────────────────

  Widget _buildProgressSection() {
    if (_allQuizzes.isEmpty) return const SizedBox.shrink();

    final total = _stats?.totalQuizzes ?? 0;
    final wins = _stats?.totalWins ?? 0;
    final failed = total - wins;
    final avg = _stats?.averageScore ?? 0.0;

    // Category breakdown
    final Map<String, int> catMap = {};
    for (final q in _allQuizzes) {
      catMap[q.categoryName] = (catMap[q.categoryName] ?? 0) + 1;
    }
    final topCats = catMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Score Distribution',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.darkNavy),
          ),
          const SizedBox(height: 14),

          // Pass bar
          _progressBar('Passed', wins, total, AppColors.tealGreen),
          const SizedBox(height: 10),
          _progressBar('Failed', failed, total, Colors.redAccent),
          const SizedBox(height: 10),
          _progressBar('Avg Score', avg.toInt(), 100, avg >= 60 ? AppColors.tealGreen : Colors.orange, suffix: '%'),

          if (topCats.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            const Text(
              'Top Categories',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.darkNavy),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children:
                  topCats.take(5).map((e) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.tealGreen.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.tealGreen.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            e.key,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkNavy,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.tealGreen,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${e.value}',
                              style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _progressBar(String label, int value, int total, Color color, {String suffix = ''}) {
    final pct = total > 0 ? (value / total).clamp(0.0, 1.0) : 0.0;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: AppColors.greyS600, fontWeight: FontWeight.w600)),
            Text('$value$suffix', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 7,
          ),
        ),
      ],
    );
  }

  // ─── FILTER ROW ──────────────────────────────────────────────────────────

  Widget _buildFilterRow() {
    final filters = [
      {'key': 'all', 'label': 'All', 'icon': Icons.list_alt},
      {'key': 'passed', 'label': 'Passed', 'icon': Icons.check_circle_outline},
      {'key': 'failed', 'label': 'Failed', 'icon': Icons.cancel_outlined},
      {'key': 'ongoing', 'label': 'Ongoing', 'icon': Icons.hourglass_empty},
    ];

    return Container(
      height: 46,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children:
            filters.map((f) {
              final bool sel = _selectedFilter == f['key'];
              Color c;
              switch (f['key']) {
                case 'passed':
                  c = AppColors.tealGreen;
                  break;
                case 'failed':
                  c = Colors.redAccent;
                  break;
                case 'ongoing':
                  c = Colors.orange;
                  break;
                default:
                  c = AppColors.darkNavy;
              }
              // Count badge
              int count = 0;
              switch (f['key']) {
                case 'all':
                  count = _allQuizzes.length;
                  break;
                case 'passed':
                  count = _allQuizzes.where((q) => q.passed).length;
                  break;
                case 'failed':
                  count = _allQuizzes.where((q) => !q.passed && q.status == 'completed').length;
                  break;
                case 'ongoing':
                  count = _allQuizzes.where((q) => q.status == 'in_progress').length;
                  break;
              }

              return GestureDetector(
                onTap: () => setState(() => _selectedFilter = f['key'] as String),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: sel ? c : const Color(0xFFF0F2F8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sel ? c : Colors.grey.withOpacity(0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(f['icon'] as IconData, size: 12, color: sel ? Colors.white : AppColors.greyS600),
                      const SizedBox(width: 5),
                      Text(
                        f['label'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                          color: sel ? Colors.white : AppColors.greyS700,
                        ),
                      ),
                      if (count > 0) ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: sel ? Colors.white.withOpacity(0.25) : c.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: sel ? Colors.white : c),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  // ─── CARD ────────────────────────────────────────────────────────────────
  Widget _buildCard(QuizAttemptItem quiz) {
    final bool passed = quiz.passed;
    final bool ongoing = quiz.status == 'in_progress';

    final Color statusColor =
        ongoing
            ? Colors.orange
            : passed
            ? AppColors.tealGreen
            : Colors.redAccent;

    final String statusLabel =
        ongoing
            ? 'Ongoing'
            : passed
            ? 'Passed'
            : 'Failed';

    final IconData statusIcon =
        ongoing
            ? Icons.hourglass_empty
            : passed
            ? Icons.check_circle
            : Icons.cancel;

    return GestureDetector(
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => QuizReviewPage(
                    attemptId: int.tryParse(quiz.id.toString()) ?? 0,
                    userId: int.tryParse(_user!.id.toString()) ?? 0,
                    quizTitle: quiz.quizTitle,
                    pageType: widget.pageType,
                  ),
            ),
          ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(
          children: [
            // ── Top row ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withOpacity(0.2)),
                    ),
                    child: Icon(Icons.quiz_outlined, color: statusColor, size: 22),
                  ),
                  const SizedBox(width: 12),

                  // Title + chips
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quiz.quizTitle,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.darkNavy,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _chip(quiz.categoryName, AppColors.darkNavy.withOpacity(0.08), AppColors.darkNavy),
                            _chip(
                              quiz.difficultyLevel,
                              _diffColor(quiz.difficultyLevel).withOpacity(0.1),
                              _diffColor(quiz.difficultyLevel),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, color: statusColor, size: 12),
                        const SizedBox(width: 3),
                        Text(
                          statusLabel,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Stats row ─────────────────────────────────
            Container(
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: const Color(0xFFF8F9FF), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Expanded(child: _statCol('${quiz.score.toStringAsFixed(0)}%', 'Score', statusColor)),
                  _miniDiv(),
                  Expanded(child: _statCol('${quiz.correctAnswers}', 'Correct', AppColors.tealGreen)),
                  _miniDiv(),
                  Expanded(child: _statCol('${quiz.wrongAnswers}', 'Wrong', Colors.redAccent)),
                  _miniDiv(),
                  Expanded(child: _statCol(quiz.rank > 0 ? '#${quiz.rank}' : '-', 'Rank', AppColors.lightGold)),
                ],
              ),
            ),

            // ── Footer ───────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.08)))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left — date + time taken
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.access_time_rounded, size: 12, color: AppColors.greyS600),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${quiz.date}  ${quiz.time}',
                            style: TextStyle(fontSize: 10, color: AppColors.greyS600, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (quiz.timeTaken.isNotEmpty && quiz.timeTaken != 'N/A') ...[
                          const SizedBox(width: 8),
                          Icon(Icons.timer_outlined, size: 12, color: AppColors.greyS600),
                          const SizedBox(width: 3),
                          Text(
                            quiz.timeTaken,
                            style: TextStyle(fontSize: 10, color: AppColors.greyS600, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Right — Rank button + View Details
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Leaderboard / Rank button ──
                      GestureDetector(
                        onTap:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => LeaderboardPage(
                                      // courseId: int.tryParse(quiz.quizId.toString()) ?? 0,
                                      //  courseName: quiz.categoryName,
                                      quizId: int.tryParse(quiz.quizId.toString()) ?? 0,
                                      quizTitle: quiz.quizTitle,
                                      //  isMock: false,
                                    ),
                              ),
                            ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6B4EFF).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF6B4EFF).withOpacity(0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.leaderboard_rounded, size: 12, color: Color(0xFF6B4EFF)),
                              SizedBox(width: 3),
                              Text(
                                'Rank',
                                style: TextStyle(fontSize: 10, color: Color(0xFF6B4EFF), fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      // ── View Details ──
                      GestureDetector(
                        onTap:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => QuizReviewPage(
                                      attemptId: int.tryParse(quiz.id.toString()) ?? 0,
                                      userId: int.tryParse(_user!.id.toString()) ?? 0,
                                      quizTitle: quiz.quizTitle,
                                      pageType: widget.pageType,
                                    ),
                              ),
                            ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Details',
                              style: TextStyle(fontSize: 10, color: AppColors.tealGreen, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(width: 2),
                            Icon(Icons.chevron_right, size: 14, color: AppColors.tealGreen),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _diffColor(String diff) {
    switch (diff.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return AppColors.greyS600;
    }
  }

  Widget _chip(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: text)),
    );
  }

  Widget _statCol(String value, String label, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color, fontFamily: 'Poppins')),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 9, color: AppColors.greyS600, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _miniDiv() => Container(width: 1, height: 28, color: Colors.grey.withOpacity(0.15));

  // ─── EMPTY STATE ─────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: AppColors.tealGreen.withOpacity(0.08), shape: BoxShape.circle),
            child: Icon(Icons.quiz_outlined, size: 56, color: AppColors.greyS400),
          ),
          const SizedBox(height: 16),
          const Text(
            'No tests found',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.darkNavy),
          ),
          const SizedBox(height: 6),
          Text(
            'Start giving tests to see your history here',
            style: TextStyle(fontSize: 12, color: AppColors.greyS600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ─── DETAILS SHEET ───────────────────────────────────────────────────────

  void _showDetails(QuizAttemptItem quiz) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _detailSheet(quiz),
    );
  }

  Widget _detailSheet(QuizAttemptItem quiz) {
    final bool passed = quiz.passed;
    final bool ongoing = quiz.status == 'in_progress';
    final Color sc =
        ongoing
            ? Colors.orange
            : passed
            ? AppColors.tealGreen
            : Colors.redAccent;
    final String headline =
        ongoing
            ? 'Test In Progress ⏳'
            : passed
            ? 'Test Passed! 🎉'
            : 'Test Failed 😔';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.withOpacity(0.25), borderRadius: BorderRadius.circular(10)),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: sc.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: Icon(Icons.quiz_outlined, color: sc, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(headline, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: sc)),
                            const SizedBox(height: 3),
                            Text(
                              quiz.quizTitle,
                              style: TextStyle(fontSize: 12, color: AppColors.greyS600, fontWeight: FontWeight.w500),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Score card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [sc.withOpacity(0.12), sc.withOpacity(0.04)]),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: sc.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _detailScore('${quiz.score.toStringAsFixed(0)}%', 'Score', sc),
                        Container(width: 1, height: 40, color: sc.withOpacity(0.2)),
                        _detailScore(quiz.rank > 0 ? '#${quiz.rank}' : 'N/A', 'Rank', AppColors.lightGold),
                        Container(width: 1, height: 40, color: sc.withOpacity(0.2)),
                        _detailScore('${quiz.accuracy.toStringAsFixed(0)}%', 'Accuracy', Colors.blue),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Answer breakdown
                  const Text(
                    'Answer Breakdown',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.darkNavy),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _answerCard(
                          Icons.check_circle,
                          '${quiz.correctAnswers}',
                          'Correct',
                          AppColors.tealGreen,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: _answerCard(Icons.cancel, '${quiz.wrongAnswers}', 'Wrong', Colors.redAccent)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _answerCard(Icons.remove_circle_outline, '${quiz.skipped}', 'Skipped', Colors.orange),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Info
                  const Text(
                    'Details',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.darkNavy),
                  ),
                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: const Color(0xFFF8F9FF), borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        _infoRow(Icons.category_outlined, 'Category', quiz.categoryName),
                        _infoRow(Icons.signal_cellular_alt, 'Difficulty', quiz.difficultyLevel),
                        _infoRow(Icons.calendar_today_outlined, 'Date', '${quiz.date}  ${quiz.time}'),
                        _infoRow(Icons.timer_outlined, 'Time Taken', quiz.timeTaken),
                        _infoRow(Icons.hourglass_bottom_outlined, 'Duration', quiz.duration),
                        _infoRow(Icons.quiz_outlined, 'Total Questions', '${quiz.totalQuestions}'),
                        _infoRow(Icons.people_outline, 'Total Participants', '${quiz.totalParticipants}'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Close button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.tealGreen, AppColors.darkNavy]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'Close',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
          ],
        ),
      ),
    );
  }

  Widget _detailScore(String value, String label, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color, fontFamily: 'Poppins')),
        Text(label, style: TextStyle(fontSize: 11, color: AppColors.greyS600)),
      ],
    );
  }

  Widget _answerCard(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 5),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.darkNavy)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, color: AppColors.greyS600)),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.greyS600),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 12, color: AppColors.greyS600)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.darkNavy)),
        ],
      ),
    );
  }
}
