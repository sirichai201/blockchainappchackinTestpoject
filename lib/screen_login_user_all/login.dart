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

  Future<void> _login() async {
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
            // จัดการกับ role ที่ไม่รู้จัก (ถ้ามี)
            break;
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      if (e.code == 'user-not-found') {
        errorMessage = 'ไม่มีผู้ใช้ที่มีอีเมลนี้.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'รหัสผ่านไม่ถูกต้องสำหรับอีเมลนี้.';
      } else {
        errorMessage = 'เกิดข้อผิดพลาด: $e';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      String errorMessage = 'มีข้อผิดพลาด: $e';
      if (e is PlatformException && e.code == 'UNKNOWN') {
        errorMessage = 'เกิดข้อผิดพลาด: รหัสผ่านหรืออีเมลไม่ถูกต้อง';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
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
              Image.asset(
                'assets/images/ku.png',
                width: 100,
                height: 150,
              ),
              const SizedBox(height: 30.0),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              const SizedBox(height: 20.0),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              const SizedBox(height: 20.0),
              _loginButton(context),
              const SizedBox(height: 10.0),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ForgetPassword(),
                    ),
                  );
                },
                child: const Text('Forgot Password?'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _loginButton(BuildContext context) {
    return ElevatedButton(
      onPressed: _login, // เรียกฟังก์ชัน _login
      child: Text('Login', style: TextStyle(fontSize: 18)),
    );
  }
}
