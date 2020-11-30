import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:monkoodog/DataProvider/DataProvider.dart';
import 'package:monkoodog/Modals/User.dart';
import 'package:provider/provider.dart';

class ProfileUpdateScreen extends StatefulWidget {
  @override
  _ProfileUpdateScreenState createState() => _ProfileUpdateScreenState();
}

class _ProfileUpdateScreenState extends State<ProfileUpdateScreen> {
  User user = User();

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration(milliseconds: 100)).then((value) async {
      user.uid = (await FirebaseAuth.instance.currentUser()).uid;
      setState(() {});
    });
  }

  @override
  Widget build(context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Update Profile"),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: Firestore.instance
            .collection('users')
            .document(user.uid)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasData) {
            user = User.fromJson(snap.data.data);
          }

          return (snap.data == null)
              ? Center(
                  child: CircularProgressIndicator(),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 10,
                    ),
                    Center(
                      child: InkWell(
                        onTap: () {
                          getImage(snap);
                        },
                        child: CircleAvatar(
                          backgroundColor: Colors.black12,
                          radius: 60,
                          child: (loading > 0)
                              ? CircularProgressIndicator(
                                  backgroundColor: Colors.white,
                                )
                              : Container(),
                          backgroundImage: (user.userUrl == null)
                              ? AssetImage("assets/images/logo.png")
                              : NetworkImage(user.userUrl),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    TextFormField(
                      onChanged: (val) {
                        user.displayName = val;
                      },
                      initialValue: user.displayName ?? "",
                      decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          labelText: "User Name"),
                    ),
                    SizedBox(
                      height: 15,
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.call,
                        color: Colors.black,
                      ),
                      title: Text(user.userPhone ?? ''),
                      trailing: Icon(Icons.edit),
                      onTap: () {},
                    ),
                    SizedBox(
                      height: 15,
                    ),
                    SizedBox(
                      height: 15,
                    ),
                    ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await snap.data.reference.updateData(user.toJson());
                          Provider.of<DataProvider>(context, listen: false)
                              .getUser();
                        },
                        child: Text("Save")),
                  ],
                );
        },
      ),
    );
  }

  Uint8List profileImage;
  double loading = 0;

  Future getImage(snap) async {

    loading =1;
    setState(() {

    });
    ImageSource source;

    await showDialog(
        context: context,
        child: Dialog(
          child: Wrap(
            children: [
              ListTile(
                onTap: () {
                  source = ImageSource.camera;

                  Navigator.pop(context);
                },
                title: Text("Camera"),
                trailing: Icon(Icons.camera_alt_rounded),
              ),
              ListTile(
                onTap: () {
                  source = ImageSource.gallery;
                  Navigator.pop(context);
                },
                title: Text("Gallery"),
                trailing: Icon(Icons.collections),
              ),
            ],
          ),
        ));

    var image = await ImagePicker()
        .getImage(maxWidth: 200, maxHeight: 200, source: source);
    profileImage = await image.readAsBytes();
    var storage = FirebaseStorage.instance.ref();
    var uploadTask = storage
        .child(DateTime.now().millisecondsSinceEpoch.toString())
        .putData(profileImage);


    user.userUrl = (await (await uploadTask.onComplete).ref.getDownloadURL());

    print(user.userUrl);
    await snap.data.reference.updateData(user.toJson());
    Provider.of<DataProvider>(context, listen: false)
        .getUser();
    saveProfile();
    loading = 0;
    setState(() {});

  }

  saveProfile() async {
    FirebaseUser user = await FirebaseAuth.instance.currentUser();


  }
}
