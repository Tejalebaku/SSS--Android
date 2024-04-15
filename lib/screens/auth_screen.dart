import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:servicez/constants.dart';
import 'package:servicez/screens/nav.dart';
import '/widgets/auth/auth_form.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});


  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  
  final _auth = FirebaseAuth.instance;

  var _isLoading = false;

  void _submitAuthForm(
    String email,
    String password,
    String userName,
    bool isLogin,
    BuildContext ctx,
  ) async {
    // ignore: unused_local_variable
    UserCredential userCredential;
    try {
      setState(() {
        _isLoading = true;
      });
      if (isLogin) {
        userCredential = await _auth.signInWithEmailAndPassword(
            email: email, password: password);
        final result = await FirebaseFirestore.instance
                  .collection('user_role')
                  .where("email", isEqualTo: email)
                  .get();
        if(result.docs.isNotEmpty){
          var resultData = result.docs.first.data();
          if(resultData.isNotEmpty){
            setState(() {
              userRole = resultData['role'];
            });
          }
        }
        setState(() {
          usermail = email;
          _isLoading = false;
        });
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) =>  const NavScreen()));
      } else {
        userCredential = await _auth.createUserWithEmailAndPassword(
            email: email, password: password);
        await FirebaseChatCore.instance.createUserInFirestore(
          types.User(
            firstName: email.split("@")[0],
            id: userCredential.user!.uid, // UID from Firebase Authentication
            imageUrl: 'https://i.pravatar.cc/300',
            lastName: '',
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    } on PlatformException catch (err) {
      var message = "An error occured please check your credentails";
      if (err.message != null) {
        message = err.message!;
      }

      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(ctx).colorScheme.error,
      ));

      setState(() {
        _isLoading = false;
      });
    } catch (err) {
      // ignore: avoid_print
      print(err);
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        content: Text("Invalid Credentials, $err"),
        backgroundColor: Theme.of(ctx).colorScheme.error,
      ));
      setState(() {
        _isLoading = false;
      });
    }
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AuthForm(_submitAuthForm, _isLoading),
    );
  }
}