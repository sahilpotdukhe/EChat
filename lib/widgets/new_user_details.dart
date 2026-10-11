import 'package:echat/models/user_model.dart';
import 'package:echat/providers/user_provider.dart';
import 'package:echat/resources/auth_methods.dart';
import 'package:echat/utils/theme_preference.dart';
import 'package:echat/widgets/common/info_section.dart';
import 'package:echat/widgets/common/user_avatar.dart';
import 'package:echat/widgets/edit_profile.dart';
import 'package:echat/widgets/full_image_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_kit/shadcn_kit.dart';

/// The Profile tab: your photo and details, appearance (System / Light /
/// Dark), editing your profile and logging out.
class NewUserDetails extends StatefulWidget {
  const NewUserDetails({super.key});

  @override
  State<NewUserDetails> createState() => _NewUserDetailsState();
}

class _NewUserDetailsState extends State<NewUserDetails> {
  bool _loggingOut = false;

  Future<void> _logOut() async {
    final confirmed = await showShadcnAlertDialog(
      context,
      title: 'Log out of EChat?',
      description: 'You\'ll stop getting message and call notifications on this phone until you log back in.',
      confirmLabel: 'Log out',
      destructive: true,
    );
    if (confirmed != true || !mounted) return;
    setState(() => _loggingOut = true);
    try {
      await AuthMethods().logOut(context);
    } catch (e) {
      debugPrint('Logout failed: $e');
      if (mounted) {
        setState(() => _loggingOut = false);
        showShadcnToast(context, title: 'Couldn\'t log out. Please try again.', variant: ShadcnToastVariant.destructive);
      }
    }
  }

  void _setThemeMode(String value) {
    final mode = ThemeMode.values.byName(value);
    ShadcnThemeController.of(context).setMode(mode);
    ThemePreference.save(mode);
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).getUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.only(right: ShadcnSpacing.sm),
              child: ShadcnButton(
                variant: ShadcnButtonVariant.ghost,
                leading: const Icon(Icons.edit_outlined),
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditProfile())),
                child: const Text('Edit'),
              ),
            ),
        ],
      ),
      body: user == null
          ? const Center(child: SizedBox.square(dimension: 28, child: CircularProgressIndicator(strokeWidth: 2.5)))
          : RefreshIndicator(
              onRefresh: () => Provider.of<UserProvider>(context, listen: false).refreshUser(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(ShadcnSpacing.lg, ShadcnSpacing.sm, ShadcnSpacing.lg, ShadcnSpacing.xl3),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _header(user),
                        ShadcnGap.xl2,
                        InfoSection(
                          title: 'Account',
                          children: [
                            InfoRow(icon: Icons.mail_outline_rounded, title: user.email, subtitle: 'Email'),
                            InfoRow(
                              icon: Icons.phone_outlined,
                              title: user.phoneNumber.isEmpty ? 'Add your phone number' : user.phoneNumber,
                              subtitle: 'Phone',
                              onTap: user.phoneNumber.isEmpty ? _openEdit : null,
                            ),
                            if (user.gender.isNotEmpty)
                              InfoRow(
                                icon: Icons.person_outline_rounded,
                                title: user.gender[0].toUpperCase() + user.gender.substring(1),
                                subtitle: 'Gender',
                              ),
                          ],
                        ),
                        ShadcnGap.xl2,
                        _appearance(),
                        ShadcnGap.xl3,
                        ShadcnButton(
                          variant: ShadcnButtonVariant.outline,
                          size: ShadcnButtonSize.lg,
                          fullWidth: true,
                          loading: _loggingOut,
                          foregroundColor: context.shadcn.destructive,
                          leading: const Icon(Icons.logout_rounded),
                          onPressed: _logOut,
                          child: const Text('Log out'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  void _openEdit() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditProfile()));

  Widget _header(UserModel user) {
    final name = user.name.isEmpty ? 'EChat user' : user.name;
    final heroTag = 'avatar_${user.uid}';
    return Column(
      children: [
        Hero(
          tag: heroTag,
          child: UserAvatar(
            name: user.name,
            imageUrl: user.profilePhoto,
            size: 104,
            onTap: user.profilePhoto.isEmpty
                ? _openEdit
                : () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => FullImageWidget(imageUrl: user.profilePhoto, heroTag: heroTag, title: name),
                    )),
          ),
        ),
        ShadcnGap.lg,
        ShadcnText(name, variant: ShadcnTextVariant.h3, textAlign: TextAlign.center, maxLines: 2),
        if (user.username.isNotEmpty) ...[
          ShadcnGap.xs,
          ShadcnText(user.username.replaceFirst('echat:', '@'), variant: ShadcnTextVariant.lead),
        ],
      ],
    );
  }

  Widget _appearance() {
    final controller = ShadcnThemeController.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: ShadcnText(
            'APPEARANCE',
            variant: ShadcnTextVariant.muted,
            style: const ShadcnTextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8),
          ),
        ),
        ShadcnTabs(
          fullWidth: true,
          contentSpacing: 0,
          initialValue: controller.mode.name,
          onChanged: _setThemeMode,
          items: const [
            ShadcnTabItem(value: 'system', label: 'System', icon: Icon(Icons.brightness_auto_outlined, size: 16), content: SizedBox.shrink()),
            ShadcnTabItem(value: 'light', label: 'Light', icon: Icon(Icons.light_mode_outlined, size: 16), content: SizedBox.shrink()),
            ShadcnTabItem(value: 'dark', label: 'Dark', icon: Icon(Icons.dark_mode_outlined, size: 16), content: SizedBox.shrink()),
          ],
        ),
      ],
    );
  }
}
