import 'dart:io';
import 'package:blockchainappchackin/screen_addmin/user_admin.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';


class CreateRewards extends StatefulWidget {
  @override
  _CreateRewardsState createState() => _CreateRewardsState();
}

class _CreateRewardsState extends State<CreateRewards> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  String? name;
  double? balanceInEther;  // ใช้ balanceInEther แทนตัวแปร coin
  int? quantity;
  File? _imageFile;


  Future<void> pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> addReward() async {
    if (_formKey.currentState?.validate() == true) {
      _formKey.currentState?.save();

      String? imageUrl;
      if (_imageFile != null) {
        final ref = _storage.ref('rewards/${DateTime.now().toIso8601String()}');
        await ref.putFile(_imageFile!);
        imageUrl = await ref.getDownloadURL();
      }

      await _firestore.collection('rewards').add({
        'name': name,
        'imageUrl': imageUrl,
        'coin': balanceInEther,
        'quantity': quantity,
      });

      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => UserAdmin()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('สร้างของรางวัล'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => UserAdmin()));
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (_imageFile != null) Image.file(_imageFile!),
              ElevatedButton(
                onPressed: pickImage,
                child: Text('เลือกรูปภาพ'),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'ชื่อของรางวัล'),
                validator: (value) => value?.isEmpty == true ? 'กรุณาใส่ชื่อของรางวัล' : null,
                onSaved: (value) => name = value,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'จำนวนเหรียญที่ต้องการ'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) => value == null || double.tryParse(value) == null
                    ? 'กรุณาใส่จำนวนเหรียญในรูปแบบที่ถูกต้อง'
                    : null,
                onSaved: (value) => balanceInEther = double.tryParse(value ?? '0'),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'จำนวนของรางวัล'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value == null || int.tryParse(value) == null
                        ? 'กรุณาใส่จำนวนของรางวัลในรูปแบบที่ถูกต้อง'
                        : null,
                onSaved: (value) => quantity = int.tryParse(value ?? '0'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: addReward,
                child: Text('ยืนยัน'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
