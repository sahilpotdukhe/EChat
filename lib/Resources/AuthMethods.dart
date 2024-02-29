import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echat/Models/UserModel.dart';
import 'package:echat/Utils/utilities.dart';
import 'package:echat/enum/UserState.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

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

  Future<User?> googleSignIn(BuildContext context) async {
    try {
      GoogleSignInAccount? signInAccount = await _googleSignIn.signIn();

      GoogleSignInAuthentication? signInAuthentication = await signInAccount!.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: signInAuthentication.accessToken,
          idToken: signInAuthentication.idToken
      );

      await _auth.signInWithCredential(credential);
      String? email = _auth.currentUser?.email;
      checkAlreadyRegistered(email!).then((isNewUser) {
        if (isNewUser) {
          showToast(
              "Account LoggedIn Successfully", backgroundColor: Colors.green,
              context: context);
        } else {
          showToast(
              "Account Created Successfully", backgroundColor: Colors.green,
              context: context);
        }
      });

      DocumentSnapshot userdocs = await firestore
          .collection("Users")
          .doc(_auth.currentUser!.uid)
          .get();
      if (userdocs.data() == null) {
        String username = Utils.getUsername(signInAccount.email);
        await firestore.collection("Users").doc(_auth.currentUser!.uid)
            .set({
          "name": _auth.currentUser!.displayName,
          "email": _auth.currentUser!.email,
          "uid": _auth.currentUser!.uid,
          "profile_photo": _auth.currentUser!.photoURL,
          "status": "",
          "state": 0,
          "username": username
        });
      }
    } catch (e) {
      print(e.toString());
    }
    return null;
  }

  Future<bool> checkAlreadyRegistered(String email) async {
    QuerySnapshot result = await firestore.collection("Users").
                            where("email", isEqualTo: email).
                            get();
    final List<DocumentSnapshot> docs = result.docs;
    // If user is already registered means it has entry in the firestore database so the doc length will be equal to or greater than 1
    return docs.isNotEmpty ? true : false;
  }

  Future googleLogOut() async {
    try {
      await _googleSignIn.disconnect();
      await _googleSignIn.signOut();
      ZegoUIKitPrebuiltCallInvitationService().uninit();

    } catch (e) {
      print(e);
    }
    _auth.signOut();
  }
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