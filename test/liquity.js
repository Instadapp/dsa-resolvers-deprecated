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

  describe("getTrovePositionHints()", () => {
    it("returns the upper and lower address of Troves nearest to the given Trove", async () => {
      const collateral = hre.ethers.utils.parseEther("10");
      const debt = hre.ethers.utils.parseUnits("5000", 18);
      const searchIterations = 10;
      const [upperHint, lowerHint] = await liquity.getTrovePositionHints(
        collateral,
        debt,
        searchIterations
      );

      expect(upperHint).eq("0xbf9a4eCC4151f28C03100bA2C0555a3D3e439e69");
      expect(lowerHint).eq("0xa4FC81A7AB93360543eb1e814D0127f466012CED");
    });
  });

  describe("getRedemptionPositionHints()", () => {
    it("returns the upper and lower address of the range of Troves to be redeemed against the given amount", async () => {
      const amount = hre.ethers.utils.parseUnits("10000", 18); // 10,000 LUSD
      const oracleEthPrice = await liquityPriceOracle.callStatic.fetchPrice();
      const searchIterations = 10;
      const [
        partialRedemptionHintNicr,
        firstHint,
        upperHint,
        lowerHint,
      ] = await liquity.getRedemptionPositionHints(
        amount,
        oracleEthPrice,
        searchIterations
      );

      expect(partialRedemptionHintNicr).eq("69529933762909647");
      expect(firstHint).eq("0xc16aDd8bA17ab81B27e930Da8a67848120565d8c");
      expect(upperHint).eq("0x66882C005188F0F4d95825ED7A7F78ed3055f167");
      expect(lowerHint).eq("0x0C22C11a8ed4C23ffD19629283548B1692b58e92");
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
