import 'package:blockchainappchackin/screen_nisit/user_nisit.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


import 'RewardDetail.dart';


class RedeemRewards extends StatelessWidget {
  final String uid;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  RedeemRewards({required this.uid});

  static Future<void> showRedeemDialog(BuildContext context, String rewardId,
      Map<String, dynamic> rewardData) async {
    bool? isFirstConfirmation = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ยืนยันการแลก'),
        content: Text(
            'คุณต้องการแลก ${rewardData['name']} ใช้เหรียญ ${rewardData['cost']} coins หรือไม่?'),
        actions: [
          TextButton(
            child: Text('ยกเลิก'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: Text('ยืนยัน'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (isFirstConfirmation == true) {
      bool? isSecondConfirmation = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('ยืนยันการแลกอีกครั้ง'),
          content: Text('คุณแน่ใจหรือว่าต้องการแลก ${rewardData['name']}?'),
          actions: [
            TextButton(
              child: Text('ยกเลิก'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text('ยืนยัน'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      );

      if (isSecondConfirmation == true) {
        // Execute the redeem function or any other necessary transaction here.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => UserNisit()));
              }),
          title: Text('RedeemRewards')),
          
          
      body: Padding(
        padding: const EdgeInsets.only(top: 20.0), // เพิ่มระยะห่างจาก AppBar
        child: Column(
          children: [
            Container(
              width: 310,
              height: 70,
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 131, 125, 124), // สีแดงของกรอบ
                border: Border.all(color: const Color.fromARGB(255, 204, 182, 181), width: 1), // ขอบกรอบสีแดง
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      width: 50, // ตั้งค่าขนาดของวงกลม
                      height: 50, // ตั้งค่าขนาดของวงกลม
                      decoration: BoxDecoration(
                        shape: BoxShape.circle, // ทำให้เป็นวงกลม
                        image: DecorationImage(
                          image: NetworkImage('https://cdn.pixabay.com/photo/2017/06/13/12/54/profile-2398783_1280.png'), // ใส่ URL ของรูปภาพ
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 20, // เพิ่มระยะห่างระหว่างวงกลมและช่องสีเหลี่ยม
                  ),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white, // สีของช่องสีเหลี่ยม
                      shape: BoxShape.rectangle, // ทำให้เป็นรูปสี่เหลี่ยม
                    ),
                    child: Center(
                      child: Text('10'), // จำนวนเหรียญ
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 30,),
            Expanded(
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('rewards').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
      
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text('ไม่มีรางวัลที่สามารถแลกได้ในขณะนี้'));
            }
      
            final rewards = snapshot.data!.docs;
            return ListView.builder(
              itemCount: rewards.length,
              itemBuilder: (context, index) {
                final reward = rewards[index];
                final rewardData = reward.data() as Map<String, dynamic>;
      
                return ListTile(
                  leading: (rewardData['imageUrl'] != null &&
                          rewardData['imageUrl'] is String)
                      ? Image.network(rewardData['imageUrl'] as String)
                      : null,
                  title: Text(rewardData['name'] ?? 'Unknown'),
                  subtitle:
                      Text('Cost: ${rewardData['cost'] ?? 'Unknown'} coins'),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          RewardDetail(rewardData: rewardData, uid: uid),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
        ],),),);
    
  }
}


