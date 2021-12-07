import TicketInterface from '@pooltogether/v4-core/abis/ITicket.json';
import { deployMockContract, MockContract } from '@ethereum-waffle/mock-contract';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { expect } from 'chai';
import { Contract, ContractFactory, Signer } from 'ethers';
import { ethers } from 'hardhat';

import { increaseTime as increaseTimeUtil } from './utils/increaseTime';

const increaseTime = (time: number) => increaseTimeUtil(provider, time);

const { constants, getContractFactory, getSigners, provider, utils, Wallet } = ethers;
const { parseEther: toWei } = utils;
const { AddressZero } = constants;

describe('TwabRewards', () => {
    let wallet1: SignerWithAddress;
    let wallet2: SignerWithAddress;
    let wallet3: SignerWithAddress;

    let erc20MintableFactory: ContractFactory;
    let ticketFactory: ContractFactory;
    let twabRewardsFactory: ContractFactory;

    let rewardToken: Contract;
    let ticket: Contract;
    let twabRewards: Contract;

    let mockTicket: MockContract;

    let createPromotionTimestamp: number;

    before(async () => {
        [wallet1, wallet2, wallet3] = await getSigners();

        erc20MintableFactory = await getContractFactory('ERC20Mintable');
        ticketFactory = await getContractFactory('TicketHarness');
        twabRewardsFactory = await getContractFactory('TwabRewardsHarness');
    });

    beforeEach(async () => {
        rewardToken = await erc20MintableFactory.deploy('Reward', 'REWA');
        twabRewards = await twabRewardsFactory.deploy();
        ticket = await erc20MintableFactory.deploy('Ticket', 'TICK');

        ticket = await ticketFactory.deploy('Ticket', 'TICK', 18, wallet1.address);

        mockTicket = await deployMockContract(wallet1, TicketInterface);
    });

    const tokensPerEpoch = toWei('10000');
    const epochDuration = 604800; // 1 week in seconds
    const numberOfEpochs = 12; // 3 months since 1 epoch runs for 1 week
    const promotionAmount = tokensPerEpoch.mul(numberOfEpochs);

    const createPromotion = async (
        ticketAddress: string,
        epochsNumber: number = numberOfEpochs,
    ) => {
        await rewardToken.mint(wallet1.address, promotionAmount);
        await rewardToken.approve(twabRewards.address, promotionAmount);

        createPromotionTimestamp = (await ethers.provider.getBlock('latest')).timestamp;

        return await twabRewards.createPromotion(
            ticketAddress,
            rewardToken.address,
            tokensPerEpoch,
            createPromotionTimestamp,
            epochDuration,
            epochsNumber,
        );
    };

    describe('createPromotion()', async () => {
        it('should create a new promotion', async () => {
            const promotionId = 1;

            expect(await createPromotion(ticket.address))
                .to.emit(twabRewards, 'PromotionCreated')
                .withArgs(promotionId);

            const promotion = await twabRewards.callStatic.getPromotion(promotionId);

            expect(promotion.creator).to.equal(wallet1.address);
            expect(promotion.ticket).to.equal(ticket.address);
            expect(promotion.token).to.equal(rewardToken.address);
            expect(promotion.tokensPerEpoch).to.equal(tokensPerEpoch);
            expect(promotion.startTimestamp).to.equal(createPromotionTimestamp);
            expect(promotion.epochDuration).to.equal(epochDuration);
            expect(promotion.numberOfEpochs).to.equal(numberOfEpochs);
        });

        it('should create a second promotion and handle allowance properly', async () => {
            const promotionIdOne = 1;
            const promotionIdTwo = 2;

            expect(await createPromotion(ticket.address))
                .to.emit(twabRewards, 'PromotionCreated')
                .withArgs(promotionIdOne);

            const firstPromotion = await twabRewards.callStatic.getPromotion(promotionIdOne);

            expect(firstPromotion.creator).to.equal(wallet1.address);
            expect(firstPromotion.ticket).to.equal(ticket.address);
            expect(firstPromotion.token).to.equal(rewardToken.address);
            expect(firstPromotion.tokensPerEpoch).to.equal(tokensPerEpoch);
            expect(firstPromotion.startTimestamp).to.equal(createPromotionTimestamp);
            expect(firstPromotion.epochDuration).to.equal(epochDuration);
            expect(firstPromotion.numberOfEpochs).to.equal(numberOfEpochs);

            expect(await createPromotion(ticket.address))
                .to.emit(twabRewards, 'PromotionCreated')
                .withArgs(promotionIdTwo);

            const secondPromotion = await twabRewards.callStatic.getPromotion(promotionIdTwo);

            expect(secondPromotion.creator).to.equal(wallet1.address);
            expect(secondPromotion.ticket).to.equal(ticket.address);
            expect(secondPromotion.token).to.equal(rewardToken.address);
            expect(secondPromotion.tokensPerEpoch).to.equal(tokensPerEpoch);
            expect(secondPromotion.startTimestamp).to.equal(createPromotionTimestamp);
            expect(secondPromotion.epochDuration).to.equal(epochDuration);
            expect(secondPromotion.numberOfEpochs).to.equal(numberOfEpochs);
        });

        it('should fail to create a new promotion if ticket is address zero', async () => {
            await expect(createPromotion(AddressZero)).to.be.revertedWith(
                'TwabRewards/ticket-not-zero-address',
            );
        });

        it('should fail to create a new promotion if ticket is not an actual ticket', async () => {
            const randomWallet = Wallet.createRandom();

            await expect(createPromotion(randomWallet.address)).to.be.revertedWith(
                'TwabRewards/invalid-ticket',
            );
        });

        it('should fail to create a new promotion if number of epochs exceeds limit', async () => {
            await expect(createPromotion(ticket.address, 256)).to.be.reverted;
        });
    });

    describe('cancelPromotion()', async () => {
        it('should cancel a promotion and transfer the correct amount of reward tokens', async () => {
            for (let index = 0; index < numberOfEpochs; index++) {
                let promotionId = index + 1;

                await createPromotion(ticket.address);

                const { epochDuration, numberOfEpochs, tokensPerEpoch } =
                    await twabRewards.callStatic.getPromotion(promotionId);

                if (index > 0) {
                    await increaseTime(epochDuration * index);
                }

                const transferredAmount = tokensPerEpoch
                    .mul(numberOfEpochs)
                    .sub(tokensPerEpoch.mul(index));

                expect(await twabRewards.cancelPromotion(promotionId, wallet1.address))
                    .to.emit(twabRewards, 'PromotionCancelled')
                    .withArgs(promotionId, transferredAmount);

                expect(await rewardToken.balanceOf(wallet1.address)).to.equal(transferredAmount);

                // We burn tokens from wallet1 to reset balance
                await rewardToken.burn(wallet1.address, transferredAmount);
            }
        });

        it('should fail to cancel promotion if not owner', async () => {
            await createPromotion(ticket.address);

            await expect(
                twabRewards.connect(wallet2).cancelPromotion(1, AddressZero),
            ).to.be.revertedWith('TwabRewards/only-promotion-creator');
        });

        it('should fail to cancel an inactive promotion', async () => {
            await createPromotion(ticket.address);
            await increaseTime(epochDuration * 13);

            await expect(twabRewards.cancelPromotion(1, wallet1.address)).to.be.revertedWith(
                'TwabRewards/promotion-not-active',
            );
        });

        it('should fail to cancel promotion if recipient is address zero', async () => {
            await createPromotion(ticket.address);

            await expect(twabRewards.cancelPromotion(1, AddressZero)).to.be.revertedWith(
                'TwabRewards/recipient-not-zero-address',
            );
        });
    });

    describe('extendPromotion()', async () => {
        it('should extend a promotion', async () => {
            await createPromotion(ticket.address);

            const numberOfEpochsAdded = 6;
            const extendedPromotionAmount = tokensPerEpoch.mul(numberOfEpochsAdded);
            const extendedPromotionEpochs = numberOfEpochs + numberOfEpochsAdded;

            await rewardToken.mint(wallet1.address, extendedPromotionAmount);
            await rewardToken.approve(twabRewards.address, extendedPromotionAmount);

            const promotionId = 1;

            expect(await twabRewards.extendPromotion(promotionId, numberOfEpochsAdded))
                .to.emit(twabRewards, 'PromotionExtended')
                .withArgs(promotionId, numberOfEpochsAdded);

            expect(
                (await twabRewards.callStatic.getPromotion(promotionId)).numberOfEpochs,
            ).to.equal(extendedPromotionEpochs);

            expect(await rewardToken.balanceOf(wallet1.address)).to.equal(0);
            expect(await rewardToken.balanceOf(twabRewards.address)).to.equal(
                promotionAmount.add(extendedPromotionAmount),
            );
        });

        it('should fail to extend an inactive promotion', async () => {
            await createPromotion(ticket.address);
            await increaseTime(epochDuration * 13);

            await expect(twabRewards.extendPromotion(1, 6)).to.be.revertedWith(
                'TwabRewards/promotion-not-active',
            );
        });

        it('should fail to extend an inexistent promotion', async () => {
            await createPromotion(ticket.address);

            await expect(twabRewards.extendPromotion(2, 6)).to.be.revertedWith(
                'TwabRewards/promotion-not-active',
            );
        });

        it('should fail to extend a promotion over the epochs limit', async () => {
            await createPromotion(ticket.address);

            await expect(twabRewards.extendPromotion(1, 244)).to.be.reverted;
        });
    });

    describe('getPromotion()', async () => {
        it('should get promotion by id', async () => {
            await createPromotion(ticket.address);

            const promotion = await twabRewards.callStatic.getPromotion(1);

            expect(promotion.creator).to.equal(wallet1.address);
            expect(promotion.ticket).to.equal(ticket.address);
            expect(promotion.token).to.equal(rewardToken.address);
            expect(promotion.tokensPerEpoch).to.equal(tokensPerEpoch);
            expect(promotion.startTimestamp).to.equal(createPromotionTimestamp);
            expect(promotion.epochDuration).to.equal(epochDuration);
            expect(promotion.numberOfEpochs).to.equal(numberOfEpochs);
        });
    });

    describe('getRemainingRewards()', async () => {
        it('should return the correct amount of reward tokens left', async () => {
            await createPromotion(ticket.address);

            const promotionId = 1;
            const { epochDuration, numberOfEpochs, tokensPerEpoch } =
                await twabRewards.callStatic.getPromotion(promotionId);

            for (let index = 0; index < numberOfEpochs; index++) {
                if (index > 0) {
                    await increaseTime(epochDuration);
                }

                expect(await twabRewards.getRemainingRewards(promotionId)).to.equal(
                    tokensPerEpoch.mul(numberOfEpochs).sub(tokensPerEpoch.mul(index)),
                );
            }
        });
    });

    describe('getCurrentEpochId()', async () => {
        it('should get the current epoch id of a promotion', async () => {
            await createPromotion(ticket.address);
            await increaseTime(epochDuration * 3);

            expect(await twabRewards.callStatic.getCurrentEpochId(1)).to.equal(3);
        });
    });

    describe('getRewardsAmount()', async () => {
        it('should get rewards amount for one or more epochs', async () => {
            const promotionId = 1;
            const epochIds = ['0', '1', '2'];

            const wallet2Amount = toWei('750');
            const wallet3Amount = toWei('250');

            const totalAmount = wallet2Amount.add(wallet3Amount);

            const wallet2ShareOfTickets = wallet2Amount.mul(100).div(totalAmount);
            const wallet2RewardAmount = wallet2ShareOfTickets.mul(tokensPerEpoch).div(100);

            const wallet3ShareOfTickets = wallet3Amount.mul(100).div(totalAmount);
            const wallet3RewardAmount = wallet3ShareOfTickets.mul(tokensPerEpoch).div(100);

            await ticket.mint(wallet2.address, wallet2Amount);
            await ticket.connect(wallet2).delegate(wallet2.address);
            await ticket.mint(wallet3.address, wallet3Amount);
            await ticket.connect(wallet3).delegate(wallet3.address);

            await createPromotion(ticket.address);
            await increaseTime(epochDuration * 3);

            expect(
                await twabRewards.callStatic.getRewardsAmount(
                    wallet2.address,
                    promotionId,
                    epochIds,
                ),
            ).to.deep.equal([wallet2RewardAmount, wallet2RewardAmount, wallet2RewardAmount]);

            expect(
                await twabRewards.callStatic.getRewardsAmount(
                    wallet3.address,
                    promotionId,
                    epochIds,
                ),
            ).to.deep.equal([wallet3RewardAmount, wallet3RewardAmount, wallet3RewardAmount]);
        });

        it('should decrease rewards amount if user delegate in the middle of an epoch', async () => {
            const promotionId = 1;
            const epochIds = ['0', '1', '2'];
            const halfEpoch = epochDuration / 2;

            const wallet2Amount = toWei('750');
            const wallet3Amount = toWei('250');

            const totalAmount = wallet2Amount.add(wallet3Amount);

            const wallet2ShareOfTickets = wallet2Amount.mul(100).div(totalAmount);
            const wallet2RewardAmount = wallet2ShareOfTickets.mul(tokensPerEpoch).div(100);

            const wallet3ShareOfTickets = wallet3Amount.mul(100).div(totalAmount);
            const wallet3RewardAmount = wallet3ShareOfTickets.mul(tokensPerEpoch).div(100);
            const wallet3HalfRewardAmount = wallet3RewardAmount.div(2);

            await ticket.mint(wallet2.address, wallet2Amount);
            await ticket.connect(wallet2).delegate(wallet2.address);
            await ticket.mint(wallet3.address, wallet3Amount);
            await ticket.connect(wallet3).delegate(wallet3.address);

            await createPromotion(ticket.address);

            // We adjust time to delegate right in the middle of epoch 3
            await increaseTime(epochDuration * 2 + halfEpoch - 2);

            await ticket.connect(wallet3).delegate(wallet2.address);

            await increaseTime(halfEpoch + 1);

            expect(
                await twabRewards.callStatic.getRewardsAmount(
                    wallet2.address,
                    promotionId,
                    epochIds,
                ),
            ).to.deep.equal([
                wallet2RewardAmount,
                wallet2RewardAmount,
                wallet2RewardAmount.add(wallet3HalfRewardAmount),
            ]);

            expect(
                await twabRewards.callStatic.getRewardsAmount(
                    wallet3.address,
                    promotionId,
                    epochIds,
                ),
            ).to.deep.equal([wallet3RewardAmount, wallet3RewardAmount, wallet3HalfRewardAmount]);
        });

        it('should return 0 if user has no tickets delegated to him', async () => {
            const wallet2Amount = toWei('750');
            const zeroAmount = toWei('0');

            await ticket.mint(wallet2.address, wallet2Amount);

            await createPromotion(ticket.address);
            await increaseTime(epochDuration * 3);

            expect(
                await twabRewards.callStatic.getRewardsAmount(wallet2.address, 1, ['0', '1', '2']),
            ).to.deep.equal([zeroAmount, zeroAmount, zeroAmount]);
        });

        it('should return 0 if ticket average total supplies is 0', async () => {
            const zeroAmount = toWei('0');

            await createPromotion(ticket.address);
            await increaseTime(epochDuration * 3);

            expect(
                await twabRewards.callStatic.getRewardsAmount(wallet2.address, 1, ['0', '1', '2']),
            ).to.deep.equal([zeroAmount, zeroAmount, zeroAmount]);
        });

        it('should fail to get rewards amount if one or more epochs are not over yet', async () => {
            const wallet2Amount = toWei('750');
            const wallet3Amount = toWei('250');

            await ticket.mint(wallet2.address, wallet2Amount);
            await ticket.mint(wallet3.address, wallet3Amount);

            await createPromotion(ticket.address);
            await increaseTime(epochDuration * 3);

            await expect(
                twabRewards.callStatic.getRewardsAmount(wallet2.address, 1, ['1', '2', '3']),
            ).to.be.revertedWith('TwabRewards/epoch-not-over');
        });
    });

    describe('claimRewards()', async () => {
        it('should claim rewards for one or more epochs', async () => {
            const promotionId = 1;
            const epochIds = ['0', '1', '2'];

            const wallet2Amount = toWei('750');
            const wallet3Amount = toWei('250');

            const totalAmount = wallet2Amount.add(wallet3Amount);

            const wallet2ShareOfTickets = wallet2Amount.mul(100).div(totalAmount);
            const wallet2RewardAmount = wallet2ShareOfTickets.mul(tokensPerEpoch).div(100);
            const wallet2TotalRewardsAmount = wallet2RewardAmount.mul(3);

            const wallet3ShareOfTickets = wallet3Amount.mul(100).div(totalAmount);
            const wallet3RewardAmount = wallet3ShareOfTickets.mul(tokensPerEpoch).div(100);
            const wallet3TotalRewardsAmount = wallet3RewardAmount.mul(3);

            await ticket.mint(wallet2.address, wallet2Amount);
            await ticket.connect(wallet2).delegate(wallet2.address);
            await ticket.mint(wallet3.address, wallet3Amount);
            await ticket.connect(wallet3).delegate(wallet3.address);

            await createPromotion(ticket.address);
            await increaseTime(epochDuration * 3);

            expect(await twabRewards.claimRewards(wallet2.address, promotionId, epochIds))
                .to.emit(twabRewards, 'RewardsClaimed')
                .withArgs(promotionId, epochIds, wallet2TotalRewardsAmount);

            expect(await twabRewards.claimRewards(wallet3.address, promotionId, epochIds))
                .to.emit(twabRewards, 'RewardsClaimed')
                .withArgs(promotionId, epochIds, wallet3TotalRewardsAmount);

            expect(await rewardToken.balanceOf(wallet2.address)).to.equal(
                wallet2TotalRewardsAmount,
            );

            expect(await rewardToken.balanceOf(wallet3.address)).to.equal(
                wallet3TotalRewardsAmount,
            );
        });

        it('should decrease rewards amount claimed if user delegate in the middle of an epoch', async () => {
            const promotionId = 1;
            const epochIds = ['0', '1', '2'];
            const halfEpoch = epochDuration / 2;

            const wallet2Amount = toWei('750');
            const wallet3Amount = toWei('250');

            const totalAmount = wallet2Amount.add(wallet3Amount);

            const wallet3ShareOfTickets = wallet3Amount.mul(100).div(totalAmount);
            const wallet3RewardAmount = wallet3ShareOfTickets.mul(tokensPerEpoch).div(100);
            const wallet3HalfRewardAmount = wallet3RewardAmount.div(2);
            const wallet3TotalRewardsAmount = wallet3RewardAmount
                .mul(3)
                .sub(wallet3HalfRewardAmount);

            const wallet2ShareOfTickets = wallet2Amount.mul(100).div(totalAmount);
            const wallet2RewardAmount = wallet2ShareOfTickets.mul(tokensPerEpoch).div(100);
            const wallet2TotalRewardsAmount = wallet2RewardAmount
                .mul(3)
                .add(wallet3HalfRewardAmount);

            await ticket.mint(wallet2.address, wallet2Amount);
            await ticket.connect(wallet2).delegate(wallet2.address);
            await ticket.mint(wallet3.address, wallet3Amount);
            await ticket.connect(wallet3).delegate(wallet3.address);

            await createPromotion(ticket.address);

            // We adjust time to delegate right in the middle of epoch 3
            await increaseTime(epochDuration * 2 + halfEpoch - 2);

            await ticket.connect(wallet3).delegate(wallet2.address);

            await increaseTime(halfEpoch + 1);

            await expect(twabRewards.claimRewards(wallet2.address, promotionId, epochIds))
                .to.emit(twabRewards, 'RewardsClaimed')
                .withArgs(promotionId, epochIds, wallet2TotalRewardsAmount);

            await expect(twabRewards.claimRewards(wallet3.address, promotionId, epochIds))
                .to.emit(twabRewards, 'RewardsClaimed')
                .withArgs(promotionId, epochIds, wallet3TotalRewardsAmount);

            expect(await rewardToken.balanceOf(wallet2.address)).to.equal(
                wallet2TotalRewardsAmount,
            );

            expect(await rewardToken.balanceOf(wallet3.address)).to.equal(
                wallet3TotalRewardsAmount,
            );
        });

        it('should claim 0 rewards if user has no tickets delegated to him', async () => {
            const promotionId = 1;
            const epochIds = ['0', '1', '2'];
            const wallet2Amount = toWei('750');
            const zeroAmount = toWei('0');

            await ticket.mint(wallet2.address, wallet2Amount);

            await createPromotion(ticket.address);
            await increaseTime(epochDuration * 3);

            await expect(twabRewards.claimRewards(wallet2.address, promotionId, epochIds))
                .to.emit(twabRewards, 'RewardsClaimed')
                .withArgs(promotionId, epochIds, zeroAmount);

            expect(await rewardToken.balanceOf(wallet2.address)).to.equal(zeroAmount);
        });

        it('should return 0 if ticket average total supplies is 0', async () => {
            const promotionId = 1;
            const epochIds = ['0', '1', '2'];
            const zeroAmount = toWei('0');

            await createPromotion(ticket.address);
            await increaseTime(epochDuration * 3);

            await expect(twabRewards.claimRewards(wallet2.address, promotionId, epochIds))
                .to.emit(twabRewards, 'RewardsClaimed')
                .withArgs(promotionId, epochIds, zeroAmount);
        });

        it('should fail to claim rewards if one or more epochs are not over yet', async () => {
            const wallet2Amount = toWei('750');
            const wallet3Amount = toWei('250');

            await ticket.mint(wallet2.address, wallet2Amount);
            await ticket.mint(wallet3.address, wallet3Amount);

            await createPromotion(ticket.address);
            await increaseTime(epochDuration * 3);

            await expect(
                twabRewards.claimRewards(wallet2.address, 1, ['1', '2', '3']),
            ).to.be.revertedWith('TwabRewards/epoch-not-over');
        });

        it('should fail to claim rewards if one or more epochs have already been claimed', async () => {
            const promotionId = 1;

            const wallet2Amount = toWei('750');
            const wallet3Amount = toWei('250');

            await ticket.mint(wallet2.address, wallet2Amount);
            await ticket.mint(wallet3.address, wallet3Amount);

            await createPromotion(ticket.address);
            await increaseTime(epochDuration * 3);

            await twabRewards.claimRewards(wallet2.address, promotionId, ['0', '1', '2']);

            await expect(
                twabRewards.claimRewards(wallet2.address, promotionId, ['2', '3', '4']),
            ).to.be.revertedWith('TwabRewards/rewards-already-claimed');
        });
    });

    describe('_requireTicket()', () => {
        it('should revert if ticket address is address zero', async () => {
            await expect(twabRewards.requireTicket(AddressZero)).to.be.revertedWith(
                'TwabRewards/ticket-not-zero-address',
            );
        });

        it('should revert if controller does not exist', async () => {
            const randomWallet = Wallet.createRandom();

            await expect(twabRewards.requireTicket(randomWallet.address)).to.be.revertedWith(
                'TwabRewards/invalid-ticket',
            );
        });

        it('should revert if controller address is address zero', async () => {
            await mockTicket.mock.controller.returns(AddressZero);

            await expect(twabRewards.requireTicket(mockTicket.address)).to.be.revertedWith(
                'TwabRewards/invalid-ticket',
            );
        });
    });
});
