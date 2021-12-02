import TicketInterface from '@pooltogether/v4-core/abis/ITicket.json';
import YieldSourceStubInterface from '@pooltogether/v4-core/abis/YieldSourceStub.json';
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
    let prizePoolFactory: ContractFactory;
    let ticketFactory: ContractFactory;
    let twabRewardsFactory: ContractFactory;

    let depositToken: Contract;
    let prizePool: Contract;
    let rewardToken: Contract;
    let ticket: Contract;
    let twabRewards: Contract;

    let mockTicket: MockContract;
    let yieldSourceStub: MockContract;

    let latestBlockTimestamp: number;

    before(async () => {
        [wallet1, wallet2, wallet3] = await getSigners();

        erc20MintableFactory = await getContractFactory('ERC20Mintable');
        prizePoolFactory = await getContractFactory('PrizePoolHarness');
        ticketFactory = await getContractFactory('Ticket');
        twabRewardsFactory = await getContractFactory('TwabRewardsHarness');
    });

    beforeEach(async () => {
        depositToken = await erc20MintableFactory.deploy('Token', 'TOKE');
        rewardToken = await erc20MintableFactory.deploy('Reward', 'REWA');
        twabRewards = await twabRewardsFactory.deploy();
        ticket = await erc20MintableFactory.deploy('Ticket', 'TICK');

        yieldSourceStub = await deployMockContract(wallet1 as Signer, YieldSourceStubInterface);
        await yieldSourceStub.mock.depositToken.returns(depositToken.address);

        prizePool = await prizePoolFactory.deploy(wallet1.address, yieldSourceStub.address);
        ticket = await ticketFactory.deploy('Ticket', 'TICK', 18, prizePool.address);

        mockTicket = await deployMockContract(wallet1, TicketInterface);

        latestBlockTimestamp = (await ethers.provider.getBlock('latest')).timestamp;
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

        return await twabRewards.createPromotion(
            ticketAddress,
            rewardToken.address,
            tokensPerEpoch,
            latestBlockTimestamp,
            epochDuration,
            epochsNumber,
        );
    };

    describe('createPromotion()', async () => {
        it('should create a new promotion', async () => {
            const createTransaction = await createPromotion(ticket.address);
            const promotionId = 1;

            expect(createTransaction)
                .to.emit(twabRewards, 'PromotionCreated')
                .withArgs(promotionId);

            const promotion = await twabRewards.callStatic.getPromotion(promotionId);

            expect(promotion.creator).to.equal(wallet1.address);
            expect(promotion.ticket).to.equal(ticket.address);
            expect(promotion.token).to.equal(rewardToken.address);
            expect(promotion.tokensPerEpoch).to.equal(tokensPerEpoch);
            expect(promotion.startTimestamp).to.equal(latestBlockTimestamp);
            expect(promotion.epochDuration).to.equal(epochDuration);
            expect(promotion.numberOfEpochs).to.equal(numberOfEpochs);
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
    });

    describe('cancelPromotion()', async () => {
        it('should cancel a promotion during the first epoch and transfer full reward tokens amount', async () => {
            await createPromotion(ticket.address);

            const promotionId = 1;
            const cancelTransaction = await twabRewards.cancelPromotion(
                promotionId,
                wallet1.address,
            );

            expect(cancelTransaction)
                .to.emit(twabRewards, 'PromotionCancelled')
                .withArgs(promotionId, promotionAmount);

            expect(await rewardToken.balanceOf(wallet1.address)).to.equal(promotionAmount);
        });

        it('should cancel a promotion during the 6th epoch and transfer half the reward tokens amount', async () => {
            await createPromotion(ticket.address);
            await increaseTime(epochDuration * 6 - epochDuration / 2);

            const promotionId = 1;
            const halfPromotionAmount = promotionAmount.div(2);
            const cancelTransaction = await twabRewards.cancelPromotion(
                promotionId,
                wallet1.address,
            );

            expect(cancelTransaction)
                .to.emit(twabRewards, 'PromotionCancelled')
                .withArgs(promotionId, halfPromotionAmount);

            expect(await rewardToken.balanceOf(wallet1.address)).to.equal(halfPromotionAmount);
        });

        it('should cancel a promotion during the last epoch and transfer 0 reward tokens amount', async () => {
            await createPromotion(ticket.address);
            await increaseTime(epochDuration * numberOfEpochs - epochDuration / 2);

            const promotionId = 1;
            const cancelTransaction = await twabRewards.cancelPromotion(
                promotionId,
                wallet1.address,
            );

            expect(cancelTransaction)
                .to.emit(twabRewards, 'PromotionCancelled')
                .withArgs(promotionId, 0);

            expect(await rewardToken.balanceOf(wallet1.address)).to.equal(0);
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

    describe('_requireEpochLimit()', () => {
        it('should revert if number of epochs exceeds limit', async () => {
            await expect(twabRewards.requireEpochLimit(256)).to.be.revertedWith(
                'TwabRewards/exceeds-255-epochs-limit',
            );
        });
    });
});
