import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart';
import 'package:monkoodog/DataProvider/DataProvider.dart';
import 'package:monkoodog/Modals/NewPet.dart';
import 'package:monkoodog/Widgets/ToogleButton.dart';
import 'package:monkoodog/utils/age.dart';
import 'package:monkoodog/utils/utiles.dart';
import 'package:multiselectable_dropdown/multiselectable_dropdown.dart';
import 'package:provider/provider.dart';

class AddPetScreen extends StatefulWidget {
  @override
  _AddPetScreenState createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  var genderSelected = [true, false];
  var breedSelected = [true, false];
  Uint8List profileImage;

  var feedBackController = TextEditingController();
  var petNameController = TextEditingController();

  var formkey = GlobalKey<FormState>();

  List _diseasesResult = [];
  List _allergiesResult = [];

  var selectedDiseases = "", selectedAllergies = "";
  var step = 1;

  buildBottomButton() {
    var user = Provider.of<FirebaseUser>(context);
    var location = Provider.of<DataProvider>(context).userLocation;
    return ClipRRect(
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      child: InkWell(
        onTap: () async {
          if (step == 1) {
            if (formkey.currentState.validate()) {
              if (selectedPrimaryBreed == null) {
                showErrorDialog("OOPS, Please select primary breed");
              } else if (!imageExists) {
                showErrorDialog("OOPS, Please upload image of pet");
              }else if(age==null){
                showErrorDialog("OOPS, Please select date of birth of pet");
              }
              else {
                step = 2;
                setState(() {});
              }
            }
          } else {
            showLoadingDialog();
            String gender =
                genderSelected.indexOf(true) == 0 ? "Male" : "Female";
            Geoflutterfire geo = Geoflutterfire();

            var pet = NewPet(
              position: geo
                  .point(
                      latitude: location.latitude,
                      longitude: location.longitude)
                  .data,
              diseases: _diseasesResult,
              dob: age.toString().substring(0, 10),
              gender: gender,
              longitude: location.longitude,
              created: DateTime.now().toString(),
              id: user.uid,
              latitude: location.latitude,
              name: petNameController.text,
              age: Age.weeks(
                      fromDate: age,
                      toDate: DateTime.now(),
                      includeToDate: false)
                  .toString(),
              userId: user.uid,
              loves: feedBackController.text,
              primaryBreed: selectedPrimaryBreed,
              secondaryBreed: selectedSecondaryBreed,
              media: profileImageUrl.toString(),
              allergies: _allergiesResult,
              breed: selectedPrimaryBreed,
              breedType: selectedSecondaryBreed == null ? 0 : 1,
            );

            await Firestore.instance
                .collection("pets")
                .add(NewPet.getData(pet));
            Navigator.pop(context);
            showSuccesDialog();
            setState(() {});
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: Utiles.primaryBgColor,
          ),
          height: 75,
          child: Center(
              child: Text(
            step == 2 ? "Finish" : "Next",
            style: Theme.of(context)
                .textTheme
                .headline6
                .copyWith(color: Colors.white),
          )),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // if(Provider.of<DataProvider>(context).userLocation==null)
    //   Provider.of<DataProvider>(context, listen: false).getdata();
  }

  List breeds;
  DateTime age;
  FocusNode focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    breeds = Provider.of<DataProvider>(context).breeds;
    return WillPopScope(
      onWillPop: () async {
        bool status = false;
        showDialog(
            context: context,
            child: AlertDialog(
              title: Text("Do you want to exit"),
              actions: [
                FlatButton(
                    onPressed: () {
                      Navigator.pop(context);
                      return true;
                    },
                    child: Text("Continue")),
                FlatButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    child: Text("Quit")),
              ],
            ));

        return status;
      },
      child: Scaffold(
        key: scaffold_key,
        resizeToAvoidBottomPadding: false,
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text("Add Pet"),
        ),
        bottomNavigationBar: buildBottomButton(),
        body: step == 2
            ? buildAddPet2()
            : Form(
                key: formkey,
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  physics: BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      Container(
                        height: 160,
                        padding: EdgeInsets.all(8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Fill dog's info",
                                    style: Theme.of(context)
                                        .textTheme
                                        .headline6
                                        .copyWith(color: Colors.black),
                                  ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  buildWithHeading(
                                    "Name",
                                    TextFormField(
                                      validator: (val) =>
                                          val.isEmpty ? "Enter Pet Name" : null,
                                      controller: petNameController,
                                      focusNode: focusNode,
                                      decoration: InputDecoration(
                                          hintText: "Enter Name"),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Column(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: () {
                                        getImage();
                                      },
                                      child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 0, vertical: 10),
                                            child: (profileImage != null)
                                                ? Image.memory(profileImage)
                                                : Image.asset(
                                                    "assets/images/dog.png",
                                                    fit: BoxFit.cover,
                                                  ),
                                          )),
                                    ),
                                  ),
                                  Text(
                                    "Upload photo",
                                    style: TextStyle(color: Colors.black54),
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                              flex: 5,
                              child: buildWithHeading(
                                  "Date of Birth",
                                  Container(
                                    decoration: BoxDecoration(
                                        boxShadow: [
                                          BoxShadow(
                                              spreadRadius: 1,
                                              color: Colors.black12,
                                              blurRadius: 3)
                                        ],
                                        borderRadius: BorderRadius.circular(10),
                                        color: Colors.white),
                                    child: ListTile(
                                      onTap: () async {
                                        var currentdate = DateTime.now();
                                        age = await showDatePicker(
                                            context: context,
                                            initialDate:
                                                DateTime(currentdate.year - 3),
                                            firstDate:
                                                DateTime(currentdate.year - 3),
                                            lastDate: currentdate);
                                        setState(() {});
                                      },
                                      title: Text(age == null
                                          ? "Select Date"
                                          : age.toString().substring(0, 10)),
                                      trailing: Icon(
                                        Icons.calendar_today_rounded,
                                        size: 30,
                                      ),
                                    ),
                                  ))),
                          Expanded(
                            flex: 3,
                            child: SizedBox(),
                          )
                        ],
                      ),
                      Container(
                        padding: EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 10,
                            ),
                            buildWithHeading(
                                "Gender",
                                ToogleButtonColored(
                                  onTap: (val) {
                                    for (int i = 0;
                                        i < genderSelected.length;
                                        i++)
                                      genderSelected[i] = !genderSelected[i];

                                    setState(() {});
                                    genderSelected[val] = true;
                                  },
                                  buttons: [" Male ", "Female"],
                                )),
                            SizedBox(
                              height: 10,
                            ),
                            buildWithHeading(
                                "Breed",
                                ToogleButtonColored(
                                  onTap: (val) {
                                    for (int i = 0;
                                        i < breedSelected.length;
                                        i++) breedSelected[i] = false;

                                    breedSelected[val] = true;
                                    setState(() {});
                                  },
                                  buttons: ["Pure", "Mix"],
                                )),
                            SizedBox(
                              height: 10,
                            ),
                            buildWithHeading(
                                "Choose Primary Breed",
                                InkWell(
                                  onTap: () {
                                    buildSearchBottomSheet(true);
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        vertical: 18, horizontal: 24),
                                    decoration: BoxDecoration(
                                        boxShadow: [
                                          BoxShadow(
                                              spreadRadius: 1,
                                              color: Colors.black12,
                                              blurRadius: 3)
                                        ],
                                        borderRadius: BorderRadius.circular(10),
                                        color: Colors.white),
                                    child: Text(selectedPrimaryBreed ??
                                        "Select Primary Breed"),
                                  ),
                                )),
                            SizedBox(
                              height: 10,
                            ),
                            (breedSelected[1])
                                ? buildWithHeading(
                                    "Choose Secondary Breed",
                                    InkWell(
                                      onTap: () {
                                        buildSearchBottomSheet(false);
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                            vertical: 18, horizontal: 24),
                                        decoration: BoxDecoration(
                                            boxShadow: [
                                              BoxShadow(
                                                  spreadRadius: 1,
                                                  color: Colors.black12,
                                                  blurRadius: 3)
                                            ],
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            color: Colors.white),
                                        child: Text(selectedSecondaryBreed ??
                                            "Select Secondary Breed"),
                                      ),
                                    ))
                                : SizedBox()
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  buildAddPet2() {
    List<MultipleSelectItem> _diseases =
        Provider.of<DataProvider>(context).diseases;
    List<MultipleSelectItem> _allergies =
        Provider.of<DataProvider>(context).allergies;
    return Container(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            Text(
              "",
              style: Theme.of(context)
                  .textTheme
                  .headline6
                  .copyWith(color: Colors.black),
            ),
            SizedBox(
              height: 30,
            ),
            buildWithHeading(
                "Does your dog have any allergies?",
                Container(
                  width: MediaQuery.of(context).size.width,
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                            spreadRadius: 1,
                            color: Colors.black12,
                            blurRadius: 3)
                      ],
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white),
                  child: MultipleDropDown(
                    placeholder: 'Select Allergies',
                    disabled: false,
                    values: _allergiesResult,
                    elements: _allergies,
                  ),
                ),
                optional: true),
            SizedBox(
              height: 10,
            ),
            buildWithHeading(
                "Does your dog have any diseases?",
                Container(
                  width: MediaQuery.of(context).size.width,
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                            spreadRadius: 1,
                            color: Colors.black12,
                            blurRadius: 3)
                      ],
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white),
                  child: MultipleDropDown(
                    placeholder: 'Select Disease',
                    disabled: false,
                    values: _diseasesResult,
                    elements: _diseases,
                  ),
                ),
                optional: true),
            SizedBox(
              height: 10,
            ),
            buildWithHeading(
                "Tell us what your dog loves",
                Container(
                  width: MediaQuery.of(context).size.width,
                  height: 200,
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                            spreadRadius: 1,
                            color: Colors.black12,
                            blurRadius: 3)
                      ],
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white),
                  child: TextFormField(
                    keyboardType: TextInputType.multiline,
                    maxLines: 5,
                    maxLength: 250,
                    controller: feedBackController,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(14),
                      hintText: 'Tell us what your dog loves',
                    ),
                    onSaved: (String value) {
                      // This optional block of code can be used to run
                      // code when the user saves the form.
                    },
                    /*  validator: (String value) {
                                              return value.isEmpty
                                                  ? 'Please Type feedback'
                                                  : null;
                                            },*/
                  ),
                ),
                optional: true),
            SizedBox(
              height: 10,
            ),
          ],
        ),
      ),
    );
  }

  buildWithHeading(title, Widget, {optional}) {
    if (optional == null) {
      optional = false;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title ${optional ? "" : "*"}',
        ),
        SizedBox(
          height: 10,
        ),
        Align(
          alignment: Alignment.center,
          child: Widget,
        )
      ],
    );
  }

  var bottomSheetController;
  String selectedPrimaryBreed = null, selectedSecondaryBreed = null;
  var scaffold_key = GlobalKey<ScaffoldState>();
  Widget suggestionList = SizedBox();

  buildSearchBottomSheet(isPrimary) {
    suggestionList = buildListModels(breeds, isPrimary);
    if (focusNode.hasFocus) focusNode.unfocus();

    focusNode.unfocus();

    bottomSheetController = scaffold_key.currentState.showBottomSheet(
        (context) => Container(
              child: Column(
                children: [
                  ListTile(
                    title: Text(
                      "Choose Breed",
                      style: Theme.of(context).textTheme.headline6,
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.close,color: Colors.red,),
                      onPressed: (){
                        if(isPrimary)
                          {
                            selectedPrimaryBreed =null;
                          }else{
                          selectedSecondaryBreed = null;
                        }
                        Navigator.pop(context);
                      }
                      ,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextFormField(
                      autofocus: true,
                      onFieldSubmitted: (val) {
                        if (isPrimary)
                          selectedPrimaryBreed = val;
                        else
                          selectedSecondaryBreed = val;
                      },
                      onChanged: (val) {
                        print(breeds.toString());
                        suggestionList = buildListModels(
                            breeds
                                .where((element) =>
                                    element.contains(val.toLowerCase()))
                                .toList(),
                            isPrimary);
                        print(suggestionList.toString());
                        bottomSheetController.setState(() {});

                        if (isPrimary)
                          selectedPrimaryBreed = val;
                        else
                          selectedSecondaryBreed = val;
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: "Type Breed here",
                      ),
                    ),
                  ),
                  suggestionList
                ],
              ),
            ),
        backgroundColor: Colors.white,
        clipBehavior: Clip.hardEdge);
  }

  Widget buildListModels(List stringList, bool isPrimary) {
    return Container(
      height: MediaQuery.of(context).size.height * .8,
      child: ListView.builder(
        physics: BouncingScrollPhysics(),
        itemCount: stringList.length,
        itemBuilder: (context, index) => Card(
          child: ListTile(
            onTap: () {
              if (isPrimary)
                selectedPrimaryBreed = stringList[index];
              else
                selectedSecondaryBreed = stringList[index];

              Navigator.pop(context);
            },
            title: Text(
              stringList[index],
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.subtitle1,
            ),
          ),
        ),
      ),
    );
  }

  var imageUploading = true;
  var imageExists = false;
  var profileImageUrl;

  var imageUploadingProgress = 0.0;

  LocationData userLocation;

  getUserLocation() async {
    userLocation = await Location().getLocation();
    setState(() {});
  }

  Future getImage() async {
    if (profileImageUrl != null)
      (await FirebaseStorage.instance.getReferenceFromUrl(profileImageUrl))
          .delete();
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

    if (!mounted) return;

    profileImage = await image.readAsBytes();
    setState(() {
      imageExists = true;
      imageUploading = true;
    });

    showDialog(
        useSafeArea: true,
        barrierDismissible: false,
        context: context,
        useRootNavigator: false,
        child: AlertDialog(
          title: Image.asset(
            'assets/images/pet_vector.png',
            height: 90,
            width: 90,
          ),
          content: Wrap(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: LinearProgressIndicator(),
              ),
              Text(
                "Image is Uploading Please wait....",
                style: Theme.of(context)
                    .textTheme
                    .headline6
                    .copyWith(color: Colors.black),
              )
            ],
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
    var storage = FirebaseStorage.instance.ref();
    var uploadTask = storage
        .child(DateTime.now().millisecondsSinceEpoch.toString())
        .putData(profileImage);

    uploadTask.events.listen((event) {});

    var imageUrl = (await (await uploadTask.onComplete).ref.getDownloadURL());

    //dismiss the dialog
    Navigator.pop(context);
    print(imageUrl);
    setState(() {
      imageUploading = false;

      imageUploadingProgress = 0.0;
    });
    profileImageUrl = imageUrl.toString();
    imageExists = true;
    setState(() {});
  }

  @override
  void dispose() {
    // FirebaseStorage.instance.getReferenceFromUrl(profileImageUrl);
  }

  showErrorDialog(message) {
    showDialog(
        context: context,
        child: AlertDialog(
          title: Icon(
            Icons.info,
            color: Colors.red,
            size: 30,
          ),
          content: Text(message),
          actions: [
            FlatButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text("Retry"))
          ],
        ));
  }

  showSuccesDialog() {
    showDialog(
        context: context,
        child: AlertDialog(
          title: Image.asset(
            'assets/images/paw.png',
            width: 70,
            height: 70,
          ),
          content: Text(
            "Congratulations",
            style: Theme.of(context)
                .textTheme
                .headline6
                .copyWith(color: Colors.black),
          ),
          actions: [
            FlatButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: Text("Ok"))
          ],
        ));
  }

  bool validate() {
    if (formkey.currentState.validate()) {}
  }

  showLoadingDialog() {
    showDialog(
        context: context,
        child: AlertDialog(
          title: Image.asset(
            'assets/images/pet_vector.png',
            height: 90,
            width: 90,
          ),
          content: Wrap(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: LinearProgressIndicator(),
              ),
              Text(
                "Pet is adding please wait....",
                style: Theme.of(context)
                    .textTheme
                    .headline6
                    .copyWith(color: Colors.black),
              )
            ],
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
  }
}
