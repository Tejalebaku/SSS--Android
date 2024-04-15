import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:servicez/screens/service_list.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late List<dynamic> users;
  @override
  void initState(){
    users = [];
    getServiceGroups();
    super.initState();
  }
  void getServiceGroups() async {
    var collection = FirebaseFirestore.instance.collection('service_group');
    var snapshot = await collection.get();
    for (var user in snapshot.docs){
      users.add(user.data());
    }
    setState(() {
      users;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: buildBody(),
      ),
    );
  }

  Widget buildBody(){
    if(users.isNotEmpty){
       var lastUser = users.last;
       List<Widget> body = [];
       for(var index=0; index<users.length~/2; index++){
        buildSerivcegroupRows(body, index);
       }
       body.add(buidLastServiceGroupCard(lastUser));

       return Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: body,
          )
        );
    }
    return Container();
  }

  buildSerivcegroupRows(body, index){
    var firstUser = users[index];
    var secondUser = users[index + 1];
    body.add(Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          buidLastServiceGroupCard(firstUser),
          buidLastServiceGroupCard(secondUser)
        ],
      ),
    ));
    return body;
  }

  buidLastServiceGroupCard(user){
    return InkWell(
      onTap: () {
        Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ServiceList(service_group: user['name']),
                ),
              );
      },
      child: Container(
        width: MediaQuery.of(context).size.width * 0.4,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6.0),
          image: DecorationImage(
            image: NetworkImage(user['image']),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6.0),
            color: Colors.white.withOpacity(0.6)
          ),
          child: Text(
            user['name'],
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            ),
        ),
      ),
    );
  }
}