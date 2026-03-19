import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:tazaquiznew/API/Language_converter/translation_service.dart';
import 'package:tazaquiznew/API/api_client.dart';
import 'package:tazaquiznew/API/api_endpoint.dart';
import 'package:tazaquiznew/authentication/AuthRepository.dart';
import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/models/blog_post_modal.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class NewsPage extends StatefulWidget {
  const NewsPage({super.key});
  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> with TickerProviderStateMixin {
  List<BlogPost> _posts = [];
  bool _loading = true;
  String? _error;
  late AnimationController _fadeCtrl;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fetch();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final authRepository = Authrepository(Api_Client.dio);

      final response = await authRepository.fetchBlogPosts();
      print('Blog posts response: ${response.data}');
      final data = response.data;

      if (data['success'] == true) {
        setState(() {
          _posts = (data['data'] as List).map((e) => BlogPost.fromJson(e)).toList();
          _loading = false;
        });
        _fadeCtrl.forward(from: 0);
      } else {
        setState(() {
          _error = data['error'] ?? 'Unknown error';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6FA),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _appBar(),
            if (_loading)
              const SliverFillRemaining(child: _LoadingView())
            else if (_error != null)
              SliverFillRemaining(child: _ErrorView(error: _error!, onRetry: _fetch))
            else ...[
              _featured(),
              _sectionHeader('Latest Articles'),
              _postsList(),
              const SliverToBoxAdapter(child: SizedBox(height: 30)),
            ],
          ],
        ),
      ),
    );
  } // ── BLOG PAGE APP BAR ────────────────────────

  // ── BLOG PAGE APP BAR ────────────────────────
  SliverAppBar _appBar() => SliverAppBar(
    expandedHeight: 115,
    pinned: true,
    stretch: true,
    elevation: 0,
    backgroundColor: const Color(0xFF0D6E6E),
    foregroundColor: Colors.white,
    systemOverlayStyle: SystemUiOverlayStyle.light,

    // Collapsed title — sirf text
    title: const Text('News & Blog', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
    centerTitle: false,

    // View All — scroll ke baad bhi dikhega
    actions: [
      Padding(
        padding: const EdgeInsets.only(right: 16),
        child: GestureDetector(
          onTap: () => launchUrl(Uri.parse('https://tazaquiz.com/blogs'), mode: LaunchMode.externalApplication),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TranslatedText(
                  'View All',
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                ),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 12),
              ],
            ),
          ),
        ),
      ),
    ],

    flexibleSpace: FlexibleSpaceBar(
      stretchModes: const [StretchMode.zoomBackground],
      background: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A2A2A), Color(0xFF0D6E6E)],
          ),
        ),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              right: -40,
              top: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.05)),
              ),
            ),
            Positioned(
              left: -20,
              bottom: -30,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.04)),
              ),
            ),

            // Content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 45, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row — sirf badge, View All actions mein hai
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.15)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_stories_rounded, color: Colors.white, size: 11),
                              SizedBox(width: 5),
                              TranslatedText(
                                'CURRENT AFFAIRS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(color: Color(0xFF4ECDC4), shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        TranslatedText(
                          '${_posts.length} articles • Updated daily',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  // ── FEATURED (first post big card) ───────────
  Widget _featured() {
    if (_posts.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: FadeTransition(opacity: _fadeCtrl, child: _FeaturedCard(post: _posts.first)),
      ),
    );
  }

  // ── SECTION HEADER ────────────────────────────
  Widget _sectionHeader(String label) => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(color: const Color(0xFF0D1B2A), borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0D1B2A))),
        ],
      ),
    ),
  );

  // ── POSTS LIST (rest) ─────────────────────────
  Widget _postsList() {
    final rest = _posts.length > 1 ? _posts.sublist(1) : <BlogPost>[];
    return SliverList(
      delegate: SliverChildBuilderDelegate((ctx, i) {
        final delay = (i * 0.12).clamp(0.0, 0.8);
        final anim = CurvedAnimation(parent: _fadeCtrl, curve: Interval(delay, 1.0, curve: Curves.easeOut));
        return AnimatedBuilder(
          animation: _fadeCtrl,
          builder:
              (_, child) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(anim),
                  child: child,
                ),
              ),
          child: Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 12), child: _SmallCard(post: rest[i])),
        );
      }, childCount: rest.length),
    );
  }
}

// ─────────────────────────────────────────────
//  FEATURED CARD
// ─────────────────────────────────────────────
class _FeaturedCard extends StatelessWidget {
  final BlogPost post;
  const _FeaturedCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NewsDetailPage(post: post))),
      child: Container(
        height: 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image
              if (post.featuredImage != null)
                Image.network(
                  post.featuredImage!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: const Color(0xFF1A3A5C)),
                )
              else
                Container(color: const Color(0xFF1A3A5C)),

              // Dark gradient
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87],
                    stops: [0.3, 1.0],
                  ),
                ),
              ),

              // FEATURED badge
              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: Colors.amber.shade600, borderRadius: BorderRadius.circular(8)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, color: Colors.white, size: 11),
                      SizedBox(width: 4),
                      TranslatedText(
                        'FEATURED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom content
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: post.categoryColor, borderRadius: BorderRadius.circular(6)),
                        child: Text(
                          post.category,
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TranslatedText(
                        post.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                          shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.person_outline, color: Colors.white70, size: 13),
                          const SizedBox(width: 4),
                          TranslatedText(
                            post.author,
                            style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.access_time_outlined, color: Colors.white70, size: 12),
                          const SizedBox(width: 4),
                          TranslatedText(post.readTime, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                          const Spacer(),
                          TranslatedText(
                            post.formattedDate,
                            style: const TextStyle(color: Colors.white54, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SMALL CARD
// ─────────────────────────────────────────────
class _SmallCard extends StatelessWidget {
  final BlogPost post;
  const _SmallCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NewsDetailPage(post: post))),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              child: SizedBox(
                width: 110,
                height: 110,
                child:
                    post.featuredImage != null
                        ? Image.network(
                          post.featuredImage!,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => Container(
                                color: post.categoryColor.withOpacity(0.15),
                                child: Icon(Icons.article_outlined, color: post.categoryColor, size: 32),
                              ),
                        )
                        : Container(
                          color: post.categoryColor.withOpacity(0.15),
                          child: Icon(Icons.article_outlined, color: post.categoryColor, size: 32),
                        ),
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: post.categoryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: TranslatedText(
                        post.category,
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: post.categoryColor),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TranslatedText(
                      post.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_time_outlined, size: 11, color: Colors.grey.shade400),
                        const SizedBox(width: 3),
                        Text(post.readTime, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                        const Spacer(),
                        TranslatedText(post.formattedDate, style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TranslatedText(
                          'Read More',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: post.categoryColor),
                        ),
                        const SizedBox(width: 2),
                        Icon(Icons.arrow_forward_rounded, size: 13, color: post.categoryColor),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  DETAIL PAGE
// ─────────────────────────────────────────────
class NewsDetailPage extends StatelessWidget {
  final BlogPost post;
  const NewsDetailPage({super.key, required this.post});

  Future<void> _open(BuildContext context) async {
    try {
      await launchUrl(Uri.parse(post.url), mode: LaunchMode.externalApplication);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Browser open nahi ho saka')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: const Color(0xFF0D1B2A),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (post.featuredImage != null)
                    Image.network(
                      post.featuredImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: const Color(0xFF0D1B2A)),
                    )
                  else
                    Container(color: const Color(0xFF0D1B2A)),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black26, Colors.black87],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [IconButton(icon: const Icon(Icons.open_in_browser_rounded), onPressed: () => _open(context))],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(color: post.categoryColor, borderRadius: BorderRadius.circular(8)),
                    child: TranslatedText(
                      post.category,
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Title
                  TranslatedText(
                    post.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Author row
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: const Color(0xFFF4F6FA), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: post.categoryColor,
                          child: TranslatedText(
                            post.author.isNotEmpty ? post.author[0].toUpperCase() : 'T',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TranslatedText(
                              post.author,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            TranslatedText(
                              '${post.formattedDate}  •  ${post.readTime}',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Container(height: 1, color: const Color(0xFFEEF0F4)),
                  const SizedBox(height: 20),

                  // Excerpt
                  if (post.excerpt.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: post.categoryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border(left: BorderSide(color: post.categoryColor, width: 3)),
                      ),
                      child: Text(
                        post.excerpt.length > 300 ? '${post.excerpt.substring(0, 300)}...' : post.excerpt,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF334155),
                          height: 1.7,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),

                  const SizedBox(height: 32),

                  // Read Full Article
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _open(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D1B2A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 4,
                        shadowColor: const Color(0xFF0D1B2A).withOpacity(0.4),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.open_in_browser_rounded, size: 18),
                          SizedBox(width: 8),
                          TranslatedText(
                            'Website pe Poora Article Padho',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.3),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  LOADING (skeleton)
// ─────────────────────────────────────────────
class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        const SizedBox(height: 20),
        _Skeleton(height: 280),
        const SizedBox(height: 12),
        _Skeleton(height: 110),
        const SizedBox(height: 12),
        _Skeleton(height: 110),
      ],
    ),
  );
}

class _Skeleton extends StatefulWidget {
  final double height;
  const _Skeleton({required this.height});
  @override
  State<_Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<_Skeleton> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween(begin: 0.4, end: 1.0).animate(_c),
    child: Container(
      height: widget.height,
      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(16)),
    ),
  );
}

// ─────────────────────────────────────────────
//  ERROR VIEW
// ─────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
            child: Icon(Icons.wifi_off_rounded, color: Colors.red.shade400, size: 48),
          ),
          const SizedBox(height: 20),
           TranslatedText(
            'Oops! Kuch problem aayi',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 8),
          TranslatedText(
            error,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label:  TranslatedText('Dobara Try Karo', style: TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D1B2A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    ),
  );
}
