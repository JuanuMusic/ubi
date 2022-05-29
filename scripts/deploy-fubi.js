const deploymentParams = require('../deployment-params');

async function main() {

    const [deployer] = await ethers.getSigners();

    console.log(
        "Deploying contracts with the account:",
        deployer.address
    );

    console.log("Account balance:", (await deployer.getBalance()).toString());

    const UBI_ADDRESS = "0xf261c4f93d1b2991bB47e7F295AF3B2Fc17BD440";
    const FUBI_GOVERNOR = "0x2ad91063e489CC4009DF7feE45C25c8BE684Cf6a";
    const FUBI_MAX_DELEGATIONS = 100;
    const FUBI_NAME = "Flow UBI";
    const FUBI_SYMBOL = "FUBI";

    const FUBI = await ethers.getContractFactory("fUBI");
    console.log("Deploying fUBI");
    const fubi = await FUBI.deploy(UBI_ADDRESS, FUBI_GOVERNOR, FUBI_MAX_DELEGATIONS, FUBI_NAME, FUBI_SYMBOL);

    await fubi.deployed()

    console.log("FUBI deployed to:", fubi.address);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
