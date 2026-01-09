import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:tazaquiznew/API/api_client.dart';
import 'package:tazaquiznew/authentication/AuthRepository.dart';
import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/models/referallist_modal.dart';
import 'package:tazaquiznew/utils/richText.dart';
import 'package:tazaquiznew/utils/session_manager.dart';
import 'package:tazaquiznew/widgets/custom_button.dart';

class ReferralListPage extends StatefulWidget {
  const ReferralListPage({super.key});

  @override
  State<ReferralListPage> createState() => _ReferralListPageState();
}

class _ReferralListPageState extends State<ReferralListPage> {
  List<ReferralUserDetail> _referralList = [];
  int page = 1;
  ScrollController scrollController = ScrollController();
  bool isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    scrollController.removeListener(_scrollListener);
    scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (scrollController.position.pixels == scrollController.position.maxScrollExtent && !isLoadingMore) {
      _loadMoreData();
    }
  }

  Future<void> _loadMoreData() async {
    setState(() {
      isLoadingMore = true;
    });

    page++;
    final newData = await fetchReferralList(page);

    setState(() {
      _referralList.addAll(newData);
      isLoadingMore = false;
    });
  }

  Future<List<ReferralUserDetail>> fetchReferralList([int currentPage = 1]) async {
    final user = await SessionManager.getUser();

    if (user == null) {
      return [];
    }

    try {
      // TODO: Replace with your actual API repository
      Authrepository authRepository = Authrepository(Api_Client.dio);
      final data = {'user_id': user.id.toString(), 'page': currentPage.toString()};

      final responseFuture = await authRepository.fetchReferralList(data);

      if (responseFuture.statusCode == 200) {
        dynamic responseData = responseFuture.data;

        if (responseData is String) {
          responseData = jsonDecode(responseData);
        }

        final List<dynamic> list = (responseData['referral_user_details'] as List<dynamic>?) ?? [];

        if (list.isEmpty) {
          return [];
        }

        return list.map((e) {
          return ReferralUserDetail.fromJson(e as Map<String, dynamic>);
        }).toList();
      } else {
        return [];
      }
    } catch (e, stackTrace) {
      print('Error fetching referral list: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: AppColors.tealGreen,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(16))),
        leading: AppButton.setBackIcon(context, () {
          Navigator.pop(context);
        }, AppColors.white),
        title: AppRichText.setTextPoppinsStyle(
          context,
          'My Referrals',
          16,
          AppColors.white,
          FontWeight.w900,
          1,
          TextAlign.left,
          0.0,
        ),
        elevation: 2,
      ),
      body: FutureBuilder<List<ReferralUserDetail>>(
        future: fetchReferralList(page),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: AppColors.tealGreen, strokeWidth: 3));
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: AppColors.greyS700),
                  SizedBox(height: 16),
                  AppRichText.setTextPoppinsStyle(
                    context,
                    'Something went wrong!',
                    14,
                    AppColors.greyS700,
                    FontWeight.w600,
                    1,
                    TextAlign.center,
                    0.0,
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 80, color: AppColors.greyS700.withOpacity(0.5)),
                  SizedBox(height: 16),
                  AppRichText.setTextPoppinsStyle(
                    context,
                    'No referrals found',
                    16,
                    AppColors.greyS700,
                    FontWeight.w600,
                    1,
                    TextAlign.center,
                    0.0,
                  ),
                  SizedBox(height: 8),
                  AppRichText.setTextPoppinsStyle(
                    context,
                    'Start sharing your code to earn rewards!',
                    13,
                    AppColors.greyS700.withOpacity(0.7),
                    FontWeight.w500,
                    2,
                    TextAlign.center,
                    1.3,
                  ),
                ],
              ),
            );
          }

          // Initialize the list on first load
          if (_referralList.isEmpty) {
            _referralList = snapshot.data!;
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: EdgeInsets.all(16),
                  itemCount: _referralList.length,
                  itemBuilder: (context, index) {
                    return _buildReferralCard(_referralList[index]);
                  },
                ),
              ),
              if (isLoadingMore)
                Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(color: AppColors.tealGreen, strokeWidth: 3),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildReferralCard(ReferralUserDetail referral) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (referral.status) {
      case '0':
        statusColor = Colors.orange;
        statusText = 'Pending';
        statusIcon = Icons.schedule;
        break;
      case '1':
        statusColor = AppColors.tealGreen;
        statusText = 'Credited';
        statusIcon = Icons.check_circle;
        break;
      case '2':
        statusColor = Colors.red;
        statusText = 'Rejected';
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = AppColors.greyS700;
        statusText = 'Unknown';
        statusIcon = Icons.help;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 2),
        boxShadow: [BoxShadow(color: statusColor.withOpacity(0.15), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name Row
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.tealGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.person, size: 20, color: AppColors.tealGreen),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Referred To',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.greyS700,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        referral.name,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkNavy,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            Divider(height: 24, color: AppColors.greyS700.withOpacity(0.2)),

            // Date Time Row
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: AppColors.greyS700),
                SizedBox(width: 8),
                Text(
                  'Date: ',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.greyS700,
                  ),
                ),
                Expanded(
                  child: Text(
                    referral.datetime as String,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkNavy,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 12),

            // Status Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(statusIcon, size: 16, color: statusColor),
                    SizedBox(width: 8),
                    Text(
                      'Status: ',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.greyS700,
                      ),
                    ),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
                if (10 != null)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.tealGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '₹ 10',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: AppColors.tealGreen,
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
}
