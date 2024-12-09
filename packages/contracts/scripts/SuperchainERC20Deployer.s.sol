// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script, console} from "forge-std/Script.sol";
import {Vm} from "forge-std/Vm.sol";
import {L2NativeSuperchainERC20} from "../src/L2NativeSuperchainERC20.sol";

contract SuperchainERC20Deployer is Script {
    string deployConfig;

    constructor() {
        string memory deployConfigPath = vm.envOr("DEPLOY_CONFIG_PATH", string("/configs/deploy-config.toml"));
        string memory filePath = string.concat(vm.projectRoot(), deployConfigPath);
        deployConfig = vm.readFile(filePath);
    }

    modifier broadcast() {
        vm.startBroadcast(msg.sender);
        _;
        vm.stopBroadcast();
    }

    function setUp() public {}

    function run() public {
        string[] memory chainsToDeployTo = vm.parseTomlStringArray(deployConfig, ".deploy_config.chains");

        for (uint256 i = 0; i < chainsToDeployTo.length; i++) {
            string memory chainToDeployTo = chainsToDeployTo[i];
            console.log("Starting deployment on chain: ", chainToDeployTo);

            vm.createSelectFork(chainToDeployTo);
            (address deployedAddress, address ownerAddr) = deployL2NativeSuperchainERC20();

            console.log("Deployment successful on chain: ", chainToDeployTo);
            console.log("Deployed address: ", deployedAddress);
            console.log("Owner address: ", ownerAddr);

            outputDeploymentResult(deployedAddress, ownerAddr);
        }
    }

    function deployL2NativeSuperchainERC20() public broadcast returns (address addr_, address ownerAddr_) {
        ownerAddr_ = vm.parseTomlAddress(deployConfig, ".token.owner_address");
        string memory name = vm.parseTomlString(deployConfig, ".token.name");
        string memory symbol = vm.parseTomlString(deployConfig, ".token.symbol");
        uint256 decimals = vm.parseTomlUint(deployConfig, ".token.decimals");

        require(decimals <= type(uint8).max, "Decimals exceed uint8 range");
        require(bytes(name).length > 0, "Token name cannot be empty");
        require(bytes(symbol).length > 0, "Token symbol cannot be empty");
        require(ownerAddr_ != address(0), "Owner address cannot be zero");

        bytes memory initCode = abi.encodePacked(
            type(L2NativeSuperchainERC20).creationCode,
            abi.encode(ownerAddr_, name, symbol, uint8(decimals))
        );

        address preComputedAddress = vm.computeCreate2Address(_implSalt(), keccak256(initCode));
        if (preComputedAddress.code.length > 0) {
            console.log("Token already deployed at: ", preComputedAddress);
            addr_ = preComputedAddress;
        } else {
            addr_ = address(new L2NativeSuperchainERC20{salt: _implSalt()}(ownerAddr_, name, symbol, uint8(decimals)));
            console.log("Deployed token at: ", addr_);
        }
    }

    function outputDeploymentResult(address deployedAddress, address ownerAddr) public {
        console.log("Saving deployment result...");

        string memory obj = "result";
        vm.serializeAddress(obj, "deployedAddress", deployedAddress);
        string memory jsonOutput = vm.serializeAddress(obj, "ownerAddress", ownerAddr);

        vm.writeJson(jsonOutput, "deployment.json");
    }

    function _implSalt() internal view returns (bytes32) {
        string memory salt = vm.parseTomlString(deployConfig, ".deploy_config.salt");
        require(bytes(salt).length > 0, "Salt cannot be empty");
        return keccak256(abi.encodePacked(salt));
    }
}
