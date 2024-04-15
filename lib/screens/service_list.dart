
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:servicez/constants.dart';

class ServiceList extends StatefulWidget {
  const ServiceList({super.key, required this.service_group});
  final String service_group;

  @override
  State<ServiceList> createState() => _ServiceListState();
}

class _ServiceListState extends State<ServiceList> {
  List<dynamic> services = [];
  String merchantKeyValue = "rzp_test_MGWGsjkJ3Kthbl";
  late Razorpay razorpay;
  late String selectedServiceGroup, selectedService, selectedServiceAmount, paymentId;

  @override
  void initState() {
    getServicesList();
    razorpay = Razorpay();
    super.initState();
  }

  void getServicesList() async{
    final result = await FirebaseFirestore.instance
                  .collection('services')
                  .where("service_group", isEqualTo: widget.service_group)
                  .get();
    for(var service in result.docs){
      services.add(service.data());
    }
    setState(() {
      services;
    });
  }

  Map<String, Object> getPaymentOptions(amountValue, serviceName, description) {
    return {
      'key': merchantKeyValue,
      'amount': int.parse(amountValue),
      'name': "$serviceName: $description",
      'description': description,
      'send_sms_hash': true,
      'prefill': {
        'email': usermail
      }
    };
  }

   void handlePaymentErrorResponse(PaymentFailureResponse response){
    showAlertDialog(context, "Payment Failed", "Code: ${response.code}\nDescription: ${response.message}");
  }

  void handlePaymentSuccessResponse(PaymentSuccessResponse response){

    saveServiceRequest(response.paymentId);
    showAlertDialog(context, "Payment Successful", "Payment ID: ${response.paymentId}");
  }

  showAlertDialog(context, String title, String message) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Disallows dismissing the dialog by tapping outside it
      builder: (BuildContext context2) {
        return CupertinoAlertDialog(
          title:  Text(title),
          content:  Text(message),
          actions: <Widget>[
            CupertinoDialogAction(
              child: const Text("Continue"),
              onPressed: () {
                Navigator.of(context).pop(); // Dismisses the dialog
                razorpay.clear();
              },
            ),
          ],
        );
      },
    );
  }

  void saveServiceRequest(paymentId){
    CollectionReference serviceRequests = FirebaseFirestore.instance.collection('service_requests');
    serviceRequests.add({
      'user': usermail,
      'service_group': selectedServiceGroup,
      'service_name': selectedService,
      'service_price': selectedServiceAmount,
      'status': 'Requested',
      'assigned_to': "",
      'payment_id': paymentId
    }).then((value) {
      print("Record added successfully with ID: ${value.id}");
    }).catchError((error) {
      print("Failed to add record: $error");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/background.jpg"),
              fit: BoxFit.cover,
            )
          ),
          child: Column(
            children: [
              const SizedBox(height: 10,),
              buildHeader(),
              const SizedBox(height: 10,),
              buildBody()
            ],
          ),
        ),
      ),
    );
  }

  Widget buildHeader(){
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(width: 10,),
          InkWell(
            onTap: () {
              Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6.0),
                color: Colors.white.withOpacity(0.6)
              ),
              child: const Icon(
                CupertinoIcons.back
              ),
            ),
          ),
          const SizedBox(width: 10,),
          Container(
            margin: const EdgeInsets.all(10),
            child: const Text(
            'ServiceZ App',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
              fontSize: 26,
            ),
            textAlign: TextAlign.left,
            ),
          )
        ],
      ),
    );
  }

  Widget buildBody(){
    return Container(
      child: buildCards(),
    );
  }

  Widget buildCards(){
    if(services.isEmpty){
      return const Text("Services not found");
    }

    List<Widget> cards = [];
    for(var service in services){
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
        borderRadius: BorderRadius.circular(6.0),
        color: Colors.white.withOpacity(0.6)
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Container(
            width: MediaQuery.of(context).size.width * 0.4,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6.0),
              image: DecorationImage(
                image: NetworkImage(service['image']),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 10,),
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
                  "Service Type: ${service['name']}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  "Service Charge: ₹${service['price']}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      selectedServiceGroup = service['service_group'];
                      selectedService = service['name'];
                      selectedServiceAmount = service['price'].toString();
                    });
                    merchantKeyValue = merchantKeyValue;
                    String amountValue = (int.parse(service['price'].toString()) * 100).toString();
                    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, handlePaymentErrorResponse);
                    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, handlePaymentSuccessResponse);
                    razorpay.open(getPaymentOptions(amountValue, service['service_group'], service['name']));
                  }, 
                  child: const Text("Book Now"))
              ],
            ),
          )
        ],
      ),
    );
  }

}