import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echat/models/user_model.dart';
import 'package:echat/screens/login_screen.dart';
import 'package:echat/utils/utilities.dart';
import 'package:echat/screens/home_screen.dart';
import 'package:echat/enums/user_state.dart';
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
      return HomeScreen();
    } else {
      return LoginScreen();
    }
  }
}

class AuthMethods {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<User?> getCurrentUser() async {
    User? currentUser = _auth.currentUser;
    return currentUser;
  }

  // Null when signed out or the profile doc doesn't exist (yet).
  Future<UserModel?> getUserDetails() async{
    User? currentUser = await getCurrentUser();
    if (currentUser == null) return null;
    return getUserDetailsById(currentUser.uid);
  }

  // Null when there is no profile doc for this id (e.g. a deleted account).
  Future<UserModel?> getUserDetailsById(String id) async{
      DocumentSnapshot documentSnapshot = await firestore.collection("Users").doc(id).get();
      final data = documentSnapshot.data() as Map<String, dynamic>?;
      return data == null ? null : UserModel.fromMap(data);
  }

  Future<User?> createAccountbyEmail(String email, String password, BuildContext context) async{
    try{
      User? user = (await _auth.createUserWithEmailAndPassword(email: email, password: password)).user;
      if(user != null){
        debugPrint("User Created Successfully");
        return user;
      }else{
        debugPrint("Account creation failed");
        return user;
      }
    }catch(e){
      debugPrint('$e');
      return null;
    }
  }

  Future<User?> logInByEmail(String email, String password) async{
    try{
      User? user = (await _auth.signInWithEmailAndPassword(email: email, password: password)).user;
      if(user != null){
        debugPrint("Login Successful");
        return user;
      }else{
        debugPrint("Login failed");
        return user;
      }
    }catch(e){
      debugPrint('$e');
      return null;
    }
  }

  Future logOut(BuildContext context) async {
    final provider = Provider.of<GoogleSignInProvider>(context, listen: false);
    await provider.googlelogout(context);
  }

  // Run before signing out (the rules need the user still signed in): stop
  // this phone getting the account's notifications and show them offline.
  // Offline, this gives up after a few seconds so logout isn't blocked; the
  // deleted token then fails on the server, which clears it on the next send.
  Future<void> clearSessionOnThisDevice() async {
    final String? uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      await firestore.collection('Users').doc(uid).update({
        'notification_token': '',
        'state': Utils.stateToNum(UserState.offline),
      }).timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('Could not clear session on logout: $e');
    }
    try {
      await FirebaseMessaging.instance.deleteToken().timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('Could not delete notification token: $e');
    }
  }

  Future<void> setUserProfile({String? name,String? email, var mobilenumber, var profilePic,String? authType}) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return;
    String username = Utils.getUsername(email ?? '');
    await firestore.collection("Users").doc(currentUser.uid)
        .set({
      "name": name ?? '',
      "email": email ?? '',
      "uid": currentUser.uid,
      "profile_photo": profilePic ?? '',
      "status": "",
      "state": 0,
      "username": username,
      "gender": '',
      "phone_Number": mobilenumber ?? '',
      "auth_type": authType,
      "notification_token": "",
    });
    await saveNotificationToken(currentUser.uid);
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

  // Saves this phone's push token on the user's profile. Some devices have no
  // token (emulators without Play services, iPhones without push set up); then
  // the user just won't get notifications instead of the app crashing.
  Future<void> saveNotificationToken(String userId) async {
    try {
      final String? token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      await updateToken(userId, token);
    } catch (e) {
      debugPrint('Could not save notification token: $e');
    }
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
  final googleSignIn = GoogleSignIn.instance;
  // google_sign_in 7+ must be initialized exactly once before use.
  static Future<void>? _initialization;
  GoogleSignInAccount? _user;
  GoogleSignInAccount get user => _user!;

  Future googleLogin(context) async {
    try {
      await (_initialization ??= googleSignIn.initialize());
      final GoogleSignInAccount googleUser;
      try {
        googleUser = await googleSignIn.authenticate();
      } on GoogleSignInException catch (e) {
        if (e.code == GoogleSignInExceptionCode.canceled) return;
        rethrow;
      }
      _user = googleUser;
      debugPrint('user...');
      debugPrint('$_user');
      final googleAuth = googleUser.authentication;
      debugPrint("this is goooogle-- $googleAuth");
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      DocumentSnapshot userDocs = await FirebaseFirestore.instance
          .collection('Users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get();
      // Wait for the profile to exist before the caller opens the home screen,
      // which reads it straight away.
      if (userDocs.data() == null) {
        await authMethods.setUserProfile(name: _user?.displayName, email: _user?.email,mobilenumber: '',profilePic:_user?.photoUrl,authType: "googleAuth");
      }else{
        await authMethods.saveNotificationToken(userDocs.id);
      }


      return true;
    } catch (e) {
      debugPrint(e.toString());
      return false;
    }
  }

  // Used for every logout (email or Google); disconnecting Google is a no-op
  // for email accounts.
  Future googlelogout(BuildContext context) async {
    await authMethods.clearSessionOnThisDevice();
    try {
      await googleSignIn.disconnect();
    } catch (e) {
      debugPrint('Google disconnect: $e');
    }
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    // Clear the whole back stack so Back can't return into the signed-out app.
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=>LoginScreen()), (route) => false);

  }
}
