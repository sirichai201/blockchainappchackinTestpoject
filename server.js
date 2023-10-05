const express = require('express');
const admin = require('firebase-admin');
const Web3 = require('web3');
const cors = require('cors');
const app = express();
const bodyParser = require('body-parser');
require('dotenv').config();
app.use(bodyParser.json()); 
app.use(cors());
app.use(express.json());
const web3 = new Web3('http://127.0.0.1:7545');



const contractABI = [
  {
    "inputs": [],
    "stateMutability": "nonpayable",
    "type": "constructor"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "address",
        "name": "student",
        "type": "address"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "amount",
        "type": "uint256"
      }
    ],
    "name": "Rewarded",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "address",
        "name": "student",
        "type": "address"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "amount",
        "type": "uint256"
      }
    ],
    "name": "SpentCoin",
    "type": "event"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "",
        "type": "address"
      }
    ],
    "name": "balances",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "owner",
    "outputs": [
      {
        "internalType": "address",
        "name": "",
        "type": "address"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "deposit",
    "outputs": [],
    "stateMutability": "payable",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "getBalance",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "amount",
        "type": "uint256"
      }
    ],
    "name": "spendCoin",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "student",
        "type": "address"
      }
    ],
    "name": "rewardStudent",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  }
];
const contractAddress = '0x469559b1Bb19E22B9CD0C49E5FC03960130dB123';

const contract = new web3.eth.Contract(contractABI, contractAddress);

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

    const senderAddress = '0x469559b1Bb19E22B9CD0C49E5FC03960130dB123';
    const privateKey = process.env.PRIVATE_KEY;
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

const PORT = 3000;
app.listen(PORT, () => console.log(`เซิร์ฟเวอร์กำลังทำงานที่พอร์ต ${PORT}`));
