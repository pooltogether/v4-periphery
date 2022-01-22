import { task } from "hardhat/config";

import {
    AUSDC_ADDRESS_MAINNET,
    INCENTIVES_CONTROLLER_ADDRESS_MAINNET,
    LENDING_POOL_ADDRESSES_PROVIDER_REGISTRY_ADDRESS_MAINNET,
    EXECUTIVE_TEAM_ADDRESS_MAINNET,
    TOKEN_DECIMALS,
} from "../../Constants";

import { action, success } from "../../helpers";

export default task("fork:create-pool", "Create pool").setAction(async (taskArguments, hre) => {
    action("Create pool...");

    const {
        deployments: { deploy },
        getNamedAccounts,
    } = hre;

    const { deployer } = await getNamedAccounts();

    console.log("Deployer is: ", deployer);

    const aaveUsdcYieldSourceResult = await deploy("ATokenYieldSource", {
        from: deployer,
        args: [
            AUSDC_ADDRESS_MAINNET,
            INCENTIVES_CONTROLLER_ADDRESS_MAINNET,
            LENDING_POOL_ADDRESSES_PROVIDER_REGISTRY_ADDRESS_MAINNET,
            TOKEN_DECIMALS,
            "PTaUSDCY",
            "PoolTogether aUSDC Yield",
            EXECUTIVE_TEAM_ADDRESS_MAINNET,
        ],
    });

    await deploy("YieldSourcePrizePool", {
        from: deployer,
        args: [deployer, aaveUsdcYieldSourceResult.address],
    });

    success("Pool created!");
});
