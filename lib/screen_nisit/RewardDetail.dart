import 'package:flutter/material.dart';

import 'RedeemRewards.dart';

class RewardDetail extends StatelessWidget {
  final Map<String, dynamic> rewardData;
  final String uid;

  RewardDetail({required this.rewardData, required this.uid});

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
