import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tazaquiz/API/api_client.dart';
import 'package:tazaquiz/authentication/AuthRepository.dart';
import 'package:tazaquiz/constants/app_colors.dart';
import 'package:tazaquiz/models/login_response_model.dart';
import 'package:tazaquiz/models/payment_history_modal.dart';
import 'package:tazaquiz/utils/richText.dart';
import 'package:tazaquiz/utils/session_manager.dart';

class PaymentHistoryPage extends StatefulWidget {
  @override
  _PaymentHistoryPageState createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage> {
  String _selectedFilter = 'all'; // 'all', 'success', 'pending', 'failed'

  bool _isLoading = true;
  List<PaymentItem> _allTransactions = [];
  PaymentStats? _stats;
  UserModel? _user;
  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  Future<void> _getUserData() async {
    _user = await SessionManager.getUser();
    setState(() {});
    await fetchPaymentHistory(_user!.id);
  }

  Future<void> fetchPaymentHistory(String userId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      Authrepository authRepository = Authrepository(Api_Client.dio);
      final data = {'user_id': _user!.id.toString()};

      final response = await authRepository.fetch_paymentHistory(data);

      if (response.statusCode == 200) {
        final responseData = response.data;
        final paymentResponse = PaymentHistoryResponse.fromJson(responseData);

        setState(() {
          _allTransactions = paymentResponse.data;
          _stats = paymentResponse.stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching payment history: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<PaymentItem> get _filteredTransactions {
    if (_selectedFilter == 'all') {
      return _allTransactions;
    }
    return _allTransactions.where((txn) => txn.displayStatus == _selectedFilter).toList();
  }

  void _showTransactionDetails(PaymentItem transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildTransactionDetailsSheet(transaction),
    );
  }

  String _formatDate(String dateTime) {
    try {
      final date = DateTime.parse(dateTime);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateTime;
    }
  }

  String _formatTime(String dateTime) {
    try {
      final date = DateTime.parse(dateTime);
      return DateFormat('hh:mm a').format(date);
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greyS1,
      appBar: _buildAppBar(),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.tealGreen)))
              : Column(
                children: [
                  _buildSummaryCard(),
                  _buildFilterChips(),
                  Expanded(child: _filteredTransactions.isEmpty ? _buildEmptyState() : _buildTransactionsList()),
                ],
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
          child: Icon(Icons.arrow_back, color: AppColors.white, size: 20),
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
      title: AppRichText.setTextPoppinsStyle(
        context,
        'Payment History',
        16,
        AppColors.white,
        FontWeight.w900,
        1,
        TextAlign.left,
        0.0,
      ),
    );
  }

  Widget _buildSummaryCard() {
    final successCount = _stats?.successCount ?? 0;
    final pendingCount = _stats?.pendingCount ?? 0;
    final failedCount = _stats?.failedCount ?? 0;
    final totalSpent = _stats?.totalSpent ?? 0.0;

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.tealGreen, AppColors.darkNavy],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.tealGreen.withOpacity(0.3), blurRadius: 15, offset: Offset(0, 8))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.account_balance_wallet, color: AppColors.white, size: 25),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppRichText.setTextPoppinsStyle(
                      context,
                      'Total Spent',
                      12,
                      AppColors.white.withOpacity(0.9),
                      FontWeight.w600,
                      1,
                      TextAlign.left,
                      0.0,
                    ),
                    AppRichText.setTextPoppinsStyle(
                      context,
                      '₹ ${totalSpent.toStringAsFixed(0)}',
                      22,
                      AppColors.white,
                      FontWeight.w900,
                      1,
                      TextAlign.left,
                      0.0,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  icon: Icons.check_circle,
                  label: 'Success',
                  value: '$successCount',
                  color: AppColors.lightGold,
                ),
                Container(width: 1, height: 40, color: AppColors.white.withOpacity(0.3)),
                _buildSummaryItem(
                  icon: Icons.schedule,
                  label: 'Pending',
                  value: '$pendingCount',
                  color: Colors.orangeAccent,
                ),
                Container(width: 1, height: 40, color: AppColors.white.withOpacity(0.3)),
                _buildSummaryItem(icon: Icons.cancel, label: 'Failed', value: '$failedCount', color: Colors.redAccent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        SizedBox(height: 6),
        AppRichText.setTextPoppinsStyle(context, value, 16, AppColors.white, FontWeight.w900, 1, TextAlign.center, 0.0),
        SizedBox(height: 2),
        AppRichText.setTextPoppinsStyle(
          context,
          label,
          11,
          AppColors.white.withOpacity(0.8),
          FontWeight.w600,
          1,
          TextAlign.center,
          0.0,
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 40,
      margin: EdgeInsets.symmetric(horizontal: 13),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip('All', 'all', Icons.list),
          SizedBox(width: 8),
          _buildFilterChip('Success', 'success', Icons.check_circle),
          SizedBox(width: 8),
          _buildFilterChip('Pending', 'pending', Icons.schedule),
          SizedBox(width: 8),
          _buildFilterChip('Failed', 'failed', Icons.cancel),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = _selectedFilter == value;
    Color chipColor;

    switch (value) {
      case 'success':
        chipColor = AppColors.tealGreen;
        break;
      case 'pending':
        chipColor = Colors.orange;
        break;
      case 'failed':
        chipColor = AppColors.red;
        break;
      default:
        chipColor = AppColors.darkNavy;
    }

    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? LinearGradient(colors: [chipColor, chipColor.withOpacity(0.7)]) : null,
          color: isSelected ? null : AppColors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: isSelected ? chipColor : AppColors.greyS300!, width: isSelected ? 2 : 1),
          boxShadow:
              isSelected ? [BoxShadow(color: chipColor.withOpacity(0.3), blurRadius: 8, offset: Offset(0, 4))] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: isSelected ? AppColors.white : AppColors.greyS600),
            SizedBox(width: 6),
            AppRichText.setTextPoppinsStyle(
              context,
              label,
              13,
              isSelected ? AppColors.white : AppColors.darkNavy,
              FontWeight.w700,
              1,
              TextAlign.center,
              0.0,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _filteredTransactions.length,
      itemBuilder: (context, index) {
        final transaction = _filteredTransactions[index];
        final isLast = index == _filteredTransactions.length - 1;
        return _buildTransactionCard(transaction, isLast);
      },
    );
  }

  Widget _buildTransactionCard(PaymentItem transaction, bool isLast) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (transaction.displayStatus) {
      case 'success':
        statusColor = AppColors.tealGreen;
        statusIcon = Icons.check_circle;
        statusText = 'Success';
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        statusText = 'Pending';
        break;
      case 'failed':
        statusColor = AppColors.red;
        statusIcon = Icons.cancel;
        statusText = 'Failed';
        break;
      default:
        statusColor = AppColors.greyS600;
        statusIcon = Icons.help;
        statusText = 'Unknown';
    }

    return InkWell(
      onTap: () => _showTransactionDetails(transaction),
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  // Timeline dot
                  Column(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: statusColor.withOpacity(0.4), blurRadius: 8, spreadRadius: 2)],
                        ),
                      ),
                      if (!isLast)
                        Container(width: 2, height: 60, color: AppColors.greyS300, margin: EdgeInsets.only(top: 4)),
                    ],
                  ),
                  SizedBox(width: 16),
                  // Transaction details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: AppRichText.setTextPoppinsStyle(
                                context,
                                transaction.productDisplayName,
                                15,
                                AppColors.darkNavy,
                                FontWeight.w700,
                                2,
                                TextAlign.left,
                                0.0,
                              ),
                            ),
                            AppRichText.setTextPoppinsStyle(
                              context,
                              '₹${transaction.amount.toStringAsFixed(0)}',
                              16,
                              AppColors.darkNavy,
                              FontWeight.w900,
                              1,
                              TextAlign.right,
                              0.0,
                            ),
                          ],
                        ),
                        SizedBox(height: 6),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.lightGold.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: AppRichText.setTextPoppinsStyle(
                            context,
                            transaction.productTypeDisplay,
                            10,
                            AppColors.darkNavy,
                            FontWeight.w600,
                            1,
                            TextAlign.left,
                            0.0,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 14, color: AppColors.greyS600),
                            SizedBox(width: 4),
                            AppRichText.setTextPoppinsStyle(
                              context,
                              '${_formatDate(transaction.purchaseDate)} • ${_formatTime(transaction.purchaseDate)}',
                              12,
                              AppColors.greyS600,
                              FontWeight.w500,
                              1,
                              TextAlign.left,
                              0.0,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      SizedBox(width: 6),
                      AppRichText.setTextPoppinsStyle(
                        context,
                        statusText,
                        12,
                        statusColor,
                        FontWeight.w700,
                        1,
                        TextAlign.left,
                        0.0,
                      ),
                    ],
                  ),
                  Row(
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
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.tealGreen),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.tealGreen.withOpacity(0.1), AppColors.darkNavy.withOpacity(0.05)],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.receipt_long, size: 80, color: AppColors.greyS400),
          ),
          SizedBox(height: 24),
          AppRichText.setTextPoppinsStyle(
            context,
            'No transactions found',
            20,
            AppColors.darkNavy,
            FontWeight.w800,
            1,
            TextAlign.center,
            0.0,
          ),
          SizedBox(height: 12),
          AppRichText.setTextPoppinsStyle(
            context,
            'Try changing your filter selection',
            14,
            AppColors.greyS600,
            FontWeight.w500,
            1,
            TextAlign.center,
            0.0,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionDetailsSheet(PaymentItem transaction) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (transaction.displayStatus) {
      case 'success':
        statusColor = AppColors.tealGreen;
        statusIcon = Icons.check_circle;
        statusText = 'Payment Successful';
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        statusText = 'Payment Pending';
        break;
      case 'failed':
        statusColor = AppColors.red;
        statusIcon = Icons.cancel;
        statusText = 'Payment Failed';
        break;
      default:
        statusColor = AppColors.greyS600;
        statusIcon = Icons.help;
        statusText = 'Unknown Status';
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: 12),
            width: 50,
            height: 5,
            decoration: BoxDecoration(color: AppColors.greyS300, borderRadius: BorderRadius.circular(10)),
          ),

          // Header with status
          Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.15), shape: BoxShape.circle),
                  child: Icon(statusIcon, color: statusColor, size: 48),
                ),
                SizedBox(height: 16),
                AppRichText.setTextPoppinsStyle(
                  context,
                  statusText,
                  22,
                  AppColors.darkNavy,
                  FontWeight.w900,
                  1,
                  TextAlign.center,
                  0.0,
                ),
                SizedBox(height: 8),
                AppRichText.setTextPoppinsStyle(
                  context,
                  '₹${transaction.amount.toStringAsFixed(2)}',
                  32,
                  AppColors.darkNavy,
                  FontWeight.w900,
                  1,
                  TextAlign.center,
                  0.0,
                ),
              ],
            ),
          ),

          Container(height: 1, color: AppColors.greyS200),

          // Transaction details
          Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppRichText.setTextPoppinsStyle(
                  context,
                  'Transaction Details',
                  16,
                  AppColors.darkNavy,
                  FontWeight.w800,
                  1,
                  TextAlign.left,
                  0.0,
                ),
                SizedBox(height: 16),
                _buildDetailRow('Item', transaction.productDisplayName),
                _buildDetailRow('Type', transaction.productTypeDisplay),
                _buildDetailRow('Transaction ID', transaction.transactionId ?? 'N/A'),
                _buildDetailRow('Order ID', transaction.orderId),
                _buildDetailRow('Date', _formatDate(transaction.purchaseDate)),
                _buildDetailRow('Time', _formatTime(transaction.purchaseDate)),
                _buildDetailRow('Payment Method', transaction.paymentMethod ?? 'N/A'),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.transparent,
                    shadowColor: AppColors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: EdgeInsets.zero,
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [AppColors.tealGreen, AppColors.darkNavy]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      alignment: Alignment.center,
                      child: AppRichText.setTextPoppinsStyle(
                        context,
                        'Close',
                        14,
                        AppColors.white,
                        FontWeight.w700,
                        1,
                        TextAlign.center,
                        0.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppRichText.setTextPoppinsStyle(
            context,
            label,
            13,
            AppColors.greyS600,
            FontWeight.w600,
            1,
            TextAlign.left,
            0.0,
          ),
          Flexible(
            child: AppRichText.setTextPoppinsStyle(
              context,
              value,
              13,
              AppColors.darkNavy,
              FontWeight.w700,
              1,
              TextAlign.right,
              0.0,
            ),
          ),
        ],
      ),
    );
  }
}
