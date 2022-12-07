import { deployMockContract, MockContract } from "@ethereum-waffle/mock-contract";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { BigNumber, Contract, ContractFactory } from "ethers";
import { artifacts, ethers } from "hardhat";
import { Artifact } from "hardhat/types";

import { ICrossChainRelayer as ICrossChainRelayerType } from "../types";
import { IDrawBeacon } from "../types/@pooltogether/v4-core/contracts/interfaces/IDrawBuffer";

const { constants, getContractFactory, getSigners, provider, utils } = ethers;
const { getTransactionReceipt } = provider;
const { Interface } = utils;
const { AddressZero, Zero } = constants;

describe("DrawRelayer", () => {
    let wallet: SignerWithAddress;

    let drawRelayerFactory: ContractFactory;
    let drawRelayer: Contract;

    let drawExecutorFactory: ContractFactory;
    let drawExecutor: Contract;

    let ICrossChainExecutor: Artifact;
    let crossChainExecutorMock: MockContract;

    let ICrossChainRelayer: Artifact;
    let crossChainRelayerMock: MockContract;

    let IDrawBuffer: Artifact;
    let drawBufferMock: MockContract;

    const beaconPeriodSeconds = 86400;

    const NEWEST_DRAW = {
        winningRandomNumber: BigNumber.from(
            "40915453424841276066216659657882080769542951486300783855291357409493418239004"
        ),
        drawId: 3,
        timestamp: BigNumber.from(1670267603),
        beaconPeriodStartedAt: BigNumber.from(1670180400),
        beaconPeriodSeconds,
    };

    const DRAW_2 = {
        winningRandomNumber: BigNumber.from(
            "64339088980103463139645995941327992265254002724697124345779657466504643646813"
        ),
        drawId: 2,
        timestamp: BigNumber.from(1670008199),
        beaconPeriodStartedAt: BigNumber.from(1669921200),
        beaconPeriodSeconds,
    };

    const DRAW_1 = {
        winningRandomNumber: BigNumber.from(
            "80553736152766854578213568172612508909811630975130684656101794566871918526593"
        ),
        drawId: 1,
        timestamp: BigNumber.from(1669748591),
        beaconPeriodStartedAt: BigNumber.from(1669662000),
        beaconPeriodSeconds,
    };

    const drawIds = [DRAW_1.drawId, DRAW_2.drawId, NEWEST_DRAW.drawId];

    const draws = [
        [
            DRAW_1.winningRandomNumber,
            DRAW_1.drawId,
            DRAW_1.timestamp,
            DRAW_1.beaconPeriodStartedAt,
            DRAW_1.beaconPeriodSeconds,
        ],
        [
            DRAW_2.winningRandomNumber,
            DRAW_2.drawId,
            DRAW_2.timestamp,
            DRAW_2.beaconPeriodStartedAt,
            DRAW_2.beaconPeriodSeconds,
        ],
        [
            NEWEST_DRAW.winningRandomNumber,
            NEWEST_DRAW.drawId,
            NEWEST_DRAW.timestamp,
            NEWEST_DRAW.beaconPeriodStartedAt,
            NEWEST_DRAW.beaconPeriodSeconds,
        ],
    ];

    before(async () => {
        [wallet] = await getSigners();

        ICrossChainExecutor = await artifacts.readArtifact("ICrossChainExecutor");
        ICrossChainRelayer = await artifacts.readArtifact("ICrossChainRelayer");
        IDrawBuffer = await artifacts.readArtifact("IDrawBuffer");
        drawRelayerFactory = await getContractFactory("DrawRelayer");
        drawExecutorFactory = await getContractFactory("DrawExecutor");
    });

    beforeEach(async () => {
        crossChainExecutorMock = await deployMockContract(wallet, ICrossChainExecutor.abi);
        crossChainRelayerMock = await deployMockContract(wallet, ICrossChainRelayer.abi);
        drawBufferMock = await deployMockContract(wallet, IDrawBuffer.abi);
        drawRelayer = await drawRelayerFactory.deploy(drawBufferMock.address);
        drawExecutor = await drawExecutorFactory.deploy(
            crossChainExecutorMock.address,
            drawRelayer.address,
            drawBufferMock.address
        );
    });

    describe("constructor()", () => {
        it("should deploy contract", async () => {
            expect(await drawRelayer.callStatic.drawBuffer()).to.equal(drawBufferMock.address);
        });

        it("should fail to deploy contract if drawBuffer is address zero", async () => {
            await expect(drawRelayerFactory.deploy(AddressZero)).to.be.revertedWith(
                "DR/drawBuffer-not-zero-address"
            );
        });
    });

    describe("bridgeNewestDraw()", async () => {
        it("should bridge the newest recorded draw", async () => {
            await drawBufferMock.mock.getNewestDraw.returns(NEWEST_DRAW);

            const {
                winningRandomNumber,
                drawId,
                timestamp,
                beaconPeriodStartedAt,
                beaconPeriodSeconds,
            } = NEWEST_DRAW;

            const callData = new Interface([
                "function pushDraw((uint256,uint32,uint64,uint64,uint32))",
            ]).encodeFunctionData("pushDraw", [
                [
                    winningRandomNumber,
                    drawId,
                    timestamp,
                    beaconPeriodStartedAt,
                    beaconPeriodSeconds,
                ],
            ]);

            const calls: ICrossChainRelayerType.CallStruct[] = [
                {
                    target: drawExecutor.address,
                    data: callData,
                },
            ];

            await crossChainRelayerMock.mock.relayCalls.withArgs(calls, 500000).returns(1);

            await expect(
                drawRelayer.bridgeNewestDraw(crossChainRelayerMock.address, drawExecutor.address)
            )
                .to.emit(drawRelayer, "DrawBridged")
                .withArgs(crossChainRelayerMock.address, drawExecutor.address, [
                    winningRandomNumber,
                    drawId,
                    timestamp,
                    beaconPeriodStartedAt,
                    beaconPeriodSeconds,
                ]);
        });
    });

    describe("bridgeDraw()", async () => {
        it("should bridge draw", async () => {
            const {
                winningRandomNumber,
                drawId,
                timestamp,
                beaconPeriodStartedAt,
                beaconPeriodSeconds,
            } = DRAW_2;

            await drawBufferMock.mock.getDraw.withArgs(drawId).returns(DRAW_2);

            const callData = new Interface([
                "function pushDraw((uint256,uint32,uint64,uint64,uint32))",
            ]).encodeFunctionData("pushDraw", [
                [
                    winningRandomNumber,
                    drawId,
                    timestamp,
                    beaconPeriodStartedAt,
                    beaconPeriodSeconds,
                ],
            ]);

            const calls: ICrossChainRelayerType.CallStruct[] = [
                {
                    target: drawExecutor.address,
                    data: callData,
                },
            ];

            await crossChainRelayerMock.mock.relayCalls.withArgs(calls, 500000).returns(1);

            await expect(
                drawRelayer.bridgeDraw(drawId, crossChainRelayerMock.address, drawExecutor.address)
            )
                .to.emit(drawRelayer, "DrawBridged")
                .withArgs(crossChainRelayerMock.address, drawExecutor.address, [
                    winningRandomNumber,
                    drawId,
                    timestamp,
                    beaconPeriodStartedAt,
                    beaconPeriodSeconds,
                ]);
        });

        it("should fail to bridge draw if drawId is zero", async () => {
            await expect(
                drawRelayer.bridgeDraw(Zero, crossChainRelayerMock.address, drawExecutor.address)
            ).to.be.revertedWith("DR/drawId-gt-zero");
        });
    });

    describe("bridgeDraws()", async () => {
        it("should bridge several draws", async () => {
            await drawBufferMock.mock.getDraws.withArgs(drawIds).returns(draws);

            const callData = new Interface([
                "function pushDraws((uint256,uint32,uint64,uint64,uint32)[])",
            ]).encodeFunctionData("pushDraws", [draws]);

            const calls: ICrossChainRelayerType.CallStruct[] = [
                {
                    target: drawExecutor.address,
                    data: callData,
                },
            ];

            const gasLimit = 1000000;

            await crossChainRelayerMock.mock.relayCalls.withArgs(calls, gasLimit).returns(1);

            const bridgeDrawsTx = await drawRelayer.bridgeDraws(
                drawIds,
                crossChainRelayerMock.address,
                drawExecutor.address,
                gasLimit
            );

            await expect(bridgeDrawsTx).to.emit(drawRelayer, "DrawsBridged");

            const bridgeDrawsTxReceipt = await getTransactionReceipt(bridgeDrawsTx.hash);

            const bridgeDrawsTxEvents = bridgeDrawsTxReceipt.logs.map((log) => {
                try {
                    return drawRelayer.interface.parseLog(log);
                } catch (e) {
                    return null;
                }
            });

            const drawsBridgedEvent = bridgeDrawsTxEvents.find(
                (event) => event && event.name === "DrawsBridged"
            );

            if (drawsBridgedEvent) {
                expect(drawsBridgedEvent.args[0]).to.equal(crossChainRelayerMock.address);
                expect(drawsBridgedEvent.args[1]).to.equal(drawExecutor.address);
                drawsBridgedEvent.args[2].map((draw: IDrawBeacon.DrawStruct, index: number) => {
                    const currentDraw = draws[index];

                    expect(draw.winningRandomNumber).to.equal(currentDraw[0]);
                    expect(draw.drawId).to.equal(currentDraw[1]);
                    expect(draw.timestamp).to.equal(currentDraw[2]);
                    expect(draw.beaconPeriodStartedAt).to.equal(currentDraw[3]);
                    expect(draw.beaconPeriodSeconds).to.equal(currentDraw[4]);
                });
            }
        });
    });

    describe("_relayCalls()", async () => {
        it("should fail to relay calls if relayer is address zero", async () => {
            const { drawId } = DRAW_2;

            await drawBufferMock.mock.getDraw.withArgs(drawId).returns(DRAW_2);

            await expect(
                drawRelayer.bridgeDraw(drawId, AddressZero, drawExecutor.address)
            ).to.be.revertedWith("DR/relayer-not-zero-address");
        });

        it("should fail to relay calls if drawExecutor is address zero", async () => {
            const { drawId } = DRAW_2;

            await drawBufferMock.mock.getDraw.withArgs(drawId).returns(DRAW_2);

            await expect(
                drawRelayer.bridgeDraw(drawId, crossChainRelayerMock.address, AddressZero)
            ).to.be.revertedWith("DR/drawExecutor-not-zero-address");
        });

        it("should fail to relay calls if gasLimit is not gt zero", async () => {
            await drawBufferMock.mock.getDraws.withArgs(drawIds).returns(draws);

            await expect(
                drawRelayer.bridgeDraws(
                    drawIds,
                    crossChainRelayerMock.address,
                    drawExecutor.address,
                    Zero
                )
            ).to.be.revertedWith("DR/gasLimit-gt-zero");
        });
    });
});
