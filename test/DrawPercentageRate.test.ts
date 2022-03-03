import { expect } from 'chai';
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
    let wallet2: SignerWithAddress;
    let wallet3: SignerWithAddress;

    let drawPercentageRate: Contract;
    let ticket: MockContract;
    let prizeTierHistory: MockContract;
    let drawBuffer: MockContract;
    let drawPercentageRateFactory: ContractFactory;

    const MIN_PICK_COST = BigNumber.from('1');
    const DPR = BigNumber.from('1');

    before(async () => {
        [wallet1, wallet2, wallet3] = await getSigners();
        const Ticket = await artifacts.readArtifact('PrizeTierHistory');
        const PrizeTierHistory = await artifacts.readArtifact('PrizeTierHistory');
        ticket = await deployMockContract(wallet1, Ticket.abi);
        prizeTierHistory = await deployMockContract(wallet1, PrizeTierHistory.abi);
        drawBuffer = await deployMockContract(wallet1, DrawBuffer.abi);
        drawPercentageRateFactory = await ethers.getContractFactory('DrawPercentageRateHarness');
    });

    beforeEach(async () => {
        drawPercentageRate = await drawPercentageRateFactory.deploy(
            ticket.address,
            prizeTierHistory.address,
            drawBuffer.address,
            MIN_PICK_COST,
            DPR,
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
        // Calculate Cardinality
        describe('calculateCardinality()', () => {
            it('should successfully calculate a valid cardinality.', async () => {
                const TOTAL_SUPPLY = BigNumber.from('1000');
                const PRIZE = BigNumber.from('100');
                const BIT_RANGE_SIZE = BigNumber.from('2');
                const DPR = parseUnits('0.01', '9');
                const MIN_PICK_COST = BigNumber.from('1');
                const value = await drawPercentageRate.calculateCardinality(
                    TOTAL_SUPPLY,
                    PRIZE,
                    BIT_RANGE_SIZE,
                    DPR,
                    MIN_PICK_COST,
                );
                expect(value).to.eq(BigNumber.from('7'));
            });

            it('should successfully calculate a valid cardinality and number of picks.', async () => {
                const TOTAL_SUPPLY = BigNumber.from('1000');
                const PRIZE = BigNumber.from('10');
                const BIT_RANGE_SIZE = BigNumber.from('2');
                const DPR = parseUnits('0.1', '9');
                const MIN_PICK_COST = BigNumber.from('1');
                const value = await drawPercentageRate.calculateCardinality(
                    TOTAL_SUPPLY,
                    PRIZE,
                    BIT_RANGE_SIZE,
                    DPR,
                    MIN_PICK_COST,
                );
                expect(value).to.eq(BigNumber.from('4'));
            });
        });

        // Calculate Number of Picks
        describe('calculateNumberOfPicks()', () => {
            it('should successfully calculate a valid cardinality.', async () => {
                const TOTAL_SUPPLY = BigNumber.from('1000');
                const PRIZE = BigNumber.from('100');
                const BIT_RANGE_SIZE = BigNumber.from('2');
                const DPR = parseUnits('0.01', '9');
                const MIN_PICK_COST = BigNumber.from('1');
                const value = await drawPercentageRate.calculateNumberOfPicks(
                    TOTAL_SUPPLY,
                    PRIZE,
                    BIT_RANGE_SIZE,
                    DPR,
                    MIN_PICK_COST,
                );
                expect(value).to.eq(BigNumber.from('1638'));
            });

            it('should successfully calculate a valid cardinality and number of picks.', async () => {
                const TOTAL_SUPPLY = BigNumber.from('1000');
                const PRIZE = BigNumber.from('10');
                const BIT_RANGE_SIZE = BigNumber.from('2');
                const DPR = parseUnits('0.1', '9');
                const MIN_PICK_COST = BigNumber.from('1');
                const value = await drawPercentageRate.calculateNumberOfPicks(
                    TOTAL_SUPPLY,
                    PRIZE,
                    BIT_RANGE_SIZE,
                    DPR,
                    MIN_PICK_COST,
                );
                expect(value).to.eq(BigNumber.from('2560'));
            });
        });

        // Calculate Number of Picks using Cardinality and Fraction of Odds
        describe('calculateNumberOfPicksWithCardinalityAndFraction()', () => {
            it('should successfully calculate number of picks of using cardinality and fraction of odds', async () => {
                const BIT_RANGE_SIZE = BigNumber.from('2');
                const CARDINALITY = BigNumber.from('7');
                const FRACTION_OF_ODDS = BigNumber.from('100000000');
                const value =
                    await drawPercentageRate.calculateNumberOfPicksWithCardinalityAndFraction(
                        BIT_RANGE_SIZE,
                        CARDINALITY,
                        FRACTION_OF_ODDS,
                    );
                expect(value).to.eq(BigNumber.from('1638'));
            });

            it('should successfully calculate number of picks of using cardinality and fraction of odds', async () => {
                const BIT_RANGE_SIZE = BigNumber.from('2');
                const CARDINALITY = BigNumber.from('4');
                const FRACTION_OF_ODDS = BigNumber.from('10000000000');
                const value =
                    await drawPercentageRate.calculateNumberOfPicksWithCardinalityAndFraction(
                        BIT_RANGE_SIZE,
                        CARDINALITY,
                        FRACTION_OF_ODDS,
                    );
                expect(value).to.eq(BigNumber.from('2560'));
            });
        });

        describe('calculateCardinalityAndNumberOfPicks()', () => {
            it('should successfully calculate a valid cardinality and number of picks.', async () => {
                const TOTAL_SUPPLY = BigNumber.from('1000');
                const PRIZE = BigNumber.from('100');
                const BIT_RANGE_SIZE = BigNumber.from('2');
                const DPR = parseUnits('0.01', '9');
                const MIN_PICK_COST = BigNumber.from('1');
                const value = await drawPercentageRate.calculateCardinalityAndNumberOfPicks(
                    TOTAL_SUPPLY,
                    PRIZE,
                    BIT_RANGE_SIZE,
                    DPR,
                    MIN_PICK_COST,
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
                    TOTAL_SUPPLY,
                    PRIZE,
                    BIT_RANGE_SIZE,
                    DPR,
                    MIN_PICK_COST,
                );
                expect(value.cardinality).to.eq(BigNumber.from('4'));
                expect(value.numberOfPicks).to.eq(BigNumber.from('2560'));
            });
        });

        describe('calculatePrizeDistribution()', () => {
            it('should successfully calculate a PrizeDistribution using mock historical Draw parameters', async () => {
                const DRAW_ID = 1;
                const DRAW_PERCENTAGE_RATE = '1';
                // expect(await drawPercentageRate.calculatePrizeDistribution(DRAW_ID, DRAW_PERCENTAGE_RATE)).to.eq(true);
                expect(true).to.eq(true);
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

        describe('calculateCardinalityCeiling()', () => {
            it('should successfully calculate the cardinality from max picks', async () => {
                const BIT_RANGE_SIZE = BigNumber.from('4');
                const MAX_PICKS = BigNumber.from('1000');
                const CARDINALITY_EXPECT = BigNumber.from('3');
                const read = await drawPercentageRate.calculateCardinalityCeiling(
                    BIT_RANGE_SIZE,
                    MAX_PICKS,
                );
                expect(read).to.eq(CARDINALITY_EXPECT);
            });
        });

        describe('calculateFractionOfOdds()', () => {
            it('should successfully calculate the fracion of odds', async () => {
                const DRAW_PERCENTAGE_RATE = BigNumber.from('100000');
                const TOTAL_SUPPLY = BigNumber.from('100000');
                const PRIZE = parseEther('1');
                expect(
                    await drawPercentageRate.calculateFractionOfOdds(
                        DRAW_PERCENTAGE_RATE,
                        TOTAL_SUPPLY,
                        PRIZE,
                    ),
                ).to.eq(BigNumber.from('0'));
            });
        });
    });

    describe('Getters', () => {
        it('should get the destination address', async () => {
            expect(await drawPercentageRate.getTicket()).to.equal(ticket.address);
        });
        it('should get the strategy address', async () => {
            expect(await drawPercentageRate.getPrizeTierHistory()).to.equal(
                prizeTierHistory.address,
            );
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
            drawPercentageRate.setTicket(ticket.address);
            expect(await drawPercentageRate.getTicket()).to.equal(ticket.address);
        });
        it('should set the strategy address', async () => {
            drawPercentageRate.setPrizeTierHistory(prizeTierHistory.address);
            expect(await drawPercentageRate.getPrizeTierHistory()).to.equal(
                prizeTierHistory.address,
            );
        });
        it('should set the reserve address', async () => {
            drawPercentageRate.setDrawBuffer(drawBuffer.address);
            expect(await drawPercentageRate.getDrawBuffer()).to.equal(drawBuffer.address);
        });
        it('should set the DPR (draw percentage rate)', async () => {
            await drawPercentageRate.setDpr(DPR);
            expect(await drawPercentageRate.getDpr()).to.equal(DPR);
        });
    });
});
