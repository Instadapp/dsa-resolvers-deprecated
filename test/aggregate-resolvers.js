const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Resolver getPosition", function () {
  let maker, compound, aaveV2;
  before("Deploy Aggregate Resolvers", async function () {
    maker = await (
      await ethers.getContractFactory("InstaMakerDAOAggregateResolver")
    ).deploy();
    compound = await (
      await ethers.getContractFactory("InstaCompoundAggregateResolver")
    ).deploy();
    aaveV2 = await (
      await ethers.getContractFactory("InstaAaveV2AggregateResolver")
    ).deploy();
  });

  it("should get position for maker", async function () {
    const id = 2571;
    const position = await maker.getPosition(id);
    expect(position).gt(0);
  });

  it("should get position for compound", async function () {
    const account = "0x005280119e7070fd1999703ec606c5e97b146e84";
    const tx = compound.getPosition(account);
    expect(tx).to.satisfy;
  });

  it("should get position for aaveV2", async function () {
    const account = "0x005280119e7070fd1999703ec606c5e97b146e84";
    const position = await aaveV2.getPosition(account);
    console.log(position.toString());
    expect(position).gt(0);
  });
});
