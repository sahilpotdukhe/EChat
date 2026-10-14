import 'package:echat/resources/auth_methods.dart';
import 'package:echat/screens/home_screen.dart';
import 'package:echat/screens/sign_up_screen.dart';
import 'package:echat/theme/app_colors.dart';
import 'package:echat/utils/validators.dart';
import 'package:echat/widgets/auth_layout.dart';
import 'package:echat/widgets/common/busy_overlay.dart';
import 'package:echat/widgets/google_sign_in_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_kit/shadcn_kit.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  late final _authMethods = AuthMethods();

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isSendingReset = false;

  bool get _busy => _isLoading || _isGoogleLoading;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => HomeScreen()),
      (route) => false,
    );
  }

  Future<void> _signIn() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final user = await _authMethods.logInByEmail(_email.text.trim(), _password.text);
    if (!mounted) return;
    if (user != null) {
      await _authMethods.saveNotificationToken(user.uid);
      if (!mounted) return;
      _goHome();
      return;
    }
    setState(() => _isLoading = false);
    showShadcnAlertDialog(
      context,
      icon: ShadcnIconBadge(Icons.error_outline_rounded, color: context.shadcn.destructive),
      title: 'Couldn\'t sign you in',
      description: 'The email or password is incorrect. Check them and try again.',
      confirmLabel: 'Try again',
      cancelLabel: null,
    );
  }

  Future<void> _signInWithGoogle() async {
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

  Future<void> _resetPassword() async {
    final email = _email.text.trim();
    if (!Validators.isEmail(email)) {
      showShadcnAlertDialog(
        context,
        icon: const ShadcnIconBadge(Icons.info_outline_rounded),
        title: 'Reset your password',
        description: 'Type your account\'s email address in the email field above, '
            'then tap "Forgot password?" again.',
        confirmLabel: 'Got it',
        cancelLabel: null,
      );
      return;
    }
    setState(() => _isSendingReset = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      showShadcnAlertDialog(
        context,
        icon: ShadcnIconBadge(Icons.mark_email_read_outlined, color: context.colors.success),
        title: 'Check your inbox',
        description: 'We sent a password reset link to $email. '
            'If you don\'t see it, look in your spam folder.',
        confirmLabel: 'OK',
        cancelLabel: null,
      );
    } catch (e) {
      debugPrint('$e');
      if (!mounted) return;
      showShadcnToast(context, title: 'Couldn\'t send the reset email. Please try again.', variant: ShadcnToastVariant.destructive);
    } finally {
      if (mounted) setState(() => _isSendingReset = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BusyOverlay(
      visible: _isGoogleLoading,
      message: 'Signing in with Google…',
      hint: 'Choose your account in the window that opens.',
      child: AuthLayout(
        title: 'Welcome back',
        subtitle: 'Sign in to pick up your conversations.',
        illustration: 'assets/login.png',
        form: AutofillGroup(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                ShadcnPasswordInput(
                  controller: _password,
                  label: 'Password',
                  placeholder: 'Your password',
                  leading: const Icon(Icons.lock_outline_rounded),
                  textInputAction: TextInputAction.done,
                  validator: Validators.requiredPassword,
                  autovalidateMode: AutovalidateMode.onUserInteractionIfError,
                  style: authInputStyle,
                  onSubmitted: (_) => _busy ? null : _signIn(),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: ShadcnButton(
                    variant: ShadcnButtonVariant.link,
                    loading: _isSendingReset,
                    onPressed: _busy ? null : _resetPassword,
                    child: const Text('Forgot password?'),
                  ),
                ),
                ShadcnGap.sm,
                ShadcnButton(
                  size: ShadcnButtonSize.lg,
                  fullWidth: true,
                  loading: _isLoading,
                  onPressed: _isGoogleLoading ? null : _signIn,
                  child: const Text('Sign in'),
                ),
                ShadcnGap.xl2,
                const ShadcnSeparator(label: 'or'),
                ShadcnGap.xl2,
                GoogleSignInButton(onPressed: _busy ? null : _signInWithGoogle),
              ],
            ),
          ),
        ),
        footer: AuthFooterLink(
          question: 'New to EChat?',
          action: 'Create an account',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SignUpScreen()),
          ),
        ),
      ),
    );
  }
}
