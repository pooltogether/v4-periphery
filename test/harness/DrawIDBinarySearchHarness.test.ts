// @ts-ignore
import { ethers } from 'hardhat';
import { expect } from 'chai';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { Contract, ContractFactory } from 'ethers';

const { getSigners, utils } = ethers;

describe('DrawIDBinarySearchHarness', () => {
    let wallet1: SignerWithAddress;

    let drawIdBinaryHarness: Contract;
    let drawIdBinaryHarnessFactory: ContractFactory;

    const structsWithDrawID = [
        {
            drawId: 1,
        },
        {
            drawId: 6,
        },
        {
            drawId: 9
        },
        {
            drawId: 12
        }
    ];

    before(async () => {
        [wallet1] = await getSigners();
        drawIdBinaryHarnessFactory = await ethers.getContractFactory('DrawIDBinarySearchHarness', wallet1);
    });

    beforeEach(async () => {
        drawIdBinaryHarness = await drawIdBinaryHarnessFactory.deploy([]);
    });

    describe('Getters', () => {
        it('should succeed to get Draw ID list from history', async () => {
            await drawIdBinaryHarness.injectTimeline(structsWithDrawID);
            const prizeTierFromHistory = await drawIdBinaryHarness.list([3, 7, 15]);
            expect(prizeTierFromHistory[0].drawId).to.equal(1);
            expect(prizeTierFromHistory[1].drawId).to.equal(6);
            expect(prizeTierFromHistory[2].drawId).to.equal(12);
        });

    });

});
