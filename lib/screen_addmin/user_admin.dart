import 'package:flutter/material.dart';

import '../screen_login_user_all/login.dart';
import '../screen_nisit/RedeemRewards_nisit.dart';
import 'caeate_user.dart';

class UserAdmin extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Admin'),
        leading: IconButton(
          // ปุ่มย้อนกลับ
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => Login())); // ย้อนกลับไปหน้าก่อนหน้า
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            children: [
              // ปุ่มสำหรับการสร้างบัญชี
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => CreateUser()),
                  );
                },
                child: Text('สร้างบัญชี'),
              ),
              SizedBox(
                height: 20,
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => RedeemRewards(
                              uid: '',
                            )),
                  );
                },
                child: Text('จัดการของราวัล'),
              ),
              // คุณสามารถเพิ่มปุ่มหรือวิดเจ็ตอื่นๆ ที่ต้องการได้ที่นี่
            ],
          ),
        ),
      ),
    );
  }
}
