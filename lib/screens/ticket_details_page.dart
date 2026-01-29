import 'package:flutter/material.dart';
import 'package:tazaquiz/constants/app_colors.dart';
import 'package:tazaquiz/utils/richText.dart';
import 'package:tazaquiz/widgets/custom_button.dart';
import 'package:url_launcher/url_launcher.dart';

class Ticket_Details_Page extends StatefulWidget {
  final String tId;
  final String tRaisedDateTime;
  final String tstatus;
  final String tReason;
  final String tDescription;
  final String admRemark;
  final String admDateTime;

  const Ticket_Details_Page({
    super.key,
    required this.tId,
    required this.tRaisedDateTime,
    required this.tstatus,
    required this.tReason,
    required this.tDescription,
    required this.admRemark,
    required this.admDateTime,
  });

  @override
  State<Ticket_Details_Page> createState() => _Ticket_Details_PageState();
}

class _Ticket_Details_PageState extends State<Ticket_Details_Page> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greyS1,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildStatusHeader(),
            SizedBox(height: 16),
            _buildTicketInfoCard(),
            SizedBox(height: 16),
            if (widget.tstatus == "1") _buildResolutionCard(),
            if (widget.tstatus == "0") _buildPendingCard(),
            if (widget.tstatus == "2") _buildProcessingCard(),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: Size.fromHeight(100),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.darkNavy, AppColors.tealGreen],
          ),
          boxShadow: [BoxShadow(color: AppColors.tealGreen.withOpacity(0.3), blurRadius: 15, offset: Offset(0, 5))],
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                AppButton.setBackIcon(context, () {
                  Navigator.pop(context);
                }, AppColors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppRichText.setTextPoppinsStyle(
                        context,
                        'Ticket Details',
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
                        'Ticket #${widget.tId}',
                        10.5,
                        AppColors.lightGold,
                        FontWeight.w500,
                        1,
                        TextAlign.left,
                        0.0,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.tealGreen.withOpacity(0.15), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 15, offset: Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.tealGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.tealGreen),
                ),
                SizedBox(width: 10),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppRichText.setTextPoppinsStyle(
                        context,
                        'Raised On',
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
                        widget.tRaisedDateTime,
                        12,
                        AppColors.darkNavy,
                        FontWeight.w700,
                        2,
                        TextAlign.left,
                        1.2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _getStatusColor(widget.tstatus).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _getStatusColor(widget.tstatus).withOpacity(0.4), width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_getStatusIcon(widget.tstatus), size: 16, color: _getStatusColor(widget.tstatus)),
                SizedBox(width: 6),
                AppRichText.setTextPoppinsStyle(
                  context,
                  _getStatusText(widget.tstatus),
                  12,
                  _getStatusColor(widget.tstatus),
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
    );
  }

  Widget _buildTicketInfoCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.tealGreen.withOpacity(0.15), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 15, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.tealGreen.withOpacity(0.08), AppColors.darkNavy.withOpacity(0.04)],
              ),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [AppColors.tealGreen, AppColors.darkNavy]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.info_outline, color: AppColors.white, size: 20),
                ),
                SizedBox(width: 12),
                AppRichText.setTextPoppinsStyle(
                  context,
                  'Ticket Information',
                  15,
                  AppColors.darkNavy,
                  FontWeight.w900,
                  1,
                  TextAlign.left,
                  0.0,
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                _buildDetailRow(Icons.confirmation_number_outlined, 'Ticket ID', '#${widget.tId}', AppColors.tealGreen),
                SizedBox(height: 16),
                _buildDetailRow(Icons.category_outlined, 'Issue Category', widget.tReason, AppColors.darkNavy),
                SizedBox(height: 16),
                _buildDetailRow(Icons.description_outlined, 'Description', widget.tDescription, AppColors.oxfordBlue),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResolutionCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.3), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 15, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.08),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                ),
                SizedBox(width: 12),
                AppRichText.setTextPoppinsStyle(
                  context,
                  'Resolution Details',
                  15,
                  AppColors.darkNavy,
                  FontWeight.w900,
                  1,
                  TextAlign.left,
                  0.0,
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                _buildDetailRow(
                  Icons.comment_outlined,
                  'Admin Remarks',
                  widget.admRemark.isEmpty ? 'No remarks provided' : widget.admRemark,
                  Colors.green,
                ),
                SizedBox(height: 16),
                _buildDetailRow(
                  Icons.event_available_outlined,
                  'Resolved On',
                  widget.admDateTime.isEmpty ? 'N/A' : widget.admDateTime,
                  Colors.green,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.orange.withOpacity(0.1), Colors.orange.withOpacity(0.05)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), shape: BoxShape.circle),
            child: Icon(Icons.access_time, color: Colors.orange, size: 24),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppRichText.setTextPoppinsStyle(
                  context,
                  'Pending Resolution',
                  15,
                  AppColors.darkNavy,
                  FontWeight.w700,
                  1,
                  TextAlign.left,
                  0.0,
                ),
                SizedBox(height: 6),
                AppRichText.setTextPoppinsStyle(
                  context,
                  'Our team is working on your ticket. We\'ll update you once it\'s resolved.',
                  12,
                  AppColors.greyS700,
                  FontWeight.w500,
                  5,
                  TextAlign.left,
                  1.5,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.blue.withOpacity(0.1), Colors.blue.withOpacity(0.05)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.2), shape: BoxShape.circle),
            child: Icon(Icons.sync, color: Colors.blue, size: 24),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppRichText.setTextPoppinsStyle(
                  context,
                  'In Progress',
                  15,
                  AppColors.darkNavy,
                  FontWeight.w700,
                  1,
                  TextAlign.left,
                  0.0,
                ),
                SizedBox(height: 6),
                AppRichText.setTextPoppinsStyle(
                  context,
                  'Your ticket is being processed by our support team.',
                  12,
                  AppColors.greyS700,
                  FontWeight.w500,
                  5,
                  TextAlign.left,
                  1.5,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, Color iconColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 18, color: iconColor),
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
                FontWeight.w600,
                1,
                TextAlign.left,
                0.0,
              ),
              SizedBox(height: 4),
              AppRichText.setTextPoppinsStyle(
                context,
                value,
                13,
                AppColors.darkNavy,
                FontWeight.w500,
                10,
                TextAlign.left,
                1.4,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
