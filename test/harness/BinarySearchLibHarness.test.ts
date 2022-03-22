// @ts-ignore
import { ethers } from 'hardhat';
import { expect } from 'chai';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { Contract, ContractFactory } from 'ethers';

const { getSigners } = ethers;

describe.only('BinarySearchLibHarness', () => {
    let wallet1: SignerWithAddress;
    let binarySearchLib: Contract;
    let binarySearchLibFactory: ContractFactory;
    let binarySearchLibHarness: Contract;
    let binarySearchLibHarnessFactory: ContractFactory;


    before(async () => {
        [wallet1] = await getSigners();
        binarySearchLibFactory = await ethers.getContractFactory('BinarySearchLib');
        binarySearchLib = await binarySearchLibFactory.deploy();
        binarySearchLibHarnessFactory = await ethers.getContractFactory(
            'BinarySearchLibHarness',
            {
                libraries: {
                    BinarySearchLib: binarySearchLib.address,
                }
            }
        );
    });

    beforeEach(async () => {
        binarySearchLibHarness = await binarySearchLibHarnessFactory.deploy([]);
    });

    describe('history.length == 1', () => {
        it('should succeed to get index [0] when using Draw Id ["1"] as the input', async () => {
            await binarySearchLibHarness.set([1]);
            const index = await binarySearchLibHarness.getIndex(1);
            expect(index).to.equal(0);
            const indexList = await binarySearchLibHarness.getIndexes([1]);
            expect(indexList[0]).to.equal(0);
        });

        it('should succeed to get index [0] when using Draw Id ["2"] as the input', async () => {
            await binarySearchLibHarness.set([1]);
            const index = await binarySearchLibHarness.getIndex(10);
            expect(index).to.equal(0);
            const indexList = await binarySearchLibHarness.getIndexes([1]);
            expect(indexList[0]).to.equals(0);
        });
        
        it('should fail to get index when passing Draw Id "0" as the input', async () => {
            await binarySearchLibHarness.set([1]);
            expect(binarySearchLibHarness.getIndex(0)).to.be.revertedWith(
                'BinarySearchLib/draw-id-out-of-range',
            );
        });
    })

    describe('history.length == 2', () => {
        it('should succeed to get index [0,1] when using Draw Id ["1", "4"] as the input', async () => {
            await binarySearchLibHarness.set([1,4]);
            const indexOne = await binarySearchLibHarness.getIndex(1);
            expect(indexOne).to.equal(0);
            const indexTwo = await binarySearchLibHarness.getIndex(4);
            expect(indexTwo).to.equal(1);
            const indexList = await binarySearchLibHarness.getIndexes([1,4]);
            expect(indexList[0]).to.equal(0);
            expect(indexList[1]).to.equal(1);
        });

        it('should succeed to get index [0,1] when using Draw Id ["2", "5"] as the input', async () => {
            await binarySearchLibHarness.set([1,4]);
            const indexOne = await binarySearchLibHarness.getIndex(2);
            expect(indexOne).to.equal(0);
            const indexTwo = await binarySearchLibHarness.getIndex(5);
            expect(indexTwo).to.equal(1);
            const indexList = await binarySearchLibHarness.getIndexes([2,5]);
            expect(indexList[0]).to.equal(0);
            expect(indexList[1]).to.equal(1);
        });
    })
    
    describe('history.length == 3', () => {
        it('should succeed to get index [0,1,2] when using Draw Id ["1", "4", "8"] as the input', async () => {
            await binarySearchLibHarness.set([1,4,8]);
            const indexOne = await binarySearchLibHarness.getIndex(1);
            expect(indexOne).to.equal(0);
            const indexTwo = await binarySearchLibHarness.getIndex(4);
            expect(indexTwo).to.equal(1);
            const indexThree = await binarySearchLibHarness.getIndex(8);
            expect(indexThree).to.equal(2);
            const indexList = await binarySearchLibHarness.getIndexes([1,4,8]);
            expect(indexList[0]).to.equal(0);
            expect(indexList[1]).to.equal(1);
            expect(indexList[2]).to.equal(2);
        });

        it('should succeed to get index [0,1,2] when using Draw Id ["2", "5", "9"] as the input', async () => {
            await binarySearchLibHarness.set([1,4,8]);
            const indexOne = await binarySearchLibHarness.getIndex(2);
            expect(indexOne).to.equal(0);
            const indexTwo = await binarySearchLibHarness.getIndex(5);
            expect(indexTwo).to.equal(1);
            const indexThree = await binarySearchLibHarness.getIndex(9);
            expect(indexThree).to.equal(2);
            const indexList = await binarySearchLibHarness.getIndexes([2,5,9]);
            expect(indexList[0]).to.equal(0);
            expect(indexList[1]).to.equal(1);
            expect(indexList[2]).to.equal(2);
        });
    })
    
    describe('history.length == 4', () => {
        it('should succeed to get index [0,1,2,3] when using Draw Id ["1", "4", "8", "16"] as the input', async () => {
            await binarySearchLibHarness.set([1,4,8,16]);
            const indexOne = await binarySearchLibHarness.getIndex(1);
            expect(indexOne).to.equal(0);
            const indexTwo = await binarySearchLibHarness.getIndex(4);
            expect(indexTwo).to.equal(1);
            const indexThree = await binarySearchLibHarness.getIndex(8);
            expect(indexThree).to.equal(2);
            const indexFour = await binarySearchLibHarness.getIndex(16);
            expect(indexFour).to.equal(3);
            const indexList = await binarySearchLibHarness.getIndexes([1,4,8,16]);
            expect(indexList[0]).to.equal(0);
            expect(indexList[1]).to.equal(1);
            expect(indexList[2]).to.equal(2);
            expect(indexList[3]).to.equal(3);
        });

        it('should succeed to get index [0,1,2,3] when using Draw Id ["2", "5", "9", "17"] as the input', async () => {
            await binarySearchLibHarness.set([1,4,8, 16]);
            const indexOne = await binarySearchLibHarness.getIndex(2);
            expect(indexOne).to.equal(0);
            const indexTwo = await binarySearchLibHarness.getIndex(5);
            expect(indexTwo).to.equal(1);
            const indexThree = await binarySearchLibHarness.getIndex(9);
            expect(indexThree).to.equal(2);
            const indexFour = await binarySearchLibHarness.getIndex(17);
            expect(indexFour).to.equal(3);
            const indexList = await binarySearchLibHarness.getIndexes([2,5,9,17]);
            expect(indexList[0]).to.equal(0);
            expect(indexList[1]).to.equal(1);
            expect(indexList[2]).to.equal(2);
            expect(indexList[3]).to.equal(3);
        });

        it('should succeed to get index [0,1,2] when using Draw Id ["1", "4", "9"] as the input', async () => {
            await binarySearchLibHarness.set([1,4,8,16]);
            const indexList = await binarySearchLibHarness.getIndexes([1,4,9]);
            expect(indexList[0]).to.equal(0);
            expect(indexList[1]).to.equal(1);
            expect(indexList[2]).to.equal(2);
        });
    })
    
    describe('history.length == 5', () => {
        it('should succeed to get index [0,1,2,3] when using Draw Id ["1", "4", "8", "16", "32"] as the input', async () => {
            await binarySearchLibHarness.set([1,4,8,16,32]);
            const indexOne = await binarySearchLibHarness.getIndex(1);
            expect(indexOne).to.equal(0);
            const indexTwo = await binarySearchLibHarness.getIndex(4);
            expect(indexTwo).to.equal(1);
            const indexThree = await binarySearchLibHarness.getIndex(8);
            expect(indexThree).to.equal(2);
            const indexFour = await binarySearchLibHarness.getIndex(16);
            expect(indexFour).to.equal(3);
            const indexFive = await binarySearchLibHarness.getIndex(32);
            expect(indexFive).to.equal(4);
            const indexList = await binarySearchLibHarness.getIndexes([1,4,8,16,32]);
            expect(indexList[0]).to.equal(0);
            expect(indexList[1]).to.equal(1);
            expect(indexList[2]).to.equal(2);
            expect(indexList[3]).to.equal(3);
            expect(indexList[4]).to.equal(4);
        });

        it('should succeed to get index [0,1,2,3,4] when using Draw Id ["2", "5", "9", "17", "33"] as the input', async () => {
            await binarySearchLibHarness.set([1,4,8,16,32]);
            const indexOne = await binarySearchLibHarness.getIndex(2);
            expect(indexOne).to.equal(0);
            const indexTwo = await binarySearchLibHarness.getIndex(5);
            expect(indexTwo).to.equal(1);
            const indexThree = await binarySearchLibHarness.getIndex(9);
            expect(indexThree).to.equal(2);
            const indexFour = await binarySearchLibHarness.getIndex(17);
            expect(indexFour).to.equal(3);
            const indexFive = await binarySearchLibHarness.getIndex(33);
            expect(indexFive).to.equal(4);
            const indexList = await binarySearchLibHarness.getIndexes([2,5,9,17,33]);
            expect(indexList[0]).to.equal(0);
            expect(indexList[1]).to.equal(1);
            expect(indexList[2]).to.equal(2);
        });
    })
    
    describe('history.length == 6', () => {
        it('should succeed to get index [0,1,2,3,4,5] when using Draw Id ["1", "4", "8", "16", "32", "64"] as the input', async () => {
            await binarySearchLibHarness.set([1,4,8,16,32,64]);
            const indexOne = await binarySearchLibHarness.getIndex(1);
            expect(indexOne).to.equal(0);
            const indexTwo = await binarySearchLibHarness.getIndex(4);
            expect(indexTwo).to.equal(1);
            const indexThree = await binarySearchLibHarness.getIndex(8);
            expect(indexThree).to.equal(2);
            const indexFour = await binarySearchLibHarness.getIndex(16);
            expect(indexFour).to.equal(3);
            const indexFive = await binarySearchLibHarness.getIndex(32);
            expect(indexFive).to.equal(4);
            const indexSix = await binarySearchLibHarness.getIndex(64);
            expect(indexSix).to.equal(5);
            const indexList = await binarySearchLibHarness.getIndexes([1,4,8,16,32,64]);
            expect(indexList[0]).to.equal(0);
            expect(indexList[1]).to.equal(1);
            expect(indexList[2]).to.equal(2);
            expect(indexList[3]).to.equal(3);
            expect(indexList[4]).to.equal(4);
            expect(indexList[5]).to.equal(5);
        });

        it('should succeed to get index [0,1,2,3,4,5] when using Draw Id ["2", "5", "9", "17", "33", "65"] as the input', async () => {
            await binarySearchLibHarness.set([1,4,8,16,32,64]);
            const indexOne = await binarySearchLibHarness.getIndex(2);
            expect(indexOne).to.equal(0);
            const indexTwo = await binarySearchLibHarness.getIndex(5);
            expect(indexTwo).to.equal(1);
            const indexThree = await binarySearchLibHarness.getIndex(9);
            expect(indexThree).to.equal(2);
            const indexFour = await binarySearchLibHarness.getIndex(17);
            expect(indexFour).to.equal(3);
            const indexFive = await binarySearchLibHarness.getIndex(33);
            expect(indexFive).to.equal(4);
            const indexSix = await binarySearchLibHarness.getIndex(65);
            expect(indexSix).to.equal(5);
            const indexList = await binarySearchLibHarness.getIndexes([2,5,9,17,33,65]);
            expect(indexList[0]).to.equal(0);
            expect(indexList[1]).to.equal(1);
            expect(indexList[2]).to.equal(2);
            expect(indexList[3]).to.equal(3);
            expect(indexList[4]).to.equal(4);
            expect(indexList[5]).to.equal(5);
        });
    })
    
    describe('history.length == 7', () => {
        it('should succeed to get index [0,1,2,3,4,5] when using Draw Id ["1", "4", "8", "16", "32", "64", "128"] as the input', async () => {
            await binarySearchLibHarness.set([1,4,8,16,32,64,128]);
            const indexOne = await binarySearchLibHarness.getIndex(1);
            expect(indexOne).to.equal(0);
            const indexTwo = await binarySearchLibHarness.getIndex(4);
            expect(indexTwo).to.equal(1);
            const indexThree = await binarySearchLibHarness.getIndex(8);
            expect(indexThree).to.equal(2);
            const indexFour = await binarySearchLibHarness.getIndex(16);
            expect(indexFour).to.equal(3);
            const indexFive = await binarySearchLibHarness.getIndex(32);
            expect(indexFive).to.equal(4);
            const indexSix = await binarySearchLibHarness.getIndex(64);
            expect(indexSix).to.equal(5);
            const indexSeven = await binarySearchLibHarness.getIndex(128);
            expect(indexSeven).to.equal(6);
            const indexList = await binarySearchLibHarness.getIndexes([1,4,8,16,32,64,128]);
            expect(indexList[0]).to.equal(0);
            expect(indexList[1]).to.equal(1);
            expect(indexList[2]).to.equal(2);
            expect(indexList[3]).to.equal(3);
            expect(indexList[4]).to.equal(4);
            expect(indexList[5]).to.equal(5);
            expect(indexList[6]).to.equal(6);
        });

        it('should succeed to get index [0,1,2,3,4,5] when using Draw Id ["2", "5", "9", "17", "33", "65"] as the input', async () => {
            await binarySearchLibHarness.set([1,4,8,16,32,64,128]);
            const indexOne = await binarySearchLibHarness.getIndex(2);
            expect(indexOne).to.equal(0);
            const indexTwo = await binarySearchLibHarness.getIndex(5);
            expect(indexTwo).to.equal(1);
            const indexThree = await binarySearchLibHarness.getIndex(9);
            expect(indexThree).to.equal(2);
            const indexFour = await binarySearchLibHarness.getIndex(17);
            expect(indexFour).to.equal(3);
            const indexFive = await binarySearchLibHarness.getIndex(33);
            expect(indexFive).to.equal(4);
            const indexSix = await binarySearchLibHarness.getIndex(65);
            expect(indexSix).to.equal(5);
            const indexSeven = await binarySearchLibHarness.getIndex(129);
            expect(indexSeven).to.equal(6);
            const indexList = await binarySearchLibHarness.getIndexes([2,5,9,17,33,65,129]);
            expect(indexList[0]).to.equal(0);
            expect(indexList[1]).to.equal(1);
            expect(indexList[2]).to.equal(2);
            expect(indexList[3]).to.equal(3);
            expect(indexList[4]).to.equal(4);
            expect(indexList[5]).to.equal(5);
            expect(indexList[6]).to.equal(6);
        });
    })
});
