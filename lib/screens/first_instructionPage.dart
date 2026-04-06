import 'package:flutter/material.dart';
import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/screens/livetest.dart';
import 'package:tazaquiznew/screens/mockTestScreen.dart';

class QuizInstructionPage extends StatefulWidget {
  String testTitle;
  String subject;
  String Quiz_id;
  int timeLimit;
  String? pageType;

  QuizInstructionPage({
    super.key,
    required this.testTitle,
    required this.subject,
    required this.timeLimit,
    required this.Quiz_id,
    required this.pageType,
  });

  @override
  State<QuizInstructionPage> createState() => _QuizInstructionPageState();
}

class _QuizInstructionPageState extends State<QuizInstructionPage> {
  bool _declared = false;

  // ── Gradients (from your app) ────────────────────────────────────────────
  static const List<List<Color>> _mockGradients = [
    [Color(0xFF0D4B3B), Color(0xFF1A8070)],
    [Color(0xFF0B3D5E), Color(0xFF1A6D8A)],
    [Color(0xFF1A4D6D), Color(0xFF0D7A6B)],
    [Color(0xFF0C3756), Color(0xFF28A194)],
    [Color(0xFF093D4A), Color(0xFF1A7A6D)],
  ];

  // ── Instructions data ────────────────────────────────────────────────────
  static const List<String> _instructions = [
    'This test contains <b>100 total questions</b>.',
    'Each question has <b>4 options</b>, out of which only <b>one is correct</b>.',
    'You have to finish the test in <b>120 minutes</b>.',
    'Try not to guess the answer as there is <b>negative marking</b>.',
    'You can attempt this test <b>only once</b>. Complete before submitting or closing the app.',
  ];

  // ── Marking scheme data ──────────────────────────────────────────────────
  static const List<_MarkItem> _markingScheme = [
    _MarkItem(
      icon: Icons.check_circle_outline_rounded,
      label: 'Correct Answer',
      desc: 'Marks awarded per question',
      value: '+2',
      iconBg: AppColors.correctBg,
      iconColor: AppColors.correct,
      valueColor: AppColors.correct,
    ),
    _MarkItem(
      icon: Icons.cancel_outlined,
      label: 'Wrong Answer',
      desc: 'Negative marking deducted',
      value: '−0.2',
      iconBg: AppColors.wrongBg,
      iconColor: AppColors.wrong,
      valueColor: AppColors.wrong,
    ),
    _MarkItem(
      icon: Icons.remove_circle_outline_rounded,
      label: 'Unattempted',
      desc: 'No marks deducted',
      value: '0',
      iconBg: AppColors.skipBg,
      iconColor: AppColors.skipColor,
      valueColor: AppColors.textHint,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel('Instructions'),
                  _buildInstructionsCard(),
                  _sectionLabel('Marking Scheme'),
                  _buildMarkingCard(),
                  _sectionLabel('Declaration'),
                  _buildDeclarationCard(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  // ── Header with gradient ─────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _mockGradients[0], // Using first gradient: dark teal
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // App bar row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Exam Instructions',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Exam title section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      border: Border.all(color: Colors.white.withOpacity(0.35)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'MEMORY BASED PAPER',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Bihar Police\nSub-Inspector Recruitment',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700, height: 1.35),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '18th January 2026  |  Shift 1',
                    style: TextStyle(color: Colors.white.withOpacity(0.72), fontSize: 12.5),
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),

            // Stats strip
            Container(
              color: AppColors.primaryDark.withOpacity(0.5),
              child: Row(
                children: const [
                  _StatChip(value: '100', label: 'Questions'),
                  _StatChip(value: '120', label: 'Minutes'),
                  _StatChip(value: '200', label: 'Max Marks'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section label ────────────────────────────────────────────────────────
  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 7),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.accentTeal,
        letterSpacing: 0.9,
      ),
    ),
  );

  // ── Instructions card ─────────────────────────────────────────────────────
  Widget _buildInstructionsCard() {
    return _Card(
      child: Column(
        children: List.generate(_instructions.length, (i) {
          final isLast = i == _instructions.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Number badge
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12), shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Instruction text (bold parts highlighted)
                    Expanded(child: _buildRichInstruction(_instructions[i])),
                  ],
                ),
              ),
              if (!isLast) const Divider(height: 0.5, color: AppColors.divider, indent: 14, endIndent: 14),
            ],
          );
        }),
      ),
    );
  }

  // Simple rich text parser for <b> tags
  Widget _buildRichInstruction(String text) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'<b>(.*?)<\/b>');
    int last = 0;
    for (final match in regex.allMatches(text)) {
      if (match.start > last) {
        spans.add(TextSpan(text: text.substring(last, match.start)));
      }
      spans.add(
        TextSpan(
          text: match.group(1),
          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primaryDark),
        ),
      );
      last = match.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last)));
    }
    return RichText(
      text: TextSpan(style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.55), children: spans),
    );
  }

  // ── Marking scheme card ──────────────────────────────────────────────────
  Widget _buildMarkingCard() {
    return _Card(
      child: Column(
        children: List.generate(_markingScheme.length, (i) {
          final item = _markingScheme[i];
          final isLast = i == _markingScheme.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: item.iconBg, borderRadius: BorderRadius.circular(10)),
                      child: Icon(item.icon, color: item.iconColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.label,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(item.desc, style: const TextStyle(fontSize: 11.5, color: AppColors.textHint)),
                        ],
                      ),
                    ),
                    Text(
                      item.value,
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: item.valueColor),
                    ),
                  ],
                ),
              ),
              if (!isLast) const Divider(height: 0.5, color: AppColors.divider, indent: 14, endIndent: 14),
            ],
          );
        }),
      ),
    );
  }

  // ── Declaration card ─────────────────────────────────────────────────────
  Widget _buildDeclarationCard() {
    return _Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => setState(() => _declared = !_declared),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: _declared ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _declared ? AppColors.primary : AppColors.textHint, width: 2),
                ),
                child: _declared ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'I have read all the instructions carefully and have understood them. '
                'I agree not to cheat or use unfair means in this examination. '
                'I understand that using unfair means of any sort — for my own or '
                'someone else\'s benefit — will result in cancellation of my candidature '
                'and may lead to legal action.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom bar ───────────────────────────────────────────────────────────
  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
        boxShadow: [
          BoxShadow(color: AppColors.primaryDark.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, -3)),
        ],
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      child: Row(
        children: [
          // Previous button
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.maybePop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('← Previous', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 10),

          // Start button
          Expanded(
            flex: 2,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _declared ? 1.0 : 0.45,
              child: ElevatedButton(
                onPressed: _declared ? _onStart : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.primary,
                  disabledForegroundColor: Colors.white,
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: _declared ? 3 : 0,
                ),
                child: const Text('I am Ready to Begin →', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onStart() {
    // TODO: Navigate to quiz screen
    if (widget.pageType == 'mock_test') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => MockTestScreen(
                testTitle: widget.testTitle.toString(),
                subject: widget.subject.toString(),
                Quiz_id: widget.Quiz_id.toString(),
                timeLimit: widget.timeLimit,
              ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => LiveTestScreen(
                testTitle: widget.testTitle.toString(),
                subject: widget.subject.toString(),
                Quiz_id: widget.Quiz_id.toString(),
                timeLimit: widget.timeLimit,
              ),
        ),
      );
    }
  }
}

// ── Reusable card wrapper ────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 1.5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: AppColors.primaryDark.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 1)),
        ],
      ),
      child: child,
    );
  }
}

// ── Stat chip in header ──────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  const _StatChip({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.white.withOpacity(0.12), width: 0.5))),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.gold)),
            const SizedBox(height: 2),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 9,
                color: Colors.white.withOpacity(0.6),
                letterSpacing: 0.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Marking scheme data model ────────────────────────────────────────────────
class _MarkItem {
  const _MarkItem({
    required this.icon,
    required this.label,
    required this.desc,
    required this.value,
    required this.iconBg,
    required this.iconColor,
    required this.valueColor,
  });

  final IconData icon;
  final String label;
  final String desc;
  final String value;
  final Color iconBg;
  final Color iconColor;
  final Color valueColor;
}

class AppColors {
  static const Color primaryDark = Color(0xFF0D4B3B);
  static const Color primary = Color(0xFF1A8070);
  static const Color primaryLight = Color(0xFF28A194);
  static const Color accentTeal = Color(0xFF0D7A6B);
  static const Color background = Color(0xFFF0F5F4);
  static const Color surface = Colors.white;
  static const Color divider = Color(0xFFDDECE9);
  static const Color textPrimary = Color(0xFF1A2E2B);
  static const Color textSecondary = Color(0xFF546E6A);
  static const Color textHint = Color(0xFF90ADAA);
  static const Color gold = Color(0xFFFFD54F);
  static const Color correct = Color(0xFF2E7D32);
  static const Color correctBg = Color(0xFFE8F5E9);
  static const Color wrong = Color(0xFFC62828);
  static const Color wrongBg = Color(0xFFFFEBEE);
  static const Color skipBg = Color(0xFFE0F2F1);
  static const Color skipColor = Color(0xFF00695C);
}
