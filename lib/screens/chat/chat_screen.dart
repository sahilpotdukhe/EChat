import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echat/enums/view_state.dart';
import 'package:echat/models/message_model.dart';
import 'package:echat/models/user_model.dart';
import 'package:echat/providers/image_upload_provider.dart';
import 'package:echat/providers/user_provider.dart';
import 'package:echat/resources/auth_methods.dart';
import 'package:echat/resources/chat_firebase_methods.dart';
import 'package:echat/resources/firebase_storage_method.dart';
import 'package:echat/screens/call/pickup_layout.dart';
import 'package:echat/screens/chat/message_bubble.dart';
import 'package:echat/screens/chat/widgets/attachment_sheet.dart';
import 'package:echat/screens/chat/widgets/chat_composer.dart';
import 'package:echat/screens/chat/widgets/chat_parts.dart';
import 'package:echat/theme/app_colors.dart';
import 'package:echat/utils/call_utilities.dart';
import 'package:echat/utils/message_utils.dart';
import 'package:echat/utils/responsive.dart';
import 'package:echat/widgets/common/user_avatar.dart';
import 'package:echat/widgets/receiver_details.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_kit/shadcn_kit.dart';

class ChatScreen extends StatefulWidget {
  final UserModel receiver;

  const ChatScreen({super.key, required this.receiver});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatFirebaseMethods _chatFirebaseMethods = ChatFirebaseMethods();
  final FirebaseStorageMethod _firebaseStorageMethod = FirebaseStorageMethod();
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
  late final Stream<DocumentSnapshot> _receiverStream =
      AuthMethods().getUserStream(uid: widget.receiver.uid);

  /// Widest the messages and the typing bar get on tablets.
  static const double _maxChatWidth = 760;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    _messagesStream = _messagesQuery();
    _scrollController.addListener(_onScroll);
    _initializeSender();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot> _messagesQuery() => FirebaseFirestore.instance
      .collection("messages")
      .doc(_currentUserId)
      .collection(widget.receiver.uid)
      .orderBy("timestamp", descending: true)
      .limit(_messageLimit)
      .snapshots();

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
          title: ChatHeaderTitle(
            receiver: widget.receiver,
            receiverStream: _receiverStream,
            onTap: _sender == null ? null : _openProfile,
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
            const SizedBox(width: 6),
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
    final XFile? selectedImage = await ImagePicker().pickImage(source: source);
    // Picker closed without choosing: nothing to upload.
    if (selectedImage == null) return;
    setState(() => _uploadProgress = 0);
    _jumpToLatest();
    try {
      await _firebaseStorageMethod.uploadImage(
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
      await _firebaseStorageMethod.uploadAnyFile(
          pickedFiles.first, widget.receiver.uid, _currentUserId, imageUploadProvider, _onUploadProgress);
    } catch (e) {
      debugPrint('File upload failed: $e');
      _showError("Couldn't send the file. Please try again.");
    }
  }
}
