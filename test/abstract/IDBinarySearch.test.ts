// @ts-ignore
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Contract, ContractFactory } from "ethers";

const { getSigners } = ethers;

describe("IDBinarySearch", () => {
    let wallet1: SignerWithAddress;
    let wallet2: SignerWithAddress;
    let wallet3: SignerWithAddress;

    let binarySearchLogic: Contract;
    let binarySearchLogicFactory: ContractFactory;

    before(async () => {
        [wallet1, wallet2, wallet3] = await getSigners();
        binarySearchLogicFactory = await ethers.getContractFactory("IDBinarySearch");
    });

    beforeEach(async () => {
        binarySearchLogic = await binarySearchLogicFactory.deploy();
    });

    describe("Core", () => {
        describe("getNewestIndex()", () => {});
    });
});
