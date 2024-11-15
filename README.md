# SuperchainERC20 Starter Kit

<details>
<summary><h2>📑 Table of Contents</h2></summary>

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [🤔 What is SuperchainERC20?](#-what-is-superchainerc20)
  - [`IERC7802`](#ierc7802)
- [🚀 Getting Started](#-getting-started)
  - [1. Install prerequisites: `foundry`](#1-install-prerequisites-foundry)
  - [2. Clone and navigate to the repository:](#2-clone-and-navigate-to-the-repository)
  - [3. Install project dependencies using pnpm:](#3-install-project-dependencies-using-pnpm)
  - [4. Initialize .env files:](#4-initialize-env-files)
  - [5. Start the development environment:](#5-start-the-development-environment)
- [📦 Deploying SuperchainERC20s](#-deploying-superchainerc20s)
  - [Configuring RPC urls](#configuring-rpc-urls)
  - [Deployment config](#deployment-config)
    - [`[deploy-config]`](#deploy-config)
    - [`[token]`](#token)
  - [Deploying a token](#deploying-a-token)
  - [Best practices for deploying SuperchainERC20](#best-practices-for-deploying-superchainerc20)
    - [Use Create2 to deploy SuperchainERC20](#use-create2-to-deploy-superchainerc20)
    - [`crosschainMint` and `crosschainBurn` permissions](#crosschainmint-and-crosschainburn-permissions)
- [🧪 E2E Tests](#-e2e-tests)
  - [Prerequisites](#prerequisites)
  - [Running the Tests](#running-the-tests)
- [🌉 Example: How to bridge a SuperchainERC20 token to another chain](#-example-how-to-bridge-a-superchainerc20-token-to-another-chain)
- [🤝 Contributing](#-contributing)
- [⚖️ License](#-license)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

</details>

## 🤔 What is SuperchainERC20?

`SuperchainERC20` is an implementation of [ERC-7802](https://ethereum-magicians.org/t/erc-7802-crosschain-token-interface/21508) designed to enable asset interoperability in the Superchain.
`SuperchainERC20` tokens are fungible across the Superchain by giving the `SuperchainERC20Bridge` permission to mint and burn the token during cross-chain transfers. For more information on SuperchainERC20 please visit the [docs](https://docs.optimism.io/stack/interop/superchain-erc20).

**Note**: ERC20 tokens that do not utilize the `SuperchainERC20Bridge` for cross-chain transfers can still achieve fungibility across the Superchain through interop message passing with a custom bridge solution. For these custom tokens, implementing [ERC-7802](https://ethereum-magicians.org/t/erc-7802-crosschain-token-interface/21508) is strongly recommended, as it unifies cross-chain mint and burn interfaces, enabling tokens to benefit from a standardized approach to cross-chain transfers.

### `IERC7802`

To achieve cross-chain functionality, the `SuperchainERC20` standard incorporates the `IERC7802` interface, defining essential functions and events:

- **`crosschainMint`**: Mints tokens on the destination chain as part of a cross-chain transfer.
- **`crosschainBurn`**: Burns tokens on the source chain to facilitate the transfer.
- **Events (`CrosschainMint` and `CrosschainBurn`)**: Emit when tokens are minted or burned, enabling transparent tracking of cross-chain transactions.

## 🚀 Getting Started

### 1. Install prerequisites: `foundry`

`supersim` requires `anvil` to be installed.

Follow [this guide](https://book.getfoundry.sh/getting-started/installation) to install Foundry.

### 2. Clone and navigate to the repository:

```sh
git clone git@github.com:ethereum-optimism/superchainerc20-starter.git
cd superchainerc20-starter
```

### 3. Install project dependencies using pnpm:

```sh
pnpm i
```

### 4. Initialize .env files:

```sh
pnpm init:env
```

### 5. Start the development environment:

This command will:

- Start the `supersim` local development environment
- Deploy the smart contracts to the test networks
- Launch the example frontend application

```sh
pnpm dev
```

## 📦 Deploying SuperchainERC20s

### Configuring RPC urls

This repository includes a script to automatically fetch the public RPC URLs for each chain listed in the [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/main/chainList.json) and add them to the `[rpc_endpoints]` configuration section of `foundry.toml`.

The script ensures that only new RPC URLs are appended, preserving any URLs already present in `foundry.toml`. To execute this script, run:

```sh
pnpm contracts:update:rpcs
```

### Deployment config

The deployment configuration for token deployments is managed through the `deploy-config.toml` file. Below is a detailed breakdown of each configuration section:

#### `[deploy-config]`

This section defines parameters for deploying token contracts.

- `salt`: A unique identifier used for deploying token contracts via [`Create2`]. This value along with the contract bytecode ensures that contract deployments are deterministic.
  - example: `salt = "ethers phoenix"`
- `chains`: Lists the chains where the token will be deployed. Each chain must correspond to an entry in the `[rpc_endpoints]` section of `foundry.toml`.
  - example: `chains = ["op_chain_a","op_chain_b"]`

#### `[token]`

Deployment configuration for the token that will be deployed.

- `owner_address`: the address designated as the owner of the token.
  - The `L2NativeSuperchainERC20.sol` contract included in this repo extends the [`Ownable`](https://github.com/Vectorized/solady/blob/c3b2ffb4a3334ea519555c5ea11fb0e666f8c2bc/src/auth/Ownable.sol) contract
  - example: `owner_address = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"`
- `name`: the token's name.
  - example: `name = "TestSuperchainERC20"`
- `symbol`: the token's symbol.
  - example: `symbol = "TSU"`
- `decimals`: the number of decimal places the token supports.
  - example: `decimals = 18`

### Deploying a token

Before proceeding with this section, ensure that your `deploy-config.toml` file is fully configured (see the [Deployment config](#deployment-config) section for more details on setup). Additionally, confirm that the `[rpc_endpoints]` section in `foundry.toml` is properly set up by following the instructions in [Configuring RPC urls](#configuring-rpc-urls).

Deployments are executed through the `SuperchainERC20Deployer.s.sol` script. This script deploys tokens across each specified chain in the deployment configuration using `Create2`, ensuring deterministic contract addresses for each deployment. The script targets the `L2NativeSuperchainERC20.sol` contract by default. If you need to modify the token being deployed, either update this file directly or point the script to a custom token contract of your choice.

To execute a token deployment run:

```sh
pnpm contracts:deploy:token

```

### Best practices for deploying SuperchainERC20

#### Use Create2 to deploy SuperchainERC20

`Create2` ensures that the address is deterministically determined by the bytecode of the contract and the provided salt. This is crucial because in order for cross-chain transfers of `SuperchainERC20`s to work with interop, the tokens must be deployed at the same address across all chains.

#### `crosschainMint` and `crosschainBurn` permissions

For best security practices `SuperchainERC20Bridge` should be the only contract with permission to call `crosschainMint` and `crosschainBurn`. These permissions are set up by default when using the `SuperchainERC20` contract.

## 🧪 E2E Tests

The `packages/e2e-test` directory contains simple end-to-end integration tests using `vitest` that run against `supersim`

### Prerequisites

Before running the tests, ensure you have:

1. Completed all steps in the [Getting Started](#-getting-started) section
2. Initialized your environment variables (`pnpm init:env`)

### Running the Tests

```sh
pnpm e2e-test
```

The tests will run against your local supersim instance.

## 🌉 Example: How to bridge a SuperchainERC20 token to another chain

**Note**: Interop is currently in active development and not yet ready for production use. This example uses [supersim](https://github.com/ethereum-optimism/supersim) in order to demonstrate how cross-chain transfers will work once interop is live.

**Note**: this example uses a pre-funded test account provided by anvil for all transactions and as the owner of the `L2NativeSuperchainERC20`. The address of this account is `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266` and private key is `0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80`

**1. Follow the steps in the [Getting started](#getting-started) section.**

After completing these steps, you will have the following set up:

- `supersim` running in autorelay mode with two L2 chains
- The `L2NativeSuperchainERC20` token deployed on both chains

**2. Find the address and owner of the L2NativeSuperchainERC20 token that was deployed.**

The address that the token in step 1 was deployed to and the address of the owner of the token can be found in the [deployment.json](packages/contracts/deployment.json) file under the `"deployedAddress"` and `"ownerAddress"` fields. The `deployedAddress` address will be used for any token interactions in the next steps and the private key of the `ownerAddress` will need to be used for step 3 since minting requires owner privileges. In this example `deployment.json` file the token in step 1 was deployed at `0x5BCf71Ca0CE963373d917031aAFDd6D98B80B159` and the owner address is `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266`:

```sh
# example
{
  "deployedAddress": "0x5BCf71Ca0CE963373d917031aAFDd6D98B80B159",
  "ownerAddress": "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
}
```

**3. Mint tokens to transfer on chain 901**

The following command creates a transaction using `cast` to mint 1000 `L2NativeSuperchainERC20` tokens. Replace `<deployed-token-address>` with the `deployedAddress` from [deployment.json](packages/contracts/deployment.json), replace `<recipient-address>` with the address you would like to send the tokens to, and replace `<owner-address-private-key>` with the private key of the `ownerAddress` from step [deployment.json](packages/contracts/deployment.json).

```sh
cast send <deployed-token-address> "mintTo(address _to, uint256 _amount)" <recipient-address> 1000  --rpc-url http://127.0.0.1:9545 --private-key <owner-address-private-key>
```

**4. Initiate the send transaction on chain 901**

Send the tokens from Chain 901 to Chain 902 by calling `SendERC20` on the `SuperchainTokenBridge`. The `SuperchainTokenBridge` is an OP Stack predeploy and can be located at address `0x4200000000000000000000000000000000000028`. Replace `<deployed-token-address>` with the `deployedAddress` from [deployment.json](packages/contracts/deployment.json), replace `<recipient-address>` with the address you would like to send the tokens to, and replace `<token-sender-private-key>` with the private key of the recipient address from step 3.

```sh
cast send 0x4200000000000000000000000000000000000028 "sendERC20(address _token, address _to, uint256 _amount, uint256 _chainId)" <deployed-token-address> <recipient-address> 1000 902 --rpc-url http://127.0.0.1:9545 --private-key <token-sender-private-key>
```

**5. Wait for the relayed message to appear on chain 902**

In a few seconds, you should see the RelayedMessage on chain 902:

```sh
# example
INFO [11-01|16:02:25.089] SuperchainTokenBridge#RelayERC20 token=0x5BCf71Ca0CE963373d917031aAFDd6D98B80B159 from=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 to=0x70997970C51812dc3A010C7d01b50e0d17dc79C8 amount=1000 source=901
```

**6. Check the balance on chain 902**

Verify that the balance for the recipient of the `L2NativeSuperchainERC20` on chain 902 has increased:

```sh
cast balance --erc20 <deployed-token-address> <recipient-address> --rpc-url http://127.0.0.1:9546
```

## 🤝 Contributing

Contributions are encouraged, but please open an issue before making any major changes to ensure your changes will be accepted.

## ⚖️ License

Files are licensed under the [MIT license](./LICENSE).

<a href="./LICENSE"><img src="https://user-images.githubusercontent.com/35039927/231030761-66f5ce58-a4e9-4695-b1fe-255b1bceac92.png" alt="License information" width="200" /></a>
