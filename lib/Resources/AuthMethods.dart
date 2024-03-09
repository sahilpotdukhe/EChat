import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echat/Models/UserModel.dart';
import 'package:echat/Screens/LoginScreen.dart';
import 'package:echat/Utils/utilities.dart';
import 'package:echat/Widgets/BottomNavigationBar.dart';
import 'package:echat/enum/UserState.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
class Authenticate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (_auth.currentUser != null) {
      return BotttomNavigationBar();
    } else {
      return LoginScreen();
    }
  }
}

class AuthMethods {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<User?> getCurrentUser() async {
    User? currentUser = _auth.currentUser;
    return currentUser;
  }

  Future<UserModel> getUserDetails() async{
    User? currentUser = await getCurrentUser();

    DocumentSnapshot documentSnapshot = await firestore.collection("Users").doc(currentUser!.uid).get();
    return UserModel.fromMap(documentSnapshot.data() as Map<String,dynamic>);
  }

  Future<UserModel> getUserDetailsById(id) async{
      DocumentSnapshot documentSnapshot = await firestore.collection("Users").doc(id).get();
      return UserModel.fromMap(documentSnapshot.data() as Map<String,dynamic>);
  }

  Future<User?> createAccountbyEmail(String email, String password, BuildContext context) async{
    try{
      User? user = (await _auth.createUserWithEmailAndPassword(email: email, password: password)).user;
      if(user != null){
        print("User Created Successfully");
        return user;
      }else{
        print("Account creation failed");
        return user;
      }
    }catch(e){
      print(e);
      return null;
    }
  }

  Future<User?> logInByEmail(String email, String password) async{
    try{
      User? user = (await _auth.signInWithEmailAndPassword(email: email, password: password)).user;
      if(user != null){
        print("Login Successful");
        return user;
      }else{
        print("Login failed");
        return user;
      }
    }catch(e){
      print(e);
      return null;
    }
  }

  Future logOut(BuildContext context) async {
    FirebaseAuth _auth = FirebaseAuth.instance;

    try {
      try {
        final provider =
        Provider.of<GoogleSignInProvider>(context, listen: false);
        provider.googlelogout(context);
      } catch (e) {
        await _auth.signOut().then((value) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );
        });
      }
    } catch (e) {
      print("error");
    }
  }

  void setUserProfile({String? name,String? email, var mobilenumber, var profilePic,String? authType}) async {
    String username = Utils.getUsername(email!);
    String? initialToken = await FirebaseMessaging.instance.getToken();
    print("Initial Token Sign up screen ${initialToken}");

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async{
      print("New Token Sign up screen ${newToken}");
    });
    await firestore.collection("Users").doc(_auth.currentUser!.uid)
        .set({
      "name": name,
      "email": email,
      "uid": _auth.currentUser!.uid,
      "profile_photo": profilePic,
      "status": "",
      "state": 0,
      "username": username,
      "gender": '',
      "phone_Number": mobilenumber,
      "auth_type": authType,
      "notification_token": initialToken
    });
    await updateToken(_auth.currentUser!.uid, initialToken!);
  }

  Future<bool> checkAlreadyRegistered(String email) async {
    QuerySnapshot result = await firestore.collection("Users").
                            where("email", isEqualTo: email).
                            get();
    final List<DocumentSnapshot> docs = result.docs;
    // If user is already registered means it has entry in the firestore database so the doc length will be equal to or greater than 1
    return docs.isNotEmpty ? true : false;
  }

  Future<void> updateToken(String userId, String token) async {
    await firestore.collection('Users').doc(userId).update({
      'notification_token': token,
    });
  }

  // Future googleLogOut() async {
  //   try {
  //     await _googleSignIn.disconnect();
  //     await _googleSignIn.signOut();
  //   } catch (e) {
  //     print(e);
  //   }
  //   _auth.signOut();
  // }
  // Loop through each document or User and store it in userlist as UserModel
// So that the userlist contains all the user except the current user
  Future<List<UserModel>> fetchAllUsers(User currentUser) async {
    List<UserModel> userList =[];
    QuerySnapshot querySnapshot = await firestore.collection("Users").get();
    for (var i = 0; i < querySnapshot.docs.length; i++) {
      if (querySnapshot.docs[i].id != currentUser.uid) {
        userList.add(UserModel.fromMap(querySnapshot.docs[i].data() as Map<String, dynamic>));
      }
    }
    return userList;
  }

  void setUserState({required String userId, required UserState userState}){
    int stateNum = Utils.stateToNum(userState);

    firestore.collection("Users").doc(userId).update({"state": stateNum});
  }

  Stream<DocumentSnapshot> getUserStream({required String uid}) =>
      firestore.collection("Users").doc(uid).snapshots();
}





class GoogleSignInProvider extends ChangeNotifier {
  AuthMethods authMethods = AuthMethods();
  final googleSignIn = GoogleSignIn();
  GoogleSignInAccount? _user;
  GoogleSignInAccount get user => _user!;

  Future googleLogin(context) async {
    try {
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return;
      _user = googleUser;
      print('user...');
      print(_user);
      final googleAuth = await googleUser.authentication;
      print("this is goooogle-- $googleAuth");
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      DocumentSnapshot userDocs = await FirebaseFirestore.instance
          .collection('Users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get();
      if (userDocs.data() == null) {
        authMethods.setUserProfile(name: _user?.displayName, email: _user?.email,mobilenumber: '',profilePic:_user?.photoUrl,authType: "googleAuth");
      }else{
        User? currentUser = await FirebaseAuth.instance.currentUser;
        String? alreadyInitialToken = await FirebaseMessaging.instance.getToken();
        print("Initial Token else already exists ${alreadyInitialToken}");
        authMethods.updateToken(currentUser!.uid, alreadyInitialToken!);
      }


      return true;
    } catch (e) {
      print(e.toString());
      return false;
    }
  }

  Future googlelogout(context) async {
    try {
      await googleSignIn.disconnect();
    } catch (e) {
      print(e);
    }
    FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>LoginScreen()));

  }
}
