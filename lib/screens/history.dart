import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:servicez/constants.dart';
import 'package:servicez/screens/chat/chat.dart';
import 'package:servicez/screens/loader.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<dynamic> userServiceRequests = [];

  @override
  void initState() {
    configLoading();
    getUserServiceRequests();
    super.initState();
  }

  void getUserServiceRequests() async{
    final QuerySnapshot<Map<String, dynamic>> result;
    if(userRole == 'SuperAdmin'){
      result = await FirebaseFirestore.instance
                    .collection('service_requests')
                    .get();
    }else if(userRole=="Servicer"){
      result = await FirebaseFirestore.instance
                    .collection('service_requests')
                    .where("assigned_to", whereIn: [""])
                    .where("status", isNotEqualTo: "Cancelled")
                    .get();
    }else{
      result = await FirebaseFirestore.instance
                    .collection('service_requests')
                    .where("user", isEqualTo: usermail)
                    .get();
    }
    for(var service in result.docs){
      Map<dynamic, dynamic> serviceData = service.data();
      serviceData['docid'] = service.id;
      userServiceRequests.add(serviceData);
    }
    if(userRole=="Servicer"){
      final result = await FirebaseFirestore.instance
                    .collection('service_requests')
                    .where("assigned_to", isEqualTo: usermail)
                    .get();
      for(var service in result.docs){
        Map<dynamic, dynamic> serviceData = service.data();
        serviceData['docid'] = service.id;
        userServiceRequests.add(serviceData);
      }
    }
    setState(() {
      print(usermail);
      print(userRole);
      userServiceRequests;
    });
  }

  void updateStatusServiceRequest(docid, status) async{
    EasyLoading.show(status: 'loading...');
    FirebaseFirestore.instance
    .collection('service_requests')
    .doc(docid)
    .update({'status': status});
    userServiceRequests.clear();
    getUserServiceRequests();
    EasyLoading.dismiss();
    EasyLoading.showSuccess("$status Successfully");

  }
  
  void assignServiceRequest(docid) async{
    EasyLoading.show(status: 'loading...');
    FirebaseFirestore.instance
    .collection('service_requests')
    .doc(docid)
    .update({'status': 'Assigned'});
    FirebaseFirestore.instance
    .collection('service_requests')
    .doc(docid)
    .update({'assigned_to': usermail});
    userServiceRequests.clear();
    getUserServiceRequests();
    EasyLoading.dismiss();
    EasyLoading.showSuccess("Assigned Successfully");

  }

  Color getColorFromStatus(status){
    if(status == "Requested"){
      return Colors.blueAccent;
    } else if(status == "Cancelled"){
      return Colors.redAccent;
    } else if(status == "Completed"){
      return Colors.greenAccent;
    } else if(status == 'Assigned'){
      return Colors.green;
    }else{
      return Colors.black;
    }
  }

  IconData getIconFromStatus(status){
    if(status == "Requested"){
      return CupertinoIcons.person_alt_circle;
    } else if(status == "Cancelled"){
      return CupertinoIcons.xmark_circle_fill;
    } else if(status == "Completed"){
      return CupertinoIcons.check_mark_circled;
    }  else if(status == 'Assigned'){
      return CupertinoIcons.person_crop_circle_badge_checkmark;
    }else{
      return CupertinoIcons.checkmark_alt_circle_fill;
    }
  }

  void startChatRoom(toUser) async{
    String username = toUser.toString().split("@")[0];
    final result = await FirebaseFirestore.instance
                .collection('users')
                .where("firstName", isEqualTo: username)
                .get();
    var userObj = result.docs.first;
    Map<String, dynamic> userJson = userObj.data();
    userJson['id'] = userObj.id;
    types.User user = types.User(id: userObj.id);
    final room = await FirebaseChatCore.instance.createRoom(user);
    // ignore: use_build_context_synchronously
    Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatPage(room: room),
                ),
              );

  }

  @override
  Widget build(BuildContext context) {
    return buildBody();
  }

  Widget buildBody(){
    if(userServiceRequests.isEmpty){
      return const Text("Services not found");
    }

    List<Widget> cards = [];
    for(var service in userServiceRequests){
      cards.add(buildCard(service));
      cards.add(const SizedBox(height: 15,));
    }

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: cards,
        ),
      ),
    );
  }

  Widget buildCard(service){
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(
          color: getColorFromStatus(service['status']),
          width: 3.0
        ),
        borderRadius: BorderRadius.circular(6.0),
        color: Colors.white.withOpacity(0.6)
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50.0),
              color: getColorFromStatus(service['status']).withOpacity(0.5)
            ),
            child: Icon(
              getIconFromStatus(service['status']),
              color: getColorFromStatus(service['status']),
              size: 100,
            ),
          ),
          Container(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Service Group: ${service['service_group']}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  "Service Type: ${service['service_name']}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  "Service Charge: ₹${service['service_price']}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  "To: ${service['assigned_to']}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    service['status'] == 'Requested' && userRole == "Customer"?
                    InkWell(
                      onTap: (){
                        updateStatusServiceRequest(service['docid'], 'Cancelled');
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6.0),
                          color: Colors.redAccent.withOpacity(0.6)
                        ),
                        child: const Row(
                          children: [
                            Icon(CupertinoIcons.xmark, color: Colors.redAccent,),
                            SizedBox(width: 10,),
                            Text("Cancel", style: TextStyle(color: Colors.white),)
                          ],
                        ),
                      ),
                    ):const SizedBox(),
                    service['assigned_to'] != "" && service['status'] != 'Cancelled'
                    && service['status'] != 'Completed' ?
                    InkWell(
                      onTap: (){
                        var usermail = "";
                        if(userRole == "Servicer"){
                          usermail = service['user'];
                        }else if(userRole == "Customer"){
                          usermail = service['assigned_to'];
                        }
                        if(usermail != ""){
                          startChatRoom(usermail);
                        }else{
                          EasyLoading.showError("Error Occureed while Initiating Chat");
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6.0),
                          color: Colors.blueAccent.withOpacity(0.6)
                        ),
                        child: const Row(
                          children: [
                            Icon(CupertinoIcons.chat_bubble_2, color: Colors.blueAccent,),
                            SizedBox(width: 10,),
                            Text("Chat", style: TextStyle(color: Colors.white),)
                          ],
                        ),
                      ),
                    ):Container(),
                    userRole == "Servicer" && service['status'] == 'Requested'?
                    InkWell(
                      onTap: (){
                        assignServiceRequest(service['docid']);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6.0),
                          color: Colors.green.withOpacity(0.6)
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.settings, color: Colors.white,),
                            SizedBox(width: 10,),
                            Text("Fix It", style: TextStyle(color: Colors.white),)
                          ],
                        ),
                      ),
                    ):Container(),
                    userRole == "Servicer" && service['status'] == 'Assigned'?
                    InkWell(
                      onTap: (){
                        updateStatusServiceRequest(service['docid'], 'Completed');
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6.0),
                          color: Colors.green.withOpacity(0.6)
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.white,),
                            SizedBox(width: 10,),
                            Text("Done", style: TextStyle(color: Colors.white),)
                          ],
                        ),
                      ),
                    ):Container()
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

}