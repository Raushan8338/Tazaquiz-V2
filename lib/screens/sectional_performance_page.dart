import 'package:flutter/material.dart';
import 'package:tazaquiznew/API/Language_converter/translation_service.dart';
import 'package:tazaquiznew/API/api_client.dart';
import 'package:tazaquiznew/authentication/AuthRepository.dart';
import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/models/login_response_model.dart';
import 'package:tazaquiznew/utils/session_manager.dart';

// Subject-wise (sectional) performance — resolved backend-side via each
// quiz's topic/education-level mapping, since individual questions aren't
// subject-tagged. Aggregates across every quiz type (no pageType filter)
// for a single overall picture, matching how Testbook/Unacademy show it.
class _SubjectPerf {
  final int courseId;
  final String courseName;
  final int subjectId;
  final String subjectName;
  final int totalQuizzes; // attempted
  final int totalAvailable; // total tests that exist in this subject
  final double avgScore;
  final int totalWins;

  _SubjectPerf({
    required this.courseId,
    required this.courseName,
    required this.subjectId,
    required this.subjectName,
    required this.totalQuizzes,
    required this.totalAvailable,
    required this.avgScore,
    required this.totalWins,
  });

  factory _SubjectPerf.fromJson(Map<String, dynamic> j) {
    int safeInt(dynamic v) => v is int ? v : int.tryParse(v.toString()) ?? 0;
    final attempted = safeInt(j['total_quizzes']);
    final available = safeInt(j['total_available']);
    return _SubjectPerf(
      courseId: safeInt(j['course_id']),
      courseName: j['course_name']?.toString() ?? 'My Course',
      subjectId: safeInt(j['subject_id']),
      subjectName: j['subject_name']?.toString() ?? 'General',
      totalQuizzes: attempted,
      totalAvailable: available < attempted ? attempted : available,
      avgScore: (j['avg_score'] as num?)?.toDouble() ?? 0.0,
      totalWins: safeInt(j['total_wins']),
    );
  }

  // A single high/low score off 1-2 attempts isn't reliable — require a
  // minimum number of attempts (capped by however many tests actually
  // exist) before calling a subject "Strong"/"mastered".
  int get _confidenceThreshold => totalAvailable < 3 ? totalAvailable : 3;
  bool get hasEnoughData => totalAvailable == 0 || totalQuizzes >= _confidenceThreshold;

  String get badgeLabel {
    if (!hasEnoughData) return 'Attempt More';
    if (avgScore >= 70) return 'Strong';
    if (avgScore >= 40) return 'Average';
    return 'Needs Work';
  }

  Color get badgeColor {
    if (!hasEnoughData) return Colors.blueGrey;
    if (avgScore >= 70) return AppColors.tealGreen;
    if (avgScore >= 40) return Colors.orange;
    return Colors.redAccent;
  }

  // Student-facing "what to do next" tip based on accuracy + attempt coverage.
  String get tip {
    if (!hasEnoughData) {
      final remaining = _confidenceThreshold - totalQuizzes;
      return 'Attempt $remaining more test${remaining == 1 ? '' : 's'} for an accurate result';
    }
    if (avgScore < 40) return 'Weak area — revise basics and retry this subject';
    if (avgScore < 70) return 'Improving — keep practicing to boost accuracy';
    if (totalAvailable > totalQuizzes) return 'Strong subject — attempt remaining tests to confirm it';
    return 'Great job — you\'ve mastered this subject';
  }
}

class SectionalPerformancePage extends StatefulWidget {
  const SectionalPerformancePage({Key? key}) : super(key: key);

  @override
  State<SectionalPerformancePage> createState() => _SectionalPerformancePageState();
}

class _SectionalPerformancePageState extends State<SectionalPerformancePage> {
  bool _isLoading = true;
  String? _error;
  List<_SubjectPerf> _subjects = [];
  UserModel? _user;

  // Groups the flat (already course-ordered) list into course sections,
  // preserving backend order.
  List<List<_SubjectPerf>> get _groupedByCourse {
    final List<List<_SubjectPerf>> groups = [];
    for (final s in _subjects) {
      if (groups.isNotEmpty && groups.last.first.courseId == s.courseId) {
        groups.last.add(s);
      } else {
        groups.add([s]);
      }
    }
    return groups;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      _user = await SessionManager.getUser();
      if (_user == null) {
        setState(() {
          _error = 'Please log in to view your performance';
          _isLoading = false;
        });
        return;
      }
      final response = await Authrepository(Api_Client.dio).fetchSubjectWisePerformance({
        'user_id': _user!.id.toString(),
      });
      final data = response.data;
      if (data is Map && data['status'] == true) {
        setState(() {
          _subjects = (data['data'] as List? ?? []).map((e) => _SubjectPerf.fromJson(e)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Could not load performance data';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Could not load performance data';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.tealGreen,
        child: _isLoading
            ? ListView(
                children: const [
                  SizedBox(height: 200),
                  Center(child: CircularProgressIndicator(color: AppColors.tealGreen)),
                ],
              )
            : _error != null
                ? ListView(
                    children: [SizedBox(height: 220, child: _buildMessage(Icons.error_outline_rounded, _error!))],
                  )
                : _subjects.isEmpty
                    ? ListView(
                        children: [
                          SizedBox(
                            height: 320,
                            child: _buildMessage(
                              Icons.donut_large_rounded,
                              'No sectional data yet.\nAttempt a few tests to see your subject-wise breakdown here.',
                            ),
                          ),
                        ],
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        children: [
                          _buildIntroCard(),
                          const SizedBox(height: 16),
                          for (final group in _groupedByCourse) ...[
                            _buildCourseHeader(group.first.courseName),
                            const SizedBox(height: 8),
                            for (final s in group) ...[
                              _buildSubjectCard(s),
                              const SizedBox(height: 12),
                            ],
                            const SizedBox(height: 6),
                          ],
                        ],
                      ),
      ),
    );
  }

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
      title: const TranslatedText(
        'Sectional Performance',
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

  Widget _buildMessage(IconData icon, String text) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(color: AppColors.tealGreen.withOpacity(0.08), shape: BoxShape.circle),
            child: Icon(icon, size: 48, color: AppColors.greyS400),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: TranslatedText(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.greyS600, fontFamily: 'Poppins'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroCard() {
    Widget bullet(String text) {
      return Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.7), shape: BoxShape.circle),
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: TranslatedText(
                text,
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10.5, fontFamily: 'Poppins', height: 1.35),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.darkNavy, Color(0xFF0D4B3B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: AppColors.darkNavy.withOpacity(0.25), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                child: const Icon(Icons.insights_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TranslatedText(
                  'Know your strong & weak subjects',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800, fontFamily: 'Poppins'),
                ),
              ),
            ],
          ),
          bullet('Grouped by the course you purchased, subject-wise'),
          bullet('Score % = your best (highest-scoring) attempt in each test'),
          bullet('"X/Y tests attempted" shows how many tests exist vs how many you\'ve given'),
          bullet('A subject is marked Strong only after enough attempts to be sure'),
        ],
      ),
    );
  }

  Widget _buildCourseHeader(String courseName) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 2),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(color: AppColors.tealGreen, borderRadius: BorderRadius.circular(3)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TranslatedText(
              courseName,
              style: const TextStyle(
                  fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.darkNavy, fontFamily: 'Poppins'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(_SubjectPerf s) {
    final Color color = s.badgeColor;
    final String badge = s.badgeLabel;
    final double coverage = s.totalAvailable > 0 ? (s.totalQuizzes / s.totalAvailable).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Compact score ring instead of a big standalone number.
              SizedBox(
                width: 44,
                height: 44,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: CircularProgressIndicator(
                        value: (s.avgScore / 100).clamp(0.0, 1.0),
                        strokeWidth: 4,
                        backgroundColor: color.withOpacity(0.12),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                    Text(
                      '${s.avgScore.toStringAsFixed(0)}%',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: color, fontFamily: 'Poppins'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TranslatedText(
                            s.subjectName,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.darkNavy, fontFamily: 'Poppins'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration:
                              BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(7)),
                          child: TranslatedText(
                            badge,
                            style:
                                TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color, fontFamily: 'Poppins'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    // ⚠️ Numbers — plain Text
                    Text(
                      '${s.totalQuizzes}/${s.totalAvailable} tests attempted · ${s.totalWins} passed',
                      style: TextStyle(fontSize: 10.5, color: AppColors.greyS500, fontFamily: 'Poppins'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: coverage,
              backgroundColor: AppColors.greyS400.withOpacity(0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.tealGreen),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, size: 13, color: color),
              const SizedBox(width: 5),
              Expanded(
                child: TranslatedText(
                  s.tip,
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: color, fontFamily: 'Poppins'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
