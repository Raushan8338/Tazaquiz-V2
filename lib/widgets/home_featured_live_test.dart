import 'package:flutter/material.dart';
import 'package:tazaquiznew/API/Language_converter/translation_service.dart';
import 'package:tazaquiznew/API/api_client.dart';
import 'package:tazaquiznew/authentication/AuthRepository.dart';
import 'package:tazaquiznew/models/quizItem_modal.dart';
import 'package:tazaquiznew/screens/featured_live_test_page.dart';

/// A compact spotlight card for an admin-flagged "featured live test"
/// (quizzes.pageType = 10), shown above the regular Live Test section.
/// Self-fetches independently of HomePage's own data load (which is
/// hardcoded server-side to pageType=7 only) — renders nothing if none is
/// currently set.
class Home_featured_live_test extends StatefulWidget {
  const Home_featured_live_test({super.key});

  @override
  State<Home_featured_live_test> createState() => _Home_featured_live_testState();
}

class _Home_featured_live_testState extends State<Home_featured_live_test> {
  QuizItem? _quiz;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final authRepository = Authrepository(Api_Client.dio);
      final response = await authRepository.get_featured_live_test();
      if (response.statusCode == 200 && response.data['data'] != null) {
        setState(() {
          _quiz = QuizItem.fromJson(response.data['data']);
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _quiz == null) return const SizedBox.shrink();
    final quiz = _quiz!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 2),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => FeaturedLiveTestPage(quizId: quiz.quizId)),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEDE4F7), width: 1),
            boxShadow: [
              BoxShadow(color: const Color(0xFF6B21A8).withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 72,
                    height: 72,
                    child: (quiz.banner != null && quiz.banner!.isNotEmpty)
                        ? Image.network(
                            quiz.banner!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _bannerFallback(),
                          )
                        : _bannerFallback(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6B21A8).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'COMPETITION',
                              style: TextStyle(
                                color: Color(0xFF6B21A8),
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (quiz.quizStatus.toLowerCase() == 'live')
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDC2626).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: const BoxDecoration(color: Color(0xFFDC2626), shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'LIVE',
                                    style: TextStyle(color: Color(0xFFDC2626), fontSize: 8.5, fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                            )
                          else if (quiz.quizStatus.toLowerCase() == 'upcoming')
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFB45309).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'UPCOMING',
                                style: TextStyle(
                                  color: Color(0xFFB45309),
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          const SizedBox(width: 6),
                          if (!quiz.isPaid)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00897B).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'FREE',
                                style: TextStyle(
                                  color: Color(0xFF00897B),
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      TranslatedText(
                        quiz.title,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0D1B3E)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (quiz.description.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        TranslatedText(
                          quiz.description,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600, height: 1.3),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF6B21A8)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bannerFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF6B21A8), Color(0xFF9333EA)]),
      ),
      child: const Center(child: Icon(Icons.stars_rounded, color: Colors.white70, size: 26)),
    );
  }
}
