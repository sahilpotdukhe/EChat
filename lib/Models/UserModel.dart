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
    required this.notificationToken
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
    return data;
  }

  UserModel.fromMap(Map<String, dynamic> mapData){
    uid = mapData['uid'];
    name = mapData['name'];
    email = mapData['email'];
    username = mapData['username'];
    status = mapData['status'];
    state = mapData['state'];
    profilePhoto = mapData['profile_photo'];
    gender= mapData['gender'];
    phoneNumber = mapData['phone_Number'];
    authType = mapData['auth_type'];
    notificationToken = mapData['notification_token'];
  }

}