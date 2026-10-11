import 'package:echat/theme/app_colors.dart';
import 'package:echat/utils/responsive.dart';
import 'package:echat/widgets/common/brand_logo.dart';
import 'package:echat/widgets/common/illustration.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_kit/shadcn_kit.dart';

/// Inputs on the sign-in screens are a little taller than the default, so
/// they're comfortable to tap.
const authInputStyle = ShadcnInputStyle(height: 48, iconSize: 18);

/// Shared page frame for the sign-in and sign-up screens.
///
/// Phones: one scrolling column (illustration, heading, form, footer).
/// Tablets / wide screens: a branded panel on the left and the form on the
/// right. On a short landscape phone the illustration is dropped to leave
/// room for the form.
class AuthLayout extends StatelessWidget {
  final String title;
  final String subtitle;
  final String illustration;
  final String panelTitle;
  final String panelSubtitle;
  final Widget form;
  final Widget? footer;
  final bool showBack;

  const AuthLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.illustration,
    required this.form,
    this.footer,
    this.showBack = false,
    this.panelTitle = 'Conversations that feel close.',
    this.panelSubtitle = 'Chat, share photos and call the people who matter, from any device.',
  });

  @override
  Widget build(BuildContext context) {
    // A sideways phone is wide but too short for the side panel.
    final wide = context.isExpanded && !context.isLandscapeShort;
    final body = wide
        ? Row(
            children: [
              Expanded(flex: 5, child: _BrandPanel(
                illustration: illustration,
                title: panelTitle,
                subtitle: panelSubtitle,
              )),
              Expanded(flex: 6, child: SafeArea(child: _formColumn(context, showIllustration: false, wide: true))),
            ],
          )
        : SafeArea(child: _formColumn(context, showIllustration: !context.isLandscapeShort, wide: false));

    return Scaffold(body: body);
  }

  Widget _formColumn(BuildContext context, {required bool showIllustration, required bool wide}) {
    final illustrationSize = (context.screenHeight * 0.24).clamp(140.0, 220.0);

    return LayoutBuilder(builder: (context, constraints) {
      return SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.symmetric(horizontal: context.pagePadding, vertical: ShadcnSpacing.lg),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - ShadcnSpacing.lg * 2),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: Breakpoints.formMaxWidth),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      if (showBack && Navigator.of(context).canPop()) ...[
                        ShadcnButton(
                          variant: ShadcnButtonVariant.secondary,
                          size: ShadcnButtonSize.icon,
                          tooltip: 'Back',
                          semanticLabel: 'Back',
                          onPressed: () => Navigator.of(context).maybePop(),
                          child: const Icon(Icons.arrow_back_rounded),
                        ),
                        ShadcnGap.md,
                      ],
                      // The wide layout already shows the logo in its side panel.
                      if (!wide) const BrandLogo(size: 36),
                    ],
                  ),
                  if (showIllustration) ...[
                    ShadcnGap.lg,
                    Center(child: Illustration(asset: illustration, maxSize: illustrationSize)),
                    ShadcnGap.lg,
                  ] else
                    ShadcnGap.xl3,
                  ShadcnText(title, variant: ShadcnTextVariant.h2),
                  ShadcnGap.sm,
                  ShadcnText(subtitle, variant: ShadcnTextVariant.lead),
                  ShadcnGap.xl2,
                  form,
                  if (footer != null) ...[ShadcnGap.xl2, footer!],
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _BrandPanel extends StatelessWidget {
  final String illustration;
  final String title;
  final String subtitle;

  const _BrandPanel({required this.illustration, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: context.colors.brandGradient),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(ShadcnSpacing.xl5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BrandLogo(size: 40, onBrand: true),
              Expanded(
                child: Center(child: Illustration(asset: illustration, maxSize: 380, onBrand: true)),
              ),
              ShadcnText(
                title,
                variant: ShadcnTextVariant.h2,
                style: const ShadcnTextStyle(color: Colors.white),
              ),
              ShadcnGap.md,
              ShadcnText(
                subtitle,
                variant: ShadcnTextVariant.lead,
                style: ShadcnTextStyle(color: Colors.white.withValues(alpha: 0.82)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Don't have an account? Sign up" style line under a form.
class AuthFooterLink extends StatelessWidget {
  final String question;
  final String action;
  final VoidCallback onTap;

  const AuthFooterLink({super.key, required this.question, required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ShadcnText(
          question,
          style: ShadcnTextStyle(color: context.shadcn.mutedForeground),
        ),
        ShadcnButton(
          variant: ShadcnButtonVariant.link,
          onPressed: onTap,
          child: Text(action),
        ),
      ],
    );
  }
}
