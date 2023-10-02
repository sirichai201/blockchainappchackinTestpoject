import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:blockchainappchackin/screen_addmin/user_admin.dart';

class RewardsList extends StatefulWidget {
  @override
  _RewardsListState createState() => _RewardsListState();
}

class _RewardsListState extends State<RewardsList> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rewards List'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => UserAdmin()),
            );
          },
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('rewards').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          final rewards = snapshot.data!.docs;
          return ListView.builder(
            itemCount: rewards.length,
            itemBuilder: (context, index) {
              final reward = rewards[index];
              final data = reward.data() as Map<String, dynamic>;

              final name = data.containsKey('name') ? data['name'] : 'No Name';
              final coin = data.containsKey('coin') ? data['coin'] : 'No Coin Value';
              final quantity = data.containsKey('quantity') ? data['quantity'] : 'No Quantity';
              final imageUrl = data.containsKey('imageUrl') ? data['imageUrl'] : null;

              return ListTile(
                title: Text(name),
                subtitle: Text('Coin: $coin Quantity: $quantity'),
                leading: imageUrl != null
                  ? Image.network(imageUrl, width: 50, fit: BoxFit.cover,)
                  : Icon(Icons.image_not_supported),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red,),
                  onPressed: () async {
                    await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Confirm Delete'),
                        content: Text('Are you sure you want to delete $name?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.of(context).pop();
                              await reward.reference.delete();
                            },
                            child: Text('Delete'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
