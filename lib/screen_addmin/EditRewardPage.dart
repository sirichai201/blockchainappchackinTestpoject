import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditRewardPage extends StatefulWidget {
  final Map<String, dynamic> reward;

  EditRewardPage({required this.reward});

  @override
  _EditRewardPageState createState() => _EditRewardPageState();
}

class _EditRewardPageState extends State<EditRewardPage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late TextEditingController _nameController;
  late TextEditingController _coinController;
  late TextEditingController _imageUrlController;
  late TextEditingController _quantityController;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.reward['name'] ?? '');
    _coinController = TextEditingController(text: widget.reward['coin']?.toString() ?? '');
    _imageUrlController = TextEditingController(text: widget.reward['imageUrl'] ?? '');
    _quantityController = TextEditingController(text: widget.reward['quantity']?.toString() ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _coinController.dispose();
    _imageUrlController.dispose();
    _quantityController.dispose();

    super.dispose();
  }

  _updateReward() async {
    if (_formKey.currentState!.validate()) {
      // Check if ID is present
      if (widget.reward['id'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: Document ID is missing!'))
        );
        return;
      }

      try {
        await _firestore.collection('rewards').doc(widget.reward['id']).update({
          'name': _nameController.text,
          'coin': int.parse(_coinController.text),
          'imageUrl': _imageUrlController.text,
          'quantity': int.parse(_quantityController.text),
        });

        Navigator.of(context).pop();
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating reward: $error'))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('แก้ไข้ของรางวัล'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _updateReward,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
              validator: (value) => value!.isEmpty ? 'Please enter a name' : null,
            ),
            TextFormField(
              controller: _coinController,
              decoration: InputDecoration(labelText: 'Coin Value'),
              keyboardType: TextInputType.number,
              validator: (value) => value!.isEmpty ? 'Please enter coin value' : null,
            ),
            TextFormField(
              controller: _imageUrlController,
              decoration: InputDecoration(labelText: 'Image URL'),
              validator: (value) => value!.isEmpty ? 'Please enter image URL' : null,
            ),
            TextFormField(
              controller: _quantityController,
              decoration: InputDecoration(labelText: 'Quantity'),
              keyboardType: TextInputType.number,
              validator: (value) => value!.isEmpty ? 'Please enter quantity' : null,
            ),
          ],
        ),
      ),
    );
  }
}
