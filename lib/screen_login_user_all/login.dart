// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

import '../screen_addmin/user_admin.dart';
import '../screen_lecturer/User_lecturer.dart';
import '../screen_nisit/User_nisit.dart';
import 'forget_password.dart';

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool isValidEmail(String email) {
    final RegExp regex = RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
    return regex.hasMatch(email);
  }

  Future<void> _login() async {
    if (!isValidEmail(_usernameController.text.trim())) {
      _showErrorSnackBar(context, 'รูปแบบอีเมลไม่ถูกต้อง');
      return;
    }
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
              email: _usernameController.text,
              password: _passwordController.text);

      if (userCredential.user != null) {
        final userId = userCredential.user!.uid;
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        final userRole = doc.data()?['role'] ?? '';

        switch (userRole) {
          case 'นิสิต':
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => UserNisit()));
            break;
          case 'อาจารย์':
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => UserLecturer()));
            break;
          case 'admin':
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => UserAdmin()));
            break;
          default:
            _showErrorSnackBar(context, 'ไม่พบ role ของผู้ใช้');
            break;
        }
      }
    } on FirebaseAuthException catch (e) {
      print("Error code: ${e.code}");
      switch (e.code) {
        case 'user-not-found':
          _showErrorSnackBar(context, 'ไม่มีผู้ใช้งานที่มีอีเมลนี้');
          break;
        case 'wrong-password':
          _showErrorSnackBar(context, 'รหัสผ่านไม่ถูกต้อง');
          break;
        default:
          _showErrorSnackBar(context, 'มีข้อผิดพลาด: $e');
          break;
      }
    } on PlatformException catch (e) {
      print("PlatformException: $e");
      if (e.code == 'ERROR_INVALID_EMAIL') {
        _showErrorSnackBar(context, 'รูปแบบอีเมลไม่ถูกต้อง');
      } else {
        _showErrorSnackBar(context, 'มีข้อผิดพลาดเกิดขึ้นในระบบ: $e');
      }
    } catch (e) {
      print("General Exception: $e");
      _showErrorSnackBar(context, 'มีข้อผิดพลาดเกิดขึ้น: $e');
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('เข้าสู่ระบบ')),
      ),
      body: Padding(
        padding: EdgeInsets.all(30.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLogo(),
              const SizedBox(height: 30.0),
              _buildUsernameField(),
              const SizedBox(height: 20.0),
              _buildPasswordField(),
              const SizedBox(height: 20.0),
              _loginButton(context),
              const SizedBox(height: 10.0),
              _buildForgetPasswordButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Image.asset(
      'assets/images/ku.png',
      width: 100,
      height: 150,
    );
  }

  Widget _buildUsernameField() {
    return TextField(
      controller: _usernameController,
      decoration: const InputDecoration(labelText: 'Username'),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: true,
      decoration: const InputDecoration(labelText: 'Password'),
    );
  }

  Widget _loginButton(BuildContext context) {
    return ElevatedButton(
      onPressed: _login,
      child: Text('Login', style: TextStyle(fontSize: 18)),
    );
  }

  Widget _buildForgetPasswordButton(BuildContext context) {
    return TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ForgetPassword(),
          ),
        );
      },
      child: const Text('Forgot Password?'),
    );
  }
}
