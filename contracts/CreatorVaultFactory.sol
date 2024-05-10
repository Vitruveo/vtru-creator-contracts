/*
 *
 *
 *   ██╗   ██╗    ██╗    ████████╗    ██████╗     ██╗   ██╗    ██╗   ██╗    ███████╗     ██████╗ 
 *   ██║   ██║    ██║    ╚══██╔══╝    ██╔══██╗    ██║   ██║    ██║   ██║    ██╔════╝    ██╔═══██╗
 *   ██║   ██║    ██║       ██║       ██████╔╝    ██║   ██║    ██║   ██║    █████╗      ██║   ██║
 *   ╚██╗ ██╔╝    ██║       ██║       ██╔══██╗    ██║   ██║    ╚██╗ ██╔╝    ██╔══╝      ██║   ██║
 *    ╚████╔╝     ██║       ██║       ██║  ██║    ╚██████╔╝     ╚████╔╝     ███████╗    ╚██████╔╝
 *     ╚═══╝      ╚═╝       ╚═╝       ╚═╝  ╚═╝     ╚═════╝       ╚═══╝      ╚══════╝     ╚═════╝ 
 * 
 */

// SPDX-License-Identifier: MIT
// Author: Nik Kalyani @techbubble
pragma solidity 0.8.17;

import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./CreatorVaultBeacon.sol";
import "./CreatorVault.sol";
import "./UnorderedBytesKeySet.sol";

contract CreatorVaultFactory is Ownable {
    using UnorderedBytesKeySetLib for UnorderedBytesKeySetLib.Set;
    UnorderedBytesKeySetLib.Set private vaultList;

    address public licenseRegistryContract;
    mapping(bytes32 => address) private vaults;
    mapping(address => address) private vaultWallets;
    CreatorVaultBeacon immutable beacon;

    event VaultCreated(string indexed vaultKey, address indexed vault, bytes32 internalKey);

    constructor(address initTarget, address licenseRegistry) {
        beacon = new CreatorVaultBeacon(initTarget);
        licenseRegistryContract = licenseRegistry;
    }

    function createVault(string calldata vaultKey, string calldata vaultName, string calldata vaultSymbol, address[] memory wallets) public {
        bytes32 key = keccak256(bytes(vaultKey));
        require(licenseRegistryContract != address(0), "License Registry contract address not set");
        require(vaults[key] == address(0), "Vault already exists");

        for(uint i=0; i<wallets.length; i++) {
            require(vaultWallets[wallets[i]] == address(0), "Wallet already belongs to another Vault");            
        }

        BeaconProxy vault = new BeaconProxy(
            address(beacon),
            abi.encodeWithSelector(CreatorVault(payable(address(0))).initialize.selector, vaultName, vaultSymbol, wallets)
        );
        vaults[key] = address(vault);
        vaultList.insert(key);

        for(uint i=0; i<wallets.length; i++) {
            vaultWallets[wallets[i]] = address(vault);           
        }

        emit VaultCreated(vaultKey, address(vault), key);
    }

    function setLicenseRegistryContract(address account) public onlyOwner {
        require(account != address(0), "Invalid License Registry Contract address");
        licenseRegistryContract = account;
    }

    function getLicenseRegistryContract() public view returns(address) {
        return(licenseRegistryContract);
    }

    function getBeacon() public view returns (address) {
        return address(beacon);
    }

    function getImplementation() public view returns (address) {
        return beacon.implementation();
    }

    function getVaultByWallet(address wallet) public view returns(address) {
        return vaultWallets[wallet];
    }
    
    function getVaultPage(uint256 page, uint256 count) public view returns(address[] memory) {
        uint start = page * count;
        address[] memory result = new address[](count);

        for(uint i=start; i<start+count; i++) {
           result[i - start] = getVaultAtIndex(i);
        }
        return(result);
    }

    function getVaultBatch(uint256 start, uint256 count) public view returns(address[] memory) {
        address[] memory result = new address[](count);

        for(uint i=start; i<start+count; i++) {
           result[i - start] = getVaultAtIndex(i);
        }
        return(result);
    }

    function getVaultCount() public view returns(uint count) {
        return vaultList.count();
    }

    function isVaultByKey(string memory vaultKey) public view returns(bool) {
        bytes32 key = keccak256(bytes(vaultKey));
        return isVault(key);
    }

    function isVault(bytes32 key) public view returns(bool) {
        return vaultList.exists(key);
    }

    function getVaultByKey(string memory vaultKey) public view returns(address) {
        bytes32 key = keccak256(bytes(vaultKey));
        return getVault(key);
    }

    function getVault(bytes32 key) public view returns(address) {
        require(vaultList.exists(key), "Can't get a Vault that doesn't exist.");
        return(vaults[key]);
    }

    function getVaultAtIndex(uint index) public view returns(address) {
        bytes32 key = vaultList.keyAtIndex(index);
        return vaults[key];
    }
    
    function getKeyAtIndex(uint index) public view returns(bytes32) {
        return vaultList.keyAtIndex(index);
    }
}