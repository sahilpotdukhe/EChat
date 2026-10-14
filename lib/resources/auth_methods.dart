import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echat/models/user_model.dart';
import 'package:echat/resources/media_storage.dart';
import 'package:echat/resources/presence_service.dart';
import 'package:echat/screens/login_screen.dart';
import 'package:echat/utils/utilities.dart';
import 'package:echat/screens/home_screen.dart';
import 'package:echat/enums/user_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
class Authenticate extends StatelessWidget {
  const Authenticate({super.key});

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
    await PresenceService.instance.stop();
    MediaStorage.reset();
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
      // On iPhone, Apple's push token arrives a moment after permission is
      // granted, and asking Firebase for its token before then fails.
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        for (var i = 0; i < 10 && await FirebaseMessaging.instance.getAPNSToken() == null; i++) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
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

  /// True when signed in, null if the user closed the Google picker.
  /// Throws [GoogleSignInFailure] with a message to show when it fails.
  Future<bool?> googleLogin(BuildContext context) async {
    final GoogleSignInAccount googleUser;
    try {
      await (_initialization ??= googleSignIn.initialize());
      googleUser = await googleSignIn.authenticate();
    } on GoogleSignInException catch (e) {
      debugPrint('Google sign-in: ${e.code} ${e.description}');
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      throw GoogleSignInFailure.fromGoogle(e);
    } catch (e) {
      // e.g. initialize() failing on an iPhone build with no Google client ID.
      _initialization = null;
      debugPrint('Google sign-in: $e');
      throw const GoogleSignInFailure(
          'Google sign-in isn\'t set up for this build of the app. Use email for now.');
    }
    _user = googleUser;

    final String? idToken = googleUser.authentication.idToken;
    if (idToken == null) {
      throw const GoogleSignInFailure('Google didn\'t return a sign-in token. Please try again.');
    }
    try {
      await FirebaseAuth.instance.signInWithCredential(GoogleAuthProvider.credential(idToken: idToken));
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Google sign-in: ${e.code} ${e.message}');
      throw GoogleSignInFailure.fromFirebase(e);
    }

    final uid = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot userDocs = await FirebaseFirestore.instance.collection('Users').doc(uid).get();
    // Wait for the profile to exist before the caller opens the home screen,
    // which reads it straight away.
    if (userDocs.data() == null) {
      await authMethods.setUserProfile(
          name: googleUser.displayName,
          email: googleUser.email,
          mobilenumber: '',
          profilePic: googleUser.photoUrl,
          authType: "googleAuth");
    } else {
      await authMethods.saveNotificationToken(uid);
    }
    return true;
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

/// Why Google sign-in failed, in words for the person signing in.
class GoogleSignInFailure implements Exception {
  final String message;

  const GoogleSignInFailure(this.message);

  factory GoogleSignInFailure.fromGoogle(GoogleSignInException e) {
    switch (e.code) {
      case GoogleSignInExceptionCode.clientConfigurationError:
      case GoogleSignInExceptionCode.providerConfigurationError:
        return const GoogleSignInFailure(
            'Google sign-in isn\'t set up correctly for this app. Use email for now.');
      case GoogleSignInExceptionCode.uiUnavailable:
        return const GoogleSignInFailure('Couldn\'t open the Google account picker. Please try again.');
      case GoogleSignInExceptionCode.interrupted:
        return const GoogleSignInFailure('Sign-in was interrupted. Please try again.');
      default:
        // Android reports "no Google account on this phone" this way too.
        return const GoogleSignInFailure(
            'Google sign-in failed. Make sure a Google account is added to this phone and try again.');
    }
  }

  factory GoogleSignInFailure.fromFirebase(FirebaseAuthException e) {
    switch (e.code) {
      case 'network-request-failed':
        return const GoogleSignInFailure('No internet connection. Check it and try again.');
      case 'user-disabled':
        return const GoogleSignInFailure('This account has been disabled.');
      case 'operation-not-allowed':
        return const GoogleSignInFailure('Google sign-in is turned off for EChat right now. Use email instead.');
      case 'account-exists-with-different-credential':
        return const GoogleSignInFailure(
            'This email already has an EChat account. Sign in with your email and password.');
      default:
        return const GoogleSignInFailure('Google sign-in failed. Please try again.');
    }
  }

  @override
  String toString() => message;
}
