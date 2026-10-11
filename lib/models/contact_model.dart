import 'package:cloud_firestore/cloud_firestore.dart';

class ContactModel{

  String uid ="";
  late Timestamp addedOn;

  ContactModel({
    required this.uid,
    required this.addedOn
});

  Map toMap(ContactModel contactModel){
    var data = Map<String,dynamic>();
    data['contact_id'] = contactModel.uid;
    data['added_on'] = contactModel.addedOn;
    return data;
  }

  ContactModel.fromMap(Map<String,dynamic> mapData){
    uid = mapData['contact_id'];
    addedOn = mapData['added_on'];
  }
}