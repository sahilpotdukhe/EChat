import 'package:flutter/material.dart';

/// Replacement for flutter_signin_button's `SignInButton(Buttons.GoogleDark)`,
/// which no longer compiles on current Flutter.
class GoogleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;
  final EdgeInsetsGeometry padding;
  final double elevation;

  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.padding = const EdgeInsets.all(4),
    this.elevation = 2,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      onPressed: onPressed,
      color: const Color(0xFF4285F4),
      elevation: elevation,
      padding: padding,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2),
            ),
            child: const Text(
              'G',
              style: TextStyle(
                color: Color(0xFF4285F4),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: Text(
              'Sign in with Google',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
