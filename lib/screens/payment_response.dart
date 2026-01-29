import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tazaquiz/constants/app_colors.dart';
import 'package:tazaquiz/utils/richText.dart';

enum PaymentStatus { success, failed, pending }

// Helper function to convert string to PaymentStatus enum
PaymentStatus parsePaymentStatus(String status) {
  switch (status.toLowerCase().trim()) {
    case 'success':
    case 'completed':
    case 'paid':
    case 'approved':
      return PaymentStatus.success;
    case 'failed':
    case 'failure':
    case 'declined':
    case 'rejected':
    case 'error':
      return PaymentStatus.failed;
    case 'pending':
    case 'processing':
    case 'initiated':
    case 'waiting':
      return PaymentStatus.pending;
    default:
      return PaymentStatus.pending; // Default to pending for unknown statuses
  }
}

// Unified Payment Status Screen
class PaymentStatusScreen extends StatefulWidget {
  final PaymentStatus status;
  final String orderId;
  final String amount;
  final String paymentMethod;
  final String? transactionId;
  final String? failureReason;

  const PaymentStatusScreen({
    Key? key,
    required this.status,
    required this.orderId,
    required this.amount,
    required this.paymentMethod,
    this.transactionId,
    this.failureReason,
  }) : super(key: key);

  // Factory constructor to create from string status
  factory PaymentStatusScreen.fromString({
    required String status,
    required String orderId,
    required String amount,
    required String paymentMethod,
    String? transactionId,
    String? failureReason,
  }) {
    return PaymentStatusScreen(
      status: parsePaymentStatus(status),
      orderId: orderId,
      amount: amount,
      paymentMethod: paymentMethod,
      transactionId: transactionId,
      failureReason: failureReason,
    );
  }

  @override
  State<PaymentStatusScreen> createState() => _PaymentStatusScreenState();
}

class _PaymentStatusScreenState extends State<PaymentStatusScreen> with TickerProviderStateMixin {
  late AnimationController _iconController;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Icon animation controller
    _iconController = AnimationController(
      duration: widget.status == PaymentStatus.pending ? const Duration(seconds: 2) : const Duration(milliseconds: 800),
      vsync: this,
    );

    // Fade animation controller
    _fadeController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);

    _scaleAnimation = CurvedAnimation(parent: _iconController, curve: Curves.elasticOut);

    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);

    // Start animations based on status
    if (widget.status == PaymentStatus.pending) {
      _iconController.repeat(); // Continuous rotation
      _fadeController.forward(); // One-time fade in
    } else {
      _iconController.forward();
      _fadeController.forward();
    }
  }

  @override
  void dispose() {
    _iconController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig();

    return Scaffold(
      backgroundColor: AppColors.greyS1,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: config.gradientColors,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Close Button
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.close, color: AppColors.darkNavy),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),

                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Status Icon
                        _buildStatusIcon(config),

                        SizedBox(height: 15),

                        // Title
                        AppRichText.setTextPoppinsStyle(
                          context,
                          config.title,
                          22,
                          AppColors.darkNavy,
                          FontWeight.w900,
                          2,
                          TextAlign.center,
                          0.0,
                        ),

                        SizedBox(height: 10),

                        // Message
                        AppRichText.setTextPoppinsStyle(
                          context,
                          config.message,
                          14,
                          AppColors.greyS600,
                          FontWeight.w500,
                          3,
                          TextAlign.center,
                          1.5,
                        ),

                        SizedBox(height: 20),

                        // Payment Details Card
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.black.withOpacity(0.08),
                                blurRadius: 25,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Order ID
                              _buildDetailRow(
                                icon: Icons.receipt_long,
                                label: 'Order ID',
                                value: widget.orderId,
                                color: AppColors.tealGreen,
                                showCopy: true,
                              ),

                              SizedBox(height: 10),

                              // Amount
                              _buildDetailRow(
                                icon: Icons.currency_rupee,
                                label: widget.status == PaymentStatus.success ? 'Amount Paid' : 'Amount',
                                value: widget.amount,
                                color: AppColors.gold,
                                isHighlight: true,
                              ),

                              SizedBox(height: 10),

                              // Payment Method
                              _buildDetailRow(
                                icon: Icons.payment,
                                label: 'Payment Method',
                                value: widget.paymentMethod,
                                color: AppColors.darkNavy,
                              ),

                              if (widget.status == PaymentStatus.success && widget.transactionId != null) ...[
                                SizedBox(height: 10),
                                _buildDetailRow(
                                  icon: Icons.tag,
                                  label: 'Transaction ID',
                                  value: widget.transactionId!,
                                  color: AppColors.tealGreen,
                                ),
                              ],

                              if (widget.status == PaymentStatus.success) ...[
                                SizedBox(height: 10),
                                _buildDetailRow(
                                  icon: Icons.access_time,
                                  label: 'Transaction Time',
                                  value: _getCurrentTime(),
                                  color: AppColors.greyS500,
                                ),
                              ],

                              SizedBox(height: 20),

                              // Status-specific info box
                              _buildInfoBox(config),
                            ],
                          ),
                        ),

                        Spacer(),

                        // Action Buttons
                        _buildActionButtons(config),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon(StatusConfig config) {
    Widget iconWidget = Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: config.iconGradient),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: config.iconColor.withOpacity(0.4), blurRadius: 30, spreadRadius: 5, offset: Offset(0, 10)),
        ],
      ),
      child: Icon(config.icon, size: 60, color: AppColors.white),
    );

    switch (widget.status) {
      case PaymentStatus.success:
        return ScaleTransition(scale: _scaleAnimation, child: iconWidget);
      case PaymentStatus.failed:
        return AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(scale: 1.0 + (_scaleAnimation.value * 0.1), child: child);
          },
          child: iconWidget,
        );
      case PaymentStatus.pending:
        return RotationTransition(turns: Tween<double>(begin: 0, end: 1).animate(_iconController), child: iconWidget);
    }
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isHighlight = false,
    bool showCopy = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color.withOpacity(0.15), color.withOpacity(0.08)]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppRichText.setTextPoppinsStyle(
                context,
                label,
                12,
                AppColors.greyS600,
                FontWeight.w600,
                1,
                TextAlign.left,
                0.0,
              ),
              SizedBox(height: 4),
              AppRichText.setTextPoppinsStyle(
                context,
                value,
                isHighlight ? 20 : 15,
                isHighlight ? color : AppColors.darkNavy,
                isHighlight ? FontWeight.w900 : FontWeight.w700,
                1,
                TextAlign.left,
                0.0,
              ),
            ],
          ),
        ),
        if (showCopy)
          IconButton(
            icon: Icon(Icons.copy, size: 18, color: AppColors.greyS600),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Order ID copied to clipboard'),
                  backgroundColor: AppColors.tealGreen,
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildInfoBox(StatusConfig config) {
    if (config.infoMessage == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [config.infoBoxColor.withOpacity(0.3), config.infoBoxColor.withOpacity(0.15)]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: config.infoBorderColor, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: config.infoIconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(config.infoIcon, color: config.infoIconColor, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: AppRichText.setTextPoppinsStyle(
              context,
              config.infoMessage!,
              12,
              config.infoIconColor,
              FontWeight.w600,
              3,
              TextAlign.left,
              1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(StatusConfig config) {
    return Column(
      children: [
        // Primary Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: config.primaryButtonAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.transparent,
              shadowColor: AppColors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: EdgeInsets.zero,
            ),
            child: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.tealGreen, AppColors.darkNavy]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                alignment: Alignment.center,
                child: AppRichText.setTextPoppinsStyle(
                  context,
                  config.primaryButtonText,
                  15,
                  AppColors.white,
                  FontWeight.w700,
                  1,
                  TextAlign.center,
                  0.0,
                ),
              ),
            ),
          ),
        ),

        SizedBox(height: 12),
      ],
    );
  }

  StatusConfig _getStatusConfig() {
    switch (widget.status) {
      case PaymentStatus.success:
        return StatusConfig(
          title: 'Payment Successful!',
          message: 'Your payment has been processed successfully.\nYou can now access your content.',
          icon: Icons.check_circle,
          iconColor: AppColors.tealGreen,
          iconGradient: [AppColors.tealGreen, Color(0xFF00A896)],
          gradientColors: [AppColors.tealGreen.withOpacity(0.08), AppColors.white],
          infoMessage: 'Your order has been confirmed. Check your email for details.',
          infoIcon: Icons.check_circle_outline,
          infoBoxColor: AppColors.tealGreen,
          infoBorderColor: AppColors.tealGreen.withOpacity(0.3),
          infoIconColor: AppColors.tealGreen,
          primaryButtonText: 'Start Learning',
          secondaryButtonText: 'Download Receipt',
          primaryButtonAction: () {
            // Navigate to course/content
            Navigator.popUntil(context, (route) => route.isFirst);
          },
          secondaryButtonAction: () {
            // Download receipt logic
          },
          secondaryButtonColor: AppColors.darkNavy,
        );

      case PaymentStatus.failed:
        return StatusConfig(
          title: 'Payment Failed',
          message: 'Unfortunately, your payment could not be processed.\nPlease try again or use a different method.',
          icon: Icons.cancel,
          iconColor: Colors.red.shade600,
          iconGradient: [Colors.red.shade600, Colors.red.shade400],
          gradientColors: [Colors.red.shade50, AppColors.white],
          infoMessage: widget.failureReason ?? 'Payment declined. Please check your payment details and try again.',
          infoIcon: Icons.error_outline,
          infoBoxColor: Colors.red,
          infoBorderColor: Colors.red.shade200,
          infoIconColor: Colors.red.shade700,
          primaryButtonText: 'Retry Payment',
          secondaryButtonText: 'Go Back',
          primaryButtonAction: () {
            // Retry payment - go back to checkout
            Navigator.pop(context);
          },
          secondaryButtonAction: () {
            Navigator.popUntil(context, (route) => route.isFirst);
          },
          secondaryButtonColor: AppColors.greyS600,
        );

      case PaymentStatus.pending:
        return StatusConfig(
          title: 'Payment Pending',
          message: 'Your payment is being processed.\nThis usually takes 2-5 minutes.',
          icon: Icons.hourglass_empty,
          iconColor: Colors.orange.shade600,
          iconGradient: [Colors.orange.shade600, Colors.orange.shade400],
          gradientColors: [Colors.orange.shade50, AppColors.white],
          infoMessage: 'We\'re verifying your payment. You\'ll receive a confirmation shortly.',
          infoIcon: Icons.info_outline,
          infoBoxColor: Colors.orange,
          infoBorderColor: Colors.orange.shade200,
          infoIconColor: Colors.orange.shade700,
          primaryButtonText: 'Check Status',
          secondaryButtonText: 'Go to Home',
          primaryButtonAction: () {
            // Check payment status - refresh or API call
            setState(() {});
          },
          secondaryButtonAction: () {
            Navigator.popUntil(context, (route) => route.isFirst);
          },
          secondaryButtonColor: AppColors.darkNavy,
        );
    }
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
  }
}

// Configuration class for different payment statuses
class StatusConfig {
  final String title;
  final String message;
  final IconData icon;
  final Color iconColor;
  final List<Color> iconGradient;
  final List<Color> gradientColors;
  final String? infoMessage;
  final IconData infoIcon;
  final Color infoBoxColor;
  final Color infoBorderColor;
  final Color infoIconColor;
  final String primaryButtonText;
  final String secondaryButtonText;
  final VoidCallback primaryButtonAction;
  final VoidCallback secondaryButtonAction;
  final Color secondaryButtonColor;

  StatusConfig({
    required this.title,
    required this.message,
    required this.icon,
    required this.iconColor,
    required this.iconGradient,
    required this.gradientColors,
    required this.infoMessage,
    required this.infoIcon,
    required this.infoBoxColor,
    required this.infoBorderColor,
    required this.infoIconColor,
    required this.primaryButtonText,
    required this.secondaryButtonText,
    required this.primaryButtonAction,
    required this.secondaryButtonAction,
    required this.secondaryButtonColor,
  });
}
