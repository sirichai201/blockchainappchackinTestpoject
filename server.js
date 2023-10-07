
require('dotenv').config();

const express = require('express');
const admin = require('firebase-admin');
const Web3 = require('web3');

const app = express();
const bodyParser = require('body-parser');

app.use(bodyParser.json()); 

app.use(express.json());
const web3 = new Web3('http://127.0.0.1:7545');

const cors = require('cors');
app.use(cors());



const privateKey = process.env.PRIVATE_KEY;
const { abi } = require('./build/contracts/MyContract.json');

const senderAddress = process.env.SENDER_ADDRESS;
const contractAddress = process.env.CONTRACT_ADDRESS;
const contract = new web3.eth.Contract(abi, contractAddress);

const serviceAccount = require('./projectblockchainapp-9defb-firebase-adminsdk-2doub-bab55a8ad3.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();



app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.path}`);
  next();
});

// สร้าง endpoint '/sendEther' ด้วย HTTP POST method สำหรับการส่ง Ether
app.post('/sendEther', async (req, res) => {
  try {
    const { receiverAddress } = req.body;

    // ตรวจสอบว่า receiverAddress ที่ได้รับมาเป็น Ethereum address ที่ถูกต้องหรือไม่
    if (!web3.utils.isAddress(receiverAddress)) {
      return res.status(400).send('ที่อยู่ Ethereum ไม่ถูกต้อง');
    }
    console.log(`เริ่มต้นการส่ง Ether ไปยัง ${receiverAddress}...`);

  
    const amountInEther = '0.05';
    const amountInWei = web3.utils.toWei(amountInEther, 'ether');

    const rawTransaction = {
      from: senderAddress,
      to: receiverAddress, // ใช้ receiverAddress ที่ได้รับมา
      gas: await contract.methods.rewardStudent(receiverAddress).estimateGas({from: senderAddress}),
      data: contract.methods.rewardStudent(receiverAddress).encodeABI(),
      value: amountInWei
    };

    const signedTransaction = await web3.eth.accounts.signTransaction(rawTransaction, privateKey);
    const receipt = await web3.eth.sendSignedTransaction(signedTransaction.rawTransaction);
    console.log('Transaction Receipt:', receipt);

    res.json({ rewardAmount: amountInEther });
    console.log(`ส่ง Ether ไปยัง ${receiverAddress} สำเร็จ.`);
  } catch (error) {
    console.error('ผิดพลาด:', error);
    res.status(500).send(error.toString());
  }
});




app.post('/createEthereumAddress', async (req, res) => {
  let userId; 

  try {
      if (!req.body || !req.body.userId) {
          return res.status(400).send('ต้องการ userId');
      }

      userId = req.body.userId;

      const account = web3.eth.accounts.create();

      const userDocRef = db.collection('users').doc(userId);
      await userDocRef.set({
        ethereumAddress: account.address,
      }, { merge: true });
  
      res.json({
        ethereumAddress: account.address,
        ethereumPrivateKey: account.privateKey
      });
    } catch (error) {
        console.error('ผิดพลาด:', error);
        console.error('รับ userId:', userId); 
        res.status(500).send(error.toString());
    }
});

app.get('/getBalance/:address', async (req, res) => {
  try {
      const address = req.params.address;
      if (!web3.utils.isAddress(address)) {
          return res.status(400).send('ที่อยู่ Ethereum ไม่ถูกต้อง');
      }

      const balanceInWei = await web3.eth.getBalance(address);
      const balanceInEther = web3.utils.fromWei(balanceInWei, 'ether');

      res.json({
          address: address,
          balanceAmount: balanceInWei,
          balanceInEther: balanceInEther
      });
  } catch (error) {
      console.error('ผิดพลาด:', error);
      res.status(500).send(error.toString());
  }
});

// สร้างของรางวัล
app.post('/addReward', async (req, res) => {
  
  try {
    // แสดงข้อมูลที่ส่งมาจาก Flutter
    console.log('Received data from Flutter:', req.body);

    const { name, coinCost, quantity } = req.body;

    const tx = await contract.methods.addReward(name, coinCost, quantity).send({ from: senderAddress });

    if (tx.status === true) {
        // ส่ง response กลับไปยัง Flutter ในรูปแบบ JSON
        res.json({
            status: 'success',
            message: 'Reward added successfully.',
            data: {
                name: name,
                coinCost: coinCost,
                quantity: quantity
            }
        });
    } else {
        throw new Error('Failed to add reward in smart contract.');
    }
  } catch (error) {
    console.error('Error:', error);
    res.status(500).send('Internal Server Error.');
  }
});



// ดูรายการของรางวัล
app.get('/getRewards', async (_, res) => {
  try {
      const rewardsList = await contract.methods.getRewards().call();
      res.json(rewardsList);
  } catch (error) {
      console.error('Error:', error);
      res.status(500).send('Internal Server Error.');
  }
});

// แลกของรางวัล
app.post('/exchangeReward', async (req, res) => {
  try {
      const { userAddress, rewardIndex } = req.body;
      const tx = await contract.methods.redeemReward(rewardIndex).send({ from: userAddress });
      if (tx.status === true) {
          res.status(200).send('Reward exchanged successfully.');
      } else {
          throw new Error('Failed to exchange reward in smart contract.');
      }
  } catch (error) {
      console.error('Error:', error);
      res.status(500).send('Internal Server Error.');
  }
});

// ดูประวัติการแลก
app.get('/getRedemptionHistory/:userAddress', async (req, res) => {
  try {
      const userAddress = req.params.userAddress;
      const history = await contract.methods.getRedemptionHistory(userAddress).call();
      res.json(history);
  } catch (error) {
      console.error('Error:', error);
      res.status(500).send('Internal Server Error.');
  }
});






const PORT = 3000;
app.listen(PORT, () => console.log(`เซิร์ฟเวอร์กำลังทำงานที่พอร์ต ${PORT}`));
