import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echat/models/user_model.dart';
import 'package:echat/resources/auth_methods.dart';
import 'package:echat/theme/app_colors.dart';
import 'package:echat/utils/call_utilities.dart';
import 'package:echat/widgets/common/user_avatar.dart';
import 'package:echat/widgets/common/info_section.dart';
import 'package:echat/widgets/full_image_widget.dart';
import 'package:echat/utils/presence.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_kit/shadcn_kit.dart';
import 'package:url_launcher/url_launcher.dart';

/// Another person's profile, opened from a chat: photo, name, online state,
/// quick actions (message, voice and video call) and their contact details.
class ReceiverDetails extends StatefulWidget {
  final UserModel receiverModel;
  final UserModel senderModel;

  /// Where live profile updates come from. Defaults to the person's
  /// Firestore profile; tests pass their own.
  final Stream<DocumentSnapshot>? userStream;

  const ReceiverDetails({
    super.key,
    required this.receiverModel,
    required this.senderModel,
    this.userStream,
  });

  @override
  State<ReceiverDetails> createState() => _ReceiverDetailsState();
}

class _ReceiverDetailsState extends State<ReceiverDetails> {
  // Live, so the online badge and any profile edits show while open.
  late final Stream<DocumentSnapshot> _userStream =
      widget.userStream ?? AuthMethods().getUserStream(uid: widget.receiverModel.uid);

  void _call(UserModel receiver, String callType) {
    CallUtilities.dial(
      fromCaller: widget.senderModel,
      toReceiver: receiver,
      context: context,
      callType: callType,
    );
  }

  Future<void> _launch(Uri uri, String failure) async {
    var opened = false;
    try {
      opened = await launchUrl(uri);
    } catch (_) {
      // Reported below.
    }
    if (!opened && mounted) {
      showShadcnToast(context, title: failure, variant: ShadcnToastVariant.destructive);
    }
  }

  void _copy(String label, String value) {
    HapticFeedback.selectionClick();
    Clipboard.setData(ClipboardData(text: value));
    showShadcnToast(context, title: '$label copied', variant: ShadcnToastVariant.success);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _userStream,
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final user = data == null ? widget.receiverModel : UserModel.fromMap(data);
        return Scaffold(
          appBar: AppBar(),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(ShadcnSpacing.lg, 0, ShadcnSpacing.lg, ShadcnSpacing.xl3),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  children: [
                    _header(user),
                    ShadcnGap.xl2,
                    _actions(user),
                    ShadcnGap.xl2,
                    _details(user),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _header(UserModel user) {
    final colors = context.colors;
    final online = Presence.isOnline(user, DateTime.now());
    final name = user.name.isEmpty ? 'EChat user' : user.name;
    final heroTag = 'avatar_${user.uid}';
    final hasPhoto = user.profilePhoto.isNotEmpty;

    return Column(
      children: [
        Hero(
          tag: heroTag,
          child: UserAvatar(
            name: user.name,
            imageUrl: user.profilePhoto,
            size: 112,
            onTap: !hasPhoto
                ? null
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
        if (online) ...[
          ShadcnGap.md,
          ShadcnBadge(
            variant: ShadcnBadgeVariant.outline,
            style: ShadcnBadgeStyle(
              foregroundColor: colors.success,
              borderColor: colors.success.withValues(alpha: 0.4),
              backgroundColor: colors.success.withValues(alpha: 0.08),
            ),
            child: const Text('● Online'),
          ),
        ],
      ],
    );
  }

  Widget _actions(UserModel user) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Message',
            // Opened from the chat, so going back is going to the chat.
            onTap: () => Navigator.of(context).maybePop(),
          ),
        ),
        ShadcnGap.md,
        Expanded(
          child: _ActionButton(icon: Icons.call_outlined, label: 'Voice', onTap: () => _call(user, 'audioCall')),
        ),
        ShadcnGap.md,
        Expanded(
          child: _ActionButton(icon: Icons.videocam_outlined, label: 'Video', onTap: () => _call(user, 'videoCall')),
        ),
      ],
    );
  }

  Widget _details(UserModel user) {
    final hasCopyable = user.email.isNotEmpty || user.phoneNumber.isNotEmpty;
    return InfoSection(
      title: 'Details',
      footer: hasCopyable ? 'Tip: press and hold a detail to copy it.' : null,
      children: [
        if (user.email.isNotEmpty)
          InfoRow(
            icon: Icons.mail_outline_rounded,
            title: user.email,
            subtitle: 'Email',
            onTap: () => _launch(Uri(scheme: 'mailto', path: user.email), 'No email app found'),
            onLongPress: () => _copy('Email', user.email),
            semanticLabel: 'Email, ${user.email}. Double tap to open, long press to copy',
          ),
        if (user.phoneNumber.isNotEmpty)
          InfoRow(
            icon: Icons.phone_outlined,
            title: user.phoneNumber,
            subtitle: 'Phone',
            onTap: () => _launch(Uri(scheme: 'tel', path: user.phoneNumber), 'Couldn\'t start a phone call'),
            onLongPress: () => _copy('Phone number', user.phoneNumber),
            semanticLabel: 'Phone, ${user.phoneNumber}. Double tap to call, long press to copy',
          ),
        if (user.gender.isNotEmpty)
          InfoRow(
            icon: Icons.person_outline_rounded,
            title: user.gender[0].toUpperCase() + user.gender.substring(1),
            subtitle: 'Gender',
          ),
      ],
    );
  }
}

/// A square-ish card with an icon above a label, for the quick actions.
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = context.shadcn;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: ShadcnCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            Icon(icon, color: t.primary, size: 24),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.foreground)),
          ],
        ),
      ),
    );
  }
}
