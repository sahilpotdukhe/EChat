import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echat/providers/user_provider.dart';
import 'package:echat/resources/chat_firebase_methods.dart';
import 'package:echat/resources/firebase_storage_method.dart';
import 'package:echat/screens/call/pickup_layout.dart';
import 'package:echat/screens/chat_list/widgets/chat_list_widgets.dart';
import 'package:echat/screens/chat/chat_quiet_box.dart';
import 'package:echat/screens/chat/message_bubble.dart';
import 'package:echat/utils/call_utilities.dart';
import 'package:echat/utils/message_utils.dart';
import 'package:echat/utils/scale_utils.dart';
import 'package:echat/widgets/receiver_details.dart';
import 'package:echat/enums/view_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:echat/models/message_model.dart';
import 'package:echat/models/user_model.dart';
import 'package:echat/providers/image_upload_provider.dart';
import 'package:echat/utils/universal_variables.dart';
import 'package:echat/widgets/modal_tile.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

class ChatScreen extends StatefulWidget {
  final UserModel receiver;

  const ChatScreen({super.key, required this.receiver});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  TextEditingController messageController = TextEditingController();
  late UserProvider userProvider;
  bool isWriting = false;
  // Loaded asynchronously in initializeSender; null until then.
  UserModel? sender;
  String _currentUserId = '';
  ChatFirebaseMethods chatFirebaseMethods = ChatFirebaseMethods();
  FirebaseStorageMethod firebaseStorageMethod = FirebaseStorageMethod();
  double uploadProgress = 0.0;

  // Messages load newest-first, a page at a time; scrolling up loads more.
  static const int _pageSize = 30;
  int _messageLimit = _pageSize;
  int _loadedCount = 0;
  // Built once (and again only when loading more), not on every rebuild:
  // a new query per keystroke would re-subscribe to Firestore each time.
  late Stream<QuerySnapshot> _messagesStream;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    _messagesStream = _messagesQuery();
    _scrollController.addListener(_loadMoreIfAtTop);
    initializeSender();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    messageController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot> _messagesQuery() => FirebaseFirestore.instance
      .collection("messages")
      .doc(_currentUserId)
      .collection(widget.receiver.uid)
      .orderBy("timestamp", descending: true)
      .limit(_messageLimit)
      .snapshots();

  // The list is reversed, so the oldest loaded message is at maxScrollExtent.
  void _loadMoreIfAtTop() {
    final position = _scrollController.position;
    final bool nearTop = position.pixels >= position.maxScrollExtent - 200;
    // Fewer messages than the limit means we already have the whole chat.
    if (!nearTop || _loadedCount < _messageLimit) return;
    setState(() {
      _messageLimit += _pageSize;
      _messagesStream = _messagesQuery();
    });
  }

  void _showError(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> initializeSender() async {
    await Future.delayed(Duration.zero);
    if (!mounted) return;
    userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.refreshUser();
    if (!mounted) return;
    if (userProvider.getUser != null) {
      setState(() {
        sender = userProvider.getUser;
      });
    } else {
      debugPrint('User is null');
    }
  }

  @override
  Widget build(BuildContext context) {
    ScaleUtils.init(context);
    ImageUploadProvider imageUploadProvider =
        Provider.of<ImageUploadProvider>(context);
    return PickupLayout(
      scaffold: Scaffold(
        backgroundColor: Colors.black,
        appBar: CustomAppBar(
          title: InkWell(
              onTap: () {
                final me = sender;
                if (me == null) return;
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ReceiverDetails(
                              receiverModel: widget.receiver,
                              senderModel: me,
                            )));
              },
              child: Text(
                widget.receiver.name,
                style: TextStyle(
                    color: Colors.white, fontSize: 16 * ScaleUtils.scaleFactor),
              )),
          actions: [
            IconButton(
                onPressed: sender == null
                    ? null
                    : () {
                        CallUtilities.dial(
                            fromCaller: sender!,
                            toReceiver: widget.receiver,
                            context: context,
                            callType: 'audioCall');
                      },
                icon: Icon(
                  Icons.phone,
                  color: Colors.white,
                )),
            IconButton(
                onPressed: sender == null
                    ? null
                    : () {
                        CallUtilities.dial(
                            fromCaller: sender!,
                            toReceiver: widget.receiver,
                            context: context,
                            callType: 'videoCall');
                      },
                icon: Icon(
                  Icons.video_call,
                  color: Colors.white,
                )),
          ],
          leading: InkWell(
            onTap: () {
              final me = sender;
              if (me == null) return;
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ReceiverDetails(
                          receiverModel: widget.receiver,
                          senderModel: me)));
            },
            child: Row(
              children: [
                SizedBox(
                  width: 8 * ScaleUtils.horizontalScale,
                ),
                Container(
                  child: CircleAvatar(
                    radius: 20 * ScaleUtils.scaleFactor,
                    backgroundColor: Colors.transparent,
                    backgroundImage: AssetImage('assets/user.jpg'),
                    foregroundImage: NetworkImage(widget.receiver.profilePhoto),
                  ),
                ),
              ],
            ),
          ),
          centerTitle: false,
        ),
        body: Column(
          children: [
            Flexible(
                child: StreamBuilder<QuerySnapshot>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                      child: Text("Couldn't load messages",
                          style: TextStyle(color: Colors.white)));
                }
                if (snapshot.data == null) {
                  return Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                _loadedCount = docs.length;
                if (docs.isEmpty) {
                  return ChatQuietBox(
                    screen: "ChatScreen",
                  );
                }
                final bool hasOlder = docs.length >= _messageLimit;
                final DateTime now = DateTime.now();
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: docs.length,
                  reverse: true,
                  itemBuilder: (context, index) {
                    final MessageModel message = MessageModel.fromMap(
                        docs[index].data() as Map<String, dynamic>);
                    final DateTime messageTime = message.timestamp.toDate();

                    // The list is newest-first, so index + 1 is the previous message.
                    // Show a date chip where the day changes. The oldest loaded
                    // message only gets one if there is nothing older to load.
                    bool startsNewDay;
                    if (index == docs.length - 1) {
                      startsNewDay = !hasOlder;
                    } else {
                      final previous = MessageModel.fromMap(
                          docs[index + 1].data() as Map<String, dynamic>);
                      startsNewDay = !MessageUtils.isSameDay(
                          messageTime, previous.timestamp.toDate());
                    }
                    final bool isMe = message.senderId == _currentUserId;
                    return Column(
                      children: [
                        if (startsNewDay)
                          Padding(
                            padding: EdgeInsets.all(8.0*ScaleUtils.scaleFactor),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10*ScaleUtils.scaleFactor),
                                color: Colors.white
                              ),
                              padding: EdgeInsets.fromLTRB(10*ScaleUtils.horizontalScale, 4*ScaleUtils.verticalScale, 10*ScaleUtils.horizontalScale, 4*ScaleUtils.verticalScale),
                              child: Text(
                                MessageUtils.chatDateLabel(messageTime, now),
                                style: TextStyle(
                                    fontSize: 15*ScaleUtils.scaleFactor,
                                    color: Colors.black),
                              ),
                            ),
                          ),
                        Container(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: MessageBubble(message: message, isMe: isMe)),
                      ],
                    );
                  },
                );
              },
            )),
            SizedBox(
              height: 10*ScaleUtils.verticalScale,
            ),
            (imageUploadProvider.getViewState == ViewState.loading)
                ? Container(
                    alignment: Alignment.centerRight,
                    child: Container(
                      margin: EdgeInsets.fromLTRB(0, 12*ScaleUtils.verticalScale, 12*ScaleUtils.horizontalScale, 0),
                      height: 250*ScaleUtils.verticalScale,
                      width: 250*ScaleUtils.horizontalScale,
                      constraints: BoxConstraints(
                          maxWidth: ScaleUtils.width* 0.65),
                      decoration: BoxDecoration(
                          color: UniversalVariables.senderColor,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10*ScaleUtils.scaleFactor),
                            topRight: Radius.circular(10*ScaleUtils.scaleFactor),
                            bottomLeft: Radius.circular(10*ScaleUtils.scaleFactor),
                          )),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          (imageUploadProvider.getViewState ==
                                  ViewState.loading)
                              ? CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : Container(),
                          SizedBox(
                            height: 10*ScaleUtils.verticalScale,
                          ),
                          if (uploadProgress > 0 &&
                              uploadProgress < 1.0)
                            Text(
                              "${(uploadProgress * 100).toStringAsFixed(2)} %",
                              style: TextStyle(color: Colors.white),
                            ),
                        ],
                      ),
                    ),
                  )
                : Container(),
            chatControls(imageUploadProvider)
          ],
        ),
      ),
    );
  }

  Widget chatControls(ImageUploadProvider imageUploadProvider) {
    void pickImageMethod({required ImageSource source}) async {
      final XFile? selectedImage = await ImagePicker().pickImage(source: source);
      // Picker closed without choosing: nothing to upload.
      if (selectedImage == null) return;
      try {
        await firebaseStorageMethod.uploadImage(selectedImage, widget.receiver.uid,
            _currentUserId, imageUploadProvider, _onUploadProgress);
      } catch (e) {
        debugPrint('Image upload failed: $e');
        _showError("Couldn't send the photo. Please try again.");
      }
    }

    addMediaModel(BuildContext context) {
      showModalBottomSheet(
          context: context,
          elevation: 0,
          backgroundColor: UniversalVariables.blackColor,
          builder: (context) {
            return Column(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(vertical: 15*ScaleUtils.verticalScale),
                  child: Row(
                    children: [
                      TextButton(
                        child: Icon(
                          Icons.close,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.maybePop(context);
                        },
                      ),
                      SizedBox(
                        width: 75*ScaleUtils.horizontalScale,
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: Text(
                          "Content and tools",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20*ScaleUtils.scaleFactor,
                              fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),
                ),
                Flexible(
                  child: ListView(
                    children: [
                      ModalTile(
                          title: "Media",
                          subtitle: "Share Photos from gallery",
                          icon: Icons.image,
                          onTap: () {
                            pickImageMethod(source: ImageSource.gallery);
                            Navigator.maybePop(context);
                          }),
                      ModalTile(
                          title: "Video",
                          subtitle: "Share Videos",
                          icon: Icons.play_circle,
                          onTap: () {
                            Navigator.maybePop(context);
                            _selectFile(imageUploadProvider, FileType.video);
                          }),
                      ModalTile(
                          title: "PDF",
                          subtitle: "Share Pdf",
                          icon: Icons.picture_as_pdf_outlined,
                          onTap: () {
                            Navigator.maybePop(context);
                            _selectFile(imageUploadProvider, FileType.custom,
                                allowedExtensions: ['pdf']);
                          }),
                      ModalTile(
                          title: "Document",
                          subtitle: "Share any file",
                          icon: Icons.attach_file,
                          onTap: () {
                            Navigator.maybePop(context);
                            _selectFile(imageUploadProvider, FileType.any);
                          }),
                      ModalTile(
                          title: "Contact",
                          subtitle: "Share Contacts",
                          icon: Icons.contacts,
                          onTap: () {}),
                      ModalTile(
                          title: "Location",
                          subtitle: "Share a location",
                          icon: Icons.add_location,
                          onTap: () {}),
                    ],
                  ),
                )
              ],
            );
          });
    }

    return Container(
      padding: EdgeInsets.all(10*ScaleUtils.scaleFactor),
      child: Row(
        children: [
          GestureDetector(
            child: Container(
              padding: EdgeInsets.all(5*ScaleUtils.scaleFactor),
              decoration: BoxDecoration(
                  gradient: UniversalVariables.appGradient,
                  shape: BoxShape.circle),
              child: Icon(
                Icons.add,
                color: Colors.white,
                size: 36*ScaleUtils.scaleFactor,
              ),
            ),
            onTap: () {
              addMediaModel(context);
            },
          ),
          SizedBox(width: 5*ScaleUtils.horizontalScale),
          Expanded(
            child: TextField(
              controller: messageController,
              style: TextStyle(color: Colors.white),
              onChanged: (val) {
                setState(() {
                  (val.isNotEmpty && val.trim() != "")
                      ? isWriting = true
                      : isWriting = false;
                });
              },
              decoration: InputDecoration(
                  hintText: "Type a message",
                  hintStyle: TextStyle(color: UniversalVariables.greyColor),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(50)),
                      borderSide: BorderSide.none),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 20*ScaleUtils.horizontalScale, vertical: 5*ScaleUtils.verticalScale),
                  filled: true,
                  fillColor: UniversalVariables.separatorColor,
                  suffixIcon: GestureDetector(
                    onTap: () async {},
                    child: Icon(Icons.face, color: Colors.white),
                  )),
            ),
          ),
          (isWriting)
              ? Container()
              : GestureDetector(
                  onTap: () {},
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10*ScaleUtils.horizontalScale),
                    child: Icon(
                      Icons.record_voice_over,
                      color: Colors.white,
                    ),
                  ),
                ),
          (isWriting)
              ? Container()
              : GestureDetector(
                  child: Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                  ),
                  onTap: () {
                    pickImageMethod(source: ImageSource.camera);
                  },
                ),
          (isWriting)
              ? Container(
                  margin: EdgeInsets.only(left: 10*ScaleUtils.horizontalScale),
                  decoration: BoxDecoration(
                      gradient: UniversalVariables.fabGradient,
                      shape: BoxShape.circle),
                  child: IconButton(
                    onPressed: () {
                      sendMessage();
                    },
                    icon: Icon(
                      Icons.send,
                      size: 28*ScaleUtils.scaleFactor,
                      color: Colors.white,
                    ),
                  ),
                )
              : Container()
        ],
      ),
    );
  }

  void sendMessage() {
    final me = sender;
    // Keep the typed text if our profile hasn't loaded yet.
    if (me == null) return;
    var text = messageController.text;
    MessageModel message = MessageModel(
        senderId: me.uid,
        receiverId: widget.receiver.uid,
        type: 'text',
        message: text,
        timestamp: Timestamp.now(),
        photoUrl: '',
        thumbnailUrl: '',
        pdfUrl: '',
        pdfName: '');
    setState(() {
      isWriting = false;
    });
    messageController.text = "";
    // Offline, the message shows straight away and is sent once back online;
    // only a real failure (e.g. rejected by the server) lands in catchError.
    chatFirebaseMethods.addMessagetoDb(message).catchError((Object e) {
      debugPrint('Message failed to send: $e');
      _showError("Message couldn't be sent: \"${_preview(text)}\"");
    });
    // addMessagetoDb asks the notification server to send the push notification.
  }

  String _preview(String text) =>
      text.length > 30 ? '${text.substring(0, 30)}…' : text;

  void _onUploadProgress(double progress) {
    if (!mounted) return;
    setState(() {
      uploadProgress = progress;
    });
  }

  // The system file picker needs no storage permission.
  Future<void> _selectFile(ImageUploadProvider imageUploadProvider, FileType type,
      {List<String>? allowedExtensions}) async {
    final List<PlatformFile> pickedFiles =
        await FilePicker.pickFiles(type: type, allowedExtensions: allowedExtensions);
    // Picker closed without choosing: nothing to upload.
    if (pickedFiles.isEmpty) return;
    try {
      await firebaseStorageMethod.uploadAnyFile(pickedFiles.first, widget.receiver.uid,
          _currentUserId, imageUploadProvider, _onUploadProgress);
    } catch (e) {
      debugPrint('File upload failed: $e');
      _showError("Couldn't send the file. Please try again.");
    }
  }
}
