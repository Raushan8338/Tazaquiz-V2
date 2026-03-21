import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tazaquiznew/API/api_client.dart';
import 'package:tazaquiznew/authentication/AuthRepository.dart';
import 'package:tazaquiznew/models/daily_quiz_attempt_modal.dart';
import 'package:tazaquiznew/models/login_response_model.dart';
import 'package:tazaquiznew/screens/daily_quiz_result_screen.dart';
import 'package:tazaquiznew/utils/session_manager.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({Key? key}) : super(key: key);

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final List<QuizAttempt> _attempts = [];
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  bool _isFirstLoad = true;
  bool _hasMore = true;
  String? _error;
  UserModel? _user;

  int _offset = 0;
  final int _limit = 5;

  @override
  void initState() {
    super.initState();
    _getUserData();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100) {
        if (!_isLoading && _hasMore) _fetchAttempts();
      }
    });
  }

  Future<void> _getUserData() async {
    _user = await SessionManager.getUser();
    if (_user == null) {
      setState(() {
        _error = 'User session not found. Please login again.';
        _isLoading = false;
        _isFirstLoad = false;
      });
      return;
    }
    await _fetchAttempts();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchAttempts() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      Authrepository authRepository = Authrepository(Api_Client.dio);
      final responseFuture = await authRepository.fetchDailyQuizAttempt({
        'user_id': _user!.id,
        'limit': _limit.toString(),
        'offset': _offset.toString(),
      });
      if (responseFuture.statusCode == 200) {
        final jsonData = responseFuture.data;
        final List newData = jsonData['data'];
        setState(() {
          _attempts.addAll(newData.map((e) => QuizAttempt.fromJson(e)));
          _hasMore = jsonData['has_more'];
          _offset += _limit;
          _isLoading = false;
          _isFirstLoad = false;
          _error = null;
        });
      } else {
        setState(() {
          _error = 'Server error. Please try again.';
          _isLoading = false;
          _isFirstLoad = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Connection failed. Check your internet.';
        _isLoading = false;
        _isFirstLoad = false;
      });
    }
  }

  String _formatDate(String rawDate) {
    try {
      final parsed = DateTime.parse(rawDate);
      return DateFormat('dd MMM yyyy').format(parsed);
    } catch (_) {
      return rawDate;
    }
  }

  Future<void> _onRefresh() async {
    setState(() {
      _attempts.clear();
      _offset = 0;
      _hasMore = true;
      _isFirstLoad = true;
      _error = null;
    });
    await _fetchAttempts();
  }

  String _grade(int score, int total) {
    final p = (score / total) * 100;
    if (p >= 90) return 'Excellent 🏆';
    if (p >= 70) return 'Good 👍';
    if (p >= 50) return 'Average 📚';
    return 'Keep Trying 💪';
  }

  Color _gradeColor(int score, int total) {
    final p = (score / total) * 100;
    if (p >= 90) return const Color(0xFF0D6E6E);
    if (p >= 70) return const Color(0xFF2979FF);
    if (p >= 50) return const Color(0xFFFF9800);
    return const Color(0xFFEF5350);
  }

  Color _gradeBg(int score, int total) {
    return _gradeColor(score, total).withOpacity(0.08);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0A3D3D), Color(0xFF0D6E6E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          'Daily Quiz Result',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18, letterSpacing: 0.3),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
          _isFirstLoad
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF0D6E6E)))
              : _error != null && _attempts.isEmpty
              ? _errorState()
              : _attempts.isEmpty
              ? _emptyState()
              : RefreshIndicator(
                color: const Color(0xFF0D6E6E),
                onRefresh: _onRefresh,
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                  itemCount: _attempts.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _attempts.length) {
                      if (_isLoading) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(child: CircularProgressIndicator(color: Color(0xFF0D6E6E), strokeWidth: 2)),
                        );
                      }
                      if (!_hasMore) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(width: 40, height: 1, color: Colors.grey.shade300),
                              const SizedBox(width: 10),
                              Text(
                                'All caught up!',
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(width: 40, height: 1, color: Colors.grey.shade300),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }

                    final a = _attempts[index];
                    final pct = ((a.score / a.total) * 100).toStringAsFixed(0);
                    final gradeColor = _gradeColor(a.score, a.total);

                    return GestureDetector(
                      onTap:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => QuizDetailScreen(
                                    userId: int.parse(_user!.id),
                                    quizDate: a.quizDate,
                                    score: a.score,
                                    total: a.total,
                                  ),
                            ),
                          ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: gradeColor.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 6)),
                          ],
                        ),
                        child: Column(
                          children: [
                            /// Top colored accent bar
                            Container(
                              height: 4,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [gradeColor, gradeColor.withOpacity(0.4)]),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  /// Score Ring
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      SizedBox(
                                        width: 62,
                                        height: 62,
                                        child: CircularProgressIndicator(
                                          value: a.score / a.total,
                                          strokeWidth: 5,
                                          backgroundColor: gradeColor.withOpacity(0.12),
                                          valueColor: AlwaysStoppedAnimation<Color>(gradeColor),
                                        ),
                                      ),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '$pct%',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                              color: gradeColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 16),

                                  /// Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.calendar_today_rounded,
                                              size: 13,
                                              color: Color(0xFF0D6E6E),
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              _formatDate(a.quizDate),
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF1A1A2E),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            _modernChip(
                                              Icons.check_circle_outline_rounded,
                                              '${a.score}/${a.total}',
                                              Colors.green,
                                            ),
                                            const SizedBox(width: 8),
                                            _modernChip(Icons.timer_outlined, '${a.timeTaken}s', Colors.orange),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _gradeBg(a.score, a.total),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            _grade(a.score, a.total),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: gradeColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0D6E6E).withOpacity(0.08),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 12,
                                      color: Color(0xFF0D6E6E),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
    );
  }

  Widget _modernChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: const Color(0xFF0D6E6E).withOpacity(0.08), shape: BoxShape.circle),
            child: const Icon(Icons.quiz_outlined, size: 48, color: Color(0xFF0D6E6E)),
          ),
          const SizedBox(height: 20),
          const Text(
            'No Attempts Yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Complete a daily quiz to see\nyour results here.',
            style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.08), shape: BoxShape.circle),
              child: const Icon(Icons.wifi_off_rounded, size: 40, color: Colors.red),
            ),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Something went wrong',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D6E6E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
              label: const Text('Try Again', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              onPressed: _onRefresh,
            ),
          ],
        ),
      ),
    );
  }
}
