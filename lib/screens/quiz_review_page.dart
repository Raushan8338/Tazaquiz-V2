import 'package:flutter/material.dart';
import 'package:tazaquiznew/API/api_client.dart';
import 'package:tazaquiznew/authentication/AuthRepository.dart';
import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/models/quiz_review_modal.dart';

class QuizReviewPage extends StatefulWidget {
  final int attemptId;
  final int userId;
  final String quizTitle;
  final int pageType;

  const QuizReviewPage({
    Key? key,
    required this.attemptId,
    required this.userId,
    required this.quizTitle,
    required this.pageType,
  }) : super(key: key);

  @override
  _QuizReviewPageState createState() => _QuizReviewPageState();
}

class _QuizReviewPageState extends State<QuizReviewPage> {
  bool _isLoading = true;
  QuizReviewResponse? _data;
  String _filter = 'all'; // all / correct / wrong / skipped

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final auth = Authrepository(Api_Client.dio);
      final res = await auth.fetchQuizReview({
        'attempt_id': widget.attemptId.toString(),
        'user_id': widget.userId.toString(),
      });
      print('Review response: ${res.data}');
      print('Review status: ${widget.attemptId.toString()}');
      print('Review status: ${widget.userId.toString()}');
      if (res.statusCode == 200) {
        setState(() {
          _data = QuizReviewResponse.fromJson(res.data);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Review error: $e');
      setState(() => _isLoading = false);
    }
  }

  List<QuizReviewQuestion> get _filtered {
    if (_data == null) return [];
    switch (_filter) {
      case 'correct':
        return _data!.questions.where((q) => q.status == 'correct').toList();
      case 'wrong':
        return _data!.questions.where((q) => q.status == 'wrong').toList();
      case 'skipped':
        return _data!.questions.where((q) => q.status == 'skipped').toList();
      default:
        return _data!.questions;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      appBar: _buildAppBar(),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.tealGreen)))
              : _data == null
              ? _buildError()
              : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildSummaryCard()),
                  SliverToBoxAdapter(child: _buildFilterRow()),
                  SliverToBoxAdapter(child: const SizedBox(height: 8)),
                  _filtered.isEmpty
                      ? SliverFillRemaining(child: _buildEmptyState())
                      : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) => _buildQuestionCard(_filtered[i], i),
                            childCount: _filtered.length,
                          ),
                        ),
                      ),
                ],
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
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.pageType == 0 ? 'Quiz Review' : 'Mock Test Review',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              fontFamily: 'Poppins',
            ),
          ),
          Text(
            widget.quizTitle,
            style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 10, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
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

  // ─── SUMMARY CARD ────────────────────────────────────────────────────────

  Widget _buildSummaryCard() {
    if (_data == null) return const SizedBox.shrink();
    final s = _data!.summary;
    final attempt = _data!.attempt;
    final passed = attempt.passed;
    final score = attempt.score;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              passed ? [AppColors.darkNavy, const Color(0xFF0D4B3B)] : [AppColors.darkNavy, const Color(0xFF4B0D0D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.darkNavy.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: [
          // Top — score + status
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                // Score circle
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: passed ? AppColors.tealGreen : Colors.redAccent, width: 2.5),
                    color: Colors.white.withOpacity(0.06),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${score.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      Text('Score', style: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.7))),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        passed
                            ? '✅ ${widget.pageType == 0 ? 'Quiz Passed' : 'Mock Test Passed'} '
                            : '❌ ${widget.pageType == 0 ? 'Quiz Failed' : 'Mock Test Failed'},',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        attempt.quizTitle,
                        style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Passing: ${attempt.passingScore.toStringAsFixed(0)}%  •  Yours: ${score.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withOpacity(0.85),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Divider(color: Colors.white.withOpacity(0.1), height: 1),

          // Bottom stats
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
            child: Row(
              children: [
                Expanded(child: _summStat('${s.total}', 'Total', Colors.white, Icons.quiz_outlined)),
                _summDiv(),
                Expanded(child: _summStat('${s.correct}', 'Correct', AppColors.tealGreen, Icons.check_circle_outline)),
                _summDiv(),
                Expanded(child: _summStat('${s.wrong}', 'Wrong', Colors.redAccent, Icons.cancel_outlined)),
                _summDiv(),
                Expanded(child: _summStat('${s.skipped}', 'Skipped', Colors.orange, Icons.remove_circle_outline)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summStat(String val, String label, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 4),
        Text(
          val,
          style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w900, fontFamily: 'Poppins'),
        ),
        Text(label, style: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.65))),
      ],
    );
  }

  Widget _summDiv() => Container(width: 1, height: 36, color: Colors.white.withOpacity(0.12));

  // ─── FILTER ROW ──────────────────────────────────────────────────────────

  Widget _buildFilterRow() {
    if (_data == null) return const SizedBox.shrink();
    final s = _data!.summary;

    final filters = [
      {'key': 'all', 'label': 'All', 'count': s.total, 'color': AppColors.darkNavy},
      {'key': 'correct', 'label': 'Correct', 'count': s.correct, 'color': AppColors.tealGreen},
      {'key': 'wrong', 'label': 'Wrong', 'count': s.wrong, 'color': Colors.redAccent},
      {'key': 'skipped', 'label': 'Skipped', 'count': s.skipped, 'color': Colors.orange},
    ];

    return Container(
      height: 46,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children:
            filters.map((f) {
              final bool sel = _filter == f['key'];
              final Color c = f['color'] as Color;
              final int cnt = f['count'] as int;
              return GestureDetector(
                onTap: () => setState(() => _filter = f['key'] as String),
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
                      Text(
                        f['label'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                          color: sel ? Colors.white : AppColors.greyS700,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      if (cnt > 0) ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: sel ? Colors.white.withOpacity(0.25) : c.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$cnt',
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

  // ─── QUESTION CARD ───────────────────────────────────────────────────────

  Widget _buildQuestionCard(QuizReviewQuestion q, int index) {
    Color statusColor;
    IconData statusIcon;
    String statusLabel;
    Color statusBg;

    switch (q.status) {
      case 'correct':
        statusColor = AppColors.tealGreen;
        statusIcon = Icons.check_circle;
        statusLabel = 'Correct';
        statusBg = AppColors.tealGreen.withOpacity(0.08);
        break;
      case 'wrong':
        statusColor = Colors.redAccent;
        statusIcon = Icons.cancel;
        statusLabel = 'Wrong';
        statusBg = Colors.redAccent.withOpacity(0.06);
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.remove_circle;
        statusLabel = 'Skipped';
        statusBg = Colors.orange.withOpacity(0.06);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Question header ──
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                // Q number
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(8)),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Question text
                Expanded(
                  child: Text(
                    q.questionText,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkNavy,
                      height: 1.4,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 12),
                      const SizedBox(width: 3),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Options ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Column(
              children:
                  q.options.map((opt) {
                    final bool isUserAnswer = opt.answerId == q.userAnswerId;
                    final bool isCorrectAnswer = opt.answerId == q.correctAnswerId;

                    Color optBg;
                    Color optBorder;
                    Color optText;
                    Widget? trailingIcon;

                    if (isCorrectAnswer) {
                      // Correct answer — always green
                      optBg = AppColors.tealGreen.withOpacity(0.1);
                      optBorder = AppColors.tealGreen;
                      optText = AppColors.darkNavy;
                      trailingIcon = Icon(Icons.check_circle, color: AppColors.tealGreen, size: 18);
                    } else if (isUserAnswer && !isCorrectAnswer) {
                      // User selected wrong
                      optBg = Colors.redAccent.withOpacity(0.08);
                      optBorder = Colors.redAccent;
                      optText = AppColors.darkNavy;
                      trailingIcon = Icon(Icons.cancel, color: Colors.redAccent, size: 18);
                    } else {
                      // Normal option
                      optBg = const Color(0xFFF8F9FF);
                      optBorder = Colors.grey.withOpacity(0.2);
                      optText = AppColors.greyS700;
                      trailingIcon = null;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: optBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: optBorder, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              opt.answerText,
                              style: TextStyle(
                                fontSize: 12,
                                color: optText,
                                fontWeight: isCorrectAnswer || isUserAnswer ? FontWeight.w700 : FontWeight.w500,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                          if (trailingIcon != null) ...[const SizedBox(width: 8), trailingIcon],
                        ],
                      ),
                    );
                  }).toList(),
            ),
          ),

          // ── Explanation ──
          if (q.explanation.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(14, 8, 14, 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Explanation',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF795548),
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          q.explanation,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF5D4037),
                            height: 1.5,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            const SizedBox(height: 14),

          // ── Marks + Time ──
          Container(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.08)))),
            child: Row(
              children: [
                Icon(Icons.star_outline, size: 12, color: AppColors.greyS600),
                const SizedBox(width: 4),
                Text(
                  'Marks: +${q.marks.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 10, color: AppColors.greyS600, fontWeight: FontWeight.w500),
                ),
                if (q.negativeMarks > 0) ...[
                  const SizedBox(width: 10),
                  Text(
                    '-${q.negativeMarks.toStringAsFixed(0)} negative',
                    style: const TextStyle(fontSize: 10, color: Colors.redAccent, fontWeight: FontWeight.w500),
                  ),
                ],
                const Spacer(),
                if (q.timeSpent > 0) ...[
                  Icon(Icons.timer_outlined, size: 12, color: AppColors.greyS600),
                  const SizedBox(width: 3),
                  Text(
                    '${q.timeSpent}s',
                    style: TextStyle(fontSize: 10, color: AppColors.greyS600, fontWeight: FontWeight.w500),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── EMPTY / ERROR ───────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.quiz_outlined, size: 56, color: AppColors.greyS400),
          const SizedBox(height: 12),
          Text(
            'No questions in this filter',
            style: TextStyle(fontSize: 14, color: AppColors.greyS600, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
          const SizedBox(height: 12),
          const Text(
            'Failed to load review',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkNavy),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _fetch,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(color: AppColors.tealGreen, borderRadius: BorderRadius.circular(8)),
              child: const Text('Retry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
