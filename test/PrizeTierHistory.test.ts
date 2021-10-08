import { expect } from 'chai';
import { ethers, artifacts } from 'hardhat';
import { deployMockContract, MockContract } from 'ethereum-waffle';
import { Signer } from '@ethersproject/abstract-signer';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { Contract, ContractFactory } from 'ethers';

import { range } from './utils/range';

const { constants, getSigners, utils } = ethers;
const { AddressZero } = constants;
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

        await prizeTierHistory.setManager(wallet2.address);
    });

    describe('Core', () => {});

    describe('Getters', () => {
        it('should succeed to get prize tiers from history', async () => {
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

        it('should fail to get a non-existent PrizeTier from history', async () => {
            await pushPrizeTiers();

            expect(prizeTierHistory.getPrizeTier(0)).to.revertedWith(
                'PrizeTierHistory/draw-id-out-of-range',
            );
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
                };

                expect(prizeTierHistory.push(drawPrizeDistribution)).to.emit(
                    prizeTierHistory,
                    'PrizeTierPushed',
                );
            });

            it('should succeed to push PrizeTier into history from Manager wallet', async () => {
                await prizeTierHistory.setManager(wallet2.address);
                const drawPrizeDistribution = {
                    drawId: 1,
                    prize: 100000,
                    validityDuration: 10000,
                    drawStart: 5000000,
                };
                await expect(
                    prizeTierHistory
                        .connect(wallet2 as unknown as Signer)
                        .push(drawPrizeDistribution),
                ).to.emit(prizeTierHistory, 'PrizeTierPushed');
            });

            it('should fail to push PrizeTier into history from Unauthorized wallet', async () => {
                const drawPrizeDistribution = {
                    drawId: 1,
                    prize: 100000,
                    validityDuration: 10000,
                    drawStart: 5000000,
                };

                await expect(
                    prizeTierHistory
                        .connect(wallet4 as unknown as Signer)
                        .push(drawPrizeDistribution),
                ).to.be.revertedWith('Manageable/caller-not-manager-or-owner');
            });
        });

        describe.skip('.set()', () => {
            it('should succeed to set existing PrizeTier in history from Owner wallet.', async () => {
                const drawPrizeDistribution = {
                    drawId: 1,
                    prize: 100000,
                    validityDuration: 10000,
                    drawStart: 5000000,
                };
                await prizeTierHistory.push(drawPrizeDistribution);

                const tiers = range(16, 0).map((i) => 0);
                const prizeTier = {
                    bitRangeSize: 10,
                    drawId: 1,
                    maxPicksPerUser: 10,
                    validityDuration: 90000,
                    tiers: tiers,
                    prize: 500000,
                };
                await expect(prizeTierHistory.setPrizeTier(prizeTier)).to.emit(
                    prizeTierHistory,
                    'PrizeTierSet',
                );
            });

            it('should fail to set existing PrizeTier due to empty history', async () => {
                const tiers = range(16, 0).map((i) => 0);
                const prizeTier = {
                    bitRangeSize: 10,
                    drawId: 1,
                    maxPicksPerUser: 10,
                    validityDuration: 90000,
                    tiers: tiers,
                    prize: 500000,
                };

                expect(prizeTierHistory.setPrizeTier(prizeTier)).to.revertedWith(
                    'PrizeTierHistory/history-empty',
                );
            });

            it('should fail to set existing PrizeTier in history from Manager wallet', async () => {
                const tiers = range(16, 0).map((i) => 0);
                const prizeTier = {
                    bitRangeSize: 10,
                    drawId: 1,
                    maxPicksPerUser: 10,
                    validityDuration: 90000,
                    tiers: tiers,
                    prize: 500000,
                };

                expect(
                    prizeTierHistory.connect(wallet2 as unknown as Signer).setPrizeTier(prizeTier),
                ).to.revertedWith('Ownable/caller-not-owner');
            });
        });
    });
});
