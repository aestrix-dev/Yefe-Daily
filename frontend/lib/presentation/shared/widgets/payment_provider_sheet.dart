import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:yefa/core/constants/app_colors.dart';

class PaymentProviderSheet extends StatelessWidget {
  final void Function() onStripeTap;
  final void Function() onPaystackTap;

  const PaymentProviderSheet({
    super.key,
    required this.onStripeTap,
    required this.onPaystackTap,
  });

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.32,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.accentDark(context),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Select Payment Method',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24.h),

            // 2-column grid layout for payment options
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onStripeTap,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 24.h),
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFF635BFF,
                        ).withOpacity(0.1), // Stripe brand color
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Stripe logo
                          Image.asset(
                            'assets/icons/stripe.png',
                            width: 40.w,
                            height: 43.h,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.payment,
                                color: const Color(0xFF635BFF),
                                size: 32.sp,
                              );
                            },
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Stripe',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: GestureDetector(
                    onTap: onPaystackTap,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 24.h),
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFF0FA958,
                        ).withOpacity(0.1), 
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Paystack logo
                          Image.asset(
                            'assets/icons/paystack.png',
                            width: 50.w,
                            height: 45.h,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.account_balance,
                                color: const Color(0xFF0FA958),
                                size: 32.sp,
                              );
                            },
                          ),
                          
                          SizedBox(height: 8.h),
                          Text(
                            'Paystack',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
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
    );
  }
}
