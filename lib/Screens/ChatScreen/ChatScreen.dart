import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echat/Resources/ChatFirebaseMethods.dart';
import 'package:echat/Resources/FirebaseStorageMethod.dart';
import 'package:echat/Screens/Call/PickupLayout.dart';
import 'package:echat/Screens/ChatList/ChatListScreenWidgets/ChatListWidgets.dart';
import 'package:echat/Screens/ChatScreen/ChatQuietBox.dart';
import 'package:echat/Utils/CallUtilities.dart';
import 'package:echat/Widgets/CachedVideoPlayer.dart';
import 'package:echat/Widgets/FullImageWidget.dart';
import 'package:echat/Widgets/PdfViewerScreen.dart';
import 'package:echat/Widgets/ReceiverDetails.dart';
import 'package:echat/enum/ViewState.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:echat/Models/MessageModel.dart';
import 'package:echat/Models/UserModel.dart';
import 'package:echat/Provider/ImageUploadProvider.dart';
import 'package:echat/Utils/UniversalVariables.dart';
import 'package:echat/Widgets/CachedChatImage.dart';
import 'package:echat/Widgets/ModalTile.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
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
  bool isWriting = false;
  late UserModel sender;
  String _currentUserId = '';
  ChatFirebaseMethods chatFirebaseMethods = ChatFirebaseMethods();
  FirebaseStorageMethod firebaseStorageMethod = FirebaseStorageMethod();
  double uploadProgress = 0.0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    User? currentUser = FirebaseAuth.instance.currentUser;
    _currentUserId = currentUser!.uid;
    setState(() {
      sender = UserModel(
          uid: currentUser.uid,
          name: currentUser.displayName ?? '',
          email: currentUser.email ?? '',
          username: '',
          status: '',
          state: 0,
          profilePhoto: currentUser.photoURL ?? '',
          gender: '',
          phoneNumber: '',
          authType: ''
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    ImageUploadProvider imageUploadProvider = Provider.of<ImageUploadProvider>(context);
    return PickupLayout(
      scaffold: Scaffold(
        backgroundColor: Colors.black,
        appBar: CustomAppBar(
          title: InkWell(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ReceiverDetails(
                              receiverModel: widget.receiver,
                              senderModel: sender,
                            )));
              },
              child: Text(
                widget.receiver.name,
                style: TextStyle(color: Colors.white, fontSize: 18),
              )),
          actions: [
            IconButton(
                onPressed: () {
                  CallUtilities.dial(
                      from_Caller: sender,
                      to_receiver: widget.receiver,
                      context: context,
                      callType: 'audioCall');
                },
                icon: Icon(
                  Icons.phone,
                  color: Colors.white,
                )),
            IconButton(
                onPressed: () {
                  CallUtilities.dial(
                      from_Caller: sender,
                      to_receiver: widget.receiver,
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
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ReceiverDetails(
                            receiverModel: widget.receiver,
                            senderModel: sender
                          )));
            },
            child: Row(
              children: [
                SizedBox(
                  width: 8,
                ),
                Container(
                  child: CircleAvatar(
                    radius: 20,
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
                child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection("messages")
                  .doc(_currentUserId)
                  .collection(widget.receiver.uid)
                  .orderBy("timestamp", descending: true)
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.data == null) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.data!.docs.length == 0) {
                  return ChatQuietBox(screen: "ChatScreen",);
                }
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  reverse: true,
                  itemBuilder: (context, index) {
                    Timestamp currentMessageDate = snapshot.data!.docs[index]['timestamp']; //This line extracts the timestamp of the current message from the docs list in the snapshot.
                    DateTime currentMessageDateTime = currentMessageDate.toDate();
                    String messageDate = '';

                    // Get the current message's date
                    DateTime? nextDateTime;
                    //This block prepares to get the timestamp of the next message.
                    if (index < snapshot.data!.docs.length - 1) {
                      //It checks if the current message is not the last one in the list to avoid an index out of bounds error.
                      Timestamp nextDate = snapshot.data!.docs[index + 1]['timestamp'];
                      nextDateTime = nextDate.toDate();
                    }

                    // Compare the current message's date with the next message's date
                    //This condition checks if the current message is the last one or if its date is different from the date of the next message.
                    // If either of these conditions is true, it means the current message marks the start of a new date group.
                    if (index == snapshot.data!.docs.length - 1 ||
                        currentMessageDateTime.year != nextDateTime?.year ||
                        currentMessageDateTime.month != nextDateTime?.month ||
                        currentMessageDateTime.day != nextDateTime?.day) {
                      // Messages are from a different day
                      if (currentMessageDateTime.year == DateTime.now().year &&
                          currentMessageDateTime.month ==
                              DateTime.now().month &&
                          currentMessageDateTime.day == DateTime.now().day) {
                        messageDate = 'Today';
                      } else if (currentMessageDateTime.year ==
                              DateTime.now().year &&
                          currentMessageDateTime.month ==
                              DateTime.now().month &&
                          currentMessageDateTime.day ==
                              DateTime.now().day - 1) {
                        messageDate = 'Yesterday';
                      } else {
                        messageDate = DateFormat('dd-MM-yyyy')
                            .format(currentMessageDate.toDate());
                      }
                    }
                    return Column(
                      children: [
                        if (messageDate.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                            child: Text(
                              messageDate,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white),
                            ),
                          ),
                        Container(
                            // Container for particular message either text message or Image message
                            alignment: (snapshot.data!.docs[index]
                                        ['senderId'] ==
                                    _currentUserId)
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            margin: EdgeInsets.fromLTRB(0, 0, 0, 0),
                            child: (snapshot.data!.docs[index]['senderId'] ==
                                    _currentUserId)
                                ? senderLayout(snapshot.data!.docs[index])
                                : receiverLayout(snapshot.data!.docs[index])),
                      ],
                    );
                  },
                );
              },
            )),
            SizedBox(
              height: 10,
            ),
            (imageUploadProvider.getViewState == ViewState.LOADING)
                ? Container(
                    alignment: Alignment.centerRight,
                    child: Container(
                      margin: EdgeInsets.fromLTRB(0, 12, 12, 0),
                      height: 270,
                      width: 268,
                      constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.65),
                      decoration: BoxDecoration(
                          color: UniversalVariables.senderColor,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(10),
                            bottomLeft: Radius.circular(10),
                          )),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          (imageUploadProvider.getViewState ==
                                  ViewState.LOADING)
                              ? CircularProgressIndicator(color: Colors.white,)
                              : Container(),
                          SizedBox(
                            height: 10,
                          ),
                          if (uploadProgress != null &&
                              uploadProgress > 0 &&
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

  Widget senderLayout(DocumentSnapshot snapshot) {
    Timestamp date = snapshot['timestamp'];
    DateTime datenew = date.toDate();

    return Container(
      margin: EdgeInsets.fromLTRB(0, 12, 12, 0),
      constraints:
          BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
      decoration: BoxDecoration(
          gradient: UniversalVariables.appGradient,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
            bottomLeft: Radius.circular(10),
          )),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              (snapshot['type'] == 'text')
                  ? Flexible(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 20, 0),
                        child: Text(
                          snapshot['message'],
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    )
                  : (snapshot['type'] == 'mp4') // Check if type is mp4
                      ? GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CachedVideoPlayerScreen(
                                    videoUrl: snapshot['photoUrl']),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(8.0, 8, 8, 0),
                            child: Stack(
                              children: [
                                CachedChatImage(
                                  imageUrl: snapshot['thumbnailUrl'],
                                  height: 250,
                                  width: 250,
                                  radius: 10,
                                  isRound: false,
                                  fit: BoxFit.cover,
                                ),
                                Container(
                                  width: 250,
                                  height: 250,
                                  child: Center(
                                    child: Icon(
                                      Icons.play_circle,
                                      size: 70,
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        )
                      : (snapshot['type'] == 'pdf')
                          ? Padding(
                            padding: const EdgeInsets.fromLTRB(8.0, 8, 8, 0),
                            child: GestureDetector(
                                onTap: () async {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => PdfViewerScreen(
                                              pdfUrl: snapshot['pdfUrl'],
                                              pdfName: snapshot['pdfName'])));
                                },
                                child: Container(
                                  height: 250,
                                  width: 250,
                                  color: Colors.white,
                                  child: Padding(
                                    padding: const EdgeInsets.all(14.0),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Icon(
                                          Icons.picture_as_pdf_outlined,
                                          size: 150,
                                          color: Colors.red,
                                        ),
                                        Text(
                                          snapshot['pdfName'],
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          )
                          : Padding(
                              padding: const EdgeInsets.fromLTRB(8.0, 8, 8, 0),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(context,
                                      MaterialPageRoute(builder: (_) {
                                    return FullImageWidget(
                                      imageUrl: snapshot['photoUrl'],
                                    );
                                  }));
                                },
                                child: Hero(
                                  tag: "imageHero_${snapshot['photoUrl']}",
                                  child: CachedChatImage(
                                    imageUrl: snapshot['photoUrl'],
                                    height: 250,
                                    width: 250,
                                    radius: 10,
                                    isRound: false,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(8, 8, 8, 4),
                child: Text(
                  DateFormat.jm().format(datenew),
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget receiverLayout(DocumentSnapshot snapshot) {
    Timestamp date = snapshot['timestamp'];
    DateTime datenew = date.toDate();
    return Container(
      margin: EdgeInsets.only(top: 12),
      constraints:
          BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
      decoration: BoxDecoration(
          color: HexColor('aeb9cc'),
          borderRadius: BorderRadius.only(
            bottomRight: Radius.circular(10),
            topRight: Radius.circular(10),
            bottomLeft: Radius.circular(10),
          )),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              (snapshot['type'] == 'text')
                  ? Flexible(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 20, 0),
                        child: Text(
                          snapshot['message'],
                          style: TextStyle(color: Colors.black, fontSize: 16),
                        ),
                      ),
                    )
                  : (snapshot['type'] == 'mp4') // Check if type is mp4
                      ? GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CachedVideoPlayerScreen(
                                    videoUrl: snapshot['photoUrl']),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(8.0, 8, 8, 0),
                            child: Stack(
                              children: [
                                SizedBox(
                                  width: 250,
                                  height: 250,
                                  child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        snapshot['thumbnailUrl'],
                                        // URL of the thumbnail image stored in Firestore
                                        fit: BoxFit.cover,
                                      )),
                                ),
                                Container(
                                  width: 250,
                                  height: 250,
                                  child: Center(
                                    child: Icon(
                                      Icons.play_circle,
                                      size: 70,
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        )
                      : (snapshot['type'] == 'pdf')
                          ? Padding(
                            padding: const EdgeInsets.fromLTRB(8.0, 8, 8, 0),
                            child: GestureDetector(
                                onTap: () async {
                                  final url = snapshot['pdfUrl'];
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => PdfViewerScreen(
                                              pdfUrl: snapshot['pdfUrl'],
                                              pdfName: snapshot['pdfName'])));
                                },
                                child: Container(
                                  height: 250,
                                  width: 250,
                                  color: Colors.white,
                                  child: Padding(
                                    padding: const EdgeInsets.all(14.0),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Icon(
                                          Icons.picture_as_pdf_outlined,
                                          size: 150,
                                          color: Colors.red,
                                        ),
                                        Text(
                                          snapshot['pdfName'],
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          )
                          : Padding(
                              padding: const EdgeInsets.fromLTRB(8.0, 8, 8, 0),
                            child: GestureDetector(
                                onTap: () {
                                  Navigator.push(context,
                                      MaterialPageRoute(builder: (_) {
                                    return FullImageWidget(
                                      imageUrl: snapshot['photoUrl'],
                                    );
                                  }));
                                },
                                child: Hero(
                                  tag: "imageHero_${snapshot['photoUrl']}",
                                  child: CachedChatImage(
                                    imageUrl: snapshot['photoUrl'],
                                    height: 250,
                                    width: 250,
                                    radius: 10,
                                    isRound: false,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                          ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(8, 8, 8, 4),
                child: Text(
                  DateFormat.jm().format(datenew),
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget chatControls(ImageUploadProvider imageUploadProvider) {
    void pickImageMethod({required ImageSource source}) async {
      XFile? selectedImage = (await ImagePicker().pickImage(source: source));
      firebaseStorageMethod.uploadImage(selectedImage, widget.receiver.uid,
          _currentUserId, imageUploadProvider,(double progress) {
            setState(() {
              uploadProgress = progress;
            });
          });
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
                  padding: EdgeInsets.symmetric(vertical: 15),
                  child: Row(
                    children: [
                      TextButton(
                        child: Icon(Icons.close,color: Colors.white,),
                        onPressed: () {
                          Navigator.maybePop(context);
                        },
                      ),
                      SizedBox(width: 75,),
                      Align(
                          alignment: Alignment.center,
                          child: Text(
                            "Content and tools",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
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
                          onTap: () async {
                            var status = await Permission.storage.status;
                            if (await Permission.storage.isDenied) {
                              await Permission.storage.request();
                            } else {}
                            _selectFile(imageUploadProvider);
                            Navigator.maybePop(context);
                          }),
                      ModalTile(
                          title: "PDF",
                          subtitle: "Share Pdf",
                          icon: Icons.picture_as_pdf_outlined,
                          onTap: () async {
                            var status = await Permission.storage.status;
                            if (await Permission.storage.isDenied) {
                              await Permission.storage.request();
                            } else {}
                            _selectFile(imageUploadProvider);
                            Navigator.maybePop(context);
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
      padding: EdgeInsets.all(10),
      child: Row(
        children: [
          GestureDetector(
            child: Container(
              padding: EdgeInsets.all(5),
              decoration: BoxDecoration(
                  gradient: UniversalVariables.appGradient,
                  shape: BoxShape.circle),
              child: Icon(
                Icons.add,
                color: Colors.white,
                size: 36,
              ),
            ),
            onTap: () {
              addMediaModel(context);
            },
          ),
          SizedBox(width: 5),
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
                      EdgeInsets.symmetric(horizontal: 20, vertical: 5),
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
                    padding: EdgeInsets.symmetric(horizontal: 10),
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
                  margin: EdgeInsets.only(left: 10),
                  decoration: BoxDecoration(
                      gradient: UniversalVariables.fabGradient,
                      shape: BoxShape.circle),
                  child: IconButton(
                    onPressed: () {
                      sendMessage();
                    },
                    icon: Icon(
                      Icons.send,
                      size: 28,
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
    var text = messageController.text;
    MessageModel message = MessageModel(
        senderId: sender.uid,
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
    chatFirebaseMethods.addMessagetoDb(message, sender, widget.receiver);
  }

  void _selectFile(ImageUploadProvider imageUploadProvider) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    firebaseStorageMethod.uploadAnyFile(
        result, widget.receiver.uid, _currentUserId, imageUploadProvider,
        (double progress) {
      setState(() {
        uploadProgress = progress;
      });
    });
  }
}
