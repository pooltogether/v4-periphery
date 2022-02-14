import { expect } from 'chai';
import { ethers, artifacts } from 'hardhat';
import { deployMockContract, MockContract } from 'ethereum-waffle';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { Contract, ContractFactory } from 'ethers';
import DrawBuffer from '@pooltogether/v4-core/artifacts/contracts/DrawBuffer.sol/DrawBuffer.json';
import { BigNumber } from 'ethereum-waffle/node_modules/ethers';

const { getSigners } = ethers;

describe('DrawPercentageRate', () => {
    let wallet1: SignerWithAddress;
    let wallet2: SignerWithAddress;
    let wallet3: SignerWithAddress;

    let drawPercentageRate: Contract;
    let ticket: MockContract;
    let prizeTierHistory: MockContract;
    let drawBuffer: MockContract;
    let drawPercentageRateFactory: ContractFactory;

    const MIN_PICK_COST = BigNumber.from('1')
    const DPR = BigNumber.from('1')

    before(async () => {
        [wallet1, wallet2, wallet3] = await getSigners();
        const Ticket = await artifacts.readArtifact('PrizeTierHistory');
        const PrizeTierHistory = await artifacts.readArtifact('PrizeTierHistory');
        ticket = await deployMockContract(wallet1, Ticket.abi);
        prizeTierHistory = await deployMockContract(wallet1, PrizeTierHistory.abi);
        drawBuffer = await deployMockContract(wallet1, DrawBuffer.abi);
        drawPercentageRateFactory = await ethers.getContractFactory('DrawPercentageRate');
    });

    beforeEach(async () => {
        drawPercentageRate = await drawPercentageRateFactory.deploy(
            ticket.address,
            prizeTierHistory.address,
            drawBuffer.address,
            MIN_PICK_COST,
            DPR
        );
    });

    describe('Core', () => {
        describe('getPrizeDistribution()', () => {
            it('should correctly calculate a valid PrizeDistrubtion', async () => {
                expect(true).to.eq(true);
            });
        });
    });

    describe('Getters', () => {
        it('should get the destination address', async () => {
            expect(await drawPercentageRate.getTicket()).to.equal(ticket.address);
        });
        it('should get the strategy address', async () => {
            expect(await drawPercentageRate.getPrizeTierHistory()).to.equal(prizeTierHistory.address);
        });
        it('should get the reserve address', async () => {
            expect(await drawPercentageRate.getDrawBuffer()).to.equal(drawBuffer.address);
        });
        it('should get the minPickCost', async () => {
            expect(await drawPercentageRate.getMinPickCost()).to.equal(MIN_PICK_COST);
        });
        it('should get the DPR (draw percentage rate)', async () => {
            expect(await drawPercentageRate.getDpr()).to.equal(DPR);
        });
    });

    describe('Setters', () => {
        it('should set the destination address', async () => {
            drawPercentageRate.setTicket(ticket.address)
            expect(await drawPercentageRate.getTicket()).to.equal(ticket.address);
        });
        it('should set the strategy address', async () => {
            drawPercentageRate.setPrizeTierHistory(prizeTierHistory.address)
            expect(await drawPercentageRate.getPrizeTierHistory()).to.equal(prizeTierHistory.address);
        });
        it('should set the reserve address', async () => {
            drawPercentageRate.setDrawBuffer(drawBuffer.address)
            expect(await drawPercentageRate.getDrawBuffer()).to.equal(drawBuffer.address);
        });
        it('should set the DPR (draw percentage rate)', async () => {
            await drawPercentageRate.setDpr(DPR)
            expect(await drawPercentageRate.getDpr()).to.equal(DPR);
        });
    });
});
