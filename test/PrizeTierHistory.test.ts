import { expect } from 'chai';
import { ethers, artifacts } from 'hardhat';
import { deployMockContract, MockContract } from 'ethereum-waffle';
import { Signer } from '@ethersproject/abstract-signer';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { Contract, ContractFactory } from 'ethers';

import { range } from './utils/range'

const { constants, getSigners, utils } = ethers;
const { AddressZero } = constants;
const { parseEther: toWei } = utils;

describe('PrizeTierHistory', () => {
  let wallet1: SignerWithAddress;
  let wallet2: SignerWithAddress;
  let wallet3: SignerWithAddress;
  let wallet4: SignerWithAddress;

  let prizeTierHistory: Contract;
  let reserve: Contract;
  let ticket: Contract;
  let strategy: MockContract;
  let prizeTierHistoryFactory: ContractFactory;
  let reserveFactory: ContractFactory;
  let erc20MintableFactory: ContractFactory;
  let prizeSplitStrategyFactory: ContractFactory;

  let destination: string;

  before(async () => {
    [wallet1, wallet2, wallet3, wallet4] = await getSigners();

    destination = wallet3.address;
    erc20MintableFactory = await ethers.getContractFactory('ERC20Mintable');
    prizeTierHistoryFactory = await ethers.getContractFactory('PrizeTierHistory');
    reserveFactory = await ethers.getContractFactory('ReserveHarness');
    prizeSplitStrategyFactory = await ethers.getContractFactory('PrizeSplitStrategy');

    let PrizeSplitStrategy = await artifacts.readArtifact('PrizeSplitStrategy');
    strategy = await deployMockContract(wallet1 as unknown as Signer, PrizeSplitStrategy.abi);
  });

  beforeEach(async () => {
    ticket = await erc20MintableFactory.deploy('Ticket', 'TICK');
    reserve = await reserveFactory.deploy(wallet1.address, ticket.address);

    const DEFAULTS = {
      bitRangeSize: 0,
      maxPicksPerUser: 10,
      tiers: range(16, 0),
      prizeExpirationSeconds: 1800
    }

    prizeTierHistory = await prizeTierHistoryFactory.deploy(
      wallet1.address, // Owner
      DEFAULTS // PrizeTierDefaults
    );
    await reserve.setManager(wallet2.address);
  });


  describe('Core', () => {

  });

  describe('Getters', () => {
    it('should succeed to get the PrizeTierDefaults struct', async () => {
      const defaults = await prizeTierHistory.getDefaults();
      expect(defaults.bitRangeSize).to.equal(0)
      expect(defaults.maxPicksPerUser).to.equal(10)
      expect(defaults.prizeExpirationSeconds).to.equal(1800)
    });

    it('should succeed to get the first PrizeTier from history', async () => {
      const drawPrizeDistribution = {
        drawId: 1,
        prize: 100000,
        validityDuration: 10000,
        drawStart: 5000000,
      }

      prizeTierHistory.push(drawPrizeDistribution)
      const defaults = await prizeTierHistory.getPrizeTier(1);
      expect(defaults.drawId).to.equal(1)
      expect(defaults.prize).to.equal(100000)
      expect(defaults.validityDuration).to.equal(5001800)
      expect(defaults.maxPicksPerUser).to.equal(10)
    });

    it('should fail to get the non-existent PrizeTier from history', async () => {
      const drawPrizeDistribution = {
        drawId: 1,
        prize: 100000,
        validityDuration: 10000,
        drawStart: 5000000,
      }
      await prizeTierHistory.push(drawPrizeDistribution)
      expect(prizeTierHistory.getPrizeTier(2))
        .to.revertedWith('PrizeTierHistory/prize-tier-unavailable')

    });
  });

  describe('Setters', () => {
    describe('.push()', () => {
      it('should succeed push PrizeTier into history from Owner wallet.', async () => {
        const drawPrizeDistribution = {
          drawId: 1,
          prize: 100000,
          validityDuration: 10000,
          drawStart: 5000000,
        }

        expect(prizeTierHistory.push(drawPrizeDistribution))
          .to.emit(prizeTierHistory, 'PrizeTierPushed')
      });

      it('should succeed to push PrizeTier into history from Manager wallet', async () => {
        await prizeTierHistory.setManager(wallet2.address);
        const drawPrizeDistribution = {
          drawId: 1,
          prize: 100000,
          validityDuration: 10000,
          drawStart: 5000000,
        }
        await expect((prizeTierHistory.connect(wallet2 as unknown as Signer)).push(drawPrizeDistribution))
          .to.emit(prizeTierHistory, 'PrizeTierPushed')
      });

      it('should fail to push PrizeTier into history from Unauthorized wallet', async () => {
        const drawPrizeDistribution = {
          drawId: 1,
          prize: 100000,
          validityDuration: 10000,
          drawStart: 5000000,
        }

        await expect(prizeTierHistory.connect(wallet4 as unknown as Signer).push(drawPrizeDistribution))
          .to.be.revertedWith('Manageable/caller-not-manager-or-owner')
      });
    })

    describe('.set()', () => {
      it('should succeed to set existing PrizeTier in history from Owner wallet.', async () => {
        const drawPrizeDistribution = {
          drawId: 1,
          prize: 100000,
          validityDuration: 10000,
          drawStart: 5000000,
        }
        await prizeTierHistory.push(drawPrizeDistribution)

        const tiers = range(16, 0).map(i => 0);
        const prizeTier = {
          bitRangeSize: 10,
          drawId: 1,
          maxPicksPerUser: 10,
          validityDuration: 90000,
          tiers: tiers,
          prize: 500000,
        }
        await expect(prizeTierHistory.setPrizeTier(prizeTier))
          .to.emit(prizeTierHistory, 'PrizeTierSet')
      });

      it('should fail to set existing PrizeTier due to empty history', async () => {
        const tiers = range(16, 0).map(i => 0);
        const prizeTier = {
          bitRangeSize: 10,
          drawId: 1,
          maxPicksPerUser: 10,
          validityDuration: 90000,
          tiers: tiers,
          prize: 500000,
        }

        expect(prizeTierHistory.setPrizeTier(prizeTier))
          .to.revertedWith('PrizeTierHistory/history-empty')
      });

      it('should fail to set existing PrizeTier in history from Manager wallet', async () => {
        const tiers = range(16, 0).map(i => 0);
        const prizeTier = {
          bitRangeSize: 10,
          drawId: 1,
          maxPicksPerUser: 10,
          validityDuration: 90000,
          tiers: tiers,
          prize: 500000,
        }

        expect((prizeTierHistory.connect(wallet2 as unknown as Signer)).setPrizeTier(prizeTier))
          .to.revertedWith('Manageable/caller-not-owner')

      });
    });
  });
});
