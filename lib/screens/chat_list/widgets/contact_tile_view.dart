import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echat/enums/user_state.dart';
import 'package:echat/models/contact_model.dart';
import 'package:echat/models/message_model.dart';
import 'package:echat/models/user_model.dart';
import 'package:echat/resources/auth_methods.dart';
import 'package:echat/resources/chat_firebase_methods.dart';
import 'package:echat/screens/chat/chat_screen.dart';
import 'package:echat/utils/message_utils.dart';
import 'package:echat/utils/utilities.dart';
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
            return ChatRow(
              user: user,
              lastMessage: last,
              isLoadingMessage: !messageSnapshot.hasData && !messageSnapshot.hasError,
              sentByMe: last?.senderId == widget.currentUserId,
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

  const ChatRow({
    super.key,
    required this.user,
    required this.lastMessage,
    required this.isLoadingMessage,
    required this.sentByMe,
  });

  @override
  Widget build(BuildContext context) {
    final last = lastMessage;

    String preview;
    if (last != null) {
      preview = MessageUtils.previewText(
        type: last.type,
        message: last.message,
        fileName: last.fileName.isNotEmpty ? last.fileName : last.pdfName,
      );
      if (sentByMe) preview = 'You: $preview';
    } else {
      preview = isLoadingMessage ? '' : 'Say hi 👋';
    }

    return ShadcnListTile(
      leading: UserAvatar(
        name: user.name,
        imageUrl: user.profilePhoto,
        size: 52,
        isOnline: Utils.numToState(user.state) == UserState.online,
      ),
      title: Text(user.name.isEmpty ? 'EChat user' : user.name),
      // Keep the message on a single line so every row has the same height.
      subtitle: Text(preview),
      trailing: last == null
          ? null
          : Text(
              MessageUtils.chatListTime(last.timestamp.toDate(), DateTime.now()),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ChatScreen(receiver: user)),
      ),
    );
  }
}
