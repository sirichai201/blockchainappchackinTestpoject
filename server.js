const express = require('express');
const Web3 = require('web3');

const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

const web3 = new Web3('http://192.168.1.3:7545');
 // หรือ endpoint ที่ถูกต้องของคุณ

const contractABI =   [
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
          "name": "date",
          "type": "uint256"
        },
        {
          "indexed": false,
          "internalType": "uint256",
          "name": "rewardAmount",
          "type": "uint256"
        }
      ],
      "name": "CheckedIn",
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
        },
        {
          "internalType": "uint256",
          "name": "",
          "type": "uint256"
        }
      ],
      "name": "attendanceRecords",
      "outputs": [
        {
          "internalType": "bool",
          "name": "",
          "type": "bool"
        }
      ],
      "stateMutability": "view",
      "type": "function"
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
      "inputs": [
        {
          "internalType": "uint256",
          "name": "date",
          "type": "uint256"
        }
      ],
      "name": "checkAttendanceAndReward",
      "outputs": [],
      "stateMutability": "nonpayable",
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
    }
  ];
const contractAddress = '0x17693a1A5Bc8623801BAA6Dd2a040821482BaB5B'; // หรือ address ที่ถูกต้องของคุณ

const contract = new web3.eth.Contract(contractABI, contractAddress);









app.post('/checkAttendanceAndReward', async (req, res) => {
    try {
      const { sender, date } = req.body;
      const response = await contract.methods.checkAttendanceAndReward(date).send({ from: sender });
      res.send(response);
    } catch (error) {
      console.error('Error:', error);
      res.status(500).send(error.toString());
    }
  });
  


app.get('/getBalance/:address', async (req, res) => {
    try {
        const address = req.params.address;
        const balance = await contract.methods.getBalance().call({ from: address });
        res.send({ balance });
    } catch (error) {
        console.error('เกิดข้อผิดพลาด:', error);
        res.status(500).send(error.toString());
    }
});
app.post('/sendSignedTransaction', async (req, res) => {
    try {
        const { rawTransaction } = req.body; // rawTransaction ที่ได้มาจาก Flutter
        const receipt = await web3.eth.sendSignedTransaction(rawTransaction);
        res.send(receipt);
    } catch (error) {
        console.error('Error:', error);
        res.status(500).send(error.toString());
    }
});









app.post('/createEthereumAddress', async (req, res) => {
    try {
      const { userId } = req.body; // รับ userId ที่ส่งมาจาก Client
      const account = web3.eth.accounts.create(); // สร้าง Ethereum Address ใหม่
      
      // ใช้ Firestore instance ที่ได้จาก Firebase Admin SDK
      const userDocRef = db.collection('users').doc(userId);
      await userDocRef.set({
        ethereumAddress: account.address, // ใช้ account.address ที่ได้จากการสร้าง Ethereum Address
      }, { merge: true });
  
      console.log('Ethereum Address:', account.address);
      console.log('Private Key:', account.privateKey);
      
      res.json({ ethereumAddress: account.address });
    } catch (error) {
      console.error('Error:', error);
      res.status(500).send(error.toString());
    }
  });
const PORT = 3000;
app.listen(PORT, () => console.log(`Server is running on port ${PORT}`));
