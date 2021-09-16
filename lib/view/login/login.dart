import 'package:chat_app_multiple_platforms/controller/login.dart';
import 'package:flutter/material.dart';

const double fontSize1 = 30.0;

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late TextEditingController _email;
  late TextEditingController _password;

  @override
  void initState() {
    _email = TextEditingController(text: '');
    _password = TextEditingController(text: '');

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double paddingX = width * (1 / 10);

    return Scaffold(
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxHeight: 200.0),
          decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 0.2, style: BorderStyle.solid),
              borderRadius: BorderRadius.all(Radius.circular(4.0))
          ),
          margin: EdgeInsets.only(left: paddingX, right: paddingX),
          child: Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
                      color: Colors.lightBlue,
                      child: Text(
                        'Login',
                        style: TextStyle(fontSize: fontSize1),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                child: TextField(
                  controller: _email,
                  decoration: InputDecoration(hintText: 'Email'),

                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                child: TextField(
                  controller: _password,
                  decoration: InputDecoration(hintText: 'Password'), obscureText: true,
                ),
              ),
              TextButton(onPressed: () {
                LoginController.signIn(this.context, _email.value.text, _password.value.text);
              }, child: Text('Sign in'))
            ],
          ),
        ),
      ),
    );
  }
}