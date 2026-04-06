import 'package:flutter/material.dart';
import 'package:tazaquiznew/screens/livetest.dart';
import 'package:tazaquiznew/screens/mockTestScreen.dart';

class QuizInstructionPage extends StatefulWidget {
  final String testTitle;
  final String subject;
  final String Quiz_id;
  final int timeLimit;
  final String? pageType;
  final int total_questions;
  final int totalMarks;
  final num passingMarks;
  final String instruction;
  final String negativeMark;

  const QuizInstructionPage({
    super.key,
    required this.testTitle,
    required this.subject,
    required this.timeLimit,
    required this.Quiz_id,
    required this.pageType,
    required this.total_questions,
    required this.totalMarks,
    required this.passingMarks,
    required this.instruction,
    required this.negativeMark,
  });

  @override
  State<QuizInstructionPage> createState() => _QuizInstructionPageState();
}

class _QuizInstructionPageState extends State<QuizInstructionPage> {
  bool _declared = false;
  double get correct => double.parse(widget.totalMarks.toString()) / widget.total_questions;

  List<String> get _instructions {
    final neg = widget.negativeMark;

    final q = widget.total_questions;
    final t = widget.timeLimit;

    final list = <String>[
      'The test contains <b>$q total questions</b>.',
      'Each question has <b>4 options</b>, out of which only <b>one is correct</b>.',
      'You have to finish the test in <b>$t minutes</b>.',
      'Try not to guess the answer as there is <b>negative marking</b>.',
      'You will be awarded <b>$correct mark</b> for each correct answer and '
          '<b>$neg</b> will be deducted for each wrong answer.',
      'There is <b>no negative marking</b> for the questions that you have not attempted.',
      'You can write this test <b>only once</b>. Make sure that you complete the '
          'test before you submit the test and/or close the browser.',
    ];

    if (widget.instruction.trim().isNotEmpty) {
      list.add(widget.instruction.trim());
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ── AppBar — title always visible, never scrolls away ────────────────
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: Colors.black12,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 28, color: Colors.black87),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          widget.testTitle,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        centerTitle: false,
        titleSpacing: 0,
      ),

      // ── Bottom bar: Declaration + Buttons ────────────────────────────────
      bottomNavigationBar: _buildBottomBar(),

      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Duration & Max Marks
            Row(
              children: [
                Text(
                  'Duration: ${widget.timeLimit} Mins',
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.black),
                ),
                const Spacer(),
                Text(
                  'Maximum Marks: ${widget.totalMarks}',
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.black),
                ),
              ],
            ),

            const SizedBox(height: 14),
            const Divider(color: Color(0xFFDDDDDD), height: 1),
            const SizedBox(height: 14),

            // Instructions heading
            const Text(
              'Read the following instructions carefully.',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black),
            ),
            const SizedBox(height: 10),

            // Numbered list
            ..._instructions.asMap().entries.map((e) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      child: Text('${e.key + 1}.', style: const TextStyle(fontSize: 14, color: Colors.black87)),
                    ),
                    Expanded(child: _buildRichText(e.value)),
                  ],
                ),
              );
            }),

            const SizedBox(height: 18),
            const Divider(color: Color(0xFFDDDDDD), height: 1),
            const SizedBox(height: 14),

            // Marking scheme chips
            Row(
              children: [
                _MarkChip(
                  label: 'Correct',
                  value: '+${correct.toString()}',
                  valueColor: const Color(0xFF2E7D32),
                  bgColor: const Color(0xFFE8F5E9),
                  borderColor: const Color(0xFFA5D6A7),
                ),
                const SizedBox(width: 10),
                _MarkChip(
                  label: 'Wrong',
                  value: '−${widget.negativeMark}',
                  valueColor: const Color(0xFFC62828),
                  bgColor: const Color(0xFFFFEBEE),
                  borderColor: const Color(0xFFEF9A9A),
                ),
                const SizedBox(width: 10),
                const _MarkChip(
                  label: 'Skipped',
                  value: '0',
                  valueColor: Color(0xFF546E6A),
                  bgColor: Color(0xFFE0F2F1),
                  borderColor: Color(0xFF80CBC4),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom bar ─────────────────────────────────────────────────────────────
  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE0E0E0))),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 10, offset: const Offset(0, -3))],
      ),
      padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Declaration checkbox
          GestureDetector(
            onTap: () => setState(() => _declared = !_declared),
            behavior: HitTestBehavior.opaque,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    color: _declared ? Colors.teal : Colors.white,
                    border: Border.all(color: _declared ? Colors.teal : Colors.grey, width: 1.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: _declared ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'I have read all the instructions carefully and have understood them. '
                    'I agree not to cheat or use unfair means in this examination.',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black87, height: 1.5),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Previous + Start buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.maybePop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: const BorderSide(color: Color(0xFFBBBBBB)),
                    minimumSize: const Size(0, 46),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: const Text('Previous', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _declared ? 1.0 : 0.45,
                  child: ElevatedButton(
                    onPressed: _declared ? _onStart : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.teal,
                      disabledForegroundColor: Colors.white,
                      minimumSize: const Size(0, 46),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      elevation: _declared ? 2 : 0,
                    ),
                    child: const Text(
                      'I am ready to begin',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _onStart() {
    if (widget.pageType == 'mock_test') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => MockTestScreen(
                testTitle: widget.testTitle,
                subject: widget.subject,
                Quiz_id: widget.Quiz_id,
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
                testTitle: widget.testTitle,
                subject: widget.subject,
                Quiz_id: widget.Quiz_id,
                timeLimit: widget.timeLimit,
              ),
        ),
      );
    }
  }

  Widget _buildRichText(String text) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'<b>(.*?)<\/b>');
    int last = 0;
    for (final match in regex.allMatches(text)) {
      if (match.start > last) {
        spans.add(TextSpan(text: text.substring(last, match.start)));
      }
      spans.add(
        TextSpan(text: match.group(1), style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black)),
      );
      last = match.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last)));
    }
    return RichText(
      text: TextSpan(style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.55), children: spans),
    );
  }
}

// ── Marking chip ──────────────────────────────────────────────────────────────
class _MarkChip extends StatelessWidget {
  const _MarkChip({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.bgColor,
    required this.borderColor,
  });

  final String label;
  final String value;
  final Color valueColor;
  final Color bgColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: valueColor)),
            const SizedBox(height: 3),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}
