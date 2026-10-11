import 'package:flutter/material.dart';
import 'package:shadcn_kit/shadcn_kit.dart';

/// EChat's theme: the shared shadcn violet presets, plus the few colors
/// shadcn doesn't have (success, warning, the online dot, chat bubbles and
/// the brand gradient).
///
/// Core colors come from shadcn: `context.shadcn.primary`, `.foreground`,
/// `.mutedForeground`, `.border`… EChat's extras: `context.colors.online`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color success;
  final Color warning;
  final Color online;

  /// Behind the messages, a touch off the page color so incoming bubbles
  /// stand out.
  final Color chatBackground;
  final Color bubbleOutgoing;
  final Color onBubbleOutgoing;
  final Color bubbleIncoming;
  final Color onBubbleIncoming;
  final Gradient brandGradient;

  const AppColors({
    required this.success,
    required this.warning,
    required this.online,
    required this.chatBackground,
    required this.bubbleOutgoing,
    required this.onBubbleOutgoing,
    required this.bubbleIncoming,
    required this.onBubbleIncoming,
    required this.brandGradient,
  });

  /// App-wide text tweaks over the kit defaults: regular-weight paragraphs,
  /// a bolder page heading, and `lead` as a 16px subtitle under headings.
  static const _text = ShadcnTextTheme(
    h2: ShadcnTextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.4, height: 1.2),
    p: ShadcnTextStyle(fontWeight: FontWeight.w400, height: 1.45),
    p1: ShadcnTextStyle(fontWeight: FontWeight.w400, height: 1.5),
    lead: ShadcnTextStyle(fontSize: 16, height: 1.5),
    muted: ShadcnTextStyle(fontSize: 13, height: 1.4),
  );

  static final ShadcnTheme shadcnLight = ShadcnTheme.lightViolet(radius: 12).copyWith(text: _text);
  static final ShadcnTheme shadcnDark = ShadcnTheme.darkViolet(radius: 12).copyWith(text: _text);

  static final AppColors light = AppColors(
    success: const Color(0xFF16A34A),
    warning: const Color(0xFFF59E0B),
    online: const Color(0xFF22C55E),
    chatBackground: const Color(0xFFF4F4F7),
    bubbleOutgoing: shadcnLight.primary,
    onBubbleOutgoing: shadcnLight.primaryForeground,
    bubbleIncoming: Colors.white,
    onBubbleIncoming: shadcnLight.foreground,
    brandGradient: const LinearGradient(
      colors: [Color(0xFF8E7CF8), Color(0xFF4834D4)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  static final AppColors dark = AppColors(
    success: const Color(0xFF34D399),
    warning: const Color(0xFFFBBF24),
    online: const Color(0xFF4ADE80),
    chatBackground: shadcnDark.background,
    bubbleOutgoing: shadcnDark.primary,
    onBubbleOutgoing: shadcnDark.primaryForeground,
    bubbleIncoming: const Color(0xFF23232D),
    onBubbleIncoming: shadcnDark.foreground,
    brandGradient: const LinearGradient(
      colors: [Color(0xFF7B6CF2), Color(0xFF3B2DB8)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  @override
  AppColors copyWith({
    Color? success,
    Color? warning,
    Color? online,
    Color? chatBackground,
    Color? bubbleOutgoing,
    Color? onBubbleOutgoing,
    Color? bubbleIncoming,
    Color? onBubbleIncoming,
    Gradient? brandGradient,
  }) {
    return AppColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      online: online ?? this.online,
      chatBackground: chatBackground ?? this.chatBackground,
      bubbleOutgoing: bubbleOutgoing ?? this.bubbleOutgoing,
      onBubbleOutgoing: onBubbleOutgoing ?? this.onBubbleOutgoing,
      bubbleIncoming: bubbleIncoming ?? this.bubbleIncoming,
      onBubbleIncoming: onBubbleIncoming ?? this.onBubbleIncoming,
      brandGradient: brandGradient ?? this.brandGradient,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      online: Color.lerp(online, other.online, t)!,
      chatBackground: Color.lerp(chatBackground, other.chatBackground, t)!,
      bubbleOutgoing: Color.lerp(bubbleOutgoing, other.bubbleOutgoing, t)!,
      onBubbleOutgoing: Color.lerp(onBubbleOutgoing, other.onBubbleOutgoing, t)!,
      bubbleIncoming: Color.lerp(bubbleIncoming, other.bubbleIncoming, t)!,
      onBubbleIncoming: Color.lerp(onBubbleIncoming, other.onBubbleIncoming, t)!,
      brandGradient: t < 0.5 ? brandGradient : other.brandGradient,
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>() ?? AppColors.light;
}
