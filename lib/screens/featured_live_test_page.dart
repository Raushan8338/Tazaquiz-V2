import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tazaquiznew/API/Language_converter/translation_service.dart';
import 'package:tazaquiznew/API/api_client.dart';
import 'package:tazaquiznew/authentication/AuthRepository.dart';
import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/models/login_response_model.dart';
import 'package:tazaquiznew/models/quizItem_modal.dart';
import 'package:tazaquiznew/screens/checkout.dart';
import 'package:tazaquiznew/screens/first_instructionPage.dart';
import 'package:tazaquiznew/utils/session_manager.dart';

/// Dedicated, minimal page for a featured/special live test
/// (quizzes.pageType = 10). Deliberately does NOT reuse the shared
/// QuizDetailPage (buyQuizes.dart) — that page is built around course
/// subscriptions (premium/unlock-course banners, leaderboard shortcuts,
/// ads) which don't apply here: this is a single standalone test purchase.
class FeaturedLiveTestPage extends StatefulWidget {
  final String quizId;
  const FeaturedLiveTestPage({super.key, required this.quizId});

  @override
  State<FeaturedLiveTestPage> createState() => _FeaturedLiveTestPageState();
}

class _FeaturedLiveTestPageState extends State<FeaturedLiveTestPage> {
  UserModel? _user;
  bool _isLoading = true;
  bool _hasError = false;
  QuizItem? _quiz;
  bool _isRegistered = false;
  bool _isProcessing = false;

  String? _publisherName;
  String? _publisherBio;
  String? _publisherLogo;

  Timer? _countdownTimer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    _user = await SessionManager.getUser();
    await _fetch();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  String _formatCountdown(int seconds) {
    if (seconds <= 0) return 'Starting now';
    final days = seconds ~/ 86400;
    final hours = (seconds % 86400) ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    if (days > 0) return '${days}d ${hours}h ${minutes}m';
    if (hours > 0) return '${hours}h ${minutes}m ${secs}s';
    return '${minutes}m ${secs}s';
  }

  Future<void> _fetch() async {
    if (_user == null) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      Authrepository authRepository = Authrepository(Api_Client.dio);
      final response = await authRepository.check_featured_quiz_access({
        'quiz_id': widget.quizId.toString(),
        'user_id': _user!.id.toString(),
      });

      if (response.statusCode == 200 && response.data['success'] == true && response.data['data'] != null) {
        final bool accessible = response.data['accessible'] == true;
        final Map<String, dynamic> quizJson = Map<String, dynamic>.from(response.data['data']);
        quizJson['is_accessible'] = accessible;
        quizJson['access_status'] = accessible;
        quizJson['is_purchased'] = accessible;

        final parsedQuiz = QuizItem.fromJson(quizJson);
        final startTime = DateTime.tryParse(parsedQuiz.startDateTime);
        final secondsUntilStart = startTime != null ? startTime.difference(DateTime.now()).inSeconds : 0;

        setState(() {
          _quiz = parsedQuiz;
          _isLoading = false;
          _remainingSeconds = secondsUntilStart > 0 ? secondsUntilStart : 0;
          _publisherName = quizJson['publisher_name']?.toString();
          _publisherBio = _stripHtml(quizJson['publisher_bio']?.toString());
          _publisherLogo = quizJson['publisher_logo']?.toString();
        });

        if (_remainingSeconds > 0) {
          _startCountdown();
        }

        unawaited(_checkRegistered(accessible));
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  // Publisher bio comes from the admin dashboard's rich-text editor as raw
  // HTML (e.g. "<p>...</p>") — strip tags and decode entities so it renders
  // as plain readable text instead of literal markup.
  String? _stripHtml(String? html) {
    if (html == null || html.isEmpty) return null;
    var text = html
        .replaceAll(RegExp(r'<\s*br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</\s*p\s*>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");
    return text.trim().isEmpty ? null : text.trim();
  }

  // `accessible` is the just-fetched access-check result: for a paid quiz,
  // true means a verified purchase_history row already exists. A payment
  // made via the shared CheckoutPage/Cashfree flow never calls
  // notify_live_test.php itself (that flow knows nothing about featured
  // live tests), so without this the "registered" state and the admin's
  // reminder-tracking table would silently miss every paid registrant.
  Future<void> _checkRegistered(bool accessible) async {
    try {
      Authrepository authRepository = Authrepository(Api_Client.dio);
      final response = await authRepository.check_live_test_registered({
        'quiz_id': widget.quizId.toString(),
        'user_id': _user!.id.toString(),
      });
      if (!mounted) return;
      final bool registered = response.statusCode == 200 && response.data['registered'] == true;
      if (registered) {
        setState(() => _isRegistered = true);
        return;
      }

      if (accessible && (_quiz?.isPaid ?? false)) {
        final notifyResponse = await authRepository.notify_live_test({
          'quiz_id': widget.quizId.toString(),
          'user_id': _user!.id.toString(),
        });
        if (mounted && notifyResponse.statusCode == 200 && notifyResponse.data['success'] == true) {
          setState(() => _isRegistered = true);
        }
      }
    } catch (_) {}
  }

  // Compact form for the stat card grid ("17 Sep, 1:34 PM").
  String _formatDateCompact(String raw) {
    try {
      final dt = DateTime.parse(raw);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final hour = dt.hour;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final hour12 = hour % 12 == 0 ? 12 : hour % 12;
      return '${dt.day} ${months[dt.month - 1]}, $hour12:$minute $period';
    } catch (_) {
      return raw;
    }
  }

  Future<void> _handleNotifyNow() async {
    if (_user == null) return;
    setState(() => _isProcessing = true);
    try {
      Authrepository authRepository = Authrepository(Api_Client.dio);
      final response = await authRepository.notify_live_test({
        'quiz_id': widget.quizId.toString(),
        'user_id': _user!.id.toString(),
      });
      if (!mounted) return;
      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _isRegistered = true;
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const TranslatedText("You're registered! We'll notify you before the test starts."),
            backgroundColor: AppColors.tealGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else {
        setState(() => _isProcessing = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // Routes through the same CheckoutPage + Cashfree flow every other
  // purchase in the app already uses (checkout.dart), instead of
  // reinventing the payment trigger inline — package_id '0' + content_type
  // 'QUIZ' tells checkout_details.php to price off the quiz's own price
  // (no GST) rather than a package.
  Future<void> _handleBuyNow() async {
    if (_quiz == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutPage(
          contentType: 'QUIZ',
          contentId: widget.quizId,
          package_id: '0',
        ),
      ),
    );
    // Refresh in case a payment completed while we were away, so the
    // Enroll button correctly flips to Registered.
    if (mounted) await _fetch();
  }

  Future<void> _navigateToJoinQuiz() async {
    if (_quiz == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizInstructionPage(
          testTitle: _quiz!.title,
          subject: _quiz!.difficultyLevel,
          Quiz_id: widget.quizId.toString(),
          timeLimit: int.tryParse(_quiz!.timeLimit) ?? 0,
          pageType: 'live_test',
          total_questions: _quiz!.totalQuestions,
          totalMarks: _quiz!.totalMarks,
          passingMarks: int.tryParse(_quiz!.passing_score ?? '0') ?? 0,
          instruction: _quiz!.instruction,
          negativeMark: _quiz!.negative_mark,
          courseId: '0',
        ),
      ),
    );
    if (mounted) await _fetch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_hasError || _quiz == null)
              ? _buildErrorState()
              : _buildContent(),
      bottomNavigationBar: (!_isLoading && !_hasError && _quiz != null) ? _buildBottomBar() : null,
    );
  }

  Widget _buildErrorState() {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  const TranslatedText('Could not load this test right now.'),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _fetch, child: const TranslatedText('Retry')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final quiz = _quiz!;
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          backgroundColor: AppColors.darkNavy,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: (quiz.banner != null && quiz.banner!.isNotEmpty)
                ? Image.network(
                    quiz.banner!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [AppColors.darkNavy, AppColors.tealGreen]),
                      ),
                    ),
                  )
                : Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [AppColors.darkNavy, AppColors.tealGreen]),
                    ),
                    child: const Center(child: Icon(Icons.stars_rounded, color: Colors.white54, size: 56)),
                  ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B21A8).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const TranslatedText(
                    'COMPETITION',
                    style: TextStyle(
                      color: Color(0xFF6B21A8),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TranslatedText(
                  quiz.title,
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.darkNavy),
                ),
                if (quiz.description.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  TranslatedText(
                    quiz.description,
                    style: TextStyle(fontSize: 13.5, color: Colors.grey.shade700, height: 1.5),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        Icons.event_rounded,
                        'Starts',
                        _formatDateCompact(quiz.startDateTime),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildStatCard(
                        Icons.timer_outlined,
                        'Duration',
                        '${quiz.timeLimit} min',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        Icons.help_outline_rounded,
                        'Questions',
                        '${quiz.totalQuestions}',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildStatCard(
                        Icons.military_tech_outlined,
                        'Total Marks',
                        quiz.totalMarks > 0 ? '${quiz.totalMarks}' : '-',
                      ),
                    ),
                  ],
                ),
                if (_remainingSeconds > 0) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFAEB),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFBD038), width: 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.schedule_rounded, color: Color(0xFFB45309), size: 14),
                        const SizedBox(width: 7),
                        TranslatedText(
                          'Starts in',
                          style: const TextStyle(fontSize: 12, color: Color(0xFFB45309), fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _formatCountdown(_remainingSeconds),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                _buildPublisherCard(),
                const SizedBox(height: 20),
                _buildFaqSection(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.tealGreen),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.darkNavy),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          TranslatedText(
            label,
            style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildPublisherCard() {
    final String name = (_publisherName != null && _publisherName!.isNotEmpty) ? _publisherName! : 'TazaTest';
    final String bio = (_publisherBio != null && _publisherBio!.isNotEmpty)
        ? _publisherBio!
        : 'TazaQuiz\'s trusted content partner, designing exam-pattern mock tests and live competitions that match the real exam difficulty and structure.';
    final bool hasLogo = _publisherLogo != null && _publisherLogo!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 42,
              height: 42,
              child: hasLogo
                  ? Image.network(
                      _publisherLogo!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _publisherIconFallback(),
                    )
                  : _publisherIconFallback(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TranslatedText(
                  'Published by $name',
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.darkNavy),
                ),
                const SizedBox(height: 4),
                TranslatedText(
                  bio,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _publisherIconFallback() {
    return Container(
      color: AppColors.tealGreen.withOpacity(0.1),
      child: const Icon(Icons.verified_rounded, color: AppColors.tealGreen, size: 22),
    );
  }

  Widget _buildFaqSection() {
    final faqs = <_Faq>[
      _Faq(
        'How do I attempt this test?',
        'Tap Enroll Now (or Notify Now if it\'s free) to register. Once the test goes live, come back to this page or your notifications to start it.',
      ),
      _Faq(
        'Is there negative marking?',
        'Negative marking depends on this specific test\'s rules — check the description above for details on marking scheme.',
      ),
      _Faq(
        'What if I miss the live window?',
        'You can still attempt the test after it starts, as long as it hasn\'t ended — your score and rank will still be recorded.',
      ),
      _Faq(
        'Will I get a certificate or rank?',
        'Yes — your performance and rank for this test will appear in your Profile under Live Test Performance.',
      ),
      _Faq(
        'Is payment secure?',
        'Yes, payments are processed securely through Cashfree, the same trusted payment partner used across TazaQuiz.',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TranslatedText(
          'Frequently Asked Questions',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.darkNavy),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          child: Column(
            children: faqs.asMap().entries.map((entry) {
              final isLast = entry.key == faqs.length - 1;
              return Column(
                children: [
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 14),
                      childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                      title: TranslatedText(
                        entry.value.question,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.darkNavy),
                      ),
                      expandedAlignment: Alignment.topLeft,
                      children: [
                        TranslatedText(
                          entry.value.answer,
                          style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast) const Divider(height: 1, color: Color(0xFFF1F1F1)),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFEEEEEE))),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, -3))],
      ),
      child: SafeArea(
        top: false,
        child: _buildButton(),
      ),
    );
  }

  Widget _buildButton() {
    final bool isPaidQuiz = _quiz?.isPaid ?? false;
    // For a paid quiz, whether to show the registered/countdown/Join-Now
    // state must be driven by the LIVE access check (quiz.isAccessible,
    // re-verified against purchase_history on every fetch) — not by
    // _isRegistered, which is a one-time notification-table record that
    // stays true forever once set and would otherwise keep showing access
    // even if the underlying purchase is later removed/refunded. Free
    // quizzes have no purchase to re-check, so _isRegistered (did they tap
    // Notify) is the correct signal there.
    final bool hasAccess = isPaidQuiz ? (_quiz?.isAccessible ?? false) : _isRegistered;

    if (hasAccess) {
      final bool isLive = _quiz?.quizStatus.toLowerCase() == 'live';

      if (isLive) {
        return SizedBox(
          width: double.infinity,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.darkNavy, AppColors.tealGreen]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: AppColors.tealGreen.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _navigateToJoinQuiz,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TranslatedText(
                        'Join Now',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFAEB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFBD038), width: 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.schedule_rounded, color: Color(0xFFB45309), size: 18),
            const SizedBox(width: 8),
            TranslatedText(
              'Starts in',
              style: const TextStyle(fontSize: 13, color: Color(0xFFB45309), fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 6),
            Text(
              _formatCountdown(_remainingSeconds),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
            ),
          ],
        ),
      );
    }

    final actionButton = Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.darkNavy, AppColors.tealGreen]),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: AppColors.tealGreen.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _isProcessing ? null : (isPaidQuiz ? _handleBuyNow : _handleNotifyNow),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 15, horizontal: isPaidQuiz ? 28 : 15),
            child: _isProcessing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                  )
                : TranslatedText(
                    isPaidQuiz ? 'Enroll Now' : 'Notify Now',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
          ),
        ),
      ),
    );

    if (!isPaidQuiz) {
      return SizedBox(width: double.infinity, child: actionButton);
    }

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Price',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
              ),
              Text(
                '₹${_quiz?.price.toStringAsFixed(0) ?? ''}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.darkNavy),
              ),
            ],
          ),
        ),
        actionButton,
      ],
    );
  }
}

class _Faq {
  final String question;
  final String answer;
  const _Faq(this.question, this.answer);
}
