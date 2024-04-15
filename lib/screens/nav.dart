import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:servicez/constants.dart';
import 'package:servicez/screens/add_screen.dart';
import 'package:servicez/screens/auth_screen.dart';
import 'package:servicez/screens/chat/rooms.dart';
import 'package:servicez/screens/dashboard.dart';
import 'package:servicez/screens/history.dart';
import 'package:sliding_clipped_nav_bar/sliding_clipped_nav_bar.dart';

class NavScreen extends StatefulWidget {
  const NavScreen({Key? key}) : super(key: key);

  @override
  _NavScreenState createState() => _NavScreenState();
}

class _NavScreenState extends State<NavScreen> {
  late PageController _pageController;
  int selectedIndex = 0;
  List<BarItem> barItems=[];
  final List<Widget> _listOfWidget=[];
  final bool _colorful = false;
  @override
  void initState() {
    generateNabButtons();
    super.initState();
    _pageController = PageController(initialPage: selectedIndex);
  }

  generateNabButtons(){
    _listOfWidget.add(
      Container(
        alignment: Alignment.center,
        child: const DashboardScreen(),
      )
    );
    _listOfWidget.add(
        Container(
          alignment: Alignment.center,
          child: const HistoryScreen(),
        )
      );
    barItems.add(
      BarItem(
        icon: Icons.home,
        title: 'Home',
      )
    );
    barItems.add(
      BarItem(
        icon: Icons.history_rounded,
        title: 'History',
      )
    );

    if(userRole == 'SuperAdmin'){
      _listOfWidget.add(
        Container(
          alignment: Alignment.center,
          child: const AddScreen(),
        )
      );
      barItems.add(
        BarItem(
          icon: Icons.tune_sharp,
          title: 'Add',
        )
      );
      
    }else{
      _listOfWidget.add(
        Container(
          alignment: Alignment.center,
          child: const RoomsPage(),
        )
      );
      barItems.add(
        BarItem(
            icon: CupertinoIcons.chat_bubble_2,
            title: 'Chat',
          )
      );
    }

    setState(() {
      barItems;
      _listOfWidget;
    });
      
  }

  void onButtonPressed(int index) {
    setState(() {
      selectedIndex = index;
    });
    _pageController.animateToPage(selectedIndex,
        duration: const Duration(milliseconds: 400), curve: Curves.easeOutQuad);
  }

  void logout() async{
    setState(() {
      userRole='Customer';
    });
    await FirebaseAuth.instance.signOut();
    Navigator.push(context, MaterialPageRoute(builder: (context) => const AuthScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/background.jpg"),
            fit: BoxFit.cover,
          )
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SafeArea(
                child: Container(
                  margin: const EdgeInsets.all(10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                      'ServiceZ App',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                        fontSize: 26,
                      ),
                      textAlign: TextAlign.left,
                      ),
                      InkWell(
                        onTap: () {
                         logout();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6.0),
                            color: Colors.white.withOpacity(0.6)
                          ),
                          child: const Icon(
                            Icons.logout,
                            color: Colors.redAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              ),
            Expanded(
              child: PageView(
                physics: const NeverScrollableScrollPhysics(),
                controller: _pageController,
                children: _listOfWidget,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SlidingClippedNavBar(
              backgroundColor: Colors.white,
              onButtonPressed: onButtonPressed,
              iconSize: 30,
              activeColor: const Color(0xFF01579B),
              selectedIndex: selectedIndex,
              barItems: barItems,
            ),
    );
  }
}
