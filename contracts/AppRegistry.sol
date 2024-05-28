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

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./UnorderedStringKeySet.sol";

contract AppRegistry is
    Initializable,
    AccessControlUpgradeable,
    UUPSUpgradeable {

    using UnorderedStringKeySetLib for UnorderedStringKeySetLib.Set;
    UnorderedStringKeySetLib.Set private testnetList;
    UnorderedStringKeySetLib.Set private mainnetList;

    struct AppInfo {
        string key;
        address account;
        address owner;
    }

    mapping(string => AppInfo) testnet;
    mapping(string => AppInfo) mainnet;

    function initialize() public initializer {
        __UUPSUpgradeable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function version() public pure returns(string memory) {
        return "1.0.0";
    }

    function get(string memory key, bool isTestNet) public view returns(address) {

        return isTestNet ? testnet[key].account : mainnet[key].account;
    }

    function register(string memory key, address account, bool isTestNet) public {
        require(isTestNet ? testnet[key].account == address(0) : mainnet[key].account == address(0), "Key already exists");

        if (isTestNet) {
            testnet[key] = AppInfo(key, account, msg.sender);
        } else {
            mainnet[key] = AppInfo(key, account, msg.sender);
        }
    }

    function update(string memory key, address account, bool isTestNet) public {
        require(isTestNet ? testnet[key].owner == msg.sender : mainnet[key].owner == msg.sender, "Unauthorized user");

        if (isTestNet) {
            testnet[key] = AppInfo(key, account, msg.sender);
        } else {
            mainnet[key] = AppInfo(key, account, msg.sender);
        }

    }

    function remove(string memory key, bool isTestNet) public {
        require(isTestNet ? testnet[key].owner == msg.sender : mainnet[key].owner == msg.sender, "Unauthorized user");

        if (isTestNet) {
            delete testnet[key];
        } else {
            delete mainnet[key];
        }
    }

    function getAppBatch(uint256 start, uint256 count, bool isTestNet) public view returns(AppInfo[] memory) {
        AppInfo[] memory result = new AppInfo[](count);

        for(uint i=start; i<start+count; i++) {
           result[i - start] = getAppAtIndex(i, isTestNet);
        }
        return(result);
    }

    function getAppCount(bool isTestNet) public view returns(uint count) {
        return isTestNet ? testnetList.count() : mainnetList.count();
    }

    function isApp(string calldata key, bool isTestNet) public view returns(bool) {
        return isTestNet ? testnetList.exists(key) : mainnetList.exists(key);
    }

    function getApp(string calldata key, bool isTestNet) public view returns(AppInfo memory) {
        require(isApp(key, isTestNet), "Can't get a key that doesn't exist.");
        return isTestNet ? testnet[key] : mainnet[key];
    }

    function getAppAtIndex(uint index, bool isTestNet) public view returns(AppInfo memory) {
        string memory key = isTestNet ? testnetList.keyAtIndex(index) : mainnetList.keyAtIndex(index);
        return isTestNet ? testnet[key] : mainnet[key];
    }

    function recoverVTRU() external onlyRole(DEFAULT_ADMIN_ROLE) {
        (bool recovered, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(recovered, "Recovery failed"); 
    }

    receive() external payable {
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

}