import { expect } from 'chai';
// @ts-ignore
import { ethers } from 'hardhat';
import { Signer } from '@ethersproject/abstract-signer';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { Contract, ContractFactory } from 'ethers';
import { range } from './utils/range';
import { parseUnits } from 'ethers/lib/utils';

const { getSigners, utils } = ethers;
const { parseEther: toWei } = utils;

describe('PrizeTierHistoryV2', () => {
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
            expiryDuration: 10000,
            prize: toWei('10000'),
            endTimestampOffset: 3000,
            dpr: parseUnits('.1', 9),
        },
        {
            bitRangeSize: 5,
            drawId: 6,
            maxPicksPerUser: 10,
            tiers: range(16, 0).map((i) => 0),
            expiryDuration: 10000,
            prize: toWei('10000'),
            endTimestampOffset: 3000,
            dpr: parseUnits('.1', 9),
        },
        {
            bitRangeSize: 5,
            drawId: 9,
            maxPicksPerUser: 10,
            tiers: range(16, 0).map((i) => 0),
            expiryDuration: 10000,
            prize: toWei('10000'),
            endTimestampOffset: 3000,
            dpr: parseUnits('.1', 9),
        },
        {
            bitRangeSize: 5,
            drawId: 20,
            maxPicksPerUser: 10,
            tiers: range(16, 0).map((i) => 0),
            expiryDuration: 10000,
            prize: toWei('10000'),
            endTimestampOffset: 3000,
            dpr: parseUnits('.1', 9),
        }
    ];

    const pushPrizeTiers = async () => {
        Promise.all(prizeTiers.map(async (tier) => {
            await prizeTierHistory.push(tier);
        }));
    };

    before(async () => {
        [wallet1, wallet2, wallet3, wallet4] = await getSigners();
        prizeTierHistoryFactory = await ethers.getContractFactory('PrizeTierHistoryV2');
    });

    beforeEach(async () => {
        // Deploy PrizeTierHistoryV2 with an empty history for each test
        prizeTierHistory = await prizeTierHistoryFactory.deploy(wallet1.address, []);
    });

    describe('Getters', () => {
        
        it('should succeed to get prize tiers from history', async () => {
            await pushPrizeTiers();
            const prizeTierFromHistory = await prizeTierHistory.getPrizeTierList([3, 7, 15]);
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
            await expect(prizeTierHistory.getPrizeTier(0)).to.revertedWith(
                'PrizeTierHistoryV2/draw-id-not-zero',
            );
        });

        it('should fail to get a PrizeTer after history range', async () => {
            await prizeTierHistory.push(prizeTiers[2]);
            await expect(prizeTierHistory.getPrizeTier(4)).to.be.revertedWith(
                'PrizeTierHistoryV2/draw-id-out-of-range',
            );
        });
    });

    describe('Setters', () => {
        describe('push()', () => {
            it('should succeed push PrizeTier into history from Owner wallet.', async () => {
                await expect(prizeTierHistory.push(prizeTiers[0])).to.emit(
                    prizeTierHistory,
                    'PrizeTierPushed',
                );
            });

            it('should succeed to push PrizeTier into history from Manager wallet', async () => {
                await prizeTierHistory.setManager(wallet2.address);
                await expect(
                    prizeTierHistory.connect(wallet2 as unknown as Signer).push(prizeTiers[0]),
                ).to.emit(prizeTierHistory, 'PrizeTierPushed');
            });

            it('should fail to push PrizeTier into history from unauthorized wallet', async () => {
                await expect(
                    prizeTierHistory.connect(wallet4 as unknown as Signer).push(prizeTiers[0]),
                ).to.be.revertedWith('Manageable/caller-not-manager-or-owner');
            });
        });

        describe('replace()', async () => {
            it('should succeed to replace an an existing PrizeTier struct', async () => {
                const prizeTier = {
                    ...prizeTiers[1],
                    bitRangeSize: 12,
                };
                await pushPrizeTiers();
                await expect(prizeTierHistory.replace(prizeTier)).to.emit(
                    prizeTierHistory,
                    'PrizeTierSet',
                );
                const prizeTierVal = await prizeTierHistory.getPrizeTier(prizeTier.drawId);
                expect(prizeTierVal.bitRangeSize).to.equal(12);
            });
    
            it('should FAIL to replace a PrizeTier the PrizeTierHistoryV2 instance has a FALSE history.', async () => {
                const prizeTier = {
                    ...prizeTiers[1],
                    drawId: 4,
                    bitRangeSize: 12,
                };
                await expect(prizeTierHistory.replace(prizeTier)).to.be.revertedWith(
                    'PrizeTierHistoryV2/no-prize-tiers',
                );
            })

            it('should FAIL to replace a PrizeTier the PrizeTierHistoryV2 instance history started after.', async () => {
                const prizeTier = {
                    ...prizeTiers[0],
                    drawId: 10000
                };
                await prizeTierHistory.push(prizeTier)
                const prizeTierReplace = {
                    ...prizeTiers[0],
                    drawId: 1
                };
                await expect(prizeTierHistory.replace(prizeTierReplace)).to.be.revertedWith(
                    'PrizeTierHistoryV2/draw-id-out-of-range',
                );
            });
            
            it('should FAIL to replace a PrizeTier that DOES NOT exist.', async () => {
                const prizeTier = {
                    ...prizeTiers[1],
                    drawId: 4,
                    bitRangeSize: 12,
                };
                await pushPrizeTiers();
                await expect(prizeTierHistory.replace(prizeTier)).to.be.revertedWith(
                    'PrizeTierHistoryV2/draw-id-must-match',
                );
            });

        });

        describe('injectTimeline()', () => {
            it('should SUCCEED to inject a PrizeTier history when the PrizeTierHistoryV2 instance has a FALSE history', async () => {
                await expect(prizeTierHistory.injectTimeline(prizeTiers)).to.emit(
                    prizeTierHistory,
                    'PrizeTierPushed',
                );
            });
            
            it('should FAIL to inject a PrizeTier history for a PrizeTierHistoryV2 instance with TRUE history', async () => {
                await pushPrizeTiers();
                await expect(prizeTierHistory.injectTimeline(prizeTiers)).to.be.revertedWith(
                    'PrizeTierHistoryV2/history-not-empty',
                );
            });
            
            it('should FAIL to inject a PrizeTier history for a PrizeTierHistoryV2 instance IF the injection history is EMPTY', async () => {
                await pushPrizeTiers();
                await expect(prizeTierHistory.injectTimeline([])).to.be.revertedWith(
                    'PrizeTierHistoryV2/timeline-empty',
                );
            });

        });
    });

});
