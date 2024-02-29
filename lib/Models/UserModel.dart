class UserModel{
  String uid="";
  String name="";
  String email="";
  String username="";
  String status="";
  int state=0;
  String profilePhoto="";

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.username,
    required this.status,
    required this.state,
    required this.profilePhoto,
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
  }

}