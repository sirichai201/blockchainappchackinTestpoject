const express = require('express');
const Web3 = require('web3');
const { abi } = require('./abi.1');

const app = express();
const web3 = new Web3('http://localhost:8545'); // Change to your Ethereum node RPC URL

const contractAddress = '...'; // Change to your contract address
const contract = new web3.eth.Contract(abi, contractAddress);

app.post('/exchange', async (req, res) => {
  try {
    const { data, from } = req.body;
    const gasPrice = await web3.eth.getGasPrice();
    const gasEstimate = await contract.methods.exchangeDataForTokens(data).estimateGas({ from });

    const receipt = await contract.methods.exchangeDataForTokens(data).send({ from, gasPrice, gas: gasEstimate });
    res.send({ success: true, transactionHash: receipt.transactionHash });
  } catch (error) {
    console.error(error);
    res.status(500).send({ success: false, error: error.message });
  }
});

app.listen(3000, () => console.log('Server running on port 3000'));