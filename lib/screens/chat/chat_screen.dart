import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echat/enums/view_state.dart';
import 'package:echat/models/contact_model.dart';
import 'package:echat/models/message_model.dart';
import 'package:echat/models/user_model.dart';
import 'package:echat/providers/image_upload_provider.dart';
import 'package:echat/providers/user_provider.dart';
import 'package:echat/resources/auth_methods.dart';
import 'package:echat/resources/chat_firebase_methods.dart';
import 'package:echat/resources/chat_media_uploader.dart';
import 'package:echat/resources/local_notifications.dart';
import 'package:echat/resources/media_compressor.dart';
import 'package:echat/resources/notification_service.dart';
import 'package:echat/screens/call/pickup_layout.dart';
import 'package:echat/screens/chat/message_bubble.dart';
import 'package:echat/screens/chat/widgets/attachment_sheet.dart';
import 'package:echat/screens/chat/widgets/chat_composer.dart';
import 'package:echat/screens/chat/widgets/chat_parts.dart';
import 'package:echat/screens/chat/widgets/delete_sheets.dart';
import 'package:echat/theme/app_colors.dart';
import 'package:echat/utils/call_utilities.dart';
import 'package:echat/utils/message_utils.dart';
import 'package:echat/utils/responsive.dart';
import 'package:echat/widgets/common/typing_watcher.dart';
import 'package:echat/widgets/common/user_avatar.dart';
import 'package:echat/widgets/receiver_details.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_kit/shadcn_kit.dart';

class ChatScreen extends StatefulWidget {
  final UserModel receiver;

  const ChatScreen({super.key, required this.receiver});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ChatFirebaseMethods _chatFirebaseMethods = ChatFirebaseMethods();
  final ChatMediaUploader _mediaUploader = ChatMediaUploader();
  final ScrollController _scrollController = ScrollController();

  // Loaded asynchronously in _initializeSender; null until then.
  UserModel? _sender;
  String _currentUserId = '';
  double _uploadProgress = 0.0;
  bool _showJumpToLatest = false;

  // Messages load newest-first, a page at a time; scrolling up loads more.
  static const int _pageSize = 30;
  int _messageLimit = _pageSize;
  int _loadedCount = 0;
  // Built once (and again only when loading more), not on every rebuild:
  // a new query per keystroke would re-subscribe to Firestore each time.
  late Stream<QuerySnapshot> _messagesStream;
  // My chat-list entry for them: says when they're typing to me.
  late final Stream<DocumentSnapshot> _myEntryStream = _chatFirebaseMethods.contactStream(
      myId: FirebaseAuth.instance.currentUser?.uid ?? '', peerId: widget.receiver.uid);

  // When I last told them I'm typing; null while I'm not.
  DateTime? _typingSentAt;
  static const Duration _typingRefresh = Duration(seconds: 3);

  late final Stream<DocumentSnapshot> _receiverStream =
      AuthMethods().getUserStream(uid: widget.receiver.uid);

  /// Widest the messages and the typing bar get on tablets.
  static const double _maxChatWidth = 760;

  // Messages from them already sent off to be marked read.
  final Set<String> _markedRead = {};
  bool _appInForeground = true;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    _messagesStream = _messagesQuery();
    _scrollController.addListener(_onScroll);
    _initializeSender();
    WidgetsBinding.instance.addObserver(this);
    _messageController.addListener(_onTextChanged);
    // No notifications for this chat while it's open, and clear any shown.
    LocalNotifications.openChatPeerId = widget.receiver.uid;
    LocalNotifications.dismissChat(widget.receiver.uid);
    // So the first message's notification isn't held up by a sleeping server.
    NotificationService.warmUp();
    if (_currentUserId.isNotEmpty) {
      _chatFirebaseMethods.clearUnread(myId: _currentUserId, peerId: widget.receiver.uid);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopTyping();
    if (LocalNotifications.openChatPeerId == widget.receiver.uid) LocalNotifications.openChatPeerId = null;
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // "typing…" for them while there's text in the box, refreshed every few
  // seconds (their side hides it 6 s after the last refresh).
  void _onTextChanged() {
    if (_currentUserId.isEmpty) return;
    if (_messageController.text.trim().isEmpty) {
      _stopTyping();
      return;
    }
    final now = DateTime.now();
    final last = _typingSentAt;
    if (last != null && now.difference(last) < _typingRefresh) return;
    _typingSentAt = now;
    _chatFirebaseMethods.setTyping(myId: _currentUserId, peerId: widget.receiver.uid, typing: true);
  }

  void _stopTyping() {
    if (_typingSentAt == null) return;
    _typingSentAt = null;
    _chatFirebaseMethods.setTyping(myId: _currentUserId, peerId: widget.receiver.uid, typing: false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final foreground = state == AppLifecycleState.resumed;
    // Leaving the app with text in the box isn't typing.
    if (!foreground) _stopTyping();
    if (foreground == _appInForeground) return;
    // Rebuilding re-checks for messages that arrived while away.
    setState(() => _appInForeground = foreground);
    if (foreground) LocalNotifications.openChatPeerId = widget.receiver.uid;
  }

  // Metadata changes too, so a message's clock turns into a tick as soon as
  // the server has it.
  Stream<QuerySnapshot> _messagesQuery() => FirebaseFirestore.instance
      .collection("messages")
      .doc(_currentUserId)
      .collection(widget.receiver.uid)
      .orderBy("timestamp", descending: true)
      .limit(_messageLimit)
      .snapshots(includeMetadataChanges: true);

  // Their messages on screen become "read" (blue ticks for them), but only
  // while this chat really is in front of me.
  void _markVisibleAsRead(List<QueryDocumentSnapshot> docs) {
    if (!_appInForeground || !(ModalRoute.of(context)?.isCurrent ?? false)) return;
    final peerId = widget.receiver.uid;
    final ids = <String>[
      for (final doc in docs)
        if (!_markedRead.contains(doc.id) && _needsRead(doc.data() as Map<String, dynamic>, peerId)) doc.id,
    ];
    if (ids.isEmpty) return;
    _markedRead.addAll(ids);
    _chatFirebaseMethods.markRead(myId: _currentUserId, peerId: peerId, messageIds: ids);
    _chatFirebaseMethods.clearUnread(myId: _currentUserId, peerId: peerId);
  }

  static bool _needsRead(Map<String, dynamic> data, String peerId) {
    final status = data['status'];
    return data['senderId'] == peerId && (status == MessageStatus.sent || status == MessageStatus.delivered);
  }

  void _onScroll() {
    final position = _scrollController.position;

    // The list is reversed: 0 is the newest message.
    final showJump = position.pixels > 400;
    if (showJump != _showJumpToLatest) setState(() => _showJumpToLatest = showJump);

    // The oldest loaded message is at maxScrollExtent. Fewer messages than
    // the limit means we already have the whole chat.
    final bool nearTop = position.pixels >= position.maxScrollExtent - 200;
    if (!nearTop || _loadedCount < _messageLimit) return;
    setState(() {
      _messageLimit += _pageSize;
      _messagesStream = _messagesQuery();
    });
  }

  void _jumpToLatest() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
  }

  void _showError(String text) {
    if (!mounted) return;
    showShadcnToast(context, title: text, variant: ShadcnToastVariant.destructive);
  }

  Future<void> _initializeSender() async {
    await Future.delayed(Duration.zero);
    if (!mounted) return;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.refreshUser();
    if (!mounted) return;
    if (userProvider.getUser != null) {
      setState(() => _sender = userProvider.getUser);
    } else {
      debugPrint('User is null');
    }
  }

  void _openProfile() {
    final me = _sender;
    if (me == null) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ReceiverDetails(receiverModel: widget.receiver, senderModel: me),
    ));
  }

  void _call(String callType) {
    final me = _sender;
    if (me == null) return;
    CallUtilities.dial(fromCaller: me, toReceiver: widget.receiver, context: context, callType: callType);
  }

  @override
  Widget build(BuildContext context) {
    final imageUploadProvider = Provider.of<ImageUploadProvider>(context);
    final uploading = imageUploadProvider.getViewState == ViewState.loading;
    final colors = context.colors;
    final side = ((context.screenWidth - _maxChatWidth) / 2).clamp(0.0, double.infinity);

    return PickupLayout(
      scaffold: Scaffold(
        backgroundColor: colors.chatBackground,
        appBar: AppBar(
          titleSpacing: 0,
          title: StreamBuilder<DocumentSnapshot>(
            stream: _myEntryStream,
            builder: (context, snapshot) {
              final data = snapshot.data?.data() as Map<String, dynamic>?;
              final typingAt = data == null ? null : ContactModel.fromMap(data).typingAt;
              return TypingWatcher(
                typingAt: typingAt,
                builder: (context, typing) => ChatHeaderTitle(
                  receiver: widget.receiver,
                  receiverStream: _receiverStream,
                  isTyping: typing,
                  onTap: _sender == null ? null : _openProfile,
                ),
              );
            },
          ),
          actions: [
            ShadcnButton(
              variant: ShadcnButtonVariant.ghost,
              size: ShadcnButtonSize.icon,
              tooltip: 'Voice call',
              semanticLabel: 'Voice call',
              onPressed: _sender == null ? null : () => _call('audioCall'),
              child: const Icon(Icons.call_outlined, size: 22),
            ),
            ShadcnButton(
              variant: ShadcnButtonVariant.ghost,
              size: ShadcnButtonSize.icon,
              tooltip: 'Video call',
              semanticLabel: 'Video call',
              onPressed: _sender == null ? null : () => _call('videoCall'),
              child: const Icon(Icons.videocam_outlined, size: 24),
            ),
            PopupMenuButton<String>(
              tooltip: 'More options',
              onSelected: (value) {
                if (value == 'delete') _deleteChat();
                if (value == 'profile') _openProfile();
              },
              itemBuilder: (_) => [
                if (_sender != null) const PopupMenuItem(value: 'profile', child: Text('View contact')),
                const PopupMenuItem(value: 'delete', child: Text('Delete chat')),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  _messages(side),
                  Positioned(
                    right: 16 + side,
                    bottom: 12,
                    child: AnimatedScale(
                      scale: _showJumpToLatest ? 1 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: ShadcnButton(
                        variant: ShadcnButtonVariant.outline,
                        size: ShadcnButtonSize.icon,
                        tooltip: 'Jump to latest',
                        semanticLabel: 'Jump to latest message',
                        style: const ShadcnButtonStyle(shape: CircleBorder()),
                        onPressed: _jumpToLatest,
                        child: const Icon(Icons.keyboard_arrow_down_rounded, size: 24),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (uploading)
              Padding(
                padding: EdgeInsets.only(left: side, right: side, bottom: 8),
                child: UploadBubble(progress: _uploadProgress),
              ),
            ResponsiveCenter(
              maxWidth: _maxChatWidth,
              child: ChatComposer(
                controller: _messageController,
                canSend: _sender != null,
                onSend: _sendMessage,
                onAttach: () => _attach(imageUploadProvider),
                onCamera: () => _pickImage(ImageSource.camera, imageUploadProvider),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _messages(double side) {
    return StreamBuilder<QuerySnapshot>(
      stream: _messagesStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ShadcnEmptyState(
            icon: Icons.cloud_off_rounded,
            title: 'Couldn\'t load messages',
            description: 'Check your internet connection and try again.',
            action: ShadcnButton(
              variant: ShadcnButtonVariant.outline,
              leading: const Icon(Icons.refresh_rounded),
              onPressed: () => setState(() => _messagesStream = _messagesQuery()),
              child: const Text('Retry'),
            ),
          );
        }
        if (snapshot.data == null) {
          return const Center(
            child: SizedBox.square(dimension: 28, child: CircularProgressIndicator(strokeWidth: 2.5)),
          );
        }
        final docs = snapshot.data!.docs;
        _loadedCount = docs.length;
        if (docs.isEmpty) return _emptyChat();

        final messages = [
          for (final doc in docs) MessageModel.fromMap(doc.data() as Map<String, dynamic>),
        ];
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _markVisibleAsRead(docs);
        });
        final bool hasOlder = docs.length >= _messageLimit;
        final DateTime now = DateTime.now();
        final senderName = widget.receiver.name.isEmpty ? 'EChat user' : widget.receiver.name;

        return LayoutBuilder(builder: (context, constraints) {
          final chatWidth = (constraints.maxWidth - side * 2).clamp(0.0, _maxChatWidth);
          final bubbleMaxWidth = (chatWidth * 0.78).clamp(0.0, 520.0);

          return ListView.builder(
            controller: _scrollController,
            reverse: true,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.only(left: side, right: side, top: 8, bottom: 10),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              // Newest-first: index + 1 is the older neighbour, index - 1 the newer.
              final message = messages[index];
              final time = message.timestamp.toDate();
              final older = index + 1 < messages.length ? messages[index + 1] : null;
              final newer = index > 0 ? messages[index - 1] : null;

              // Show a date chip where the day changes. The oldest loaded
              // message only gets one if there is nothing older to load.
              final bool startsNewDay = older == null
                  ? !hasOlder
                  : !MessageUtils.isSameDay(time, older.timestamp.toDate());
              bool groups(MessageModel? other) =>
                  other != null &&
                  MessageUtils.groupsWith(
                    senderA: message.senderId,
                    timeA: time,
                    senderB: other.senderId,
                    timeB: other.timestamp.toDate(),
                  );

              return Column(
                children: [
                  if (startsNewDay) DateChip(label: MessageUtils.chatDateLabel(time, now)),
                  MessageBubble(
                    message: message,
                    isMe: message.senderId == _currentUserId,
                    // Not on the server yet (offline): a clock instead of ticks.
                    isPending: docs[index].metadata.hasPendingWrites,
                    onLongPress: () => _showMessageActions(docs[index].id, message),
                    senderName: senderName,
                    maxWidth: bubbleMaxWidth,
                    groupedWithOlder: !startsNewDay && groups(older),
                    groupedWithNewer: groups(newer),
                  ),
                ],
              );
            },
          );
        });
      },
    );
  }

  Widget _emptyChat() {
    final receiver = widget.receiver;
    final firstName = receiver.name.trim().isEmpty ? 'them' : receiver.name.trim().split(RegExp(r'\s+')).first;
    return ShadcnEmptyState(
      illustration: Center(child: UserAvatar(name: receiver.name, imageUrl: receiver.profilePhoto, size: 88)),
      title: 'Say hi to $firstName',
      description: 'This is the start of your conversation. Messages, photos and files you share will show up here.',
      action: ShadcnButton(
        onPressed: _sender == null
            ? null
            : () {
                _messageController.text = 'Hi 👋';
                _sendMessage();
              },
        child: const Text('👋  Say hi'),
      ),
    );
  }

  void _sendMessage() {
    final me = _sender;
    // Keep the typed text if our profile hasn't loaded yet.
    if (me == null) return;
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    final message = MessageModel(
        senderId: me.uid,
        receiverId: widget.receiver.uid,
        type: 'text',
        message: text,
        timestamp: Timestamp.now(),
        photoUrl: '',
        thumbnailUrl: '',
        pdfUrl: '',
        pdfName: '');
    // Sending clears "typing…" on their side (see addMessagetoDb).
    _typingSentAt = null;
    _messageController.clear();
    _jumpToLatest();
    // Offline, the message shows straight away and is sent once back online;
    // only a real failure (e.g. rejected by the server) lands in catchError.
    // addMessagetoDb also asks the notification server to send the push.
    _chatFirebaseMethods.addMessagetoDb(message).catchError((Object e) {
      debugPrint('Message failed to send: $e');
      _showError("Message couldn't be sent: \"${_preview(text)}\"");
    });
  }

  Future<void> _showMessageActions(String messageId, MessageModel message) async {
    final isMe = message.senderId == _currentUserId;
    final action = await showMessageActionsSheet(
      context,
      canCopy: message.type == 'text' && message.message.isNotEmpty,
      canDeleteForEveryone: isMe && !message.isDeleted && !message.isCall,
    );
    if (action == null || !mounted) return;
    switch (action) {
      case MessageAction.copy:
        Clipboard.setData(ClipboardData(text: message.message));
        showShadcnToast(context, title: 'Message copied', variant: ShadcnToastVariant.success);
      case MessageAction.deleteForMe:
        _chatFirebaseMethods
            .deleteMessageForMe(myId: _currentUserId, peerId: widget.receiver.uid, messageId: messageId)
            .catchError((Object e) {
          debugPrint('Delete for me failed: $e');
          _showError("Couldn't delete the message. Please try again.");
        });
      case MessageAction.deleteForEveryone:
        _chatFirebaseMethods
            .deleteMessageForEveryone(
                myId: _currentUserId, peerId: widget.receiver.uid, messageId: messageId, message: message)
            .catchError((Object e) {
          debugPrint('Delete for everyone failed: $e');
          _showError("Couldn't delete the message. Please try again.");
        });
    }
  }

  Future<void> _deleteChat() async {
    final forEveryone = await showDeleteChatSheet(context, name: widget.receiver.name);
    if (forEveryone == null || !mounted) return;
    final navigator = Navigator.of(context);
    try {
      await _chatFirebaseMethods.deleteChat(
          myId: _currentUserId, peerId: widget.receiver.uid, forEveryone: forEveryone);
      if (!mounted) return;
      showShadcnToast(context, title: 'Chat deleted', variant: ShadcnToastVariant.success);
      navigator.pop();
    } catch (e) {
      debugPrint('Delete chat failed: $e');
      _showError("Couldn't delete the chat. Please try again.");
    }
  }

  String _preview(String text) => text.length > 30 ? '${text.substring(0, 30)}…' : text;

  void _onUploadProgress(double progress) {
    if (!mounted) return;
    setState(() => _uploadProgress = progress);
  }

  Future<void> _attach(ImageUploadProvider imageUploadProvider) async {
    final choice = await showAttachmentSheet(context);
    if (choice == null || !mounted) return;
    switch (choice) {
      case AttachmentChoice.gallery:
        await _pickImage(ImageSource.gallery, imageUploadProvider);
      case AttachmentChoice.camera:
        await _pickImage(ImageSource.camera, imageUploadProvider);
      case AttachmentChoice.video:
        await _selectFile(imageUploadProvider, FileType.video);
      case AttachmentChoice.pdf:
        await _selectFile(imageUploadProvider, FileType.custom, allowedExtensions: ['pdf']);
      case AttachmentChoice.document:
        await _selectFile(imageUploadProvider, FileType.any);
    }
  }

  Future<void> _pickImage(ImageSource source, ImageUploadProvider imageUploadProvider) async {
    // Shrunk while picking so it uploads (and loads) fast.
    final XFile? selectedImage = await ImagePicker().pickImage(
      source: source,
      maxWidth: MediaCompressor.maxPhotoSide,
      maxHeight: MediaCompressor.maxPhotoSide,
      imageQuality: MediaCompressor.photoQuality,
    );
    // Picker closed without choosing: nothing to upload.
    if (selectedImage == null) return;
    setState(() => _uploadProgress = 0);
    _jumpToLatest();
    try {
      await _mediaUploader.uploadImage(
          selectedImage, widget.receiver.uid, _currentUserId, imageUploadProvider, _onUploadProgress);
    } catch (e) {
      debugPrint('Image upload failed: $e');
      _showError("Couldn't send the photo. Please try again.");
    }
  }

  // The system file picker needs no storage permission.
  Future<void> _selectFile(ImageUploadProvider imageUploadProvider, FileType type,
      {List<String>? allowedExtensions}) async {
    final List<PlatformFile> pickedFiles =
        await FilePicker.pickFiles(type: type, allowedExtensions: allowedExtensions);
    // Picker closed without choosing: nothing to upload.
    if (pickedFiles.isEmpty) return;
    setState(() => _uploadProgress = 0);
    _jumpToLatest();
    try {
      await _mediaUploader.uploadAnyFile(
          pickedFiles.first, widget.receiver.uid, _currentUserId, imageUploadProvider, _onUploadProgress);
    } catch (e) {
      debugPrint('File upload failed: $e');
      _showError("Couldn't send the file. Please try again.");
    }
  }
}
