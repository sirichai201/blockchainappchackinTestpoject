const MyContractBlockchain = artifacts.require("MyContractBlockchain");
const MyContractchain = artifacts.require("MyContractchain");
const ContractA = artifacts.require("ContractA");
const AttendanceContract = artifacts.require("AttendanceContract");

module.exports = async function (deployer, network, accounts) {
  // สร้างสัญญา MyContractBlockchain ก่อน
  await deployer.deploy(MyContractBlockchain);
  const myContractBlockchainInstance = await MyContractBlockchain.deployed();

  // สร้างสัญญา ContractA และกำหนดค่าเริ่มต้นเป็น 100
  await deployer.deploy(ContractA, 100);
  const contractAInstance = await ContractA.deployed();

  // สร้างสัญญา MyContractchain และส่งที่อยู่ของ ContractA และ MyContractBlockchain
  await deployer.deploy(MyContractchain, contractAInstance.address, myContractBlockchainInstance.address);

  // สร้างสัญญา AttendanceContract
  await deployer.deploy(AttendanceContract);

  // คุณสามารถทดสอบการเรียกใช้งานสัญญา AttendanceContract ได้ที่นี่หรือในส่วนอื่นของโค้ดตามที่ต้องการ
  const attendanceContractInstance = await AttendanceContract.deployed();
  console.log("AttendanceContract Address:", attendanceContractInstance.address);

  const rewardAmount = 1; // จำนวนเหรียญรางวัลที่ต้องการให้
  
  // เรียกใช้งานฟังก์ชัน checkAttendanceAndReward ในสัญญา AttendanceContract
  await attendanceContractInstance.checkAttendanceAndReward(checkInDate, rewardAmount, { from: studentAddress });

  // ตรวจสอบจำนวนเหรียญในบัญชีหลังจากเรียกใช้งาน
  const balance = await attendanceContractInstance.getBalance({ from: studentAddress });
  console.log("Balance after check-in:", balance.toString());
};