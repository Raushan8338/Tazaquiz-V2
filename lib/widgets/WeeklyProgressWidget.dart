import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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

class _WeeklyProgressWidgetState extends State<WeeklyProgressWidget> {
  int totalQuizzes = 0;
  int completedQuizzes = 0;
  double progressValue = 0.0;
  bool isLoading = true;
  bool hasData = false;
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  void _getUserData() async {
    // Fetch and set user data here if needed
    _user = await SessionManager.getUser();
    setState(() {});
    fetchData();
  }

  void fetchData() async {
    try {
      final data = {'user_id': '1'}; // Replace with actual user ID

      Authrepository authRepository = Authrepository(Api_Client.dio);

      final responseFuture = await authRepository.fetchHomeWeeklyProgress(data);

      if (responseFuture.statusCode == 200) {
        final data = responseFuture.data;

        final status = data['status'] ?? '';
        final total = int.parse(data['totalQuizzes'] ?? 0);
        final completed = int.parse(data['completedQuizzes'] ?? 0);

        setState(() {
          totalQuizzes = total;
          completedQuizzes = completed;
          progressValue = total > 0 ? (int.parse(data['completionPercentage']) ?? 0) / 100 : 0.0;

          // Only show if status is 'success' AND totalQuizzes > 0
          hasData = (status == 'success' && total > 0);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          hasData = false;
        });
      }
    } catch (e) {
      print('Error fetching data: $e');
      setState(() {
        isLoading = false;
        hasData = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Don't render anything while loading
    // if (isLoading) {
    //   return const SizedBox.shrink();
    // }

    // // Don't render if no data
    // if (!hasData) {
    //   return const SizedBox.shrink();
    // }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.08),
            Theme.of(context).colorScheme.primary.withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.15), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.tealGreen, AppColors.darkNavy],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),

                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Icon(Icons.trending_up_rounded, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [Text('Weekly Progress', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold))],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: AppColors.tealGreen, borderRadius: BorderRadius.circular(16)),
                child: Text(
                  '${(progressValue * 100).toInt()}%',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _buildStatItem('Completed', '$completedQuizzes', AppColors.tealGreen)),
              Container(
                height: 35,
                width: 1,
                color: Colors.grey[300],
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
              Expanded(child: _buildStatItem('Total', '$totalQuizzes', Colors.grey[700]!)),
              Container(
                height: 35,
                width: 1,
                color: Colors.grey[300],
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
              Expanded(child: _buildStatItem('Remaining', '${totalQuizzes - completedQuizzes}', Colors.orange[700]!)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: valueColor)),
      ],
    );
  }
}
