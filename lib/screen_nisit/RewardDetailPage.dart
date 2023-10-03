import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RewardDetailPage extends StatelessWidget {
  final DocumentSnapshot reward;

  RewardDetailPage({required this.reward});

  Future<void> _decrementRewardQuantity(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('กรุณาเข้าสู่ระบบ')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final rewardDoc = FirebaseFirestore.instance.collection('rewards').doc(reward.id);
        final rewardData = (await transaction.get(rewardDoc)).data() as Map<String, dynamic>;
        int currentQuantity = rewardData['quantity'] ?? 0;

        if (currentQuantity > 0) {
          transaction.update(rewardDoc, {'quantity': currentQuantity - 1});

          await FirebaseFirestore.instance.collection('redeem_history').doc(user.uid).collection('items').add({
            'reward_name': rewardData['name'],
            'cost': rewardData['coin'],   // ทำการเปลี่ยนเป็น 'coin'
            'redeemed_at': Timestamp.now(),
            'imageUrl': rewardData['imageUrl'] ?? '',
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ทำการแลกเรียบร้อย')),
          );

          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ของรางวัลหมดแล้ว')),
          );
        }
      });
    } catch (e) {
      print('เกิดข้อผิดพลาดในการลดจำนวนของรางวัล: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = reward.data() as Map<String, dynamic>;
    final name = data['name'] as String? ?? 'Unknown';
    final imageUrl = data['imageUrl'] as String? ?? '';
    final coin = data['coin'] as int? ?? 0;   // ทำการเปลี่ยนเป็น 'coin'
    final remainingQuantity = data['quantity'] as int? ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text('รายละเอียดของรางวัล'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl.isNotEmpty)
              Image.network(imageUrl),
            Text('Name: $name'),
            Text('Cost: $coin coins'),   // ทำการเปลี่ยนเป็น 'coin'
            Text('Remaining Quantity: $remainingQuantity'),
            ElevatedButton(
              onPressed: remainingQuantity > 0 ? () async {
                bool? confirm = await showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('ยืนยันการแลกของ'),
                      content: Text('คุณต้องการแลกของรางวัลนี้หรือไม่?'),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text('ยกเลิก'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text('ยืนยัน'),
                        ),
                      ],
                    );
                  },
                );

                if (confirm == true) {
                  await _decrementRewardQuantity(context);
                }
              } : null,
              child: Text('ยืนยันการแลกของรางวัล'),
            ),
          ],
        ),
      ),
    );
  }
}
