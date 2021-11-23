import TicketInterface from '@pooltogether/v4-core/abis/ITicket.json';
import { deployMockContract, MockContract } from '@ethereum-waffle/mock-contract';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { expect } from 'chai';
import { Contract, ContractFactory } from 'ethers';
import { ethers } from 'hardhat';

const { constants, getSigners, utils, Wallet } = ethers;
const { parseEther: toWei } = utils;
const { AddressZero } = constants;

describe('TwabRewards', () => {
    let wallet1: SignerWithAddress;
    let wallet2: SignerWithAddress;
    let wallet3: SignerWithAddress;

    let ticket: MockContract;
    let twabRewards: Contract;
    let twabRewardsFactory: ContractFactory;

    before(async () => {
        [wallet1, wallet2, wallet3] = await ethers.getSigners();
        twabRewardsFactory = await ethers.getContractFactory('TwabRewardsHarness');
    });

    beforeEach(async () => {
        twabRewards = await twabRewardsFactory.deploy(wallet1.address);
    });

    describe('constructor()', () => {
        it('should properly deploy', async () => {
            expect(await twabRewards.owner()).to.equal(wallet1.address);
            expect(twabRewards.deployTransaction)
                .to.emit(twabRewards, 'Deployed')
                .withArgs(wallet1.address);
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
            ticket = await deployMockContract(wallet1, TicketInterface);
            await ticket.mock.controller.returns(AddressZero);

            await expect(twabRewards.requireTicket(ticket.address)).to.be.revertedWith(
                'TwabRewards/invalid-ticket',
            );
        });

        it('should succeed if controller address is set', async () => {
            const randomWallet = Wallet.createRandom();

            ticket = await deployMockContract(wallet1, TicketInterface);
            await ticket.mock.controller.returns(randomWallet.address);

            await twabRewards.requireTicket(ticket.address);
        });
    });
});
