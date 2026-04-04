import 'package:flutter/material.dart';
import 'package:tazaquiznew/API/api_client.dart';
import 'package:tazaquiznew/authentication/AuthRepository.dart';
import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/models/leaderboard_modal.dart';
import 'package:tazaquiznew/models/login_response_model.dart';
import 'package:tazaquiznew/utils/session_manager.dart';

class LeaderboardPage extends StatefulWidget {
  final int? courseId;
  final String? courseName;
  final int? quizId;
  final String? quizTitle;
  final bool isMock;

  LeaderboardPage({Key? key, this.courseId, this.courseName, this.quizId, this.quizTitle, this.isMock = false})
    : super(key: key);

  @override
  _LeaderboardPageState createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  LeaderboardResponse? _data;
  UserModel? _user;
  late String _currentType;

  late List<Map<String, String>> _tabs;

  @override
  void initState() {
    super.initState();

    // ── Tabs build karo ──────────────────────────────
    _tabs = [];
    if (widget.courseId != null) {
      _tabs.add({'type': 'course', 'label': 'Course'});
    }
    if (widget.quizId != null) {
      _tabs.add({'type': widget.isMock ? 'mock' : 'quiz', 'label': widget.isMock ? 'This Mock' : 'This Quiz'});
    }
    if (_tabs.isEmpty) {
      // Fallback — sirf quiz
      _tabs.add({'type': widget.isMock ? 'mock' : 'quiz', 'label': widget.isMock ? 'Mock' : 'Quiz'});
    }

    _currentType = _tabs[0]['type']!;

    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final newType = _tabs[_tabController.index]['type']!;
        if (newType != _currentType) {
          setState(() => _currentType = newType);
          _fetch();
        }
      }
    });

    _init();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    _user = await SessionManager.getUser();
    setState(() {});
    await _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final auth = Authrepository(Api_Client.dio);
      final Map<String, String> data = {'type': _currentType, 'user_id': (_user?.id ?? 0).toString()};
      if (_currentType == 'course' && widget.courseId != null) {
        data['course_id'] = widget.courseId.toString();
      }
      if ((_currentType == 'quiz' || _currentType == 'mock') && widget.quizId != null) {
        data['quiz_id'] = widget.quizId.toString();
      }
      print('Leaderboard fetch: $data');

      final res = await auth.fetchLeaderboard(data);
      print('Leaderboard fetch: ${res.data}');
      if (res.statusCode == 200) {
        setState(() {
          _data = LeaderboardResponse.fromJson(res.data);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Leaderboard error: $e');
      setState(() => _isLoading = false);
    }
  }

  String get _pageTitle {
    if (_currentType == 'course') {
      return widget.courseName ?? 'Course Leaderboard';
    }
    return widget.quizTitle ?? (_currentType == 'mock' ? 'Mock Leaderboard' : 'Quiz Leaderboard');
  }

  // ─── BUILD ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [_buildSliverAppBar()],
        body:
            _isLoading
                ? Center(
                  child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.tealGreen)),
                )
                : _data == null
                ? _buildError()
                : RefreshIndicator(onRefresh: _fetch, color: AppColors.tealGreen, child: _buildBody()),
      ),
    );
  }

  // ─── SLIVER APP BAR ──────────────────────────────────────────────────────

  Widget _buildSliverAppBar() {
    final bool hasTabs = _tabs.length > 1;

    return SliverAppBar(
      // ── overflow fix: expandedHeight chota rakho ──
      expandedHeight: hasTabs ? 185 : 170,
      pinned: true,
      backgroundColor: AppColors.darkNavy,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0B1340), AppColors.darkNavy, Color(0xFF0D4B3B)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -40,
                top: -40,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.04)),
                ),
              ),
              Positioned(
                left: -30,
                bottom: -30,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.03)),
                ),
              ),

              // ── Main content ──
              Positioned.fill(
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Trophy — smaller
                        const Text('🏆', style: TextStyle(fontSize: 30)),
                        const SizedBox(height: 6),

                        // Title
                        Text(
                          _pageTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Poppins',
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        // My rank badge
                        if (_data?.myRank != null) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withOpacity(0.2)),
                            ),
                            child: Text(
                              'Your Rank: #${_data!.myRank}',
                              style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // ── Tabs ──
      bottom:
          hasTabs
              ? PreferredSize(
                preferredSize: const Size.fromHeight(42),
                child: Container(
                  color: AppColors.darkNavy,
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: AppColors.tealGreen,
                    indicatorWeight: 3,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white.withOpacity(0.45),
                    labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, fontFamily: 'Poppins'),
                    tabs: _tabs.map((t) => Tab(text: t['label'])).toList(),
                  ),
                ),
              )
              : null,
    );
  }

  // ─── BODY ────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    final list = _data?.leaderboard ?? [];

    if (list.isEmpty) {
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [SliverFillRemaining(child: _buildEmptyState())],
      );
    }

    final top3 = list.where((e) => e.rank <= 3).toList();
    final rest = list.where((e) => e.rank > 3).toList();

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // ── Podium — sirf 3+ players ho to ──
        if (top3.length >= 3) SliverToBoxAdapter(child: _buildPodium(top3)),

        // ── Top3 < 3 ho to list mein dikhao ──
        if (top3.length < 3 && top3.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((ctx, i) => _buildListItem(top3[i]), childCount: top3.length),
            ),
          ),

        // ── My rank card — top 3 mein nahi hai to ──
        if (_data?.myData != null && (_data?.myRank ?? 0) > 3)
          SliverToBoxAdapter(child: _buildMyRankCard(_data!.myData!)),

        // ── Info bar ──
        SliverToBoxAdapter(child: _buildInfoBar()),

        // ── Rest list (rank > 3) ──
        if (rest.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((ctx, i) => _buildListItem(rest[i]), childCount: rest.length),
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }
  // ─── BODY ────────────────────────────────────────────────────────────────

  Widget _buildPodium(List<LeaderboardItem> top3) {
    final first = top3.firstWhere((e) => e.rank == 1, orElse: () => top3[0]);
    final second = top3.firstWhere((e) => e.rank == 2, orElse: () => top3.length > 1 ? top3[1] : top3[0]);
    final third = top3.firstWhere((e) => e.rank == 3, orElse: () => top3.length > 2 ? top3[2] : top3[0]);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text('🏅', style: TextStyle(fontSize: 13)),
              SizedBox(width: 6),
              Text(
                'Top Performers',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.darkNavy,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: _podiumItem(second, 85)),
              Expanded(child: _podiumItem(first, 115)),
              Expanded(child: _podiumItem(third, 65)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _podiumItem(LeaderboardItem item, double blockH) {
    final bool isFirst = item.rank == 1;
    final Color pc =
        item.rank == 1
            ? const Color(0xFFFFD700)
            : item.rank == 2
            ? const Color(0xFFC0C0C0)
            : const Color(0xFFCD7F32);
    final double av = isFirst ? 62 : 50;

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              width: av,
              height: av,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: pc, width: 2.5),
                color: pc.withOpacity(0.08),
                boxShadow: [BoxShadow(color: pc.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child:
                  item.profileImage.isNotEmpty
                      ? ClipOval(
                        child: Image.network(
                          'https://tazaquiz.com/uploads/profile/${item.profileImage}',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _avatar(item.username, pc, av),
                        ),
                      )
                      : _avatar(item.username, pc, av),
            ),
            Positioned(
              top: -5,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: pc,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(item.badge.icon, style: TextStyle(fontSize: isFirst ? 10 : 8)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          _short(item.username),
          style: TextStyle(
            fontSize: isFirst ? 11 : 10,
            fontWeight: FontWeight.w800,
            color: item.isCurrentUser ? AppColors.tealGreen : AppColors.darkNavy,
            fontFamily: 'Poppins',
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(_scoreStr(item), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: pc)),
        const SizedBox(height: 6),
        Container(
          height: blockH,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [pc.withOpacity(0.3), pc.withOpacity(0.08)],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            border: Border.all(color: pc.withOpacity(0.2), width: 1.5),
          ),
          child: Center(
            child: Text(
              '#${item.rank}',
              style: TextStyle(
                fontSize: isFirst ? 20 : 15,
                fontWeight: FontWeight.w900,
                color: pc,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── MY RANK CARD ────────────────────────────────────────────────────────

  Widget _buildMyRankCard(LeaderboardItem item) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.darkNavy, Color(0xFF0D4B3B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: AppColors.darkNavy.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
              border: Border.all(color: AppColors.lightGold.withOpacity(0.4), width: 2),
            ),
            child: Center(
              child: Text(
                '#${item.rank}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.tealGreen, width: 2)),
            child:
                item.profileImage.isNotEmpty
                    ? ClipOval(
                      child: Image.network(
                        'https://tazaquiz.com/uploads/profile/${item.profileImage}',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _avatar(item.username, AppColors.tealGreen, 40),
                      ),
                    )
                    : _avatar(item.username, AppColors.tealGreen, 40),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.username,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Poppins',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text('Your Position', style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.6))),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _scoreStr(item),
                style: const TextStyle(
                  fontSize: 18,
                  color: AppColors.tealGreen,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Poppins',
                ),
              ),
              Text(
                _currentType == 'course' ? 'Avg Score' : 'Score',
                style: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.55)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── INFO BAR ────────────────────────────────────────────────────────────

  Widget _buildInfoBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Icon(Icons.people_outline, size: 14, color: AppColors.greyS600),
          const SizedBox(width: 5),
          Text(
            '${_data?.total ?? 0} Players',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.darkNavy),
          ),
          if (_data?.myRank != null) ...[
            const SizedBox(width: 14),
            Icon(Icons.emoji_events_outlined, size: 14, color: AppColors.tealGreen),
            const SizedBox(width: 4),
            Text(
              'Rank: #${_data!.myRank}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.tealGreen),
            ),
          ],
        ],
      ),
    );
  }

  // ─── LIST ITEM ───────────────────────────────────────────────────────────

  Widget _buildListItem(LeaderboardItem item) {
    final bool isMe = item.isCurrentUser;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? AppColors.tealGreen.withOpacity(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isMe ? AppColors.tealGreen.withOpacity(0.25) : Colors.transparent),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(
              '#${item.rank}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isMe ? AppColors.tealGreen : AppColors.greyS600,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),

          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isMe ? AppColors.tealGreen : Colors.grey.withOpacity(0.15),
                    width: isMe ? 2 : 1,
                  ),
                ),
                child:
                    item.profileImage.isNotEmpty
                        ? ClipOval(
                          child: Image.network(
                            'https://tazaquiz.com/uploads/profile/${item.profileImage}',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _avatar(item.username, AppColors.darkNavy, 40),
                          ),
                        )
                        : _avatar(item.username, AppColors.darkNavy, 40),
              ),
              Positioned(
                right: -4,
                bottom: -4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.withOpacity(0.15)),
                  ),
                  child: Text(item.badge.icon, style: const TextStyle(fontSize: 9)),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.username + (isMe ? ' 👈' : ''),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isMe ? AppColors.tealGreen : AppColors.darkNavy,
                    fontFamily: 'Poppins',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Correct: ${item.correctAnswers}/${item.totalAnswered}  •  ${item.timeTaken}',
                  style: TextStyle(fontSize: 10, color: AppColors.greyS600),
                ),
              ],
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _scoreStr(item),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: isMe ? AppColors.tealGreen : AppColors.darkNavy,
                  fontFamily: 'Poppins',
                ),
              ),
              Text(
                _currentType == 'course' ? 'Avg' : 'Score',
                style: TextStyle(fontSize: 9, color: AppColors.greyS600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── HELPERS ─────────────────────────────────────────────────────────────

  // _scoreStr() fix
  String _scoreStr(LeaderboardItem item) {
    if (_currentType == 'course') {
      return '${item.avgScore.toStringAsFixed(0)}%';
    }
    // Quiz/Mock — total_answered se percentage nikalo
    if (item.totalAnswered > 0) {
      final pct = (item.correctAnswers / item.totalAnswered * 100);
      return '${pct.toStringAsFixed(0)}%';
    }
    return '${item.score.toStringAsFixed(0)}';
  }

  Widget _avatar(String name, Color color, double size) {
    final ch = name.isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
      child: Center(
        child: Text(
          ch,
          style: TextStyle(fontSize: size * 0.35, fontWeight: FontWeight.w800, color: color, fontFamily: 'Poppins'),
        ),
      ),
    );
  }

  String _short(String name) {
    if (name.length <= 10) return name;
    return '${name.substring(0, 8)}..';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🏆', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 14),
          const Text(
            'No rankings yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.darkNavy,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 6),
          Text('Complete quizzes to appear here!', style: TextStyle(fontSize: 12, color: AppColors.greyS600)),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 52, color: Colors.redAccent),
          const SizedBox(height: 12),
          const Text(
            'Failed to load',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.darkNavy),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _fetch,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(color: AppColors.tealGreen, borderRadius: BorderRadius.circular(8)),
              child: const Text('Retry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
