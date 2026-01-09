import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tazaquiznew/API/api_client.dart';
import 'package:tazaquiznew/authentication/AuthRepository.dart';
import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/models/login_response_model.dart';
import 'package:tazaquiznew/screens/ticket_details_page.dart';
import 'package:tazaquiznew/utils/richText.dart';
import 'package:tazaquiznew/utils/session_manager.dart';
import 'package:tazaquiznew/widgets/custom_button.dart';
import 'package:tazaquiznew/models/ticketRaisedList_modal.dart';

class All_Raised_Ticket_Page extends StatefulWidget {
  const All_Raised_Ticket_Page({super.key});
  @override
  State<All_Raised_Ticket_Page> createState() => _All_Raised_Ticket_PageState();
}

class _All_Raised_Ticket_PageState extends State<All_Raised_Ticket_Page> {
  String userId = "";
  String userIds = "";
  UserModel? _user;
  List<TicketRaisedList> _ticketListItem = [];
  int _refreshKey = 0; // For triggering refresh

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  Color _getStatusColor(String status) {
    if (status == "0") return Colors.orange;
    if (status == "1") return Colors.green;
    return Colors.blue;
  }

  String _getStatusText(String status) {
    if (status == "0") return "Pending";
    if (status == "1") return "Resolved";
    return "Processing";
  }

  IconData _getStatusIcon(String status) {
    if (status == "0") return Icons.pending_outlined;
    if (status == "1") return Icons.check_circle_outline;
    return Icons.sync_outlined;
  }

  void _getUserData() async {
    _user = await SessionManager.getUser();
    setState(() {});
  }

  Future<List<TicketRaisedList>> fetchTicketList() async {
    if (_user == null) {
      return [];
    }

    try {
      Authrepository authRepository = Authrepository(Api_Client.dio);
      final data = {'user_id': _user!.id.toString()};

      final responseFuture = await authRepository.fetchTicketStatus(data);

      if (responseFuture.statusCode == 200) {
        dynamic responseData = responseFuture.data;

        if (responseData is String) {
          responseData = jsonDecode(responseData);
        }

        final List<dynamic> list = (responseData['series'] as List<dynamic>?) ?? [];

        if (list.isEmpty) {
          return [];
        }

        _ticketListItem =
            list.map((e) {
              return TicketRaisedList.fromJson(e as Map<String, dynamic>);
            }).toList();

        return _ticketListItem;
      } else {
        return [];
      }
    } catch (e, stackTrace) {
      return [];
    }
  }

  void _refreshTickets() {
    setState(() {
      _refreshKey++; // This will trigger FutureBuilder to rebuild
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greyS1,
      appBar: _buildAppBar(),
      body:
          _user == null
              ? Center(child: CircularProgressIndicator(color: AppColors.tealGreen, strokeWidth: 3))
              : FutureBuilder<List<TicketRaisedList>>(
                key: ValueKey(_refreshKey), // Key for rebuilding on refresh
                future: fetchTicketList(),
                builder: (context, snapshot) {
                  // Loading state
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: AppColors.tealGreen, strokeWidth: 3),
                          SizedBox(height: 16),
                          AppRichText.setTextPoppinsStyle(
                            context,
                            'Loading tickets...',
                            13,
                            AppColors.greyS700,
                            FontWeight.w500,
                            1,
                            TextAlign.center,
                            0.0,
                          ),
                        ],
                      ),
                    );
                  }

                  // Error state
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(20),
                              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
                              child: Icon(Icons.error_outline, size: 56, color: Colors.red.withOpacity(0.7)),
                            ),
                            SizedBox(height: 20),
                            AppRichText.setTextPoppinsStyle(
                              context,
                              'Something went wrong',
                              16,
                              AppColors.darkNavy,
                              FontWeight.w700,
                              1,
                              TextAlign.center,
                              0.0,
                            ),
                            SizedBox(height: 8),
                            AppRichText.setTextPoppinsStyle(
                              context,
                              'Please try again later',
                              13,
                              AppColors.greyS700,
                              FontWeight.w500,
                              2,
                              TextAlign.center,
                              1.4,
                            ),
                            SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _refreshTickets,
                              icon: Icon(Icons.refresh, size: 20),
                              label: Text('Retry'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.tealGreen,
                                foregroundColor: AppColors.white,
                                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Empty state
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyState();
                  }

                  // Success state with data
                  return _buildTicketList(snapshot.data!);
                },
              ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: AppColors.darkNavy,
      leading: IconButton(
        icon: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.arrow_back, color: AppColors.white, size: 16),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [AppColors.darkNavy, AppColors.tealGreen],
          ),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppRichText.setTextPoppinsStyle(
            context,
            'My Tickets',
            16,
            AppColors.white,
            FontWeight.w900,
            1,
            TextAlign.left,
            0.0,
          ),
          SizedBox(height: 4),
          AppRichText.setTextPoppinsStyle(
            context,
            'Track your support requests',
            10.5,
            AppColors.lightGold,
            FontWeight.w500,
            1,
            TextAlign.left,
            0.0,
          ),
        ],
      ),
      actions: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _refreshTickets,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.white.withOpacity(0.3), width: 1),
              ),
              child: Icon(Icons.refresh_rounded, color: AppColors.white, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  // PreferredSizeWidget _buildAppBar() {
  //   return PreferredSize(
  //     preferredSize: Size.fromHeight(100),
  //     child: Container(
  //       decoration: BoxDecoration(
  //         gradient: LinearGradient(
  //           begin: Alignment.topLeft,
  //           end: Alignment.bottomRight,
  //           colors: [AppColors.darkNavy, AppColors.tealGreen],
  //         ),
  //         boxShadow: [BoxShadow(color: AppColors.tealGreen.withOpacity(0.3), blurRadius: 15, offset: Offset(0, 5))],
  //       ),
  //       child: SafeArea(
  //         child: Padding(
  //           padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  //           child: Row(
  //             children: [
  //               AppButton.setBackIcon(context, () {
  //                 Navigator.pop(context);
  //               }, AppColors.white),
  //               SizedBox(width: 12),
  //               Expanded(
  //                 child: Column(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   mainAxisAlignment: MainAxisAlignment.center,
  //                   children: [
  //                     AppRichText.setTextPoppinsStyle(
  //                       context,
  //                       'My Tickets',
  //                       16,
  //                       AppColors.white,
  //                       FontWeight.w900,
  //                       1,
  //                       TextAlign.left,
  //                       0.0,
  //                     ),
  //                     SizedBox(height: 4),
  //                     AppRichText.setTextPoppinsStyle(
  //                       context,
  //                       'Track your support requests',
  //                       10.5,
  //                       AppColors.lightGold,
  //                       FontWeight.w500,
  //                       1,
  //                       TextAlign.left,
  //                       0.0,
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //               SizedBox(width: 8),
  //               Material(
  //                 color: Colors.transparent,
  //                 child: InkWell(
  //                   onTap: _refreshTickets,
  //                   borderRadius: BorderRadius.circular(10),
  //                   child: Container(
  //                     padding: EdgeInsets.all(10),
  //                     decoration: BoxDecoration(
  //                       color: AppColors.white.withOpacity(0.2),
  //                       borderRadius: BorderRadius.circular(10),
  //                       border: Border.all(color: AppColors.white.withOpacity(0.3), width: 1),
  //                     ),
  //                     child: Icon(Icons.refresh_rounded, color: AppColors.white, size: 20),
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.tealGreen.withOpacity(0.1), AppColors.darkNavy.withOpacity(0.05)],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.tealGreen),
            ),
            SizedBox(height: 24),
            AppRichText.setTextPoppinsStyle(
              context,
              'No Tickets Found',
              18,
              AppColors.darkNavy,
              FontWeight.w900,
              1,
              TextAlign.center,
              0.0,
            ),
            SizedBox(height: 8),
            AppRichText.setTextPoppinsStyle(
              context,
              'You haven\'t raised any support tickets yet.\nYour tickets will appear here.',
              13,
              AppColors.greyS700,
              FontWeight.w500,
              5,
              TextAlign.center,
              1.5,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketList(List<TicketRaisedList> tickets) {
    return RefreshIndicator(
      color: AppColors.tealGreen,
      onRefresh: () async {
        _refreshTickets();
        await Future.delayed(Duration(milliseconds: 500));
      },
      child: ListView.builder(
        physics: AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: EdgeInsets.all(16),
        itemCount: tickets.length,
        itemBuilder: (BuildContext context, int index) {
          final ticket = tickets[index];
          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 300 + (index * 50)),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(opacity: value, child: _buildTicketCard(ticket)),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTicketCard(TicketRaisedList ticket) {
    return Container(
      margin: EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.tealGreen.withOpacity(0.15), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 15, offset: Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Navigator.push(
            //   context,
            //   MaterialPageRoute(
            //     builder: (context) => Ticket_Details_Page(
            //       ticket.reqId,
            //       ticket.datetime,
            //       ticket.status,
            //       ticket.reason,
            //       ticket.issueDescription,
            //       ticket.adminRemarks,
            //       ticket.adminDateTime,
            //     ),
            //   ),
            // );
          },
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              // Header Section
              Container(
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.tealGreen.withOpacity(0.08), AppColors.darkNavy.withOpacity(0.04)],
                  ),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [AppColors.tealGreen, AppColors.darkNavy]),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.confirmation_number_outlined, size: 16, color: AppColors.white),
                        ),
                        SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppRichText.setTextPoppinsStyle(
                              context,
                              'Ticket ID',
                              10,
                              AppColors.greyS700,
                              FontWeight.w500,
                              1,
                              TextAlign.left,
                              0.0,
                            ),
                            SizedBox(height: 2),
                            AppRichText.setTextPoppinsStyle(
                              context,
                              '#${ticket.reqId}',
                              14,
                              AppColors.darkNavy,
                              FontWeight.w700,
                              1,
                              TextAlign.left,
                              0.0,
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(ticket.status).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _getStatusColor(ticket.status).withOpacity(0.4), width: 1.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_getStatusIcon(ticket.status), size: 14, color: _getStatusColor(ticket.status)),
                          SizedBox(width: 4),
                          AppRichText.setTextPoppinsStyle(
                            context,
                            _getStatusText(ticket.status),
                            11,
                            _getStatusColor(ticket.status),
                            FontWeight.w700,
                            1,
                            TextAlign.center,
                            0.0,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content Section
              Padding(
                padding: EdgeInsets.all(14),
                child: Column(
                  children: [
                    _buildInfoRow(Icons.calendar_today_outlined, 'Raised On', ticket.datetime, AppColors.tealGreen),
                    SizedBox(height: 12),
                    _buildInfoRow(Icons.subject_outlined, 'Issue', ticket.reason, AppColors.darkNavy),
                  ],
                ),
              ),

              // Footer Section
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => Ticket_Details_Page(
                            tId: ticket.reqId,
                            tRaisedDateTime: ticket.datetime,
                            tstatus: ticket.status,
                            tReason: ticket.reason,
                            tDescription: ticket.issueDescription,
                            admRemark: ticket.adminRemarks,
                            admDateTime: ticket.adminDateTime,
                          ),
                    ),
                  );
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.greyS1, width: 1))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      AppRichText.setTextPoppinsStyle(
                        context,
                        'View Details',
                        12,
                        AppColors.tealGreen,
                        FontWeight.w700,
                        1,
                        TextAlign.right,
                        0.0,
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.tealGreen),
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

  Widget _buildInfoRow(IconData icon, String label, String value, Color iconColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(7),
          decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppRichText.setTextPoppinsStyle(
                context,
                label,
                11,
                AppColors.greyS700,
                FontWeight.w500,
                1,
                TextAlign.left,
                0.0,
              ),
              SizedBox(height: 3),
              AppRichText.setTextPoppinsStyle(
                context,
                value,
                13,
                AppColors.darkNavy,
                FontWeight.w600,
                3,
                TextAlign.left,
                1.3,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
