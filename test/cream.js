const { expect } = require("chai");

describe("InstaCreamResolver", function () {
  let cream;
  let signer;
  const CrUSDT = '0x797AAB1ce7c01eB727ab980762bA88e7133d2157';

  it("should deploy the resolver", async function () {
    [signer] = await ethers.getSigners();

    const CreamFactory = await hre.ethers.getContractFactory("InstaCreamResolver");
    cream = await CreamFactory.deploy();
    await cream.deployed();
  });

  it("should fetch cream data from CrUSDT", async function () {
    expect(await cream.getCreamData(signer.address, [CrUSDT])).to.exist;
  });
});
