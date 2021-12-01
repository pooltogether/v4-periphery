import TicketInterface from '@pooltogether/v4-core/abis/ITicket.json';
import YieldSourceStubInterface from '@pooltogether/v4-core/abis/YieldSourceStub.json';
import { deployMockContract, MockContract } from '@ethereum-waffle/mock-contract';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { expect } from 'chai';
import { Contract, ContractFactory, Signer } from 'ethers';
import { ethers } from 'hardhat';

const { constants, getContractFactory, getSigners, utils, Wallet } = ethers;
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

    describe('createPromotion()', async () => {
        it('should create a new promotion', async () => {
            const token = rewardToken.address;
            const tokensPerEpoch = toWei('10000');
            const startTimestamp = latestBlockTimestamp;
            const epochDuration = 604800; // 1 week in seconds
            const numberOfEpochs = 12; // 3 months since 1 epoch runs for 1 week

            await rewardToken.mint(
                wallet1.address,
                tokensPerEpoch.mul(numberOfEpochs),
            );

            await twabRewards.createPromotion(
                ticket.address,
                token,
                tokensPerEpoch,
                startTimestamp,
                epochDuration,
                numberOfEpochs,
            );

            const currentPromotion = await twabRewards.callStatic.getCurrentPromotion();

            expect(currentPromotion.id).to.equal(1);
            expect(currentPromotion.creator).to.equal(wallet1.address);
            expect(currentPromotion.ticket).to.equal(ticket.address);
            expect(currentPromotion.token).to.equal(token);
            expect(currentPromotion.tokensPerEpoch).to.equal(tokensPerEpoch);
            expect(currentPromotion.startTimestamp).to.equal(startTimestamp);
            expect(currentPromotion.epochDuration).to.equal(epochDuration);
            expect(currentPromotion.numberOfEpochs).to.equal(numberOfEpochs);
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
