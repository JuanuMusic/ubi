const deploymentParams = require('../deployment-params');

async function main() {

    const [deployer] = await ethers.getSigners();

    console.log(
        "Deploying contracts with the account:",
        deployer.address
    );

    console.log("Account balance:", (await deployer.getBalance()).toString());

    const Subi = await ethers.getContractFactory("fUBI");
    console.log("Deploying sUBI");

    // const token = await upgrades.deployProxy(
    //   Token,
    //   [
    //     deploymentParams.INITIAL_SUPPLY,
    //     deploymentParams.TOKEN_NAME,
    //     deploymentParams.TOKEN_SYMBOL,
    //     deploymentParams.ACCRUED_PER_SECOND,
    //     deploymentParams.PROOF_OF_HUMANITY_KOVAN
    //   ],
    //   {
    //     initializer: 'initialize',
    //     unsafeAllowCustomTypes: true 
    //   }
    // );
    const subi = await Subi.deploy("0x1ac5F168C220De2515Af6068c5A153aFe2c76d36", "0x2ad91063e489CC4009DF7feE45C25c8BE684Cf6a", 100, "Flow UBI", "FUBI");

    await subi.deployed()

    console.log("SUBI deployed to:", subi.address);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
