import 'package:flutter/material.dart';
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

  late AnimationController _animController;
  late Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
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
    setState(() {});
    fetchData();
  }

  void fetchData() async {
    try {
      final data = {'user_id': _user?.id};
      Authrepository authRepository = Authrepository(Api_Client.dio);
      final responseFuture = await authRepository.fetchHomeWeeklyProgress(data);

      if (responseFuture.statusCode == 200) {
        final data = responseFuture.data;
        final status = data['status'];
        final total = int.parse(data['totalQuizzes'] ?? 0);
        final completed = int.parse(data['completedQuizzes'] ?? 0);
        final percent = (int.parse(data['completionPercentage']) ?? 0) / 100;

        setState(() {
          datastatus = status;
          totalQuizzes = total;
          completedQuizzes = completed;
          progressValue = total > 0 ? percent : 0.0;
          hasData = (status == 'success' && total > 0);
          isLoading = false;
        });

        if (hasData) {
          _progressAnim = Tween<double>(begin: 0, end: progressValue).animate(
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

  @override
  Widget build(BuildContext context) {
    if (!hasData) return const SizedBox.shrink();

    final remaining = totalQuizzes - completedQuizzes;
    final percent = (progressValue * 100).toInt();

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
        children: [
          /// ── Top Row: Icon + Label + Chips ──
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.tealGreen, AppColors.darkNavy],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.trending_up_rounded,
                    color: Colors.white, size: 14),
              ),
              const SizedBox(width: 8),
              Text(
                'Weekly Progress',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkNavy,
                ),
              ),
              const Spacer(),
              _chip('✅ $completedQuizzes', AppColors.tealGreen.withOpacity(0.12),
                  AppColors.tealGreen),
              const SizedBox(width: 6),
              _chip('⏳ $remaining', Colors.orange.withOpacity(0.12),
                  Colors.orange.shade700),
              const SizedBox(width: 6),
              _chip('$percent%', AppColors.tealGreen, Colors.white, bold: true),
            ],
          ),

          const SizedBox(height: 10),

          /// ── Animated Progress Bar ──
          AnimatedBuilder(
            animation: _progressAnim,
            builder: (context, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: _progressAnim.value,
                  minHeight: 7,
                  backgroundColor: Colors.grey.shade200,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.tealGreen),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color bg, Color textColor, {bool bold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: textColor,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
    );
  }
}