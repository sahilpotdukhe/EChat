import 'package:agora_uikit/agora_uikit.dart';
import 'package:echat/Screens/Call/PickupLayout.dart';
import 'package:echat/Screens/ChatList/ChatListScreenWidgets/ChatListWidgets.dart';
import 'package:echat/Screens/ChatList/ChatListScreenWidgets/UserCircle.dart';
import 'package:echat/Utils/UniversalVariables.dart';
import 'package:fast_contacts/fast_contacts.dart';
import 'package:flutter/material.dart';

class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
          backgroundColor: UniversalVariables.blackColor,
          appBar: CustomAppBar(
              title: Text(
                "Contact List",
                style: TextStyle(
                    color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
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
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(firstPhoneNumber),
                              trailing: Text(
                                "Invite",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
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
}
