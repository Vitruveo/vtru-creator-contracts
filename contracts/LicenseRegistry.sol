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
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/Base64Upgradeable.sol";
import "./UnorderedKeySet.sol";
import "./Interfaces.sol";

contract LicenseRegistry is
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    ICreatorData
{

    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter public _licenseInstanceId;

    event UsdVtruExchangeRateChanged(uint256 centsPerVtru);
    event LicenseIssued(uint indexed assetId, uint indexed licenseId, uint indexed licenseInstanceId, address licensee);


    struct GlobalInfo {
        uint256 usdVtruExchangeRate;
        address collectorCreditContract;
        address assetRegistryContract;
        address creatorVaultFactoryContract;
        address studioAccount;
        mapping(uint => LicenseInstance) licenseInstances;
        mapping(address => uint[]) licenseInstancesByOwner;
    }

    GlobalInfo public global;

    function initialize() public initializer {

        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function getLicenseInstance(uint id) public view  returns (LicenseInstance memory)
    {
        return global.licenseInstances[id];
    }

    // function buyLicense(
    //     uint assetId,
    //     uint licenseId,
    //     uint64 quantity
    // ) public payable whenNotPaused {

    //     _licenseNFTId.increment();
        
    //     global.licenseNFTs[_licenseNFTId.current()] = LicenseNFT(
    //                                                     assetId,
    //                                                     licenseId,
    //                                                     0,  // licenseFee
    //                                                     msg.value,// amountPaid
    //                                                     msg.sender, // licensee
    //                                                     quantity, // licenseQuantity
    //                                                     0,  // platformBasisPoints
    //                                                     0,  // curatorBasisPoints
    //                                                     0,  // sellerBasisPoints
    //                                                     0  // creatorRoyaltyBasisPoints
    //                                                   );
    //     global.licenseNFTLookup.push(_licenseNFTId.current());
    //     global.licenseNFTsByOwner[msg.sender].push(_licenseNFTId.current());

    //     for(uint i=0;i<quantity;i++) {
    //         _tokenId.increment();

    //         _mint(msg.sender, _tokenId.current());

    //        // emit CollectorCreditGranted(newLicenseNFT.id, account, newLicenseNFT.isUSD, newLicenseNFT.value);
    //     }
    // }

    function issueLicenseUsingCredits(uint256 assetId, uint256 licenseId, uint64 quantity) public {
        
        (uint tokens, uint usdCredit, uint otherCredit) = ICollectorCredit(global.collectorCreditContract).getAvailableCredit(msg.sender);
        
        uint64 priceUsd = IAssetRegistry(global.assetRegistryContract).getAssetAvailability(assetId, licenseId);
        uint64 totalUsd = priceUsd * quantity;
        require(usdCredit >= totalUsd, "Insufficient credit");

        
        _licenseInstanceId.increment();
        global.licenseInstancesByOwner[msg.sender].push(_licenseInstanceId.current());

        //Minting

        emit LicenseIssued(assetId, licenseId, _licenseInstanceId.current(), msg.sender);    
    }

    function getAvailableCredit(address account) public view returns(uint tokens, uint usdCredit, uint otherCredit) {
        return ICollectorCredit(global.collectorCreditContract).getAvailableCredit(account);
    }

    function setUsdVtruExchangeRate(uint256 centsPerVtru) public onlyRole(DEFAULT_ADMIN_ROLE) {
        global.usdVtruExchangeRate = centsPerVtru;
        emit UsdVtruExchangeRateChanged(centsPerVtru);
    }

    function getUsdVtruExchangeRate() public view returns(uint) {
        require(global.usdVtruExchangeRate > 0, "Exchange rate not set");
        return(global.usdVtruExchangeRate);
    }

    function setStudioAccount(address account) public  onlyRole(DEFAULT_ADMIN_ROLE) {
        require(account != address(0), "Invalid Studio account address");
        global.studioAccount = account;
    }

    function getStudioAccount() public view returns(address) {
        return(global.studioAccount);
    }

    function setCollectorCreditContract(address account) public  onlyRole(DEFAULT_ADMIN_ROLE) {
        require(account != address(0), "Invalid Collector Credits Contract address");
        global.collectorCreditContract = account;
    }

    function getCollectorCreditContract() public view returns(address) {
        return(global.collectorCreditContract);
    }

    function setAssetRegistryContract(address account) public  onlyRole(DEFAULT_ADMIN_ROLE) {
        require(account != address(0), "Invalid Asset Registry Contract address");
        global.assetRegistryContract = account;
    }

    function getAssetRegistryContract() public view returns(address) {
        return(global.assetRegistryContract);
    }

    function setCreatorVaultFactoryContract(address account) public  onlyRole(DEFAULT_ADMIN_ROLE) {
        require(account != address(0), "Invalid Creator Vault Factory Contract address");
        global.creatorVaultFactoryContract = account;
    }

    function getCreatorVaultFactoryContract() public view returns(address) {
        return(global.creatorVaultFactoryContract);
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

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(UPGRADER_ROLE) {}

    // The following functions are overrides required by Solidity.

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}