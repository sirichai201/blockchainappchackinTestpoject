import 'package:blockchainappchackin/screen_nisit/User_nisit.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'RewardDetailPage.dart';
import 'recordRedeemHistory.dart';

class RedeemRewards extends StatefulWidget {
  final String uid;

  RedeemRewards({required this.uid});

  @override
  _RedeemRewardsState createState() => _RedeemRewardsState();
}

class _RedeemRewardsState extends State<RedeemRewards> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('รายการของรางวัล'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => UserNisit()));
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => RecordRedeemHistory()),
              );
            },
          ),
        ],
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
              final DocumentSnapshot reward = snapshot.data!.docs[index];
              final Map<String, dynamic> rewardData = reward.data() as Map<String, dynamic>;

              final String imageUrl = rewardData.containsKey('imageUrl') ? rewardData['imageUrl'] as String : '';
              final String name = rewardData.containsKey('name') ? rewardData['name'] as String : 'Unknown';
              final int coin = rewardData.containsKey('coin') ? rewardData['coin'] as int : 0;
            
              final int quantity = rewardData.containsKey('quantity') ? rewardData['quantity'] as int : 0; // เพิ่มบรรทัดนี้

              return ListTile(
                leading: imageUrl.isNotEmpty
                    ? Container(
                        width: 50.0,
                        height: 50.0,
                        child: Image.network(imageUrl, fit: BoxFit.cover),
                      )
                    : null,
                title: Text(name),
                
                subtitle: Text('Cost: $coin coins - Available: $quantity'), // แสดงจำนวนคงเหลือที่นี่
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

void main() => runApp(MaterialApp(home: RedeemRewards(uid: 'some-uid')));
