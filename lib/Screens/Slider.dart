import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:liquid_swipe/Helpers/Helpers.dart';
import 'package:liquid_swipe/liquid_swipe.dart';
import 'package:monkoodog/Screens/HomePage/HomePage.dart';
import 'package:monkoodog/Screens/Login.dart';
import 'package:monkoodog/utils/utiles.dart';

class SliderPage extends StatefulWidget {
  @override
  _SliderPageState createState() => _SliderPageState();
}

class _SliderPageState extends State<SliderPage> {
  var isLooged = false;

  checcklogin() async {
    //emulator checking
    // await FirebaseAuth.instance.signInAnonymously();
    FirebaseUser user = await FirebaseAuth.instance.currentUser();
    if (user != null) {
      setState(() {
        isLooged = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    checcklogin();
  }

  int selctedPage =0;
  @override
  Widget build(BuildContext context) {
    return (isLooged)
        ? HomePage()
        : Scaffold(
      body: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 0,
            child: LiquidSwipe(
              enableSlideIcon: true,
              waveType: WaveType.liquidReveal,
              enableLoop: false,
              initialPage: 0,
              onPageChangeCallback: (val) {

                selctedPage = val;
                setState(() {

                });
              },
              pages: [
                buildSinglePage(
                    'Welcome to\nMonkoodog',
                    'Best app for your dog',
                    "assets/slide1.png",
                    Utiles.primaryBgColor,
                    isLast: false),
                buildSinglePage(
                    'Set your Location',
                    'Set your location to search nearby pets and pet services',
                    'assets/images/screen2.png',
                    Utiles.primaryButton,
                    isLast: false),
                buildSinglePage(
                    'Keep Health Track',
                    'Get your dog health \ninsights, next due date for\nvaccines and lot more.',
                    'assets/vet2.png',
                    Utiles.primaryBgColor,
                    isLast: true),
              ],
            ),
          ),

          (selctedPage==2)?Container():Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Row(

            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children:[
              buildSingleDot(0==selctedPage),
              buildSingleDot(1==selctedPage),
              buildSingleDot(2==selctedPage),
            ]

          ))
        ],
      ),
    );
  }

  Widget buildSingleDot(selected) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8),
      height: 12,
      width: 12,
      decoration: BoxDecoration(
          color: (selected)?Colors.white:Colors.grey,
          shape: BoxShape.circle
      ),
    );
  }


  Widget buildSinglePage(title, subtitle, image, color, {isLast}) {
    return Stack(
      children: [
        Container(
          color: color,
        ),
        Padding(
          padding: EdgeInsets.only(top: 70, left: 0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Text(
                  title,
                  style: Theme
                      .of(context)
                      .textTheme
                      .headline4
                      .copyWith(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(
                height: 30,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Text(
                  subtitle,
                  style: Theme
                      .of(context)
                      .textTheme
                      .headline5
                      .copyWith(
                      color: Colors.white, fontWeight: FontWeight.normal),
                ),
              ),
              SizedBox(
                height: 40,
              ),
              SizedBox(
                height: 10,
              ),
              Expanded(
                  child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Image.asset(
                        image,
                        fit: BoxFit.fitWidth,
                      )))
            ],
          ),
        ),
        (isLast) ? Container() : Positioned(
            right: 0,
            top: 0,
            bottom: 0,

            child: FlatButton(
              child: Text("Skip", style: Theme
                  .of(context)
                  .textTheme
                  .headline6
                  .copyWith(color: Colors.white),),
              onPressed: () {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => LoginScreen()));
              },
            )),
        (!isLast) ? Container() : Positioned(
          left: 0,
          bottom: 0,
          right: 0,
          child: InkWell(
            onTap: () {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => LoginScreen()));
            },
            child: Container(
              height: 60,
              color: Utiles.primaryButton,
              child: Center(
                child: Text(
                  "Get Started",
                  style: Theme
                      .of(context)
                      .textTheme
                      .headline6
                      .copyWith(color: Colors.white),
                ),
              ),
            ),
          ),
        )
      ],
    );
  }
}
