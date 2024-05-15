import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echat/Models/UserModel.dart';
import 'package:echat/Provider/AppLoadingProvider.dart';
import 'package:echat/Provider/UserProvider.dart';
import 'package:echat/Utils/ScreenDimensions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _formKey = GlobalKey<FormState>();
  String? displayName;
  String? gender = 'Male';
  XFile? _image;
  String? phoneNumber;
  FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    Provider.of<UserProvider>(context, listen: false).refreshUser();
    displayName = Provider.of<UserProvider>(context, listen: false).getUser?.name.toString();
    gender = Provider.of<UserProvider>(context, listen: false).getUser?.gender.toString();
    phoneNumber = Provider.of<UserProvider>(context, listen: false).getUser?.phoneNumber.toString();
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ScaleUtils.init(context);
    UserProvider userProvider = Provider.of<UserProvider>(context);
    UserModel? userModel = userProvider.getUser;
    final appprovider = Provider.of<AppProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Edit Profile",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: IconThemeData(
          color: Colors.white, //change your color here
        ),
        centerTitle: true,
        backgroundColor: HexColor("3957ED"),
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(new FocusNode());
        },
        child: ListView(
          shrinkWrap: true,
          children: [
            SizedBox(
              height: 30*ScaleUtils.verticalScale,
            ),
            InkWell(
              onTap: () {
                selectImage(
                    ImagePicker().pickImage(source: ImageSource.gallery));
              },
              child: Stack(
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 60*ScaleUtils.scaleFactor,
                      child: CircleAvatar(
                        radius: 60*ScaleUtils.scaleFactor,
                        backgroundColor: Colors.transparent,
                        backgroundImage: _displayChild(),
                        //foregroundImage: NetworkImage(userModel!.profilePhoto),
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      children: [
                        SizedBox(
                          height: 90*ScaleUtils.verticalScale,
                        ),
                        Container(
                          margin: EdgeInsets.only(right: 8*ScaleUtils.horizontalScale, top: 8*ScaleUtils.verticalScale),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: HexColor("3957ED"),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(8.0*ScaleUtils.scaleFactor),
                            child: Icon(
                              Icons.camera_alt,
                              size: 30*ScaleUtils.scaleFactor,
                              color: Colors.white,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Form(
              key: _formKey,
              child: Padding(
                padding:  EdgeInsets.all(16.0*ScaleUtils.scaleFactor),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding:  EdgeInsets.all(8.0*ScaleUtils.scaleFactor),
                      child: TextFormField(
                        initialValue: displayName,
                        decoration: InputDecoration(
                          hintText: 'Enter Your Name',
                          labelText: 'Name',
                          labelStyle: TextStyle(fontSize: 18.0*ScaleUtils.scaleFactor),
                          floatingLabelStyle: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 20*ScaleUtils.scaleFactor,
                              color: HexColor('3957ED')),
                          border: OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: HexColor('3957ED'), width: 2)),
                          enabledBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: HexColor('3957ED'), width: 2),
                          ),
                          suffixIcon:
                              Icon(Icons.person, color: HexColor('3957ED')),
                        ),
                        onSaved: (value) {
                          displayName = value;
                        },
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please Enter Name';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(height: 16.0*ScaleUtils.verticalScale),
                    Padding(
                      padding:  EdgeInsets.all(8.0*ScaleUtils.scaleFactor),
                      child: TextFormField(
                        initialValue: phoneNumber,
                        decoration: InputDecoration(
                          hintText: 'Enter Your Phone number',
                          labelText: 'Phone number',
                          labelStyle: TextStyle(fontSize: 18.0*ScaleUtils.scaleFactor),
                          floatingLabelStyle: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 20*ScaleUtils.scaleFactor,
                              color: HexColor('3957ED')),
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.phone_android_outlined,
                              color: HexColor('3957ED')),
                          focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: HexColor('3957ED'), width: 2)),
                          enabledBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: HexColor('3957ED'), width: 2),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            phoneNumber = value;
                          });
                        },
                        onSaved: (value) {
                          phoneNumber = value;
                        },
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please Enter Phone No';
                          } else if (value.length < 10) {
                            return 'Enter 10 digit Phone number';
                          }
                          return null;
                        },
                      ),
                    ),
                    Center(
                      child: Padding(
                        padding:  EdgeInsets.symmetric(vertical: 8.0*ScaleUtils.verticalScale),
                        child: Text(
                          'Gender',
                          style: TextStyle(
                            fontSize: 16.0*ScaleUtils.scaleFactor,
                            color: HexColor('3957ED'),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Radio<String>(
                          value: 'Male',
                          groupValue: gender,
                          onChanged: (value) {
                            setState(() {
                              gender = value!;
                            });
                          },
                        ),
                        const Text('Male'),
                        Radio<String>(
                          value: 'Female',
                          groupValue: gender,
                          onChanged: (value) {
                            setState(() {
                              gender = value!;
                            });
                          },
                        ),
                        const Text('Female'),
                      ],
                    ),
                    SizedBox(height: 16.0*ScaleUtils.verticalScale),
                    (appprovider.isLoading)
                        ? Center(child: CircularProgressIndicator())
                        : Center(
                            child: InkWell(
                              onTap: () async {
                                FocusScope.of(context)
                                    .requestFocus(new FocusNode());
                                _formKey.currentState!.save();
                                if (_formKey.currentState!.validate()) {
                                  appprovider.changeIsLoading();
                                  if (_image != null) {
                                    late String imageurl;
                                    final FirebaseStorage storage =
                                        FirebaseStorage.instance;
                                    final picture =
                                        '${userProvider.getUser!.name.toString()} Id:--- ${userProvider.getUser!.uid.toString()} Time: ${DateTime.now().microsecondsSinceEpoch.toString()}.jpg';
                                    final File _imagep = File(_image!.path);
                                    UploadTask task = storage
                                        .ref()
                                        .child('Users/${picture}')
                                        .putFile(_imagep);
                                    TaskSnapshot snapshot = (await task
                                        .whenComplete(() => task.snapshot));
                                    await task.whenComplete(() async {
                                      imageurl =
                                          await snapshot.ref.getDownloadURL();
                                    });
                                    String image = imageurl;
                                    _firestore
                                        .collection("Users")
                                        .doc(userProvider.getUser!.uid)
                                        .update({'profile_photo': image});
                                  }
                                  _firestore
                                      .collection("Users")
                                      .doc(userProvider.getUser!.uid)
                                      .update({
                                    'phone_Number': phoneNumber,
                                    'gender': gender,
                                    'name': displayName,
                                  });
                                  userProvider.refreshUser();
                                  await Future.delayed(Duration(seconds: 2));
                                  appprovider.changeIsLoading();
                                  showToast("Changes Saved", backgroundColor: Colors.green, context: context);
                                  Navigator.pop(context);
                                }
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20*ScaleUtils.scaleFactor),
                                  color: HexColor("30B319"),
                                ),
                                child: Padding(
                                  padding:  EdgeInsets.all(14.0*ScaleUtils.scaleFactor),
                                  child: Text(
                                    "Save Changes",
                                    style: TextStyle(
                                        fontSize: 14*ScaleUtils.scaleFactor, color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  void selectImage(Future<XFile?> image) async {
    XFile? tempImage = await image;
    setState(() {
      _image = tempImage;
    });
  }

  _displayChild() {
    final userprovider = Provider.of<UserProvider>(context);
    if (_image == null) {
      return (userprovider.getUser!.profilePhoto == '')
          ? AssetImage('assets/user.jpg')
          : NetworkImage(userprovider.getUser!.profilePhoto ?? '');
    } else {
      final File _imagex = File(_image!.path);
      return FileImage(_imagex);
    }
  }
}
