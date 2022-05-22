BondFi is a decenteralized bond issuer that allows bonds to be created by anyone. Currently, BondFi implements zero coupon bonds as the main bond instrument. In future releases, we will allow a variety of bonds. This is a friendly fork of Smart Contracts from Porter Finance. 

The frontend for this project is located [here](https://github.com/victorfei/ethglobal-dao-lend-interface).

## Contracts
The bond contracts use a factory pattern to create new bonds. Currently, the main contracts are BondFactory.sol and Bond.sol. 

The contract are deployed on Kovan:

BondFactory: [0xeCF51812d699B75EC85C554789B064B994419440](https://kovan.etherscan.io/address/0xecf51812d699b75ec85c554789b064b994419440)

## Development

For local development there are environment variables necessary to enable some hardhat plugins.

# Compile

```
TS_NODE_TRANSPILE_ONLY=1 npx hardhat compile.
Note: Without TS_NODE_TRANSPILE_ONLY=1 flag, compiling may result in error that generated 'typechain' artifact/folder does not exist.
```

### Deployment

Using hardhat-deploy all of the scripts in the `./deploy` folder are run. This will run the whole integration flow as well which includes deploying of the factory, tokens, creating bonds, doing bond actions, and starting auctions. If that is not desired, add a `tags` flag with what you want to deploy.

```
npx hardhat deploy --tags main-deployment # deploy bond factory
npx hardhat deploy --tags test-deployment # and deploy tokens
npx hardhat deploy --tags permissions # and grant roles & permissions
npx hardhat deploy --tags bonds # and deploy test bonds
npx hardhat deploy --tags auctions # and start bond auctions
npx hardhat deploy --tags actions # and do bond actions
```

npx hardhat deploy --network kovan
Additionally, all of the above commands can be run with `--network kovan` to deploy to the Kovan test network.

Note: The deploy script will run with the `npx hardhat node` as well as the `npx hardhat test` tasks.

### Verification

Verify deployed contracts with `hardhat-etherscan`.

```
npx hardhat verify <address>
```

### Testing

Running the hardhat test suite

```
npx hardhat test
```

Fork testing requires first running the mainnet-fork

```
npx hardhat node
```

and making the target for testing the local node

```
npx hardhat test --network localhost
```

Running the fuzzing test suite with Echidna

- Get latest release https://github.com/crytic/echidna
- Install to `/usr/local/bin`
- `npm run echidna`
- change the config located at `echidna.config.yaml` to tweak execution

### Other useful commands

```shell
npx hardhat help
npx hardhat compile # create contract artifacts
npx hardhat clean # removes artifacts and maybe other things
npx hardhat coverage # runs the contract coverage report
npx hardhat integration # runs the integration task
npx hardhat settle-auction --auctionId <auctionId> # settles an auction
npx eslint '**/*.{js,ts}' --fix
npx prettier '**/*.{json,sol,md,ts}' --write
npx solhint 'contracts/**/*.sol' --fix
```
