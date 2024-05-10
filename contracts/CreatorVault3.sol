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
import "./Interfaces.sol";

contract CreatorVault3 is
    Initializable,
    ERC721EnumerableUpgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable
{
    
    /****************************************************************************/
    /*                                  COUNTERS                                */
    /****************************************************************************/
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter public _tokenId;
    CountersUpgradeable.Counter public _licenseNFTId;

    uint public constant DECIMALS = 10 ** 18;

    /****************************************************************************/
    /*                                  ROLES                                   */
    /****************************************************************************/
    bytes32 public constant STUDIO_ROLE = bytes32(uint(0x01));
    bytes32 public constant MINTER_ROLE = bytes32(uint(0x02));

    /****************************************************************************/
    /*                                 TOKENS                                   */
    /****************************************************************************/

    struct LicenseNFT {
        uint assetId;
        uint licenseId;
        uint licenseFee;
        uint amountPaid;
        address licensee;
        uint64 licenseQuantity;
        uint16 platformBasisPoints;
        uint16 curatorBasisPoints;
        uint16 sellerBasisPoints;
        uint16 creatorRoyaltyBasisPoints;
    }

    struct GlobalData {
        string classImageURI;
        address assetRegistryContract;
        uint creatorCredits;
        uint[] licenseNFTLookup;
        address[] wallets;
        mapping(uint => LicenseNFT) licenseNFTs;
        mapping(address => uint[]) licenseNFTsByOwner;
    }
    
    GlobalData public global;

    event AssetLicensed(uint indexed assetId, uint indexed tokenId);

    function initialize(
                            string calldata vaultName,
                            string calldata vaultSymbol,
                            address[] calldata wallets
    ) public initializer {
     //   require(global.assetRegistryContract != address(0), "AssetRegistryContract address not set");

        __ERC721_init(vaultName, vaultSymbol);
        __ERC721Enumerable_init();
        __Pausable_init();
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);

        global.creatorCredits = 1;
        global.wallets = wallets;
    }

    function version() public pure returns(string memory) {
        return "3.0.0";
    }

    // function assetRegistryContract() public pure returns(address) {
    //     return 
    // }

    function isVaultWallet(address wallet) public view returns(bool) {
        require(wallet != address(0), "Invalid wallet address");
        for(uint w=0; w<global.wallets.length; w++) {
            if (global.wallets[w] == wallet) {
                return true;
            }
        }
        return false;
    }

    function getCreatorCredits() public view returns(uint) {
        return global.creatorCredits;
    }

    function useCreatorCredits(uint credits) public {
        require(msg.sender == global.assetRegistryContract, "Unauthorized user");
        require(global.creatorCredits - credits > 0, "Insufficient Creator Credits");
        global.creatorCredits -= credits;
    }

    function addCreatorCredit(uint credits) public onlyRole(STUDIO_ROLE) {
        global.creatorCredits += credits;
    }

    function setAssetRegistryContract(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(account != address(0), "Invalid Asset Registry Contract address");
        global.assetRegistryContract = account;
    }

    function grantLicense(
        uint assetId,
        uint licenseTypeId, // TODO:licenseId
        uint64 quantity
    ) public payable whenNotPaused {

        _licenseNFTId.increment();
        
        global.licenseNFTs[_licenseNFTId.current()] = LicenseNFT(
                                                        assetId,
                                                        0,
                                                        0,  // licenseFee
                                                        msg.value,// amountPaid
                                                        msg.sender, // licensee
                                                        quantity, // licenseQuantity
                                                        0,  // platformBasisPoints
                                                        0,  // curatorBasisPoints
                                                        0,  // sellerBasisPoints
                                                        0  // creatorRoyaltyBasisPoints
                                                      );
        global.licenseNFTLookup.push(_licenseNFTId.current());
        global.licenseNFTsByOwner[msg.sender].push(_licenseNFTId.current());

        for(uint i=0;i<quantity;i++) {
            _tokenId.increment();

            _mint(msg.sender, _tokenId.current());

           // emit CollectorCreditGranted(newLicenseNFT.id, account, newLicenseNFT.isUSD, newLicenseNFT.value);
        }
    }



    function getAccountTokens(address account) public view returns(LicenseNFT[] memory){

        uint[] memory nfts = global.licenseNFTsByOwner[account];
        LicenseNFT[] memory creditNFTs = new LicenseNFT[](nfts.length);
        for(uint f=0; f<nfts.length; f++) {
            creditNFTs[f] = global.licenseNFTs[nfts[f]];
        }
        return creditNFTs;
    }

    function getLicenseNFT(uint id) public view  returns (LicenseNFT memory)
    {
        return global.licenseNFTs[id];
    }

    function getLicenseNFTs() public view  returns (uint[] memory)
    {
        return global.licenseNFTLookup;
    }

  

    function tokenURI(uint tokenId) override public view returns (string memory){

        return "";
        // LicenseNFT memory creditNFT = global.licenseNFTs[tokenId];    
        // require(creditNFT.classId > 0, "Token ID does not exist");

        // LicenseNFTClass memory creditNFTClass = global.LicenseNFTClasses[creditNFT.classId];

	    // string memory json = Base64Upgradeable.encode(bytes(string(abi.encodePacked('{"name": "', creditNFTClass.name, '", "description": "Vitruveo Collector Credit NFT", "image": "', global.classImageURI, creditNFTClass.name, '.png"}'))));
	
        // return string(abi.encodePacked('data:application/json;base64,', json));
    }

    function setClassImageURI(string memory uri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        global.classImageURI = uri;
    }

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function recoverVTRU() external onlyRole(DEFAULT_ADMIN_ROLE) {
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

}

