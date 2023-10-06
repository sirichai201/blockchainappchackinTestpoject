import 'package:blockchainappchackin/screen_nisit/User_nisit.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
   late final String currentUserUid;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late User? currentUser;
  // double? userCoins; // <-- Use double for coins
 double? balanceInEther;
  @override
void initState() {
  super.initState();
  getCurrentUser().then((_) => _printUserEthereumAddress());
}





 Future<void> getCurrentUser() async {
    print('Fetching current user...');

    currentUser = FirebaseAuth.instance.currentUser;
  }

 Future<void> _printUserEthereumAddress() async {
  await getCurrentUser();
  if (currentUser?.uid != null) {
    String? ethAddress = await fetchUserEthereumAddress(currentUser!.uid);
    if (ethAddress != null) {
      print('Ethereum Address for user ${currentUser?.uid} is $ethAddress');
      setState(() {
        currentUserUid = ethAddress;
      });
    } else {
      print('Failed to fetch Ethereum Address for user UID: ${currentUser?.uid}');
    }
  } else {
    print('currentUserUid is null. Cannot fetch Ethereum Address.');
  }
}



 Future<String?> fetchUserEthereumAddress(String uid) async {
    final userDocument = await _firestore.collection('users').doc(uid).get();

    if (userDocument.exists) {
      return userDocument.data()?['ethereumAddress'];
    } else {
      print('No user found for this UID: $uid');
      return null;
    }
  }





Stream<double?> getBalanceStream() async* {
  while (true) {
    await Future.delayed(const Duration(seconds: 5)); 
    print('Fetching balance for Ethereum address: $currentUserUid...');
    final url = 'http://10.0.2.2:3000/getBalance/$currentUserUid';
    final response = await http.get(Uri.parse(url));
    print(response.body);
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      if (responseData.containsKey('balanceInEther')) {
        try {
          balanceInEther = double.parse(responseData['balanceInEther'].toString());
yield balanceInEther;

          print('Balance fetched successfully. Current Balance in Ether: $balanceInEther');
        } catch (e) {
          print('Error parsing balanceInEther: $e');
          yield null;
        }
      } else {
        yield null;
      }
    } else {
      yield null;
    }
  }
}







  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายการของรางวัล'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => UserNisit()));
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
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
    padding: const EdgeInsets.all(20.0),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.blueAccent, width: 2.0),
      borderRadius: BorderRadius.circular(15.0),
      color: const Color.fromARGB(255, 29, 124, 37),
    ),
    child: StreamBuilder<double?>(
      stream: getBalanceStream(),
      builder: (BuildContext context, AsyncSnapshot<double?> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData) {
          return const Text('กำลังโหลด...');
        }
        return Text(
          'ยอดเหรียญของคุณ: ${snapshot.data?.toStringAsFixed(2) ?? '0'} เหรียญ',
          style: const TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        );
      },
    ),
  ),
),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('rewards').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('ไม่มีรางวัลที่สามารถแลกได้ในขณะนี้'));
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
                      margin: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
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
                            : const Icon(Icons.image_not_supported),
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

