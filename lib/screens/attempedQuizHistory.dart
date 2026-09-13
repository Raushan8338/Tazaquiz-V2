import 'package:flutter/material.dart';
import 'package:tazaquiznew/API/Language_converter/translation_service.dart'; // ← ADD THIS
import 'package:tazaquiznew/API/api_client.dart';
import 'package:tazaquiznew/authentication/AuthRepository.dart';
import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/models/login_response_model.dart';
import 'package:tazaquiznew/models/quiz_history_modal.dart';
import 'package:tazaquiznew/screens/leaderboard_page.dart';
import 'package:tazaquiznew/screens/quiz_review_page.dart';
import 'package:tazaquiznew/utils/session_manager.dart';

class QuizHistoryPage extends StatefulWidget {
  final int pageType;
  final String Pagetitle;

  const QuizHistoryPage({Key? key, required this.pageType, required this.Pagetitle}) : super(key: key);
  @override
  _QuizHistoryPageState createState() => _QuizHistoryPageState();
}

class _QuizHistoryPageState extends State<QuizHistoryPage> {
  String _selectedFilter = 'all';
  // 'all' or a specific categoryName — categoryName is really the course
  // title (backend joins qa.course_id -> StudyMCategory.title), so this
  // lets a user with multiple purchased courses isolate one course's stats.
  String _selectedCourse = 'all';
  bool _isLoading = true;
  List<QuizAttemptItem> _allQuizzes = [];
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

      List<QuizAttemptItem> combined = [];
      if (response.statusCode == 200) {
        combined = QuizHistoryResponse.fromJson(response.data).data;
      }

      // "Live Test Performance" (pageType 7) also folds in results from
      // the featured/special live test type (pageType 10) — same backend
      // endpoint, called a second time with a different pageType and
      // merged here client-side, so performanceApi_v2.php itself never
      // needs to change.
      if (widget.pageType == 7) {
        try {
          final featuredResponse = await auth.fetch_Quiz_performanceApi({
            'user_id': _user!.id.toString(),
            'pageType': '10',
          });
          if (featuredResponse.statusCode == 200) {
            combined = [...combined, ...QuizHistoryResponse.fromJson(featuredResponse.data).data];
          }
        } catch (_) {
          // Featured-test results are a bonus addition here — if this
          // second call fails, still show the regular live test results.
        }
      }

      combined.sort((a, b) {
        final da = DateTime.tryParse(a.date);
        final db = DateTime.tryParse(b.date);
        if (da == null || db == null) return 0;
        return db.compareTo(da);
      });

      setState(() {
        _allQuizzes = combined;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // Quizzes for the selected course only (or everything, when 'all').
  List<QuizAttemptItem> get _courseFiltered {
    if (_selectedCourse == 'all') return _allQuizzes;
    return _allQuizzes.where((q) => q.categoryName == _selectedCourse).toList();
  }

  // Backend (performanceApi_v2.php) only ever sends status as 'won',
  // 'lost' or 'in_progress' — never the literal string 'completed'.
  List<QuizAttemptItem> get _filtered {
    final base = _courseFiltered;
    switch (_selectedFilter) {
      case 'passed':
        return base.where((q) => q.passed).toList();
      case 'failed':
        return base.where((q) => q.status == 'lost').toList();
      case 'ongoing':
        return base.where((q) => q.status == 'in_progress').toList();
      default:
        return base;
    }
  }

  // Header summary numbers follow the course filter (not the pass/fail
  // filter below it) so picking a course updates "Overall Score" etc.,
  // while All/Passed/Failed/Ongoing chips only affect the list underneath.
  int get _hdrTotal => _courseFiltered.where((q) => q.status != 'in_progress').length;
  int get _hdrWins => _courseFiltered.where((q) => q.passed).length;
  double get _hdrAvg {
    final completed = _courseFiltered.where((q) => q.status != 'in_progress').toList();
    if (completed.isEmpty) return 0.0;
    final sum = completed.fold<double>(0.0, (s, q) => s + q.score);
    return sum / completed.length;
  }

  // Reattempts mean the same quiz can appear multiple times in the flat
  // history — group by quiz so it shows as one card (latest attempt) with
  // an "N attempts" badge, and a tap reveals the full attempt-by-attempt
  // comparison instead of several near-identical cards back to back.
  List<List<QuizAttemptItem>> get _groupedFiltered {
    final Map<String, List<QuizAttemptItem>> byQuiz = {};
    final List<String> order = [];
    for (final q in _filtered) {
      if (!byQuiz.containsKey(q.quizId)) {
        byQuiz[q.quizId] = [];
        order.add(q.quizId);
      }
      byQuiz[q.quizId]!.add(q);
    }
    return order.map((id) => byQuiz[id]!).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      appBar: _buildAppBar(widget.Pagetitle),
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
                              (ctx, i) => _buildCard(_groupedFiltered[i]),
                              childCount: _groupedFiltered.length,
                            ),
                          ),
                        ),
                  ],
                ),
              ),
    );
  }

  // ─── APP BAR ─────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(String pagetitle) {
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
      title: Text(
        pagetitle,
        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'ReportSerif'),
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
    final total = _hdrTotal;
    final wins = _hdrWins;
    final avg = _hdrAvg;
    final failed = total - wins;

    final double winRateValue = total > 0 ? (wins / total) : 0.0;
    final String winRate = (winRateValue * 100).toStringAsFixed(0);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.darkNavy, Color(0xFF0D4B3B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: AppColors.darkNavy.withOpacity(0.3), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // ── Decorative background circles ──────────────
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle),
              ),
            ),
            Positioned(
              left: -20,
              bottom: -40,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(color: AppColors.tealGreen.withOpacity(0.15), shape: BoxShape.circle),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.bar_chart_rounded, size: 13, color: Colors.white.withOpacity(0.75)),
                                const SizedBox(width: 5),
                                Text(
                                  'Overall Score',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Colors.white.withOpacity(0.75),
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'ReportSerif',
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // ⚠️ Numbers — plain Text, translate mat karo
                                Text(
                                  avg.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 28,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'ReportSerif',
                                    height: 1,
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 3),
                                  child: Text(
                                    '%',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'ReportSerif',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            _performanceLabel(avg),
                          ],
                        ),
                      ),

                      // Win rate ring — kept small/secondary next to the main score.
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 60,
                              height: 60,
                              child: CircularProgressIndicator(
                                value: winRateValue,
                                strokeWidth: 5,
                                strokeCap: StrokeCap.round,
                                backgroundColor: Colors.white.withOpacity(0.12),
                                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.lightGoldS2),
                              ),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // ⚠️ Number — plain Text
                                Text(
                                  '$winRate%',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'ReportSerif',
                                  ),
                                ),
                                Text(
                                  'Pass',
                                  style: TextStyle(
                                    fontSize: 7,
                                    color: Colors.white.withOpacity(0.75),
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'ReportSerif',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Slim single-bar layout instead of three boxed cards —
                  // reads like a report line rather than a dashboard widget.
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: _statSegment('$total', 'Attempted', AppColors.lightGoldS2)),
                        _statDivider(),
                        Expanded(child: _statSegment('$wins', 'Passed', Colors.white)),
                        _statDivider(),
                        Expanded(child: _statSegment('$failed', 'Failed', const Color(0xFFFF6E6E))),
                      ],
                    ),
                  ),

                  // Score % and Pass Rate are different things — average
                  // marks vs. how many tests cleared the passing cutoff —
                  // so a low average with a high pass rate is expected, not
                  // a bug (each quiz's passing marks can be much lower than
                  // a "good" score).
                  const SizedBox(height: 10),
                  Text(
                    'Score % = your average marks · Pass Rate = tests that cleared the passing cutoff',
                    style: TextStyle(
                      fontSize: 9,
                      fontStyle: FontStyle.italic,
                      color: Colors.white.withOpacity(0.55),
                      fontFamily: 'ReportSerif',
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
      child: TranslatedText(
        label,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700, fontFamily: 'ReportSerif'),
      ),
    );
  }

  Widget _statSegment(String value, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ⚠️ Number — plain Text
        Text(
          value,
          style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.w700, fontFamily: 'ReportSerif'),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 9.5,
            color: color,
            fontWeight: FontWeight.w700,
            fontFamily: 'ReportSerif',
          ),
        ),
      ],
    );
  }

  Widget _statDivider() {
    return Container(width: 1, height: 26, color: Colors.white.withOpacity(0.12));
  }

  // ─── PROGRESS SECTION ────────────────────────────────────────────────────

  Widget _buildProgressSection() {
    if (_allQuizzes.isEmpty) return const SizedBox.shrink();

    final total = _hdrTotal;
    final wins = _hdrWins;
    final failed = total - wins;
    final avg = _hdrAvg;

    // Course list is always built from the FULL history (not the current
    // course filter) so every course stays selectable/switchable here.
    final Map<String, int> catMap = {};
    for (final q in _allQuizzes) {
      catMap[q.categoryName] = (catMap[q.categoryName] ?? 0) + 1;
    }
    final topCats = catMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final bool multipleCourses = topCats.length > 1;

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
          Text(
            'Score Distribution',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.darkNavy,
              fontFamily: 'ReportSerif',
            ),
          ),
          const SizedBox(height: 14),

          _progressBar('Passed', wins, total, AppColors.tealGreen),
          const SizedBox(height: 10),
          _progressBar('Failed', failed, total, Colors.redAccent),
          const SizedBox(height: 10),
          _progressBar('Avg Score', avg.toInt(), 100, avg >= 60 ? AppColors.tealGreen : Colors.orange, suffix: '%'),

          if (topCats.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  multipleCourses ? 'Courses' : 'Course',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkNavy,
                    fontFamily: 'ReportSerif',
                  ),
                ),
                if (multipleCourses) ...[
                  const SizedBox(width: 6),
                  Text(
                    '(tap to filter)',
                    style: TextStyle(fontSize: 9.5, color: AppColors.greyS500, fontFamily: 'ReportSerif'),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (multipleCourses) _courseChip('all', 'All', _allQuizzes.length),
                ...topCats.take(10).map((e) => _courseChip(e.key, e.key, e.value)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // A course chip toggles the course filter: tap the selected one (or "All")
  // again to clear it. `key` is 'all' or the exact categoryName to match.
  Widget _courseChip(String key, String label, int count) {
    final bool sel = _selectedCourse == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedCourse = sel ? 'all' : key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: sel ? AppColors.tealGreen : AppColors.tealGreen.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: sel ? AppColors.tealGreen : AppColors.tealGreen.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Course name — user data, translate mat karo
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: sel ? Colors.white : AppColors.darkNavy,
                fontFamily: 'ReportSerif',
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: sel ? Colors.white.withOpacity(0.25) : AppColors.tealGreen,
                borderRadius: BorderRadius.circular(10),
              ),
              // ⚠️ Number — plain Text
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'ReportSerif',
                ),
              ),
            ),
          ],
        ),
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
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.greyS600,
                fontWeight: FontWeight.w600,
                fontFamily: 'ReportSerif',
              ),
            ),
            // ⚠️ Number — plain Text
            Text(
              '$value$suffix',
              style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700, fontFamily: 'ReportSerif'),
            ),
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
              int count = 0;
              switch (f['key']) {
                case 'all':
                  count = _allQuizzes.length;
                  break;
                case 'passed':
                  count = _allQuizzes.where((q) => q.passed).length;
                  break;
                case 'failed':
                  count = _allQuizzes.where((q) => q.status == 'lost').length;
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
                          fontFamily: 'ReportSerif',
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
                          // ⚠️ Number — plain Text
                          child: Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: sel ? Colors.white : c,
                              fontFamily: 'ReportSerif',
                            ),
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

  Widget _buildCard(List<QuizAttemptItem> group) {
    final quiz = group.first; // latest attempt represents the card
    final bool hasMultipleAttempts = group.length > 1;
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

    void openReview(QuizAttemptItem attempt) => Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => QuizReviewPage(
                  attemptId: int.tryParse(attempt.id.toString()) ?? 0,
                  userId: int.tryParse(_user!.id.toString()) ?? 0,
                  quizTitle: attempt.quizTitle,
                  pageType: widget.pageType,
                ),
          ),
        );

    void openCard() {
      if (hasMultipleAttempts) {
        _showAttemptGroupSheet(group);
      } else {
        openReview(quiz);
      }
    }

    return GestureDetector(
      onTap: openCard,
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

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Quiz title — user data, translate karo
                        TranslatedText(
                          quiz.quizTitle,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkNavy,
                            height: 1.3,
                            fontFamily: 'ReportSerif',
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
                            if (hasMultipleAttempts)
                              _chip(
                                '${group.length} Attempts',
                                const Color(0xFF6B4EFF).withOpacity(0.1),
                                const Color(0xFF6B4EFF),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

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
                        TranslatedText(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                            fontFamily: 'ReportSerif',
                          ),
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
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.access_time_rounded, size: 12, color: AppColors.greyS600),
                        const SizedBox(width: 4),
                        Flexible(
                          // ⚠️ Date/time — plain Text (numbers + symbols)
                          child: Text(
                            '${quiz.date}  ${quiz.time}',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.greyS600,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'ReportSerif',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (quiz.timeTaken.isNotEmpty && quiz.timeTaken != 'N/A') ...[
                          const SizedBox(width: 8),
                          Icon(Icons.timer_outlined, size: 12, color: AppColors.greyS600),
                          const SizedBox(width: 3),
                          // ⚠️ Time value — plain Text
                          Text(
                            quiz.timeTaken,
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.greyS600,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'ReportSerif',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => LeaderboardPage(
                                      quizId: int.tryParse(quiz.quizId.toString()) ?? 0,
                                      quizTitle: quiz.quizTitle,
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
                            children: [
                              const Icon(Icons.leaderboard_rounded, size: 12, color: Color(0xFF6B4EFF)),
                              const SizedBox(width: 3),
                              Text(
                                'Rank',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF6B4EFF),
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'ReportSerif',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      GestureDetector(
                        onTap: openCard,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Details',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.tealGreen,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'ReportSerif',
                              ),
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

  // ─── ATTEMPT GROUP SHEET (reattempt comparison) ────────────────────────────

  void _showAttemptGroupSheet(List<QuizAttemptItem> group) {
    // group is newest-first (API order); reverse to compute chronological
    // deltas, then re-reverse for display so the newest attempt stays on top.
    final chronological = group.reversed.toList();
    final deltas = <double?>[null];
    for (int i = 1; i < chronological.length; i++) {
      deltas.add(chronological[i].score - chronological[i - 1].score);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.35,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.greyS300, borderRadius: BorderRadius.circular(4)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
                  child: Row(
                    children: [
                      Icon(Icons.history_rounded, color: AppColors.tealGreen, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TranslatedText(
                          group.first.quizTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.darkNavy, fontFamily: 'ReportSerif'),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
                    itemCount: group.length,
                    itemBuilder: (context, index) {
                      final attempt = group[index];
                      final attemptNumber = group.length - index;
                      // group[index] corresponds to chronological[attemptNumber-1]
                      final delta = deltas[attemptNumber - 1];
                      return _buildGroupAttemptTile(attempt, attemptNumber, delta);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGroupAttemptTile(QuizAttemptItem attempt, int attemptNumber, double? delta) {
    final bool passed = attempt.passed;

    Widget? deltaChip;
    if (delta != null && delta != 0) {
      final bool improved = delta > 0;
      deltaChip = Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: (improved ? AppColors.tealGreen : Colors.red).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              improved ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              size: 11,
              color: improved ? AppColors.tealGreen : Colors.red,
            ),
            const SizedBox(width: 2),
            Text(
              '${delta.abs().toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: improved ? AppColors.tealGreen : Colors.red,
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QuizReviewPage(
            attemptId: int.tryParse(attempt.id.toString()) ?? 0,
            userId: int.tryParse(_user!.id.toString()) ?? 0,
            quizTitle: attempt.quizTitle,
            pageType: widget.pageType,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9FB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.greyS200),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: (passed ? AppColors.tealGreen : Colors.red).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Text(
                '#$attemptNumber',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: passed ? AppColors.tealGreen : Colors.red,
                  fontFamily: 'ReportSerif',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TranslatedText(
                    'Attempt $attemptNumber',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.darkNavy, fontFamily: 'ReportSerif'),
                  ),
                  if (attempt.date.isNotEmpty)
                    Text(
                      '${attempt.date}  ${attempt.time}',
                      style: TextStyle(fontSize: 11, color: AppColors.greyS500, fontFamily: 'ReportSerif'),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${attempt.score.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: passed ? AppColors.tealGreen : Colors.red,
                    fontFamily: 'ReportSerif',
                  ),
                ),
                if (deltaChip != null) deltaChip,
              ],
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, color: AppColors.greyS400),
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
      // User data — translate karo
      child: TranslatedText(
        label,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: text, fontFamily: 'ReportSerif'),
      ),
    );
  }

  Widget _statCol(String value, String label, Color color) {
    return Column(
      children: [
        // ⚠️ Number/score — plain Text
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color, fontFamily: 'ReportSerif')),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 9, color: AppColors.greyS600, fontWeight: FontWeight.w500, fontFamily: 'ReportSerif'),
        ),
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
          TranslatedText(
            'No tests found',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.darkNavy,
              fontFamily: 'ReportSerif',
            ),
          ),
          const SizedBox(height: 6),
          TranslatedText(
            'Start giving tests to see your history here',
            style: TextStyle(fontSize: 12, color: AppColors.greyS600, fontFamily: 'ReportSerif'),
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
                            TranslatedText(
                              headline,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: sc,
                                fontFamily: 'ReportSerif',
                              ),
                            ),
                            const SizedBox(height: 3),
                            TranslatedText(
                              quiz.quizTitle,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.greyS600,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'ReportSerif',
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

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

                  TranslatedText(
                    'Answer Breakdown',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkNavy,
                      fontFamily: 'ReportSerif',
                    ),
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

                  TranslatedText(
                    'Details',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkNavy,
                      fontFamily: 'ReportSerif',
                    ),
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

                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.tealGreen, AppColors.darkNavy]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: TranslatedText(
                          'Close',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontFamily: 'ReportSerif',
                          ),
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
        // ⚠️ Number — plain Text
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color, fontFamily: 'ReportSerif')),
        Text(label, style: TextStyle(fontSize: 11, color: AppColors.greyS600, fontFamily: 'ReportSerif')),
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
          // ⚠️ Number — plain Text
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.darkNavy,
              fontFamily: 'ReportSerif',
            ),
          ),
          const SizedBox(height: 2),
          TranslatedText(label, style: TextStyle(fontSize: 10, color: AppColors.greyS600, fontFamily: 'ReportSerif')),
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
          // Label — translate karo
          TranslatedText(label, style: TextStyle(fontSize: 12, color: AppColors.greyS600, fontFamily: 'ReportSerif')),
          const Spacer(),
          // Value — plain Text (date/numbers/user data)
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.darkNavy,
              fontFamily: 'ReportSerif',
            ),
          ),
        ],
      ),
    );
  }
}
