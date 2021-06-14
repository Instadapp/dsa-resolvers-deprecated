const { expect } = require("chai");
const hardhatConfig = require("../hardhat.config");
const { BigNumber } = hre.ethers;

// Deterministic block number to run these tests from on forked mainnet. If you change this, tests will break.
const BLOCK_NUMBER = 12478959;

// Liquity user with a Trove, Stability deposit, and Stake
const JUSTIN_SUN_ADDRESS = "0x903d12bf2c57a29f32365917c706ce0e1a84cce3";

// Liquity price oracle
const PRICE_FEED_ADDRESS = "0x4c517D4e2C851CA76d7eC94B805269Df0f2201De";
const PRICE_FEED_ABI = ["function fetchPrice() external returns (uint)"];

/* Begin: Mock test data (based on specified BLOCK_NUMBER and JUSTIN_SUN_ADDRESS) */
const expectedTrovePosition = [
  /* collateral */ BigNumber.from("582880000000000000000000"),
  /* debt */ BigNumber.from("372000200000000000000000000"),
  /* icr */ BigNumber.from("3859882210893925325"),
];
const expectedStabilityPosition = [
  /* deposit */ BigNumber.from("299979329615565997640451998"),
  /* ethGain */ BigNumber.from("8629038660000000000"),
  /* lqtyGain */ BigNumber.from("53244322633874479119945"),
];
const expectedStakePosition = [
  /* amount */ BigNumber.from("981562996504090969804965"),
  /* ethGain */ BigNumber.from("18910541408996344243"),
  /* lusdGain */ BigNumber.from("66201062534511228032281"),
];

const expectedSystemState = [
  /* borrowFee */ BigNumber.from("6900285109012952"),
  /* ethTvl */ BigNumber.from("852500462432421494350957"),
  /* tcr */ BigNumber.from("3250195441371082828"),
  /* isInRecoveryMode */ false,
];
/* End: Mock test data */

describe("InstaLiquityResolver", () => {
  let liquity;
  let liquityPriceOracle;

  before(async () => {
    await resetHardhatBlockNumber(BLOCK_NUMBER); // Start tests from clean mainnet fork at BLOCK_NUMBER

    const liquityFactory = await hre.ethers.getContractFactory(
      "InstaLiquityResolver"
    );

    liquityPriceOracle = new hre.ethers.Contract(
      PRICE_FEED_ADDRESS,
      PRICE_FEED_ABI,
      hre.ethers.provider
    );

    liquity = await liquityFactory.deploy();
    await liquity.deployed();
  });

  it("deploys the resolver", () => {
    expect(liquity.address).to.exist;
  });

  describe("getTrove()", () => {
    it("returns a user's Trove position", async () => {
      const oracleEthPrice = await liquityPriceOracle.callStatic.fetchPrice();
      const trovePosition = await liquity.getTrove(
        JUSTIN_SUN_ADDRESS,
        oracleEthPrice
      );
      expect(trovePosition).to.eql(expectedTrovePosition);
    });
  });

  describe("getStabilityDeposit()", () => {
    it("returns a user's Stability Pool position", async () => {
      const stabilityPosition = await liquity.getStabilityDeposit(
        JUSTIN_SUN_ADDRESS
      );
      expect(stabilityPosition).to.eql(expectedStabilityPosition);
    });
  });

  describe("getStake()", () => {
    it("returns a user's Stake position", async () => {
      const stakePosition = await liquity.getStake(JUSTIN_SUN_ADDRESS);
      expect(stakePosition).to.eql(expectedStakePosition);
    });
  });

  describe("getPosition()", () => {
    it("returns a user's Liquity position", async () => {
      const oracleEthPrice = await liquityPriceOracle.callStatic.fetchPrice();
      const position = await liquity.getPosition(
        JUSTIN_SUN_ADDRESS,
        oracleEthPrice
      );
      const expectedPosition = [
        expectedTrovePosition,
        expectedStabilityPosition,
        expectedStakePosition,
      ];
      expect(position).to.eql(expectedPosition);
    });
  });

  describe("getSystemState()", () => {
    it("returns Liquity system state", async () => {
      const oracleEthPrice = await liquityPriceOracle.callStatic.fetchPrice();
      const systemState = await liquity.getSystemState(oracleEthPrice);
      expect(systemState).to.eql(expectedSystemState);
    });
  });
});

const resetHardhatBlockNumber = async (blockNumber) => {
  return await hre.network.provider.request({
    method: "hardhat_reset",
    params: [
      {
        forking: {
          jsonRpcUrl: hardhatConfig.networks.hardhat.forking.url,
          blockNumber,
        },
      },
    ],
  });
};
