import 'package:agora_uikit/agora_uikit.dart';
import 'package:echat/Models/UserModel.dart';
import 'package:echat/Provider/UserProvider.dart';
import 'package:echat/Screens/Call/PickupLayout.dart';
import 'package:echat/Screens/ChatList/ChatListScreenWidgets/ChatListWidgets.dart';
import 'package:echat/Screens/ChatList/ChatListScreenWidgets/UserCircle.dart';
import 'package:echat/Utils/ScreenDimensions.dart';
import 'package:echat/Utils/UniversalVariables.dart';
import 'package:fast_contacts/fast_contacts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sms/flutter_sms.dart';
import 'package:provider/provider.dart';

class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  String _currentUserId = '';
  late UserProvider userProvider;
  UserModel? currentUserModel;
  @override
  void initState() {
    User? currentUser = FirebaseAuth.instance.currentUser;
    _currentUserId = currentUser!.uid;
    getUser();
    // TODO: implement initState
    super.initState();
  }

  Future<void> getUser() async{
    await Future.delayed(Duration.zero);
    userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.refreshUser();
    if (userProvider.getUser != null) {
      UserModel? currentUser = userProvider.getUser;
      setState(() {
        currentUserModel = currentUser!;
      });
    } else {
      print('User is null');
    }
  }

  @override
  Widget build(BuildContext context) {
    ScaleUtils.init(context);
    return Scaffold(
      backgroundColor: UniversalVariables.blackColor,
      appBar: CustomAppBar(
          title: Text(
            "Contact List",
            style: TextStyle(
                color: Colors.white, fontSize: 20*ScaleUtils.scaleFactor, fontWeight: FontWeight.bold),
          ),
          actions: <Widget>[
            IconButton(
              icon: Icon(
                Icons.search,
                color: Colors.white,
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/searchScreen');
              },
            )
          ],
          leading: IconButton(
            icon: Icon(Icons.notifications),
            color: Colors.white,
            onPressed: () {},
          ),
          centerTitle: true
      ),
      body: FutureBuilder(
          future: getContacts(),
          builder: (context, AsyncSnapshot snapshot) {
            if (snapshot.data == null) {
              return Center(child: CircularProgressIndicator());
            }
            return Scrollbar(
              child: ListView.builder(
                  itemCount: snapshot.data.length,
                  itemBuilder: (context, index) {
                    Contact contact = snapshot.data![index];
                    String firstPhoneNumber =
                    contact.phones?.isNotEmpty ?? false
                        ? contact.phones![0].number ?? ''
                        : '';
                    return (firstPhoneNumber == "")
                        ? Container()
                        : ListTile(
                          leading: CircleAvatar(
                            radius: 20,
                            child: Icon(Icons.person),
                          ),
                          title: Text(
                            contact.displayName,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18*ScaleUtils.scaleFactor,
                                fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(firstPhoneNumber),
                          trailing: InkWell(
                            onTap: (){
                              String message = "${currentUserModel!.name} would like to chat and engage through video and voice calls with you on Echat.It's free!";
                              _sendSMS(message, [firstPhoneNumber]);
                            },
                            child: Text(
                              "Invite",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14*ScaleUtils.scaleFactor,
                              ),
                            ),
                          ),
                    );
                  }),
            );
          }),
    );
  }

  Future<List<Contact>> getContacts() async {
    bool isGranted = await Permission.contacts.status.isGranted;
    if (!isGranted) {
      isGranted = await Permission.contacts.request().isGranted;
    }
    if (isGranted) {
      return await FastContacts.getAllContacts();
    }
    return [];
  }

  void _sendSMS(String message, List<String> recipents) async {
    String _result = await sendSMS(message: message, recipients: recipents)
        .catchError((onError) {
      print(onError);
    });
    print(_result);
  }


}