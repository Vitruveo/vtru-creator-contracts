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

contract ContractRegistry {

    struct Contract {
        string name;
        address account;
        address owner;
    }

    mapping(string => Contract) testnet;
    mapping(string => Contract) mainnet;

    constructor() {
    }

    function get(string memory name, bool isTestNet) public view returns(address) {

        if (isTestNet) {
            return(testnet[name].account);
        }

        return(mainnet[name].account);
    }

    function register(string memory name, address account, bool isTestNet) public {
        require(isTestNet ? testnet[name].account == address(0) : mainnet[name].account == address(0), "Name already exists");

        if (isTestNet) {
            testnet[name] = Contract(name, account, msg.sender);
        } else {
            mainnet[name] = Contract(name, account, msg.sender);
        }
    }

    function update(string memory name, address account, bool isTestNet) public {
        require(isTestNet ? testnet[name].owner == msg.sender : mainnet[name].owner == msg.sender, "Unauthorized user");

        if (isTestNet) {
            testnet[name] = Contract(name, account, msg.sender);
        } else {
            mainnet[name] = Contract(name, account, msg.sender);
        }

    }


    function remove(string memory name, bool isTestNet) public {
        require(isTestNet ? testnet[name].owner == msg.sender : mainnet[name].owner == msg.sender, "Unauthorized user");

        if (isTestNet) {
            delete testnet[name];
        } else {
            delete mainnet[name];
        }

    }

}