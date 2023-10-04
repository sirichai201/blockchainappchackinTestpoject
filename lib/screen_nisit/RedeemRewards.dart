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
  int? userCoins;

  @override
  void initState() {
    super.initState();
    _getUserCoins();
  }

  void _getUserCoins() async {
    if (widget.uid.isNotEmpty) {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(widget.uid).get();
      int? coins = userDoc['coins'] as int?;
      setState(() {
        userCoins = coins ?? 0;
      });
    } else {
      setState(() {
        userCoins = 0;
      });
    }
  }

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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: EdgeInsets.all(20.0), 
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blueAccent, width: 2.0),
                borderRadius: BorderRadius.circular(15.0),
                color: Color.fromARGB(255, 29, 124, 37),
              ),
              child: Text(
                'ยอดเหรียญของคุณ: ${userCoins ?? 'กำลังโหลด...'} เหรียญ',
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
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

      return ListView.builder(
        itemCount: snapshot.data!.docs.length,
        itemBuilder: (context, index) {
          final DocumentSnapshot reward = snapshot.data!.docs[index];
          final Map<String, dynamic> rewardData = reward.data() as Map<String, dynamic>;

          final String imageUrl = rewardData['imageUrl'] as String? ?? '';
          final String name = rewardData['name'] as String? ?? 'Unknown';
          final int coin = rewardData['coin'] as int? ?? 0;
          final int quantity = rewardData['quantity'] as int? ?? 0;

          return Card(
            margin: EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => RewardDetailPage(reward: reward),
                  ),
                );
              },
              child: ListTile(
                leading: imageUrl.isNotEmpty
                    ? Container(
                        width: 50.0,
                        height: 50.0,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage(imageUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    : null,
                title: Text(name),
                subtitle: Text('Cost: $coin coins - Available: $quantity'),
              ),
            ),
          );
        },
      );
    },
  ),
),
        ],
      ),
    );
  }
}

void main() => runApp(MaterialApp(home: RedeemRewards(uid: 'some-uid')));
