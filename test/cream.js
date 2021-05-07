const { expect } = require("chai");
const { ethers } = require("hardhat");

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

  it("should fetch cream data for CrUSDT", async function () {
    expect(await cream.getCreamData(signer.address, [CrUSDT])).to.exist;
  });

  it("should fetch cream position for CrUSDT", async function () {
    const res = await cream.callStatic.getPosition(signer.address, [CrUSDT]);
    expect(res).to.exist
  });
});
