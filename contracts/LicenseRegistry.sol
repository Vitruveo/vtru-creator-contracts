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
    event LicenseIssued(string indexed assetKey, uint indexed licenseId, uint indexed licenseInstanceId, address licensee);


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

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        registerLicenseType("NFT-ART-1", "NFT", true, true);
        registerLicenseType("STREAM-ART-1", "Stream", false, false);
        registerLicenseType("REMIX-ART-1", "Remix", false, false);
        registerLicenseType("PRINT-ART-1", "Print", false, false);

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

    function issueLicenseUsingCredits(string calldata assetKey, uint256 licenseId, uint64 quantity) public {
        
        // 1) Get buyer credits
        (, uint usdCredit,) = ICollectorCredit(global.collectorCreditContract).getAvailableCredit(msg.sender);

        // 2) Check if asset license is available and get price
        (uint64 available, uint64 priceUsd) = getAssetAvailability(assetKey, licenseId);
        uint64 totalUsd = priceUsd * quantity;

        // 3) Check if buyer has enough credits
        require(usdCredit >= totalUsd, "Insufficient credit");

        // 4) Update the license available amount
        IAssetRegistry(global.assetRegistryContract).consumeLicense(licenseId, quantity);

        // 5) Generate a license instance
        _licenseInstanceId.increment();
        global.licenseInstancesByOwner[msg.sender].push(_licenseInstanceId.current());

        // License instance properties

        // 6) Mint assets
       
       // if Mintable then mint NFTs


        // 7) Credit Creator vault


        // 8) Emit event regarding license instance
        emit LicenseIssued(assetKey, licenseId, _licenseInstanceId.current(), msg.sender);    
    }

    function getAvailableCredit(address account) public view returns(uint tokens, uint usdCredit, uint otherCredit) {
        return ICollectorCredit(global.collectorCreditContract).getAvailableCredit(account);
    }

    function getAsset(string calldata assetKey) public view returns(ICreatorData.AssetInfo memory) {
        require(IAssetRegistry(global.assetRegistryContract).isAsset(assetKey), "Asset not found");
        return IAssetRegistry(global.assetRegistryContract).getAsset(assetKey);
    }

    function getAssetAvailability(string calldata assetKey, uint licenseId) public view returns(uint64, uint64) {
        require(IAssetRegistry(global.assetRegistryContract).isAsset(assetKey), "Asset not found");
        ICreatorData.LicenseInfo memory licenseInfo = IAssetRegistry(global.assetRegistryContract).getAssetLicense(assetKey, licenseId);
        require(licenseInfo.licenseTypeId > 0, "Asset or License not found");
        LicenseTypeInfo memory licenseTypeInfo = global.licenseTypes[licenseInfo.licenseTypeId];
        return getLicenseAvailability(licenseInfo, licenseTypeInfo);
    } 

    function getLicenseAvailability(ICreatorData.LicenseInfo memory licenseInfo, LicenseTypeInfo memory licenseTypeInfo) internal pure returns(uint64, uint64) {

        require(licenseInfo.licenseTypeId > 0, "License Type not found");
        require(licenseTypeInfo.isMintable, "Only mintable licenses currently supported");
        require(licenseTypeInfo.isActive, "License Type not active");
        require(licenseInfo.available > 0, "No editions available");

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

    // Studio account is required for Creator Vault
    function setStudioAccount(address account) public  onlyRole(DEFAULT_ADMIN_ROLE) {
        require(account != address(0), "Invalid Studio account address");
        global.studioAccount = account;
    }

    function getStudioAccount() public view returns(address) {
        return(global.studioAccount);
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