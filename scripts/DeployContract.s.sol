// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "lib/forge-std/src/Script.sol";
import {CampusId} from "../src/CampusId.sol"; // Adjust path if needed

contract DeployCampusId is Script {
    CampusId public campusId;

    function setUp() public {}

    function run() public returns (CampusId, address) {
        console.log("Starting CampusId deployment to Monad Testnet...");
        console.log("");

        // Load deployer account from private key
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(privateKey);

        console.log("Deployer address:", deployer);
        uint256 balance = deployer.balance;
        console.log("Deployer balance:", balance / 1e18, "MON");

        if (balance < 0.01 ether) {
            console.log("Warning: Low balance. Make sure you have enough MON.");
        }

        console.log("Network: Monad Testnet");
        console.log("Chain ID: 10143");
        console.log("RPC URL: https://testnet-rpc.monad.xyz/");
        console.log("");

        // Load constructor argument
        // address campusTokenAddress = vm.envAddress("CAMPUS_TOKEN_ADDRESS");

        vm.startBroadcast(privateKey);

        // Deploy CampusId with the token address
        campusId = new CampusId(0xA5e0a13D79802dd23C13bb8755bf1Ac9ED362454);
        address campusIdAddress = address(campusId);

        vm.stopBroadcast();

        console.log("CampusId deployed successfully!");
        console.log("Contract address:", campusIdAddress);
        console.log("Block explorer:", string.concat("https://testnet.monadexplorer.com/address/", _addressToString(campusIdAddress)));

        return (campusId, campusIdAddress);
    }

    function _addressToString(address _addr) internal pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(_addr)));
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(42);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            str[2 + i * 2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3 + i * 2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }
        return string(str);
    }
}