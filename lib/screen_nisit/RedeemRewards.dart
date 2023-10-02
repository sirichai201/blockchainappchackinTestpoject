import 'package:blockchainappchackin/screen_nisit/User_nisit.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'RewardDetailPage.dart';

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
        title: Text('Redeem Rewards'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => UserNisit()));
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
              final imageUrl = reward['imageUrl'] as String? ?? '';

              return ListTile(
                leading: imageUrl.isNotEmpty
                    ? Container(
                        width: 50.0,
                        height: 50.0,
                        child: Image.network(imageUrl, fit: BoxFit.cover),
                      )
                    : null,
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

void main() => runApp(MaterialApp(home: RedeemRewards(uid: 'some-uid')));
