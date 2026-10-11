import 'package:flutter/material.dart';
import 'package:shadcn_kit/shadcn_kit.dart';

/// "Continue with Google" button in the shadcn outline style.
class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;

  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.label = 'Continue with Google',
  });

  @override
  Widget build(BuildContext context) {
    return ShadcnButton(
      variant: ShadcnButtonVariant.outline,
      size: ShadcnButtonSize.lg,
      fullWidth: true,
      onPressed: onPressed,
      leading: const _GoogleMark(),
      child: Text(label),
    );
  }
}

/// A "G" painted in Google's four colors.
class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => const SweepGradient(
        colors: [
          Color(0xFFEA4335),
          Color(0xFFFBBC05),
          Color(0xFF34A853),
          Color(0xFF4285F4),
          Color(0xFFEA4335),
        ],
        stops: [0.0, 0.3, 0.55, 0.8, 1.0],
      ).createShader(bounds),
      child: const Text(
        'G',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, height: 1),
      ),
    );
  }
}
