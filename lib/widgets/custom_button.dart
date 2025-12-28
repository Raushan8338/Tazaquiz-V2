import 'package:flutter/material.dart';
import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/utils/richText.dart';
  class AppButton {


  static Widget setButtonStyle(
    context,
    String text,
    onPress,
    _isLoading
  ) {
    return  SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPress,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.transparent,
          shadowColor: AppColors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.tealGreen, AppColors.darkNavy],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.tealGreen.withOpacity(0.3),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Container(
            alignment: Alignment.center,
            child: _isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(AppColors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppRichText.setTextPoppinsStyle(context, text, 17, AppColors.white, FontWeight.w700, 1, TextAlign.left, 0.0),

                 
                      SizedBox(width: 10),
                      Icon(Icons.arrow_forward, color: AppColors.white, size: 20),
                    ],
                  ),
          ),
        ),
      ),
    );
  }


 static Widget setGestureDetectorButtonStyle(
    context,
    String text,
    onPress,
    
  ) {
    return GestureDetector(
        onTap: onPress,
        child: AppRichText.setTextPoppinsStyle(context, text, 14, AppColors.tealGreen, FontWeight.w800, 1, TextAlign.left, 0.0),

 ); }

 static Widget setBackIcon(
    context,
    onPress,
    Color color
  ) {
    return GestureDetector(
            onTap: onPress,
            child: Icon(Icons.arrow_back_ios_outlined,
              size: 22,
              color: color,
              )
 ); }



  }