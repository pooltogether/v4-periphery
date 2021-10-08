import { Signer } from '@ethersproject/abstract-signer';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { expect } from 'chai';
import { ethers, artifacts } from 'hardhat';
import { Contract, ContractFactory } from 'ethers';
import { deployMockContract, MockContract } from 'ethereum-waffle';

const { constants, getSigners, utils } = ethers;
const { AddressZero } = constants;
const { parseEther: toWei } = utils;

describe('PrizeTierHistory', () => {
  let wallet1: SignerWithAddress;
  let wallet2: SignerWithAddress;
  let wallet3: SignerWithAddress;

  let prizeFlush: Contract;
  let reserve: Contract;
  let ticket: Contract;
  let strategy: MockContract;
  let prizeTierHistoryFactory: ContractFactory;
  let reserveFactory: ContractFactory;
  let erc20MintableFactory: ContractFactory;
  let prizeSplitStrategyFactory: ContractFactory;

  let destination: string;

  before(async () => {
    [wallet1, wallet2, wallet3] = await getSigners();

    destination = wallet3.address;
    erc20MintableFactory = await ethers.getContractFactory('ERC20Mintable');
    prizeTierHistoryFactory = await ethers.getContractFactory('PrizeTierHistory');
    reserveFactory = await ethers.getContractFactory('ReserveHarness');
    prizeSplitStrategyFactory = await ethers.getContractFactory('PrizeSplitStrategy');

    let PrizeSplitStrategy = await artifacts.readArtifact('PrizeSplitStrategy');
    strategy = await deployMockContract(wallet1 as unknown as Signer, PrizeSplitStrategy.abi);
  });

  beforeEach(async () => {
    ticket = await erc20MintableFactory.deploy('Ticket', 'TICK');
    reserve = await reserveFactory.deploy(wallet1.address, ticket.address);
    prizeFlush = await prizeTierHistoryFactory.deploy(
      wallet1.address,
      destination,
      strategy.address,
      reserve.address,
    );
    await reserve.setManager(prizeFlush.address);
  });


  describe('Core', () => {

  });

  describe('Getters', () => {

  });

  describe('Setters', () => {

  });
});
