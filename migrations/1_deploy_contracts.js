const MyContractBlockchain = artifacts.require("MyContractBlockchain");
const MyContractchain = artifacts.require("MyContractchain");
const ContractA = artifacts.require("ContractA");

module.exports = async function (deployer, network, accounts) {
  // สร้างสัญญา MyContractBlockchain ก่อน
  await deployer.deploy(MyContractBlockchain);
  const myContractBlockchainInstance = await MyContractBlockchain.deployed();

  // สร้างสัญญา ContractA และกำหนดค่าเริ่มต้นเป็น 100
  await deployer.deploy(ContractA, 100);
  const contractAInstance = await ContractA.deployed();

  // สร้างสัญญา MyContractchain และส่งที่อยู่ของ ContractA และ MyContractBlockchain
  await deployer.deploy(MyContractchain, contractAInstance.address, myContractBlockchainInstance.address);
};
