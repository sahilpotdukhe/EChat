import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel{
  String uid="";
  String name="";
  String email="";
  String username="";
  String status="";
  String phoneNumber="";
  String gender = "";
  int state=0;
  String profilePhoto="";
  String authType="";
  String notificationToken = "";
  // Refreshed about every minute while their app is open (see
  // PresenceService). Null on profiles from before this was stored.
  Timestamp? lastSeen;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.username,
    required this.status,
    required this.state,
    required this.gender,
    required this.phoneNumber,
    required this.profilePhoto,
    required this.authType,
    required this.notificationToken,
    this.lastSeen,
});

  Map toMap(UserModel user) {
    var data = <String, dynamic>{};
    data['uid'] = user.uid;
    data['name'] = user.name;
    data['email'] = user.email;
    data['username'] = user.username;
    data["status"] = user.status;
    data["state"] = user.state;
    data["profile_photo"] = user.profilePhoto;
    data["phone_Number"]= user.phoneNumber;
    data["gender"] = user.gender;
    data['auth_type'] = user.authType;
    data['notification_token'] = user.notificationToken;
    if (user.lastSeen != null) data['last_seen'] = user.lastSeen;
    return data;
  }

  // Missing fields (older or partly-filled user docs) fall back to defaults
  // instead of throwing.
  UserModel.fromMap(Map<String, dynamic> mapData){
    uid = mapData['uid'] ?? '';
    name = mapData['name'] ?? '';
    email = mapData['email'] ?? '';
    username = mapData['username'] ?? '';
    status = mapData['status'] ?? '';
    state = (mapData['state'] as num?)?.toInt() ?? 0;
    profilePhoto = mapData['profile_photo'] ?? '';
    gender= mapData['gender'] ?? '';
    phoneNumber = mapData['phone_Number'] ?? '';
    authType = mapData['auth_type'] ?? '';
    notificationToken = mapData['notification_token'] ?? '';
    lastSeen = mapData['last_seen'] is Timestamp ? mapData['last_seen'] : null;
  }

}