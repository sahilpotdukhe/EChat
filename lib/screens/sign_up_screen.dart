import 'dart:async';

import 'package:echat/resources/auth_methods.dart';
import 'package:echat/screens/home_screen.dart';
import 'package:echat/theme/app_colors.dart';
import 'package:echat/utils/validators.dart';
import 'package:echat/widgets/auth_layout.dart';
import 'package:echat/widgets/common/busy_overlay.dart';
import 'package:echat/widgets/google_sign_in_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_kit/shadcn_kit.dart';

const _defaultProfilePic =
    'https://firebasestorage.googleapis.com/v0/b/echat-888ef.appspot.com/o/user.jpg?alt=media&token=6f598b3e-9c10-49ee-8a68-49468b32bddf';

enum _Step { form, verifying, verified }

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _mobile = TextEditingController();
  late final _authMethods = AuthMethods();

  _Step _step = _Step.form;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isResending = false;
  bool _checking = false;
  Timer? _timer;

  bool get _busy => _isLoading || _isGoogleLoading;

  @override
  void dispose() {
    _timer?.cancel();
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _mobile.dispose();
    super.dispose();
  }

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => HomeScreen()),
      (route) => false,
    );
  }

  Future<void> _createAccount() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final user = await _authMethods.createAccountbyEmail(_email.text.trim(), _password.text, context);
    if (!mounted) return;
    if (user == null) {
      setState(() => _isLoading = false);
      showShadcnAlertDialog(
        context,
        icon: ShadcnIconBadge(Icons.error_outline_rounded, color: context.shadcn.destructive),
        title: 'Couldn\'t create your account',
        description: '${_email.text.trim()} may already be registered. '
            'Try signing in instead, or use a different email.',
        confirmLabel: 'Try again',
        cancelLabel: 'Go to sign in',
      ).then((tryAgain) {
        if (tryAgain == false && mounted) Navigator.of(context).maybePop();
      });
      return;
    }

    try {
      await user.sendEmailVerification();
    } catch (e) {
      debugPrint('$e');
    }
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _step = _Step.verifying;
    });
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _checkEmailVerified());
  }

  Future<void> _checkEmailVerified() async {
    // A slow network can make checks overlap; only run one at a time.
    if (_checking) return;
    _checking = true;
    try {
      final current = FirebaseAuth.instance.currentUser;
      if (current == null) return;
      await current.reload();
      if (!(FirebaseAuth.instance.currentUser?.emailVerified ?? false)) return;

      _timer?.cancel();
      await _authMethods.setUserProfile(
        name: _name.text.trim(),
        email: _email.text.trim(),
        profilePic: _defaultProfilePic,
        authType: 'emailAuth',
        mobilenumber: _mobile.text.trim(),
      );
      if (!mounted) return;
      setState(() => _step = _Step.verified);
      await Future.delayed(const Duration(milliseconds: 1400));
      if (!mounted) return;
      _goHome();
    } catch (e) {
      debugPrint('$e');
    } finally {
      _checking = false;
    }
  }

  Future<void> _resendEmail() async {
    setState(() => _isResending = true);
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      if (mounted) showShadcnToast(context, title: 'Verification email sent again.', variant: ShadcnToastVariant.success);
    } catch (e) {
      debugPrint('$e');
      if (mounted) {
        showShadcnToast(context, title: 'Please wait a minute before asking for another email.', variant: ShadcnToastVariant.destructive);
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _signUpWithGoogle() async {
    setState(() => _isGoogleLoading = true);
    try {
      final googleProvider = Provider.of<GoogleSignInProvider>(context, listen: false);
      final signedIn = await googleProvider.googleLogin(context);
      if (!mounted) return;
      if (signedIn == true) {
        _goHome();
        return;
      }
      // null means the user closed the Google picker: no error to show.
      setState(() => _isGoogleLoading = false);
    } on GoogleSignInFailure catch (e) {
      if (!mounted) return;
      setState(() => _isGoogleLoading = false);
      showShadcnToast(context, title: e.message, variant: ShadcnToastVariant.destructive);
    } catch (e) {
      debugPrint('$e');
      if (!mounted) return;
      setState(() => _isGoogleLoading = false);
      showShadcnToast(context, title: 'Google sign-in failed. Please try again.', variant: ShadcnToastVariant.destructive);
    }
  }

  @override
  Widget build(BuildContext context) {
    final verifying = _step != _Step.form;
    return PopScope(
      // Leaving mid-verification stops the background check.
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _timer?.cancel();
      },
      child: BusyOverlay(
        visible: _isGoogleLoading,
        message: 'Signing in with Google…',
        hint: 'Choose your account in the window that opens.',
        child: AuthLayout(
          showBack: true,
          title: verifying ? 'Check your inbox' : 'Create your account',
          subtitle: verifying
              ? 'One quick step to keep your account safe.'
              : 'It only takes a minute to start chatting.',
          illustration: 'assets/second.png',
          panelTitle: 'Your people, one tap away.',
          form: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: verifying ? _verifyPanel(context) : _form(),
          ),
          footer: verifying
              ? null
              : AuthFooterLink(
                  question: 'Already have an account?',
                  action: 'Sign in',
                  onTap: () => Navigator.of(context).maybePop(),
                ),
        ),
      ),
    );
  }

  Widget _form() {
    return AutofillGroup(
      key: const ValueKey('form'),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ShadcnInput(
              controller: _name,
              label: 'Full name',
              placeholder: 'Alex Johnson',
              leading: const Icon(Icons.person_outline_rounded),
              keyboardType: TextInputType.name,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              validator: Validators.name,
              autovalidateMode: AutovalidateMode.onUserInteractionIfError,
              style: authInputStyle,
            ),
            ShadcnGap.lg,
            ShadcnInput(
              controller: _email,
              label: 'Email',
              placeholder: 'you@example.com',
              leading: const Icon(Icons.mail_outline_rounded),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              autocorrect: false,
              validator: Validators.email,
              autovalidateMode: AutovalidateMode.onUserInteractionIfError,
              style: authInputStyle,
            ),
            ShadcnGap.lg,
            ShadcnInput(
              controller: _mobile,
              label: 'Phone number',
              placeholder: '10-digit mobile number',
              leading: const Icon(Icons.phone_outlined),
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.telephoneNumberNational],
              maxLength: 10,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: Validators.phone,
              autovalidateMode: AutovalidateMode.onUserInteractionIfError,
              style: authInputStyle,
            ),
            ShadcnGap.lg,
            ShadcnPasswordInput(
              controller: _password,
              label: 'Password',
              placeholder: 'Create a strong password',
              helperText: Validators.passwordRules,
              leading: const Icon(Icons.lock_outline_rounded),
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              validator: Validators.newPassword,
              autovalidateMode: AutovalidateMode.onUserInteractionIfError,
              style: authInputStyle,
              onSubmitted: (_) => _busy ? null : _createAccount(),
            ),
            ShadcnGap.xl2,
            ShadcnButton(
              size: ShadcnButtonSize.lg,
              fullWidth: true,
              loading: _isLoading,
              onPressed: _isGoogleLoading ? null : _createAccount,
              child: const Text('Create account'),
            ),
            ShadcnGap.xl2,
            const ShadcnSeparator(label: 'or'),
            ShadcnGap.xl2,
            GoogleSignInButton(
              label: 'Sign up with Google',
              onPressed: _busy ? null : _signUpWithGoogle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _verifyPanel(BuildContext context) {
    final colors = context.colors;
    final shadcn = context.shadcn;
    final verified = _step == _Step.verified;

    return ShadcnCard(
      key: const ValueKey('verify'),
      padding: const EdgeInsets.all(ShadcnSpacing.xl2),
      child: Column(
        children: [
          SizedBox(
            height: 110,
            child: verified
                ? Icon(Icons.verified_rounded, size: 80, color: colors.success)
                : Lottie.asset('assets/email.json'),
          ),
          ShadcnGap.md,
          if (verified)
            const ShadcnText('Email verified!', variant: ShadcnTextVariant.h4, textAlign: TextAlign.center)
          else ...[
            ShadcnText(
              'We sent a verification link to',
              textAlign: TextAlign.center,
              style: ShadcnTextStyle(color: shadcn.mutedForeground),
            ),
            ShadcnGap.xs,
            ShadcnText(
              _email.text.trim(),
              variant: ShadcnTextVariant.large,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ],
          ShadcnGap.lg,
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: verified ? colors.success : shadcn.primary),
              ),
              ShadcnGap.md,
              Flexible(
                child: ShadcnText(
                  verified ? 'Taking you in…' : 'Waiting for you to tap the link…',
                  variant: ShadcnTextVariant.muted,
                ),
              ),
            ],
          ),
          if (!verified) ...[
            ShadcnGap.xl2,
            const ShadcnText(
              'Can\'t find it? Check your spam folder or send it again.',
              variant: ShadcnTextVariant.muted,
              textAlign: TextAlign.center,
            ),
            ShadcnGap.md,
            ShadcnButton(
              variant: ShadcnButtonVariant.outline,
              size: ShadcnButtonSize.lg,
              fullWidth: true,
              loading: _isResending,
              onPressed: _resendEmail,
              leading: const Icon(Icons.refresh_rounded),
              child: const Text('Resend email'),
            ),
          ],
        ],
      ),
    );
  }
}
