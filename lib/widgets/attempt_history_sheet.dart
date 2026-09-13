import 'package:flutter/material.dart';
import 'package:tazaquiznew/API/Language_converter/translation_service.dart';
import 'package:tazaquiznew/API/api_client.dart';
import 'package:tazaquiznew/authentication/AuthRepository.dart';
import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/screens/quiz_review_page.dart';

// Opens a bottom sheet listing every completed attempt for a quiz (newest
// first), each with its score and a simple up/down indicator versus the
// attempt right before it, so a student can see whether a reattempt helped.
void showAttemptHistorySheet(
  BuildContext context, {
  required String quizId,
  required String userId,
  required String? courseId,
  required String quizTitle,
  required int pageType,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AttemptHistorySheet(
      quizId: quizId,
      userId: userId,
      courseId: courseId,
      quizTitle: quizTitle,
      pageType: pageType,
    ),
  );
}

class _AttemptHistorySheet extends StatefulWidget {
  final String quizId;
  final String userId;
  final String? courseId;
  final String quizTitle;
  final int pageType;

  const _AttemptHistorySheet({
    required this.quizId,
    required this.userId,
    required this.courseId,
    required this.quizTitle,
    required this.pageType,
  });

  @override
  State<_AttemptHistorySheet> createState() => _AttemptHistorySheetState();
}

class _AttemptHistorySheetState extends State<_AttemptHistorySheet> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _attempts = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final response = await Authrepository(Api_Client.dio).fetchQuizAttemptHistory({
        'quiz_id': widget.quizId,
        'user_id': widget.userId,
        'course_id': widget.courseId,
      });
      final data = response.data is Map ? response.data : {};
      if (data['status'] == true) {
        setState(() {
          _attempts = List<Map<String, dynamic>>.from(data['attempts'] ?? []);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = data['message']?.toString() ?? 'Could not load attempt history';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load attempt history';
        _isLoading = false;
      });
    }
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
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
                decoration: BoxDecoration(
                  color: AppColors.greyS300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
                child: Row(
                  children: [
                    Icon(Icons.history_rounded, color: AppColors.tealGreen, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TranslatedText(
                        'Attempt History',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.darkNavy),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(
                            child: TranslatedText(_error!,
                                style: TextStyle(color: AppColors.greyS600)))
                        : _attempts.isEmpty
                            ? Center(
                                child: TranslatedText('No attempts yet',
                                    style: TextStyle(color: AppColors.greyS600)))
                            : ListView.builder(
                                controller: scrollController,
                                padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
                                itemCount: _attempts.length,
                                itemBuilder: (context, index) =>
                                    _buildAttemptTile(_attempts[index]),
                              ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttemptTile(Map<String, dynamic> attempt) {
    final int attemptNumber = attempt['attempt_number'] ?? 0;
    final double scorePercent = (attempt['score_percent'] ?? 0).toDouble();
    final bool passed = attempt['passed'] == true;
    final dynamic delta = attempt['score_percent_delta'];
    final double? deltaValue = delta == null ? null : (delta as num).toDouble();
    final String endTime = attempt['end_time']?.toString() ?? '';

    Widget? deltaChip;
    if (deltaValue != null && deltaValue != 0) {
      final bool improved = deltaValue > 0;
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
              '${deltaValue.abs().toStringAsFixed(1)}%',
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
            attemptId: attempt['attempt_id'] ?? 0,
            userId: int.tryParse(widget.userId) ?? 0,
            quizTitle: widget.quizTitle,
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
                  fontWeight: FontWeight.w800,
                  color: passed ? AppColors.tealGreen : Colors.red,
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
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.darkNavy),
                  ),
                  if (endTime.isNotEmpty)
                    Text(
                      _formatDate(endTime),
                      style: TextStyle(fontSize: 11, color: AppColors.greyS500),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${scorePercent.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: passed ? AppColors.tealGreen : Colors.red,
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
}
