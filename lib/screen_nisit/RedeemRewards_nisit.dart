import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../gobal/drawerbar_nisit.dart';
import '../screen_addmin/user_admin.dart';

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
                    MaterialPageRoute(builder: (context) => UserAdmin()));
              }),
          title: Text('RedeemRewards')),
      body: StreamBuilder<QuerySnapshot>(
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
                        RewardDetailPage(rewardData: rewardData, uid: uid),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class RewardDetailPage extends StatelessWidget {
  final Map<String, dynamic> rewardData;
  final String uid;

  RewardDetailPage({required this.rewardData, required this.uid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('คีย์บอร์ดเกมมิ่ง รุ่น ALISTAR X33'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (rewardData['imageUrl'] != null &&
              rewardData['imageUrl'] is String)
            Image.network(rewardData['imageUrl'] as String),
          Text(rewardData['name'] ?? 'คีย์บอร์ดเกมมิ่ง รุ่น ALISTAR X33'),
          Text('Cost: ${rewardData['cost'] ?? 'Unknown'} coins'),
          Container(
            width: 100.0,
            height: 100.0,
            child: (rewardData['imageUrl'] != null &&
                    rewardData['imageUrl'] is String)
                ? Image.network(rewardData['imageUrl'] as String,
                    fit: BoxFit.cover)
                : const Placeholder(),
          ),
          ElevatedButton(
            onPressed: () {
              RedeemRewards.showRedeemDialog(
                  context, rewardData['id'] ?? '', rewardData);
            },
            child: Text('ยืนยันการแลก'),
          ),
        ],
      ),
    );
  }
}
