import 'package:flutter/material.dart';
import 'dart:async';

class LiveTestScreen extends StatefulWidget {
  final String testTitle;
  final String subject;
  final int totalQuestions;
  final int totalParticipants;

  LiveTestScreen({
    this.testTitle = 'Advanced Mathematics Challenge',
    this.subject = 'Mathematics',
    this.totalQuestions = 25,
    this.totalParticipants = 1234,
  });

  @override
  _LiveTestScreenState createState() => _LiveTestScreenState();
}

class _LiveTestScreenState extends State<LiveTestScreen> with SingleTickerProviderStateMixin {
  int _currentQuestion = 1;
  int _timeLeft = 30;
  int _score = 0;
  int? _selectedOption;
  bool _answered = false;
  int _correctAnswer = 0;
  Timer? _timer;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  // Sample question data
  final Map<String, dynamic> _currentQuestionData = {
    'question': 'What is the derivative of x² + 3x + 5?',
    'options': ['2x + 3', 'x² + 3', '2x + 5', '3x + 3'],
    'correctAnswer': 0,
    'difficulty': 'Hard',
    'points': 50,
  };

  @override
  void initState() {
    super.initState();
    _startTimer();
    _animationController = AnimationController(vsync: this, duration: Duration(seconds: 2))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timeLeft = 30;
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          _timer?.cancel();
          _autoSubmit();
        }
      });
    });
  }

  void _selectOption(int index) {
    if (_answered) return;
    setState(() {
      _selectedOption = index;
    });
  }

  void _submitAnswer() {
    if (_selectedOption == null || _answered) return;

    setState(() {
      _answered = true;
      _timer?.cancel();
      if (_selectedOption == _correctAnswer) {
        // _score += _currentQuestionData['points'];
      }
    });

    Future.delayed(Duration(seconds: 2), () {
      _nextQuestion();
    });
  }

  void _autoSubmit() {
    if (_answered) return;
    setState(() {
      _answered = true;
    });
    Future.delayed(Duration(seconds: 2), () {
      _nextQuestion();
    });
  }

  void _nextQuestion() {
    if (_currentQuestion < widget.totalQuestions) {
      setState(() {
        _currentQuestion++;
        _selectedOption = null;
        _answered = false;
      });
      _startTimer();
    } else {
      _showResultDialog();
    }
  }

  void _showResultDialog() {
    showDialog(context: context, barrierDismissible: false, builder: (context) => _buildResultDialog());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FD),
      body: Column(
        children: [
          _buildHeader(),
          _buildProgressSection(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildLiveParticipants(),
                  _buildQuestionCard(),
                  _buildOptionsSection(),
                  if (!_answered) _buildSubmitButton(),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 12, left: 16, right: 16, bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF003161), Color(0xFF016A67)]),
        boxShadow: [BoxShadow(color: Color(0xFF003161).withOpacity(0.3), blurRadius: 20, offset: Offset(0, 5))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => _showExitDialog(),
                child: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width / 2,
                          child: Text(
                            widget.testTitle,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Text(widget.subject, style: TextStyle(fontSize: 12, color: Color(0xFFFDEB9E))),
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'LIVE',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: Color(0xFFFDEB9E), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Icon(Icons.emoji_events, color: Color(0xFF003161), size: 18),
                    SizedBox(width: 6),
                    Text(
                      '$_score',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF003161)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    double progress = _currentQuestion / widget.totalQuestions;
    double timeProgress = _timeLeft / 30;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question $_currentQuestion/${widget.totalQuestions}',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF003161)),
              ),
              ScaleTransition(
                scale: _timeLeft <= 10 ? _pulseAnimation : AlwaysStoppedAnimation(1.0),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _timeLeft <= 5
                          ? [Colors.red, Colors.red[700]!]
                          : _timeLeft <= 10
                          ? [Colors.orange, Colors.orange[700]!]
                          : [Color(0xFF016A67), Color(0xFF003161)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: (_timeLeft <= 10 ? Colors.red : Color(0xFF016A67)).withOpacity(0.3),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.timer, color: Colors.white, size: 18),
                      SizedBox(width: 6),
                      Text(
                        '$_timeLeft',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                      Text(
                        's',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Progress', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                    SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation(Color(0xFF016A67)),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Time', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                    SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: timeProgress,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation(
                          _timeLeft <= 5
                              ? Colors.red
                              : _timeLeft <= 10
                              ? Colors.orange
                              : Color(0xFF016A67),
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiveParticipants() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFFFDEB9E).withOpacity(0.3), Color(0xFFFDD835).withOpacity(0.2)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFFDEB9E), width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            children: [
              _buildParticipantAvatar('A', 0),
              Padding(padding: EdgeInsets.only(left: 24), child: _buildParticipantAvatar('B', 1)),
              Padding(padding: EdgeInsets.only(left: 48), child: _buildParticipantAvatar('C', 2)),
              Padding(padding: EdgeInsets.only(left: 72), child: _buildParticipantAvatar('+', 3)),
            ],
          ),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Live Participants',
                    style: TextStyle(fontSize: 11, color: Colors.grey[700], fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              Text(
                '${widget.totalParticipants} competing now',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF003161)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantAvatar(String letter, int index) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF016A67), Color(0xFF003161)]),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildQuestionCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Color(0xFF016A67).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.category, color: Color(0xFF016A67), size: 14),
                    SizedBox(width: 6),
                    Text(
                      widget.subject,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF016A67)),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFFFDEB9E), Color(0xFFFDD835)]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.stars, color: Color(0xFF003161), size: 14),
                    SizedBox(width: 6),
                    Text(
                      '+${_currentQuestionData['points']} XP',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF003161)),
                    ),
                  ],
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(
                  _currentQuestionData['difficulty'],
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.red),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Text(
            _currentQuestionData['question'],
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF003161), height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsSection() {
    return Container(
      margin: EdgeInsets.all(16),
      child: Column(
        children: List.generate(
          _currentQuestionData['options'].length,
          (index) => _buildOptionCard(String.fromCharCode(65 + index), _currentQuestionData['options'][index], index),
        ),
      ),
    );
  }

  Widget _buildOptionCard(String letter, String text, int index) {
    bool isSelected = _selectedOption == index;
    bool isCorrect = _answered && index == _correctAnswer;
    bool isWrong = _answered && isSelected && index != _correctAnswer;

    Color backgroundColor = Colors.white;
    Color borderColor = Colors.grey[300]!;
    Color letterBgColor = Color(0xFFF8F9FD);
    Color textColor = Color(0xFF003161);

    if (isCorrect) {
      backgroundColor = Color(0xFF016A67).withOpacity(0.1);
      borderColor = Color(0xFF016A67);
      letterBgColor = Color(0xFF016A67);
    } else if (isWrong) {
      backgroundColor = Colors.red.withOpacity(0.1);
      borderColor = Colors.red;
      letterBgColor = Colors.red;
    } else if (isSelected) {
      backgroundColor = Color(0xFFFDEB9E).withOpacity(0.2);
      borderColor = Color(0xFFFDEB9E);
      letterBgColor = Color(0xFFFDEB9E);
    }

    return GestureDetector(
      onTap: () => _selectOption(index),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor, width: 2),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected && !_answered
              ? [BoxShadow(color: Color(0xFFFDEB9E).withOpacity(0.4), blurRadius: 15, offset: Offset(0, 5))]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: letterBgColor, borderRadius: BorderRadius.circular(12)),
              child: Center(
                child: Text(
                  letter,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: (isCorrect || isWrong || (isSelected && !_answered)) ? Colors.white : Color(0xFF003161),
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
              ),
            ),
            if (_answered && (isCorrect || isWrong))
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(color: isCorrect ? Color(0xFF016A67) : Colors.red, shape: BoxShape.circle),
                child: Icon(isCorrect ? Icons.check : Icons.close, color: Colors.white, size: 20),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    bool canSubmit = _selectedOption != null;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton(
        onPressed: canSubmit ? _submitAnswer : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          disabledBackgroundColor: Colors.grey[300],
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: canSubmit ? LinearGradient(colors: [Color(0xFF016A67), Color(0xFF003161)]) : null,
            color: canSubmit ? null : Colors.grey[300],
            borderRadius: BorderRadius.circular(16),
            boxShadow: canSubmit
                ? [BoxShadow(color: Color(0xFF016A67).withOpacity(0.4), blurRadius: 20, offset: Offset(0, 10))]
                : [],
          ),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: canSubmit ? Colors.white : Colors.grey[500], size: 24),
                SizedBox(width: 12),
                Text(
                  'Submit Answer',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: canSubmit ? Colors.white : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultDialog() {
    double accuracy = (_score / (widget.totalQuestions * 50) * 100);
    int rank = (widget.totalParticipants * (1 - accuracy / 100)).toInt() + 1;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFF8F9FD)],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF016A67), Color(0xFF003161)]),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Color(0xFF016A67).withOpacity(0.4), blurRadius: 20, offset: Offset(0, 10)),
                ],
              ),
              child: Icon(Icons.emoji_events, color: Color(0xFFFDEB9E), size: 56),
            ),
            SizedBox(height: 24),
            Text(
              'Test Completed!',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF003161)),
            ),
            SizedBox(height: 8),
            Text('Great job! Here\'s your performance', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildResultStat('Score', '$_score', Icons.stars, Color(0xFF016A67)),
                _buildResultStat('Rank', '#$rank', Icons.leaderboard, Color(0xFF003161)),
                _buildResultStat('Accuracy', '${accuracy.toInt()}%', Icons.percent, Color(0xFF000B58)),
              ],
            ),
            SizedBox(height: 32),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFDEB9E).withOpacity(0.3), Color(0xFFFDD835).withOpacity(0.2)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Color(0xFFFDEB9E)),
              ),
              child: Row(
                children: [
                  Icon(Icons.emoji_events, color: Color(0xFF003161), size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'You earned $_score XP',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF003161)),
                        ),
                        Text('Keep practicing to improve!', style: TextStyle(fontSize: 11, color: Colors.grey[700])),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Color(0xFF003161), width: 2),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Review',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF003161)),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Color(0xFF016A67), Color(0xFF003161)]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        alignment: Alignment.center,
                        child: Text(
                          'Done',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 24),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color),
        ),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.warning_amber_rounded, color: Colors.red, size: 40),
              ),
              SizedBox(height: 20),
              Text(
                'Exit Test?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF003161)),
              ),
              SizedBox(height: 12),
              Text(
                'Your progress will be lost if you exit now.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey[300]!),
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Exit',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
