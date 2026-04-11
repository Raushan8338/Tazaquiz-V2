import 'package:flutter/material.dart';
import 'package:tazaquiznew/API/Language_converter/translation_service.dart';
import 'package:tazaquiznew/API/api_client.dart';
import 'package:tazaquiznew/authentication/AuthRepository.dart';
import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/models/login_response_model.dart';
import 'package:tazaquiznew/utils/session_manager.dart';

class WeeklyProgressWidget extends StatefulWidget {
  const WeeklyProgressWidget({Key? key}) : super(key: key);

  @override
  State<WeeklyProgressWidget> createState() => _WeeklyProgressWidgetState();
}

class _WeeklyProgressWidgetState extends State<WeeklyProgressWidget>
    with SingleTickerProviderStateMixin {
  int totalQuizzes = 0;
  int completedQuizzes = 0;
  double progressValue = 0.0;
  bool isLoading = true;
  String datastatus = '';
  bool hasData = false;
  UserModel? _user;

  // Static — baad mein API se replace karna
  final int qsSolved = 142;
  final int accuracyPercent = 78;
  final double studyHours = 4.2;

  late AnimationController _animController;
  late Animation<double> _progressAnim;

  final List<String> _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final List<String> _dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _progressAnim = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _getUserData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _getUserData() async {
    _user = await SessionManager.getUser();
    if (mounted) setState(() {});
    fetchData();
  }

  void fetchData() async {
    try {
      final reqData = {'user_id': _user?.id};
      final authRepository = Authrepository(Api_Client.dio);
      final response = await authRepository.fetchHomeWeeklyProgress(reqData);

      if (response.statusCode == 200) {
        final data = response.data;
        final status = data['status'];
        final total =
            int.tryParse(data['totalQuizzes']?.toString() ?? '0') ?? 0;
        final completed =
            int.tryParse(data['completedQuizzes']?.toString() ?? '0') ?? 0;
        final percent =
            (int.tryParse(data['completionPercentage']?.toString() ?? '0') ??
                    0) /
                100.0;

        setState(() {
          datastatus = status;
          totalQuizzes = total;
          completedQuizzes = completed;
          progressValue = total > 0 ? percent : 0.0;
          hasData = (status == 'success' && total > 0);
          isLoading = false;
        });

        if (hasData) {
          _progressAnim =
              Tween<double>(begin: 0, end: progressValue).animate(
            CurvedAnimation(parent: _animController, curve: Curves.easeOut),
          );
          _animController.forward();
        }
      } else {
        setState(() {
          isLoading = false;
          hasData = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        hasData = false;
      });
    }
  }

  int get _completedDays => completedQuizzes.clamp(0, 7);
  int get _todayIndex => DateTime.now().weekday - 1;

  @override
  Widget build(BuildContext context) {
    if (!hasData) return const SizedBox.shrink();

    final completedDays = _completedDays;
    final todayIdx = _todayIndex;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ── Header ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.tealGreen.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Icon(
                      Icons.trending_up_rounded,
                      color: AppColors.tealGreen,
                      size: 13,
                    ),
                  ),
                  const SizedBox(width: 7),
                  const TranslatedText(
                    'Weekly Progress',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkNavy,
                    ),
                  ),
                ],
              ),
              /// Details → TODO: apna page naam yahan add karo
              GestureDetector(
                onTap: () {
                  // TODO: Navigator.push(context, MaterialPageRoute(builder: (_) => YourResultPage()));
                },
                child: Row(
                  children: [
                    TranslatedText(
                      'Details',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.tealGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 9,
                      color: AppColors.tealGreen,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          /// ── Day Circles ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final isDone = i < completedDays;
              final isToday = i == todayIdx && !isDone;

              final Color bg = isDone
                  ? AppColors.tealGreen
                  : isToday
                      ? const Color(0xFFF59E0B)
                      : AppColors.greyS200;

              final Color textColor =
                  (isDone || isToday) ? Colors.white : AppColors.greyS500;

              return Column(
                children: [
                  AnimatedContainer(
                    duration: Duration(milliseconds: 350 + i * 50),
                    curve: Curves.easeOut,
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: bg,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _dayLetters[i],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _dayLabels[i],
                    style: TextStyle(
                      fontSize: 8,
                      color: AppColors.greyS500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            }),
          ),

          const SizedBox(height: 11),

          /// ── Divider ──
          Container(height: 1, color: AppColors.greyS200),

          const SizedBox(height: 10),

          /// ── 3 Stats ──
          IntrinsicHeight(
            child: Row(
              children: [
                _statBox(
                  value: '$qsSolved',
                  label: 'Qs solved',
                  sublabel: 'this week',
                  color: AppColors.darkNavy,
                ),
                _vertDivider(),
                _statBox(
                  value: '$accuracyPercent%',
                  label: 'Accuracy',
                  sublabel: 'all papers',
                  color: AppColors.tealGreen,
                ),
                _vertDivider(),
                _statBox(
                  value: '${studyHours.toStringAsFixed(1)}h',
                  label: 'Study time',
                  sublabel: 'this week',
                  color: const Color(0xFFF59E0B),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBox({
    required String value,
    required String label,
    required String sublabel,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,        // ← pehle 18 tha, ab 16
              fontWeight: FontWeight.w800,
              color: color,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          TranslatedText(
            label,
            style: TextStyle(
              fontSize: 9,
              color: AppColors.greyS500,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 1),
          /// Small mention — all papers / this week
          TranslatedText(
            sublabel,
            style: TextStyle(
              fontSize: 8,           // ← bahut chota
              color: AppColors.greyS400,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _vertDivider() => Container(width: 1, color: AppColors.greyS200);
}