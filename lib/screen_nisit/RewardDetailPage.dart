import 'package:blockchainappchackin/screen_nisit/User_nisit.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// อย่าลืม import หน้า UserNisit และทำการ import ทุกสิ่งที่จำเป็น

class RedeemRewards extends StatefulWidget {
  final String uid;

  RedeemRewards({required this.uid});

  @override
  _RedeemRewardsState createState() => _RedeemRewardsState();
}

class _RedeemRewardsState extends State<RedeemRewards> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> redeemReward(DocumentSnapshot reward) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final data = reward.data() as Map<String, dynamic>;
        final quantity = data['quantity'] as int;

        if (quantity <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ของรางวัลหมดแล้ว')),
          );
          return;
        }

        transaction.update(reward.reference, {'quantity': quantity - 1});
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('การแลกของรางวัลสำเร็จ')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('การแลกของรางวัลล้มเหลว: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Redeem Rewards'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => UserNisit())); // ย้อนกลับไปหน้าก่อนหน้านี้
          },
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('rewards').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('ไม่มีรางวัลที่สามารถแลกได้ในขณะนี้'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final reward = snapshot.data!.docs[index];

              return ListTile(
                title: Text(reward['name'] ?? 'Unknown'),
                subtitle: Text('Cost: ${reward['cost'] ?? 'Unknown'} coins'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => RewardDetailPage(reward: reward),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class RewardDetailPage extends StatelessWidget {
  final DocumentSnapshot reward;

  RewardDetailPage({required this.reward});

  @override
  Widget build(BuildContext context) {
    final data = reward.data() as Map<String, dynamic>;
    final name = data['name'] as String? ?? 'Unknown';
    final imageUrl = data['imageUrl'] as String? ?? '';
    final cost = data['cost'] as int? ?? 0;
    final description = data['description'] as String? ?? 'No description available';

    return Scaffold(
      appBar: AppBar(
        title: Text('Reward Detail'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl.isNotEmpty)
              Image.network(imageUrl),
            Text('Name: $name'),
            Text('Cost: $cost coins'),
            Text('Description: $description'),
          ],
        ),
      ),
    );
  }
}
