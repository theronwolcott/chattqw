import 'user_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:flutter_login/theme.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  final UserState _userState = UserState();
  Duration get loginTime => const Duration(milliseconds: 2250);

  Future<String?> _authUser(LoginData data) {
    debugPrint('Name: ${data.name}, Password: ${data.password}');
    return _userState.login(data.name, data.password);
  }

  Future<String?> _signupUser(SignupData data) {
    debugPrint('Signup Name: ${data.name}, Password: ${data.password}');
    return _userState.signup(
        data.name!,
        data.password!,
        data.additionalSignupData!['firstName']!,
        data.additionalSignupData!["lastName"]!);
  }

  Future<String?> _recoverPassword(String name) async {
    debugPrint('Name: $name');
    return "Feature not implemented";
  }

  void _close(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final overlayContext = Overlay.of(context)!.context;
    final double topPadding = MediaQuery.of(overlayContext).padding.top;
    return Stack(
      children: [
        FlutterLogin(
          // title: 'ChatTQW',
          logo: const AssetImage('assets/images/app_logo_dark.png'),
          onLogin: _authUser,
          onSignup: _signupUser,
          additionalSignupFields: [
            UserFormField(
              keyName: 'firstName',
              displayName: "First Name",
              fieldValidator: (value) {
                if (value == null || value.isEmpty) {
                  return 'First name cannot be empty';
                }
                return null;
              },
            ),
            UserFormField(
              keyName: 'lastName',
              displayName: "Last Name",
              fieldValidator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Last name cannot be empty';
                }
                return null;
              },
            ),
          ],
          onSubmitAnimationCompleted: () {
            _close(context);
          },
          onRecoverPassword: _recoverPassword,
          messages: LoginMessages(
            signUpSuccess: "You're in!",
          ),
        ),
        Positioned(
          top: topPadding,
          child: IconButton(
            iconSize: 40.0,
            icon: const Icon(Icons.close),
            onPressed: () {
              _close(context);
            },
          ),
        )
      ],
    );
  }
}
