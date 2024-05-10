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
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/Base64Upgradeable.sol";
import "./Interfaces.sol";

contract CreatorVault is
    Initializable,
    ERC721EnumerableUpgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    ICreatorData
{
   
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter public _tokenId;
    CountersUpgradeable.Counter public _licenseNFTId;

    struct GlobalData {
        uint creatorCredits;
        address[] wallets;
        address licenseRegistry;
    }

    GlobalData public global;

    mapping(uint => bytes32) private tokens; // tokenId => assetId

    function initialize(
                            string calldata vaultName,
                            string calldata vaultSymbol,
                            address[] calldata wallets
    ) public initializer {

        __ERC721_init(vaultName, vaultSymbol);
        __ERC721Enumerable_init();
        __Pausable_init();
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        global.creatorCredits = 1;
        global.wallets = wallets;
        global.licenseRegistry = ICreatorVaultFactory(msg.sender).getLicenseRegistryContract();

        for(uint w=0; w<wallets.length; w++) {
            _grantRole(KEEPER_ROLE, wallets[w]);
        }
    }

    function version() public pure returns(string memory) {
        return "1.0.0";
    }


    function addVaultWallet(address wallet) public {
        require(!isVaultWallet((wallet)), "Wallet already added in Vault");
        require(hasRole(KEEPER_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || msg.sender == ILicenseRegistry(global.licenseRegistry).getStudioAccount(), UNAUTHORIZED_USER);
        global.wallets.push(wallet);
        _grantRole(KEEPER_ROLE, wallet);
    }

    function removeVaultWallet(address wallet) public {
        require(isVaultWallet((wallet)), "Wallet not in Vault");
        require(hasRole(KEEPER_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || msg.sender == ILicenseRegistry(global.licenseRegistry).getStudioAccount(), UNAUTHORIZED_USER);
        _revokeRole(KEEPER_ROLE, wallet);
        for(uint w=0;w<global.wallets.length;w++) {
            if (global.wallets[w] == wallet) {
                if (global.wallets.length > 1) {
                    global.wallets[w] = global.wallets[global.wallets.length-1];
                }
                global.wallets.pop();
            }
        }
    }

    function getCreatorCredits() public view returns(uint) {
        return global.creatorCredits;
    }

    function useCreatorCredits(uint credits) public {
        require(
            msg.sender == ILicenseRegistry(global.licenseRegistry).getAssetRegistryContract() ||
            msg.sender == ILicenseRegistry(global.licenseRegistry).getStudioAccount() ||
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender)
            , "Unauthorized user");
        require(global.creatorCredits >= credits, "Insufficient Creator Credits");
        global.creatorCredits -= credits;
    }

    function addCreatorCredit(uint credits) public onlyRole(STUDIO_ROLE) {
        global.creatorCredits += credits;
    }

    function tokenURI(uint tokenId) override public view returns (string memory){                   
        ICreatorData.AssetInfo memory assetInfo = ILicenseRegistry(global.licenseRegistry).getAssetByKey(tokens[tokenId]);
        return assetInfo.header.tokenUri;
    }

    function isVaultWallet(address wallet) public view returns(bool) {
        require(wallet != address(0), "Invalid wallet address");
        for(uint w=0; w<global.wallets.length; w++) {
            if (global.wallets[w] == wallet) {
                return true;
            }
        }
        return false;
    }

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function claimVTRU() external onlyVaultWallet() {
        require(payable(msg.sender).send(address(this).balance));
    }

    receive() external payable {
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721EnumerableUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    modifier onlyVaultWallet() {
        require(isVaultWallet(msg.sender), ICreatorData.UNAUTHORIZED_USER);
        _;
    }
}

