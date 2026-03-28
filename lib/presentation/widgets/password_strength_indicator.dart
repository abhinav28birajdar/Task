import 'package:flutter/material.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({Key? key, required this.password})
      : super(key: key);

  double get strength {
    if (password.isEmpty) return 0;
    double score = 0;
    if (password.length >= 6) score += 0.25;
    if (password.length >= 8) score += 0.25;
    if (RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password)) score += 0.25;
    if (RegExp(r'[0-9]').hasMatch(password) &&
        RegExp(r'[!@#\$%^&*]').hasMatch(password)) score += 0.25;
    return score;
  }

  Color get _color {
    final val = strength;
    if (val <= 0.25) return Colors.red;
    if (val <= 0.5) return Colors.orange;
    if (val <= 0.75) return Colors.yellow;
    return Colors.green;
  }

  String get _text {
    final val = strength;
    if (val == 0) return '';
    if (val <= 0.25) return 'Weak';
    if (val <= 0.5) return 'Fair';
    if (val <= 0.75) return 'Good';
    return 'Strong';
  }

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: strength,
          backgroundColor: Colors.grey.shade300,
          color: _color,
          minHeight: 4,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 8),
        Text(
          _text,
          style: TextStyle(
              color: _color, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
