import 'package:echat/models/on_board_model.dart';
import 'package:echat/screens/login_screen.dart';
import 'package:echat/utils/responsive.dart';
import 'package:echat/widgets/common/brand_logo.dart';
import 'package:echat/widgets/common/illustration.dart';
import 'package:echat/widgets/common/page_dots.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_kit/shadcn_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnBoardScreens extends StatefulWidget {
  const OnBoardScreens({super.key});

  @override
  State<OnBoardScreens> createState() => _OnBoardScreensState();
}

class _OnBoardScreensState extends State<OnBoardScreens> {
  final _pageController = PageController();
  int _currentIndex = 0;

  static final List<OnBoardModel> _pages = [
    OnBoardModel(
      image: 'assets/first.png',
      text: 'Chat anytime, anywhere',
      description: 'Send messages, photos and files instantly, on any device.',
    ),
    OnBoardModel(
      image: 'assets/second.png',
      text: 'Made for your people',
      description: 'Find friends from your contacts and keep every conversation in one place.',
    ),
    OnBoardModel(
      image: 'assets/third.png',
      text: 'Crystal-clear calls',
      description: 'Jump from chat to a smooth voice or video call with a single tap.',
    ),
  ];

  bool get _isLast => _currentIndex == _pages.length - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('OnBoard', 0);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _next() {
    if (_isLast) {
      _finish();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ResponsiveCenter(
          maxWidth: 960,
          child: Column(
            children: [
              _topBar(context),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _currentIndex = i),
                  itemBuilder: (context, i) => _OnBoardPage(page: _pages[i]),
                ),
              ),
              _bottomBar(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(context.pagePadding, ShadcnSpacing.sm, ShadcnSpacing.sm, 0),
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            const BrandLogo(size: 32),
            const Spacer(),
            // Hidden (but keeping its space) on the last page, where the main
            // button already finishes.
            AnimatedOpacity(
              opacity: _isLast ? 0 : 1,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: _isLast,
                child: ShadcnButton(
                  variant: ShadcnButtonVariant.ghost,
                  onPressed: _finish,
                  child: const Text('Skip'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomBar(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(context.pagePadding, ShadcnSpacing.lg, context.pagePadding, ShadcnSpacing.xl2),
      child: Row(
        children: [
          PageDots(count: _pages.length, current: _currentIndex),
          const Spacer(),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            child: ShadcnButton(
              size: ShadcnButtonSize.lg,
              onPressed: _next,
              trailing: _isLast ? null : const Icon(Icons.arrow_forward_rounded),
              child: Text(_isLast ? 'Get started' : 'Next'),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnBoardPage extends StatelessWidget {
  final OnBoardModel page;

  const _OnBoardPage({required this.page});

  @override
  Widget build(BuildContext context) {
    final sideways = context.screenWidth > context.screenHeight;

    final text = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: sideways ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        ShadcnText(
          page.text,
          variant: ShadcnTextVariant.h2,
          textAlign: sideways ? TextAlign.start : TextAlign.center,
        ),
        ShadcnGap.md,
        ShadcnText(
          page.description,
          variant: ShadcnTextVariant.lead,
          textAlign: sideways ? TextAlign.start : TextAlign.center,
        ),
      ],
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.pagePadding),
      child: sideways
          // Landscape / tablets: picture on the left, words on the right.
          ? Row(
              children: [
                Expanded(child: Center(child: Illustration(asset: page.image, maxSize: 360))),
                ShadcnGap.xl3,
                Expanded(child: Center(child: SingleChildScrollView(child: text))),
              ],
            )
          : Column(
              children: [
                Expanded(
                  child: Align(
                    alignment: const Alignment(0, 0.5),
                    child: Illustration(asset: page.image, maxSize: 340),
                  ),
                ),
                ShadcnGap.xl2,
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: Breakpoints.formMaxWidth),
                  child: text,
                ),
                ShadcnGap.lg,
              ],
            ),
    );
  }
}
