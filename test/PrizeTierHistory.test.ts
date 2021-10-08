import { expect } from 'chai';
import { ethers } from 'hardhat';
import { Signer } from '@ethersproject/abstract-signer';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { Contract, ContractFactory } from 'ethers';
import { range } from './utils/range';

const { getSigners, utils } = ethers;
const { parseEther: toWei } = utils;

describe('PrizeTierHistory', () => {
  let wallet1: SignerWithAddress;
  let wallet2: SignerWithAddress;
  let wallet3: SignerWithAddress;
  let wallet4: SignerWithAddress;

  let prizeTierHistory: Contract;
  let prizeTierHistoryFactory: ContractFactory;

  const prizeTiers = [
    {
      bitRangeSize: 5,
      drawId: 1,
      maxPicksPerUser: 10,
      tiers: range(16, 0).map((i) => 0),
      validityDuration: 10000,
      prize: toWei('10000'),
    },
    {
      bitRangeSize: 5,
      drawId: 6,
      maxPicksPerUser: 10,
      tiers: range(16, 0).map((i) => 0),
      validityDuration: 10000,
      prize: toWei('10000'),
    },
    {
      bitRangeSize: 5,
      drawId: 9,
      maxPicksPerUser: 10,
      tiers: range(16, 0).map((i) => 0),
      validityDuration: 10000,
      prize: toWei('10000'),
    },
  ];

  const pushPrizeTiers = async () => {
    prizeTiers.map(async (tier) => {
      await prizeTierHistory.push(tier);
    });
  };

  before(async () => {
    [wallet1, wallet2, wallet3, wallet4] = await getSigners();
    prizeTierHistoryFactory = await ethers.getContractFactory('PrizeTierHistory');
  });

  beforeEach(async () => {
    prizeTierHistory = await prizeTierHistoryFactory.deploy(wallet1.address);
  });

  describe('Getters', () => {
    it('should succeed to get prize tiers from history', async () => {
      await pushPrizeTiers();
      const prizeTierFromHistory = await prizeTierHistory.getPrizeTierList([3, 7, 9]);
      expect(prizeTierFromHistory[0].drawId).to.equal(1);
      expect(prizeTierFromHistory[1].drawId).to.equal(6);
      expect(prizeTierFromHistory[2].drawId).to.equal(9);
    });

    it('should succeed to get prize tier from history', async () => {
      await pushPrizeTiers();

      prizeTiers.map(async (prizeTier) => {
        const prizeTierFromHistory = await prizeTierHistory.getPrizeTier(prizeTier.drawId);
        expect(prizeTierFromHistory.drawId).to.equal(prizeTier.drawId);
      });
    });

    it('should return prize tier before our searched draw id', async () => {
      await pushPrizeTiers();

      const prizeTierFromHistory = await prizeTierHistory.getPrizeTier(4);
      expect(prizeTierFromHistory.drawId).to.equal(prizeTiers[0].drawId);
    });

    it('should fail to get a PrizeTier before history range', async () => {
      await pushPrizeTiers();

      expect(prizeTierHistory.getPrizeTier(0)).to.revertedWith(
        'PrizeTierHistory/draw-id-not-zero',
      );
    });

    it('should fail to get a PrizeTer after history range', async () => {
      await pushPrizeTiers();
      expect(prizeTierHistory.getPrizeTier(10)).to.revertedWith(
        'PrizeTierHistory/draw-id-out-of-range',
      );
    });
  });

  describe('Setters', () => {
    describe('.push()', () => {
      it('should succeed push PrizeTier into history from Owner wallet.', async () => {
        expect(prizeTierHistory.push(prizeTiers[0])).to.emit(
          prizeTierHistory,
          'PrizeTierPushed',
        );
      });

      it('should succeed to push PrizeTier into history from Manager wallet', async () => {
        await prizeTierHistory.setManager(wallet2.address);
        await expect(
          prizeTierHistory
            .connect(wallet2 as unknown as Signer)
            .push(prizeTiers[0]),
        ).to.emit(prizeTierHistory, 'PrizeTierPushed');
      });

      it('should fail to push PrizeTier into history from Unauthorized wallet', async () => {
        await expect(
          prizeTierHistory
            .connect(wallet4 as unknown as Signer)
            .push(prizeTiers[0]),
        ).to.be.revertedWith('Manageable/caller-not-manager-or-owner');
      });
    });

    describe('.set()', () => {
      it('should succeed to set existing PrizeTier in history from Owner wallet.', async () => {
        await prizeTierHistory.push(prizeTiers[0]);
        const prizeTier = {
          ...prizeTiers[0],
          bitRangeSize: 16,
        };
        await expect(prizeTierHistory.setPrizeTier(prizeTier)).to.emit(
          prizeTierHistory,
          'PrizeTierSet',
        );
      });

      it('should fail to set existing PrizeTier due to empty history', async () => {
        expect(prizeTierHistory.setPrizeTier(prizeTiers[0])).to.revertedWith(
          'PrizeTierHistory/history-empty',
        );
      });

      it('should fail to set existing PrizeTier in history from Manager wallet', async () => {
        expect(
          prizeTierHistory.connect(wallet2 as unknown as Signer).setPrizeTier(prizeTiers[0]),
        ).to.revertedWith('Ownable/caller-not-owner');
      });
    });
  });
});
