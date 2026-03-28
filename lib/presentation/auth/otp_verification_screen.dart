import 'package:flutter/material.dart';
import '../widgets/modern_widgets.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String email;
  final VoidCallback onVerified;

  const OTPVerificationScreen({
    super.key,
    required this.email,
    required this.onVerified,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  String _otp = '';
  bool _isLoading = false;
  int _resendTimer = 60;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _resendTimer > 0) {
        setState(() => _resendTimer--);
        _startResendTimer();
      }
    });
  }

  void _verifyOTP() async {
    if (_otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid OTP')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Simulate OTP verification
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isLoading = false);
      widget.onVerified();
    }
  }

  void _resendOTP() {
    if (_resendTimer == 0) {
      setState(() => _resendTimer = 60);
      _startResendTimer();
      // TODO: Call resend OTP API
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF0a0a0f),
                        const Color(0xFF1a1a2e),
                      ]
                    : [
                        const Color(0xFFFAFAFC),
                        const Color(0xFFF0E6FF),
                      ],
              ),
            ),
          ),

          // Decorative circles
          Positioned(
            top: -150,
            right: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFb72bff).withValues(alpha: 0.3),
                    const Color(0xFFb72bff).withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),

          // Main content
          SingleChildScrollView(
            child: SizedBox(
              height: MediaQuery.of(context).size.height,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFb72bff),
                                Color(0xFF8338ec),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFb72bff).withValues(alpha: 0.4),
                                blurRadius: 20,
                                spreadRadius: 5,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.verified_user_outlined,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Title
                        Text(
                          'Verify Your Email',
                          style: Theme.of(context).textTheme.headlineLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),

                        // Subtitle
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: Theme.of(context).textTheme.bodyMedium,
                            children: [
                              const TextSpan(text: 'We\'ve sent a code to '),
                              const TextSpan(
                                text: 'your email',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFb72bff),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 48),

                        // OTP Input
                        AnimatedOTPField(
                          boxCount: 6,
                          onCompleted: (otp) {
                            setState(() => _otp = otp);
                            _verifyOTP();
                          },
                        ),
                        const SizedBox(height: 48),

                        // Verify Button
                        NestedGlowButton(
                          label: 'Verify',
                          onPressed: _verifyOTP,
                          isLoading: _isLoading,
                          glowColor: const Color(0xFFb72bff),
                        ),
                        const SizedBox(height: 24),

                        // Resend code
                        Column(
                          children: [
                            Text(
                              'Didn\'t receive the code?',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            if (_resendTimer > 0)
                              Text(
                                'Resend in ${_resendTimer}s',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: const Color(0xFFb72bff),
                                    ),
                              )
                            else
                              GestureDetector(
                                onTap: _resendOTP,
                                child: Text(
                                  'Resend Code',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: const Color(0xFFb72bff),
                                        fontWeight: FontWeight.w600,
                                        decoration: TextDecoration.underline,
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
            ),
          ),
        ],
      ),
    );
  }
}
