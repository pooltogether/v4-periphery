import { expect } from 'chai';
// @ts-ignore
import { ethers, artifacts } from 'hardhat';
import { deployMockContract, MockContract } from 'ethereum-waffle';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { Contract, ContractFactory } from 'ethers';
import DrawBuffer from '@pooltogether/v4-core/artifacts/contracts/DrawBuffer.sol/DrawBuffer.json';
import { BigNumber } from 'ethereum-waffle/node_modules/ethers';
import { parseEther, parseUnits } from 'ethers/lib/utils';

const { getSigners } = ethers;

describe('DrawPercentageRate', () => {
    let wallet1: SignerWithAddress;

    let drawPercentageRate: Contract;
    let ticket: MockContract;
    let drawBuffer: MockContract;
    let drawPercentageRateFactory: ContractFactory;

    before(async () => {
        [wallet1] = await getSigners();
        const Ticket = await artifacts.readArtifact('PrizeTierHistory');
        ticket = await deployMockContract(wallet1, Ticket.abi);
        drawBuffer = await deployMockContract(wallet1, DrawBuffer.abi);
        drawPercentageRateFactory = await ethers.getContractFactory('DrawPercentageRateHarness');
    });

    beforeEach(async () => {
        drawPercentageRate = await drawPercentageRateFactory.deploy(
            ticket.address,
            drawBuffer.address,
        );
    });

    describe('Core', () => {
        describe('getPrizeDistribution()', () => {
            it('should correctly calculate a valid PrizeDistribution', async () => {
                expect(true).to.eq(true);
            });
        });

        describe('getPrizeDistributionList()', () => {
            it('should correctly calculate a list of valid PrizeDistributions', async () => {
                expect(true).to.eq(true);
            });
        });
    });

    describe('Internal', () => {
        describe('calculateCardinalityAndNumberOfPicks()', () => {
            it('should successfully calculate a valid cardinality and number of picks.', async () => {
                const TOTAL_SUPPLY = BigNumber.from('1000');
                const PRIZE = BigNumber.from('100');
                const BIT_RANGE_SIZE = BigNumber.from('2');
                const DPR = parseUnits('0.01', '9');
                const MIN_PICK_COST = BigNumber.from('1');
                const value = await drawPercentageRate.calculateCardinalityAndNumberOfPicks(
                    BIT_RANGE_SIZE,
                    PRIZE,
                    DPR,
                    MIN_PICK_COST,
                    TOTAL_SUPPLY,
                );

                expect(value.cardinality).to.eq(BigNumber.from('7'));
                expect(value.numberOfPicks).to.eq(BigNumber.from('1638'));
            });

            it('should successfully calculate a valid cardinality and number of picks.', async () => {
                const TOTAL_SUPPLY = BigNumber.from('1000');
                const PRIZE = BigNumber.from('10');
                const BIT_RANGE_SIZE = BigNumber.from('2');
                const DPR = parseUnits('0.1', '9');
                const MIN_PICK_COST = BigNumber.from('1');
                const value = await drawPercentageRate.calculateCardinalityAndNumberOfPicks(
                    BIT_RANGE_SIZE,
                    PRIZE,
                    DPR,
                    MIN_PICK_COST,
                    TOTAL_SUPPLY,
                );

                expect(value.cardinality).to.eq(BigNumber.from('4'));
                expect(value.numberOfPicks).to.eq(BigNumber.from('2560'));
            });
        });

        describe('calculateDrawPeriodTimestampOffsets()', () => {
            it('should successfully calculate the Draw timestamp offests', async () => {
                const TIMESTAMP = BigNumber.from('1000');
                const START_OFFSET = BigNumber.from('990');
                const END_OFFSET = BigNumber.from('10');
                const offsets = await drawPercentageRate.calculateDrawPeriodTimestampOffsets(
                    TIMESTAMP,
                    START_OFFSET,
                    END_OFFSET,
                );
                expect(offsets[0][0]).to.equal(BigNumber.from('10'));
                expect(offsets[1][0]).to.equal(BigNumber.from('990'));
            });
        });
    });

    describe('Getters', () => {
        it('should get the Ticket address', async () => {
            expect(await drawPercentageRate.getTicket()).to.equal(ticket.address);
        });

        it('should get the DrawBuffer address', async () => {
            expect(await drawPercentageRate.getDrawBuffer()).to.equal(drawBuffer.address);
        });
    });

    describe('Setters', () => {
        it('should set the DrawBuffer address', async () => {
            drawPercentageRate.setDrawBuffer(drawBuffer.address);
            expect(await drawPercentageRate.getDrawBuffer()).to.equal(drawBuffer.address);
        });
    });
});
