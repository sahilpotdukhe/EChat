import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echat/models/contact_model.dart';
import 'package:echat/models/message_model.dart';
import 'package:echat/models/user_model.dart';
import 'package:echat/resources/auth_methods.dart';
import 'package:echat/resources/chat_firebase_methods.dart';
import 'package:echat/screens/chat/chat_screen.dart';
import 'package:echat/utils/message_utils.dart';
import 'package:echat/utils/presence.dart';
import 'package:echat/theme/app_colors.dart';
import 'package:echat/screens/chat/widgets/delete_sheets.dart';
import 'package:echat/screens/chat/widgets/message_extras.dart';
import 'package:echat/widgets/common/skeleton.dart';
import 'package:echat/widgets/common/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_kit/shadcn_kit.dart';

/// One conversation in the chat list: the other person's photo (with an
/// online dot), name, last message preview and its time.
class ContactTileView extends StatefulWidget {
  final ContactModel contactModel;
  final String currentUserId;

  const ContactTileView({super.key, required this.contactModel, required this.currentUserId});

  @override
  State<ContactTileView> createState() => _ContactTileViewState();
}

class _ContactTileViewState extends State<ContactTileView> {
  Future<void> _deleteChat(UserModel user) async {
    final forEveryone = await showDeleteChatSheet(context, name: user.name);
    if (forEveryone == null || !mounted) return;
    try {
      await ChatFirebaseMethods()
          .deleteChat(myId: widget.currentUserId, peerId: user.uid, forEveryone: forEveryone);
      if (mounted) showShadcnToast(context, title: 'Chat deleted', variant: ShadcnToastVariant.success);
    } catch (e) {
      debugPrint('Delete chat failed: $e');
      if (mounted) {
        showShadcnToast(context,
            title: 'Couldn\'t delete the chat. Please try again.', variant: ShadcnToastVariant.destructive);
      }
    }
  }

  // Created once, so rebuilding the list doesn't re-open the streams.
  late final Stream<DocumentSnapshot> _userStream =
      AuthMethods().getUserStream(uid: widget.contactModel.uid);
  late final Stream<QuerySnapshot> _lastMessageStream = ChatFirebaseMethods()
      .fetchLastMessageBetween(senderId: widget.currentUserId, receiverId: widget.contactModel.uid);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _userStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          // Profile no longer exists or can't be read: hide the row rather
          // than spin forever.
          if (snapshot.hasError) return const SizedBox.shrink();
          return const SkeletonListTile();
        }
        final data = snapshot.data!.data() as Map<String, dynamic>?;
        if (data == null) return const SizedBox.shrink();
        final user = UserModel.fromMap(data);

        return StreamBuilder<QuerySnapshot>(
          stream: _lastMessageStream,
          builder: (context, messageSnapshot) {
            final docs = messageSnapshot.data?.docs ?? const [];
            final MessageModel? last = docs.isEmpty
                ? null
                : MessageModel.fromMap(docs.first.data() as Map<dynamic, dynamic>);
            return ValueListenableBuilder<DateTime>(
              // Re-checks the online dot every 30 s.
              valueListenable: Presence.clock,
              builder: (context, _, __) => ChatRow(
                user: user,
                lastMessage: last,
                isLoadingMessage: !messageSnapshot.hasData && !messageSnapshot.hasError,
                sentByMe: last?.senderId == widget.currentUserId,
                unreadCount: widget.contactModel.unreadCount,
                isOnline: Presence.isOnline(user, DateTime.now()),
                onLongPress: () => _deleteChat(user),
              ),
            );
          },
        );
      },
    );
  }
}

/// The visible row, given already-loaded data.
class ChatRow extends StatelessWidget {
  final UserModel user;
  final MessageModel? lastMessage;
  final bool isLoadingMessage;
  final bool sentByMe;
  final int unreadCount;
  final bool isOnline;
  final VoidCallback? onLongPress;

  const ChatRow({
    super.key,
    required this.user,
    required this.lastMessage,
    required this.isLoadingMessage,
    required this.sentByMe,
    this.unreadCount = 0,
    this.isOnline = false,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final last = lastMessage;
    final shadcn = context.shadcn;
    final colors = context.colors;
    final hasUnread = unreadCount > 0;

    String preview;
    if (last != null) {
      preview = MessageUtils.previewText(
        type: last.type,
        message: last.message,
        fileName: last.fileName.isNotEmpty ? last.fileName : last.pdfName,
        callType: last.callType,
        sentByMe: sentByMe,
      );
      // Deleted messages and calls already say who; others get "You:".
      if (sentByMe && !last.isDeleted && !last.isCall) preview = 'You: $preview';
    } else {
      preview = isLoadingMessage ? '' : 'Say hi 👋';
    }

    final name = user.name.isEmpty ? 'EChat user' : user.name;
    final time = last == null ? null : MessageUtils.chatListTime(last.timestamp.toDate(), DateTime.now());

    return ShadcnListTile(
      leading: UserAvatar(name: user.name, imageUrl: user.profilePhoto, size: 52, isOnline: isOnline),
      title: Text(name),
      // Keep the message on a single line so every row has the same height.
      subtitle: Row(
        children: [
          if (sentByMe && last != null && !last.isDeleted) ...[
            MessageTicks(status: last.status, pending: false, color: shadcn.mutedForeground),
            const SizedBox(width: 3),
          ],
          Flexible(
            child: Text(
              preview,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: hasUnread ? TextStyle(color: shadcn.foreground, fontWeight: FontWeight.w600) : null,
            ),
          ),
        ],
      ),
      trailing: time == null && !hasUnread
          ? null
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (time != null)
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w500,
                      color: hasUnread ? colors.success : null,
                    ),
                  ),
                if (hasUnread) ...[
                  const SizedBox(height: 4),
                  Container(
                    constraints: const BoxConstraints(minWidth: 20),
                    height: 20,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: colors.success, borderRadius: BorderRadius.circular(10)),
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ],
            ),
      semanticLabel: [
        name,
        if (isOnline) 'online',
        if (hasUnread) '$unreadCount unread',
        if (preview.isNotEmpty) preview,
        if (time != null) time,
      ].join(', '),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ChatScreen(receiver: user)),
      ),
      onLongPress: onLongPress,
    );
  }
}
