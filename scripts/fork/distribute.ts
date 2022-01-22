import { usdc } from "@studydefi/money-legos/erc20";

import { task } from "hardhat/config";

import { ETH_HOLDER_ADDRESS_MAINNET, USDC_HOLDER_ADDRESS_MAINNET } from "../../Constants";
import { action, success } from "../../helpers";

export default task("fork:distribute", "Distribute Ether and USDC").setAction(
    async (taskArguments, hre) => {
        action("Distributing Ether and USDC...");

        const { getNamedAccounts, ethers } = hre;
        const { provider, getContractAt } = ethers;
        const { deployer } = await getNamedAccounts();

        const ethHolder = provider.getUncheckedSigner(ETH_HOLDER_ADDRESS_MAINNET);
        const usdcHolder = provider.getUncheckedSigner(USDC_HOLDER_ADDRESS_MAINNET);
        const usdcContract = await getContractAt(usdc.abi, usdc.address, usdcHolder);

        const recipients: { [key: string]: string } = {
            ["Deployer"]: deployer,
        };

        const keys = Object.keys(recipients);

        for (var i = 0; i < keys.length; i++) {
            const name = keys[i];
            const address = recipients[name];

            action(`Sending 1000 Ether to ${name}...`);
            await ethHolder.sendTransaction({
                to: address,
                value: ethers.utils.parseEther("1000"),
            });

            action(`Sending 1000 USDC to ${name}...`);
            await usdcContract.transfer(address, ethers.utils.parseUnits("1000", 6));
        }

        success("Done!");
    }
);
