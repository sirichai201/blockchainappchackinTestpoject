const AttendanceContract = artifacts.require("AttendanceContract");

module.exports = async function (deployer, network, accounts) {
  // สร้างสัญญา AttendanceContract
  await deployer.deploy(AttendanceContract);
  const attendanceContractInstance = await AttendanceContract.deployed();
  console.log("AttendanceContract Address:", attendanceContractInstance.address);

  // ตัวอย่างการเรียกใช้งานฟังก์ชัน checkAttendanceAndReward
  const checkInDate = Math.floor(new Date().getTime() / 1000); // ใช้ timestamp ของวันปัจจุบัน
  const studentAddress = accounts[0]; // ใช้ account ที่ 0 ใน network เป็นตัวอย่าง
  const rewardAmount = 1;
  
  await attendanceContractInstance.checkAttendanceAndReward(checkInDate, rewardAmount, { from: studentAddress });

  // ตรวจสอบจำนวนเหรียญในบัญชีหลังจากเรียกใช้งาน
  const balance = await attendanceContractInstance.getBalance({ from: studentAddress });
  console.log("Balance after check-in:", balance.toString());
};
