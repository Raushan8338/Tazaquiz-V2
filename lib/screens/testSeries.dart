import 'package:flutter/material.dart';
import 'dart:async';

class LiveTestSeriesPage extends StatefulWidget {
  @override
  _LiveTestSeriesPageState createState() => _LiveTestSeriesPageState();
}

class _LiveTestSeriesPageState extends State<LiveTestSeriesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedFilter = 0;

  final List<String> _filters = ['All', 'Live Now', 'Upcoming', 'Completed'];

  final List<Map<String, dynamic>> _testSeries = [
    {
      'title': 'Advanced Mathematics Championship',
      'subject': 'Mathematics',
      'status': 'live',
      'participants': 1234,
      'duration': '60 min',
      'questions': 30,
      'difficulty': 'Hard',
      'prize': '₹10,000',
      'startTime': '10:00 AM',
      'endTime': '11:00 AM',
      'timeLeft': {'hours': 0, 'minutes': 15, 'seconds': 30},
    },
    {
      'title': 'Science Quiz Battle',
      'subject': 'Science',
      'status': 'upcoming',
      'participants': 856,
      'duration': '45 min',
      'questions': 25,
      'difficulty': 'Medium',
      'prize': '₹5,000',
      'startTime': '2:00 PM',
      'endTime': '2:45 PM',
      'timeLeft': {'hours': 3, 'minutes': 45, 'seconds': 0},
    },
    {
      'title': 'General Knowledge Sprint',
      'subject': 'GK',
      'status': 'upcoming',
      'participants': 2341,
      'duration': '30 min',
      'questions': 40,
      'difficulty': 'Easy',
      'prize': '₹3,000',
      'startTime': '4:00 PM',
      'endTime': '4:30 PM',
      'timeLeft': {'hours': 5, 'minutes': 50, 'seconds': 0},
    },
    {
      'title': 'Physics Mastery Challenge',
      'subject': 'Physics',
      'status': 'completed',
      'participants': 1892,
      'duration': '50 min',
      'questions': 28,
      'difficulty': 'Hard',
      'prize': '₹8,000',
      'winner': 'Rahul Sharma',
      'yourRank': 42,
    },
    {
      'title': 'English Grammar Test',
      'subject': 'English',
      'status': 'live',
      'participants': 678,
      'duration': '40 min',
      'questions': 35,
      'difficulty': 'Medium',
      'prize': '₹4,000',
      'startTime': '10:30 AM',
      'endTime': '11:10 AM',
      'timeLeft': {'hours': 0, 'minutes': 25, 'seconds': 45},
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FD),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildFeaturedBanner(),
                _buildStatsSection(),
                _buildFilterSection(),
                _buildTestSeriesList(),
                SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: Color(0xFF003161),
      leading: IconButton(
        icon: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.notifications_outlined, color: Colors.white, size: 20),
          ),
          onPressed: () {},
        ),
        IconButton(
          icon: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.filter_list, color: Colors.white, size: 20),
          ),
          onPressed: () => _showFilterSheet(),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF003161), Color(0xFF016A67)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -50,
                top: -20,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle),
                ),
              ),
              Positioned(
                left: -30,
                bottom: -30,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(left: 60, right: 60, top: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Color(0xFFFDEB9E),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.bolt, color: Color(0xFF003161), size: 24),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Live Test Series',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                        ],
                      ),
                      SizedBox(height: 6),
                      Text('Compete in real-time challenges', style: TextStyle(fontSize: 13, color: Color(0xFFFDEB9E))),
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

  Widget _buildFeaturedBanner() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFDEB9E), Color(0xFFFDD835)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Color(0xFFFDEB9E).withOpacity(0.5), blurRadius: 20, offset: Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Color(0xFF003161), borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    Icon(Icons.star, color: Color(0xFFFDEB9E), size: 14),
                    SizedBox(width: 4),
                    Text(
                      'FEATURED',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Spacer(),
              Icon(Icons.emoji_events, color: Color(0xFF003161), size: 32),
            ],
          ),
          SizedBox(height: 16),
          Text(
            'Weekly Championship',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF003161)),
          ),
          SizedBox(height: 8),
          Text(
            'Win exciting prizes worth ₹50,000',
            style: TextStyle(fontSize: 14, color: Color(0xFF016A67), fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              _buildBannerStat(Icons.people, '5,234', 'Players'),
              SizedBox(width: 20),
              _buildBannerStat(Icons.calendar_today, 'Sunday', '8:00 PM'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBannerStat(IconData icon, String value, String label) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(color: Color(0xFF003161).withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: Color(0xFF003161), size: 18),
        ),
        SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF003161)),
            ),
            Text(label, style: TextStyle(fontSize: 11, color: Color(0xFF016A67))),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(child: _buildStatCard(Icons.trending_up, '2,450', 'Your Rank', Color(0xFF016A67))),
          SizedBox(width: 12),
          Expanded(child: _buildStatCard(Icons.emoji_events, '15', 'Tests Won', Color(0xFF003161))),
          SizedBox(width: 12),
          Expanded(child: _buildStatCard(Icons.star, '12,340', 'Total XP', Color(0xFF000B58))),
        ],
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 16),
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          bool isSelected = _selectedFilter == index;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = index;
              });
            },
            child: Container(
              margin: EdgeInsets.only(right: 12),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: isSelected ? LinearGradient(colors: [Color(0xFF016A67), Color(0xFF003161)]) : null,
                color: isSelected ? null : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(color: Color(0xFF016A67).withOpacity(0.3), blurRadius: 15, offset: Offset(0, 5))
                  else
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: Offset(0, 2)),
                ],
              ),
              child: Center(
                child: Text(
                  _filters[index],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : Colors.grey[700],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTestSeriesList() {
    return Column(
      children: _testSeries.map((test) {
        if (_selectedFilter == 1 && test['status'] != 'live') return SizedBox.shrink();
        if (_selectedFilter == 2 && test['status'] != 'upcoming') return SizedBox.shrink();
        if (_selectedFilter == 3 && test['status'] != 'completed') return SizedBox.shrink();

        if (test['status'] == 'live') {
          return _buildLiveTestCard(test);
        } else if (test['status'] == 'upcoming') {
          return _buildUpcomingTestCard(test);
        } else {
          return _buildCompletedTestCard(test);
        }
      }).toList(),
    );
  }

  Widget _buildLiveTestCard(Map<String, dynamic> test) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF003161), Color(0xFF016A67)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Color(0xFF003161).withOpacity(0.3), blurRadius: 20, offset: Offset(0, 10))],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'LIVE NOW',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Color(0xFFFDEB9E), borderRadius: BorderRadius.circular(12)),
                      child: Icon(Icons.bolt, color: Color(0xFF003161), size: 24),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  test['title'],
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        test['subject'],
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFFDEB9E)),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '${test['questions']} Questions • ${test['duration']}',
                      style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Time Left', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7))),
                          SizedBox(height: 4),
                          Text(
                            '${test['timeLeft']['minutes'].toString().padLeft(2, '0')}:${test['timeLeft']['seconds'].toString().padLeft(2, '0')}',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFFFDEB9E)),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.people, color: Color(0xFFFDEB9E), size: 16),
                              SizedBox(width: 4),
                              Text(
                                '${test['participants']} playing',
                                style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: Color(0xFFFDEB9E), borderRadius: BorderRadius.circular(8)),
                            child: Text(
                              'Join Now',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF003161)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingTestCard(Map<String, dynamic> test) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Color(0xFF016A67).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule, color: Color(0xFF016A67), size: 14),
                    SizedBox(width: 6),
                    Text(
                      'UPCOMING',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF016A67)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFFFDEB9E), Color(0xFFFDD835)]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.emoji_events, color: Color(0xFF003161), size: 14),
                    SizedBox(width: 4),
                    Text(
                      test['prize'],
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF003161)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            test['title'],
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF003161)),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              _buildTestInfoChip(Icons.subject, test['subject'], Color(0xFF016A67)),
              SizedBox(width: 8),
              _buildTestInfoChip(Icons.quiz, '${test['questions']} Q', Color(0xFF003161)),
              SizedBox(width: 8),
              _buildTestInfoChip(Icons.timer, test['duration'], Color(0xFF000B58)),
            ],
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(color: Color(0xFFF8F9FD), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Starts In', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          _buildCountdownBox(test['timeLeft']['hours'].toString(), 'HRS'),
                          SizedBox(width: 4),
                          Text(
                            ':',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF003161)),
                          ),
                          SizedBox(width: 4),
                          _buildCountdownBox(test['timeLeft']['minutes'].toString().padLeft(2, '0'), 'MIN'),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${test['participants']} registered', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        padding: EdgeInsets.zero,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [Color(0xFF016A67), Color(0xFF003161)]),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: Row(
                            children: [
                              Icon(Icons.notifications_active, size: 14, color: Colors.white),
                              SizedBox(width: 6),
                              Text(
                                'Remind Me',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedTestCard(Map<String, dynamic> test) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.grey[600], size: 14),
                    SizedBox(width: 6),
                    Text(
                      'COMPLETED',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Text(
                test['prize'],
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF016A67)),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            test['title'],
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF003161)),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.emoji_events, color: Color(0xFFFDEB9E), size: 20),
              SizedBox(width: 8),
              Text(
                'Winner: ${test['winner']}',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF003161)),
              ),
            ],
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(color: Color(0xFFF8F9FD), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your Rank', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                      SizedBox(height: 4),
                      Text(
                        '#${test['yourRank']}',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF016A67)),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.visibility_outlined, size: 16, color: Color(0xFF003161)),
                  label: Text(
                    'View Results',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF003161)),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Color(0xFF003161), width: 2),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownBox(String value, String label) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF016A67), Color(0xFF003161)]),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.grey[600]),
        ),
      ],
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter Tests',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF003161)),
                ),
                IconButton(icon: Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            SizedBox(height: 20),
            _buildFilterOption('All Subjects', true),
            _buildFilterOption('Mathematics', false),
            _buildFilterOption('Science', false),
            _buildFilterOption('English', false),
            SizedBox(height: 16),
            Divider(),
            SizedBox(height: 16),
            _buildFilterOption('Easy', false),
            _buildFilterOption('Medium', false),
            _buildFilterOption('Hard', false),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                padding: EdgeInsets.zero,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF016A67), Color(0xFF003161)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  alignment: Alignment.center,
                  child: Text(
                    'Apply Filters',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String text, bool isSelected) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? Color(0xFF016A67).withOpacity(0.1) : Color(0xFFF8F9FD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? Color(0xFF016A67) : Colors.transparent, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            text,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF003161)),
          ),
          if (isSelected) Icon(Icons.check_circle, color: Color(0xFF016A67), size: 20),
        ],
      ),
    );
  }
}
