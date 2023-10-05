import 'package:blockchainappchackin/screen_nisit/User_nisit.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'RewardDetailPage.dart';
import 'recordRedeemHistory.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;



class RedeemRewards extends StatefulWidget {
  final String uid;
  

  RedeemRewards({required this.uid});

  @override
  _RedeemRewardsState createState() => _RedeemRewardsState();
}

class _RedeemRewardsState extends State<RedeemRewards> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // double? userCoins; // <-- Use double for coins
 double? balanceInEther;
  @override
  void initState() {
    super.initState();
   
    // _getUserCoins();
  }

  // void _getUserCoins() async {
  //   if (widget.uid.isNotEmpty) {
  //     DocumentSnapshot userDoc = await _firestore.collection('users').doc(widget.uid).get();
  //     double? coins = (userDoc['coins'] as num?)?.toDouble(); // <-- Convert to double
  //     setState(() {
  //       userCoins = coins ?? 0.0;
  //     });
  //   } else {
  //     setState(() {
  //       userCoins = 0.0;
  //     });
  //   }
  // }


Future<void> getBalance(String ethAddress) async {
    print('Fetching balance for Ethereum address: $ethAddress...');

    final url = 'http://10.0.2.2:3000/getBalance/$ethAddress';
    final response = await http.get(Uri.parse(url));
    print(response.body);
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (responseData.containsKey('balanceInEther')) {
        try {
          balanceInEther =
              double.parse(responseData['balanceInEther'].toString());
          print('Balance fetched successfully. Current Balance in Ether: $balanceInEther');

          // ทำสิ่งที่คุณต้องการด้วย balanceInEther
        } catch (e) {
          print('Error parsing balanceInEther: $e');
        }
      } else {
        print('Error with the response: ${response.body}');
      }
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
                'ยอดเหรียญของคุณ: ${balanceInEther?.toStringAsFixed(2) ?? '0'} เหรียญ', // <-- Display with 2 decimal places
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
                    final double coin = (rewardData['coin'] as num?)?.toDouble() ?? 0.0; // <-- Convert to double
                    final int quantity = rewardData['quantity'] as int? ?? 0;

                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
                      child: ListTile(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => RewardDetailPage(reward: reward, userCoins: balanceInEther ?? 0.0, balanceInEther: balanceInEther ?? 0.0),

                            ),
                          );
                        },
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
                            : Icon(Icons.image_not_supported),
                        title: Text(name),
                        subtitle: Text('Cost: ${coin.toStringAsFixed(2)} coins - Available: $quantity'),
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
