import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { expect } from 'chai';
import { Contract, ContractFactory } from 'ethers';
import { ethers } from 'hardhat';

const { getSigners, utils } = ethers;
const { parseEther: toWei } = utils;

describe('TwabRewards', () => {
    let wallet1: SignerWithAddress;
    let wallet2: SignerWithAddress;
    let wallet3: SignerWithAddress;

    let twabRewards: Contract;
    let twabRewardsFactory: ContractFactory;

    before(async () => {
        [wallet1, wallet2, wallet3] = await ethers.getSigners();
        twabRewardsFactory = await ethers.getContractFactory('TwabRewards');
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
});
