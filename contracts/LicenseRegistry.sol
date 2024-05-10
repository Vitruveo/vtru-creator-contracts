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
    CountersUpgradeable.Counter public _licenseTypeId;

    event UsdVtruExchangeRateChanged(uint256 centsPerVtru);
    event LicenseIssued(uint indexed assetId, uint indexed licenseId, uint indexed licenseInstanceId, address licensee);


    struct LicenseTypeInfo {
        uint256 id;
        string name;
        string info;
        bool isMintable;
        bool isElastic;
        bool isActive;
        address issuer;
    }

    struct GlobalInfo {
        uint256 usdVtruExchangeRate;
        address collectorCreditContract;
        address assetRegistryContract;
        address creatorVaultFactoryContract;
        address studioAccount;
        mapping(uint => LicenseTypeInfo) licenseTypes;
        mapping(uint => LicenseInstance) licenseInstances;
        mapping(address => uint[]) licenseInstancesByOwner;
    }

    GlobalInfo public global;

    function initialize() public initializer {

        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        registerLicenseType("NFT-ART-1", "NFT", true, true);
        registerLicenseType("STREAM-ART-1", "Stream", false, false);
        registerLicenseType("REMIX-ART-1", "Remix", false, false);
        registerLicenseType("PRINT-ART-1", "Print", false, false);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function registerLicenseType(string memory name, string memory info, bool isMintable, bool isElastic) public onlyRole(DEFAULT_ADMIN_ROLE)  {

        _licenseTypeId.increment();
        global.licenseTypes[_licenseTypeId.current()] = LicenseTypeInfo(
                                                                            _licenseTypeId.current(), 
                                                                            name, 
                                                                            info,
                                                                            isMintable, 
                                                                            isElastic,
                                                                            true,   // isActive
                                                                            msg.sender // issuer
                                                                        );
    }

    function changeLicenseType(uint licenseTypeId, string memory name, string memory info, bool active) public onlyRole(DEFAULT_ADMIN_ROLE) {

        global.licenseTypes[licenseTypeId].name = name;
        global.licenseTypes[licenseTypeId].info = info;
        global.licenseTypes[licenseTypeId].isActive = active;
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
        
        (, uint usdCredit,) = ICollectorCredit(global.collectorCreditContract).getAvailableCredit(msg.sender);
        
       (uint64 available, uint64 priceUsd) = getAssetAvailability(assetId, licenseId);
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

    function getAssetAvailability(uint assetId, uint licenseId) public view returns(uint64, uint64) {
        ICreatorData.LicenseInfo memory licenseInfo = IAssetRegistry(global.assetRegistryContract).getAssetLicense(assetId, licenseId);
        LicenseTypeInfo memory licenseTypeInfo = global.licenseTypes[licenseInfo.licenseTypeId];
        return getLicenseAvailability(licenseInfo, licenseTypeInfo);
    } 

    function getLicenseAvailability(ICreatorData.LicenseInfo memory licenseInfo, LicenseTypeInfo memory licenseTypeInfo) internal pure returns(uint64, uint64) {

        require(licenseInfo.licenseTypeId > 0, "License not found");
        require(licenseInfo.available > 0, "No editions available");
        require(licenseTypeInfo.isActive, "License Type not active");

        uint64 priceUsd = licenseInfo.editionPriceUsd;

        return(licenseInfo.available, priceUsd);
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