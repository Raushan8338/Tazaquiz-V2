import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tazaquiznew/API/Language_converter/translation_service.dart';
import 'package:tazaquiznew/API/api_client.dart';
import 'package:tazaquiznew/authentication/AuthRepository.dart';
import 'package:tazaquiznew/models/daily_quiz_attempt_modal.dart';
import 'package:http/http.dart' as http;

class QuizDetailScreen extends StatefulWidget {
  final int userId;
  final String quizDate;
  final int score;
  final int total;

  const QuizDetailScreen({
    Key? key,
    required this.userId,
    required this.quizDate,
    required this.score,
    required this.total,
  }) : super(key: key);

  @override
  State<QuizDetailScreen> createState() => _QuizDetailScreenState();
}

class _QuizDetailScreenState extends State<QuizDetailScreen> {
  List<QuizResultDetail> details = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  String _formatDate(String rawDate) {
    try {
      final parsed = DateTime.parse(rawDate);
      return DateFormat('dd MMM yyyy').format(parsed);
    } catch (_) {
      return rawDate;
    }
  }

  Future<void> _fetchDetails() async {
    try {
      Authrepository authRepository = Authrepository(Api_Client.dio);
      final responseFuture = await authRepository.fetchDailyQuizAttemptDetails({
        'user_id': widget.userId.toString(),
        'quiz_date': widget.quizDate,
      });
      print('Response: ${responseFuture.data}'); // Debug log

      if (responseFuture.statusCode == 200) {
        final List data = responseFuture.data;
        setState(() {
          details = data.map((e) => QuizResultDetail.fromJson(e)).toList(); // ✅ clean
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Failed to load';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  String _optionText(QuizResultDetail d, String key) {
    switch (key) {
      case 'A':
        return d.optionA;
      case 'B':
        return d.optionB;
      case 'C':
        return d.optionC;
      case 'D':
        return d.optionD;
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final correctCount = details.where((d) => d.isCorrect).length;
    final wrongCount = details.where((d) => !d.isCorrect).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0A4A4A), Color(0xFF0D6E6E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: TranslatedText(
          'Daily Quiz Result - ' + _formatDate(widget.quizDate), // ✅ "Quiz – 2026-03-11" → "11 Mar 2026"
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF0D6E6E)))
              : error != null
              ? Center(child: TranslatedText(error!))
              : Column(
                children: [
                  /// Score Summary Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0D6E6E), Color(0xFF14A3A3)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _summaryTile('Score', '${widget.score}/${widget.total}', Icons.star_rounded),
                        _vDivider(),
                        _summaryTile('Correct', '$correctCount', Icons.check_circle_rounded),
                        _vDivider(),
                        _summaryTile('Wrong', '$wrongCount', Icons.cancel_rounded),
                      ],
                    ),
                  ),

                  /// Q&A List
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: details.length,
                      itemBuilder: (context, index) {
                        final d = details[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: d.isCorrect ? Colors.green.withOpacity(0.4) : Colors.red.withOpacity(0.4),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /// Question header
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0D6E6E),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: TranslatedText(
                                      'Q${index + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TranslatedText(
                                      d.question,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1A1A2E),
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    d.isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                    color: d.isCorrect ? Colors.green : Colors.red,
                                    size: 22,
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),
                              const Divider(height: 1),
                              const SizedBox(height: 12),

                              /// Options
                              ...['A', 'B', 'C', 'D'].map((key) {
                                final isSelected = d.selectedAnswer == key;
                                final isCorrectOpt = d.correctAnswer == key;

                                Color bgColor = Colors.grey.withOpacity(0.06);
                                Color borderColor = Colors.grey.withOpacity(0.2);
                                Color textColor = const Color(0xFF1A1A2E);
                                IconData? trailingIcon;
                                Color? iconColor;

                                if (isCorrectOpt) {
                                  bgColor = Colors.green.withOpacity(0.08);
                                  borderColor = Colors.green.withOpacity(0.5);
                                  textColor = Colors.green.shade800;
                                  trailingIcon = Icons.check_circle_rounded;
                                  iconColor = Colors.green;
                                } else if (isSelected && !isCorrectOpt) {
                                  bgColor = Colors.red.withOpacity(0.08);
                                  borderColor = Colors.red.withOpacity(0.5);
                                  textColor = Colors.red.shade800;
                                  trailingIcon = Icons.cancel_rounded;
                                  iconColor = Colors.red;
                                }

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                                  decoration: BoxDecoration(
                                    color: bgColor,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: borderColor, width: 1),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color:
                                              isCorrectOpt
                                                  ? Colors.green
                                                  : (isSelected ? Colors.red : Colors.grey.shade300),
                                        ),
                                        child: Center(
                                          child: TranslatedText(
                                            key,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: (isCorrectOpt || isSelected) ? Colors.white : Colors.grey.shade700,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: TranslatedText(
                                          _optionText(d, key),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: textColor,
                                            fontWeight:
                                                (isCorrectOpt || isSelected) ? FontWeight.w600 : FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                      if (trailingIcon != null) Icon(trailingIcon, size: 16, color: iconColor),
                                    ],
                                  ),
                                );
                              }).toList(),

                              /// Wrong answer hint
                              if (!d.isCorrect) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.amber.withOpacity(0.4)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.info_outline_rounded, size: 14, color: Colors.amber),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text.rich(
                                          TextSpan(
                                            children: [
                                              const TextSpan(
                                                text: 'You selected: ',
                                                style: TextStyle(fontSize: 11, color: Colors.grey),
                                              ),
                                              TextSpan(
                                                text: '${d.selectedAnswer} • ',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.red,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const TextSpan(
                                                text: 'Correct: ',
                                                style: TextStyle(fontSize: 11, color: Colors.grey),
                                              ),
                                              TextSpan(
                                                text: d.correctAnswer,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _summaryTile(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        TranslatedText(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
        TranslatedText(label, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _vDivider() {
    return Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3));
  }
}
