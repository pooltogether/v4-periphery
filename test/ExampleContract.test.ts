import { expect } from 'chai';
import { deployMockContract, MockContract } from 'ethereum-waffle';
import { Contract, ContractFactory, Signer, Wallet } from 'ethers';
import { ethers } from 'hardhat';
import { Interface } from 'ethers/lib/utils';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';

describe('Test Set Name', () => {
    let exampleContract: Contract

    let wallet1: SignerWithAddress, wallet2: SignerWithAddress, wallet3: SignerWithAddress, wallet4: SignerWithAddress

    beforeEach(async () =>{
        [wallet1, wallet2, wallet3, wallet4] = await ethers.getSigners()

        const exampleContractFactory: ContractFactory = await ethers.getContractFactory("ExampleContract")
        exampleContract = await exampleContractFactory.deploy()
    })
    describe("callMe()", ()=>{
        it('Test Name', async () => {
            await expect(exampleContract.callMe()).to.emit(exampleContract, "ReallyCoolEvent")
        })
    })
    describe("get Owner", () => {
        it('Test Name', async () => {
            
            expect(await exampleContract.owner()).to.equal(wallet1.address)
            expect(await exampleContract.connect(wallet2).owner()).to.not.equal(wallet2.address)
        })
    })
})