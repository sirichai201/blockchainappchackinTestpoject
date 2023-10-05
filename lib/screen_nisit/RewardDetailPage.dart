import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RewardDetailPage extends StatefulWidget {
  final DocumentSnapshot reward;
  final double userCoins;
  final double balanceInEther;

  RewardDetailPage({required this.reward, required this.userCoins, required this.balanceInEther}); // แก้ไข constructor ให้รองรับ

  @override
  _RewardDetailPageState createState() => _RewardDetailPageState();
}

class _RewardDetailPageState extends State<RewardDetailPage> {
  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _redeemReward(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    final data = widget.reward.data() as Map<String, dynamic>;
    final coin = (data['coin'] as num?)?.toDouble() ?? 0.0;

    if (widget.userCoins < coin) {
      _showSnackBar(context, 'เหรียญไม่เพียงพอสำหรับการแลก');
      return;
    }

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final rewardRef = FirebaseFirestore.instance.collection('rewards').doc(widget.reward.id);
        final userRef = FirebaseFirestore.instance.collection('users').doc(user!.uid);

        final currentReward = await transaction.get(rewardRef);
        final currentUser = await transaction.get(userRef);

        int currentQuantity = currentReward['quantity'] ?? 0;
        double currentUserCoins = (currentUser['coins'] as num?)?.toDouble() ?? 0.0;

        if (currentQuantity <= 0) {
          _showSnackBar(context, 'ของรางวัลหมดแล้ว');
          return;
        }

        transaction.update(rewardRef, {'quantity': currentQuantity - 1});
        transaction.update(userRef, {'coins': currentUserCoins - coin});

        _showSnackBar(context, 'ทำการแลกเรียบร้อย');
        Navigator.pop(context);
      });
    } catch (e) {
      print('Error redeeming reward: $e');
      _showSnackBar(context, 'เกิดข้อผิดพลาด: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.reward.data() as Map<String, dynamic>;
    final name = data['name'] as String? ?? 'Unknown';
    final imageUrl = data['imageUrl'] as String? ?? '';
    final coin = (data['coin'] as num?)?.toDouble() ?? 0.0;
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
            Text('ยอดเหรียญของคุณ: ${widget.userCoins.toStringAsFixed(2)} เหรียญ'),
            SizedBox(height: 10.0),
            if (imageUrl.isNotEmpty) Image.network(imageUrl),
            Text('Name: $name'),
            Text('Cost: ${coin.toStringAsFixed(2)} coins'),
            Text('Remaining Quantity: $remainingQuantity'),
            ElevatedButton(
              onPressed: () => _redeemReward(context),
              child: Text('ยืนยันการแลกของรางวัล'),
            ),
          ],
        ),
      ),
    );
  }
}
