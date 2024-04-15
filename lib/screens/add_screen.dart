import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:servicez/screens/loader.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

class AddScreen extends StatefulWidget {
  const AddScreen({super.key});

  @override
  State<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> {
  List<String> serviceGroupsNames = [];
  bool addServiceSelected = true;
  bool addUserSelected = false;
  final _formKey = GlobalKey<FormBuilderState>();
  final _formKey2 = GlobalKey<FormBuilderState>();

  @override
  void initState() {
    // TODO: implement initState
    configLoading();
    getServiceGroupsNames();
    super.initState();
  }

  void getServiceGroupsNames() async {
    var collection = FirebaseFirestore.instance.collection('service_group');
    var snapshot = await collection.get();
    for (var user in snapshot.docs) {
      serviceGroupsNames.add(user.data()['name'].toString());
    }

    setState(() {
      serviceGroupsNames;
    });
  }

  void addServicer(email, password) async {
    EasyLoading.show(status: 'adding...');
    final auth = FirebaseAuth.instance;
    UserCredential userCredential;
    try {
      userCredential = await auth.createUserWithEmailAndPassword(
          email: email, password: password);
      CollectionReference userRole =
          FirebaseFirestore.instance.collection('user_role');
      userRole.add({'email': email, 'role': "Servicer"}).then((value) {
        print("Servicer added");
      }).catchError((error) {
        print("Failed to add servicer: $error");
      });
      await FirebaseChatCore.instance.createUserInFirestore(
        types.User(
          firstName: email.split("@")[0],
          id: userCredential.user!.uid, // UID from Firebase Authentication
          imageUrl: 'https://i.pravatar.cc/300',
          lastName: '',
        ),
      );
    } catch (e) {
      EasyLoading.showError("Unable to add User. Error: $e");
    }
    EasyLoading.dismiss();
  }

  void addService(imageUrl, name, price, serviceGroup) async {
    EasyLoading.show(status: 'adding...');
    try {
      CollectionReference service =
          FirebaseFirestore.instance.collection('services');
      service.add({
        'image': imageUrl,
        'name': name,
        'price': price,
        'service_group': serviceGroup
      }).then((value) {
        print("Servicer added");
      }).catchError((error) {
        print("Failed to add servicer: $error");
      });
    } catch (e) {
      EasyLoading.showError("Unable to add Service. Error: $e");
    }
    EasyLoading.dismiss();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(
                left: 10.0, top: 2.0, right: 10.0, bottom: 2.0),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6.0),
                color: Colors.white.withOpacity(0.6)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                InkWell(
                  onTap: () {
                    setState(() {
                      addUserSelected = false;
                      addServiceSelected = true;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    width: MediaQuery.of(context).size.width * 0.4,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6.0),
                        color: addServiceSelected
                            ? Colors.blue.withOpacity(0.6)
                            : Colors.white),
                    child: Text(
                      "Add Service",
                      style: TextStyle(
                        color: addServiceSelected ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    setState(() {
                      addUserSelected = true;
                      addServiceSelected = false;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    width: MediaQuery.of(context).size.width * 0.4,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6.0),
                        color: addUserSelected
                            ? Colors.blue.withOpacity(0.6)
                            : Colors.white),
                    child: Text(
                      "Add Servicer",
                      style: TextStyle(
                        color: addUserSelected ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6.0),
                color: Colors.white.withOpacity(0.6)),
            child: buildForm(),
          ),
        ],
      ),
    );
  }

  Widget buildForm() {
    if (addUserSelected) {
      return Container(
        child: FormBuilder(
          key: _formKey,
          child: Column(
            children: [
              FormBuilderTextField(
                name: 'email',
                decoration: const InputDecoration(labelText: 'Email'),
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                  FormBuilderValidators.email(),
                ]),
              ),
              const SizedBox(height: 10),
              FormBuilderTextField(
                name: 'password',
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                ]),
              ),
              MaterialButton(
                color: Colors.blueAccent,
                onPressed: () {
                  _formKey.currentState?.validate();
                  debugPrint(_formKey.currentState?.instantValue.toString());
                  Map<String, dynamic> formData =
                      _formKey.currentState!.instantValue;
                  addServicer(formData['email'], formData['password']);
                  _formKey.currentState!.reset();
                },
                child: const Text('Login'),
              )
            ],
          ),
        ),
      );
    }
    return Container(
      child: FormBuilder(
        key: _formKey2,
        child: Column(
          children: [
            FormBuilderDropdown(
              name: "service_group",
              decoration:
                  const InputDecoration(labelText: ' Select Service Group'),
              items: serviceGroupsNames
                  .map((serviceGroupName) => DropdownMenuItem(
                        alignment: AlignmentDirectional.center,
                        value: serviceGroupName,
                        child: Text(serviceGroupName),
                      ))
                  .toList(),
            ),
            FormBuilderTextField(
              name: 'name',
              decoration: const InputDecoration(labelText: 'Service Name'),
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(),
              ]),
            ),
            const SizedBox(height: 10),
            FormBuilderTextField(
              name: 'price',
              decoration: const InputDecoration(labelText: 'Service Price'),
              obscureText: false,
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(),
              ]),
            ),
            const SizedBox(height: 10),
            FormBuilderTextField(
              name: 'image',
              decoration: const InputDecoration(labelText: 'Image Url'),
              obscureText: false,
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(),
              ]),
            ),
            MaterialButton(
              color: Colors.blueAccent,
              onPressed: () {
                _formKey2.currentState?.validate();
                debugPrint(_formKey2.currentState?.instantValue.toString());
                Map<String, dynamic> formData =
                    _formKey2.currentState!.instantValue;
                addService(formData['image'], formData['name'],
                    formData['price'], formData['service_group']);
                _formKey2.currentState!.reset();
              },
              child: const Text('Add Service'),
            )
          ],
        ),
      ),
    );
  }
}
