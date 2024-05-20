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
    event LicenseIssued(string indexed assetKey, uint indexed licenseId, uint indexed licenseInstanceId, address licensee, uint256 tokenId);


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
        mapping(uint => LicenseInstanceInfo) licenseInstances;
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

    function registerLicenseType(string memory name, string memory info, bool isMintable, bool isElastic) public onlyRole(DEFAULT_ADMIN_ROLE)  whenNotPaused {

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

    function changeLicenseType(uint licenseTypeId, string memory name, string memory info, bool active) public onlyRole(DEFAULT_ADMIN_ROLE)  whenNotPaused{

        global.licenseTypes[licenseTypeId].name = name;
        global.licenseTypes[licenseTypeId].info = info;
        global.licenseTypes[licenseTypeId].isActive = active;
    }

    function issueLicenseUsingCreditsDebug(string calldata assetKey, uint256 licenseTypeId, uint64 quantity) public view whenNotPaused returns(uint, uint, bool) {
        require(IAssetRegistry(global.assetRegistryContract).isAsset(assetKey), "Asset not found");
        ICreatorData.AssetInfo memory asset = IAssetRegistry(global.assetRegistryContract).getAsset(assetKey);

        address licensee = msg.sender;

        // 1) Get buyer credits
        (, uint creditCents,) = ICollectorCredit(global.collectorCreditContract).getAvailableCredits(msg.sender);

        // 2) Check if asset license is available and get price
        ICreatorData.LicenseInfo memory licenseInfo = getAvailableLicense(assetKey, licenseTypeId, quantity);
        uint64 totalCents = licenseInfo.editionCents * quantity;

        return(creditCents, uint(totalCents), creditCents >= uint(totalCents));
    }


    function issueLicenseUsingCredits(string calldata assetKey, uint256 licenseTypeId, uint64 quantity) public  whenNotPaused {
        require(IAssetRegistry(global.assetRegistryContract).isAsset(assetKey), "Asset not found");
        ICreatorData.AssetInfo memory asset = IAssetRegistry(global.assetRegistryContract).getAsset(assetKey);

        address licensee = msg.sender;

        // 1) Get buyer credits
        (, uint creditCents,) = ICollectorCredit(global.collectorCreditContract).getAvailableCredits(msg.sender);

        // 2) Check if asset license is available and get price
        ICreatorData.LicenseInfo memory licenseInfo = getAvailableLicense(assetKey, licenseTypeId, quantity);
        uint64 totalCents = licenseInfo.editionCents * quantity;

        // 3) Check if buyer has enough credits
        require(creditCents >= uint(totalCents), "Insufficient credit");

        // 4) Update the license available amount
        IAssetRegistry(global.assetRegistryContract).acquireLicense(licenseInfo.id, quantity, licensee);

        // 5) Generate a license instance
        _licenseInstanceId.increment();
        global.licenseInstancesByOwner[msg.sender].push(_licenseInstanceId.current());
        ICreatorData.LicenseInstanceInfo storage licenseInstanceInfo = global.licenseInstances[_licenseInstanceId.current()];
        licenseInstanceInfo.id = _licenseInstanceId.current();
        licenseInstanceInfo.assetKey = assetKey;
        licenseInstanceInfo.licenseId = licenseInfo.id;
        licenseInstanceInfo.licenseFeeCents = totalCents;
        licenseInstanceInfo.licensee = licensee;
        // licenseInstanceInfo.licenseQuantity;
        // licenseInstanceInfo.platformBasisPoints;
        // licenseInstanceInfo.curatorBasisPoints;
        // licenseInstanceInfo.sellerBasisPoints;
        // licenseInstanceInfo.creatorRoyaltyBasisPoints;

        // 6) Redeem credits
        licenseInstanceInfo.amountPaidCents = ICollectorCredit(global.collectorCreditContract).redeemUsd(licensee, _licenseInstanceId.current(), totalCents);

        // 7) Credit Creator vault
        uint256 vtruToTransfer = (licenseInstanceInfo.amountPaidCents * DECIMALS) / global.usdVtruExchangeRate;
        require(address(this).balance >= vtruToTransfer, "Insufficient escrow balance");
        (bool credited, ) = payable(asset.creator.vault).call{value: vtruToTransfer}("");
        require(credited, "Asset payment failed");

        // License instance properties

        // 8) Mint assets
        if (global.licenseTypes[licenseTypeId].isMintable) {
            licenseInstanceInfo.tokenId = ICreatorVault(asset.creator.vault).licensedMint(licenseInstanceInfo, licensee);
            require(licenseInstanceInfo.tokenId > 0, "Asset mint failed");
        }
       
        // 9) Credit fee splitter contract

        // 10) Emit event regarding license instance
        emit LicenseIssued(assetKey, licenseInfo.id, _licenseInstanceId.current(), licensee, licenseInstanceInfo.tokenId);    
    }

    function changeAssetStatus(string calldata assetKey, Status status) public whenNotPaused {
        return IAssetRegistry(global.assetRegistryContract).changeAssetStatus(assetKey, status);
    }

    function getAsset(string calldata assetKey) public view returns(ICreatorData.AssetInfo memory) {
        return IAssetRegistry(global.assetRegistryContract).getAsset(assetKey);
    }

    function getAssetLicense(uint licenseId) public view returns(ICreatorData.LicenseInfo memory) {
        return IAssetRegistry(global.assetRegistryContract).getAssetLicense(licenseId);
    }

    function getAssetLicenses(string calldata assetKey) public view returns(ICreatorData.LicenseInfo[] memory) {
        return IAssetRegistry(global.assetRegistryContract).getAssetLicenses(assetKey);
    }

    function getLicenseInstance(uint licenseInstanceId) public view returns(ICreatorData.LicenseInstanceInfo memory) {
        return global.licenseInstances[licenseInstanceId];
    }

    function getLicenseInstancesByOwner(address account) public view returns(ICreatorData.LicenseInstanceInfo[] memory) {

        uint[] memory ownedLicenseInstances = global.licenseInstancesByOwner[account];
        LicenseInstanceInfo[] memory licenseInstances = new LicenseInstanceInfo[](ownedLicenseInstances.length);
        for(uint i=0;i<ownedLicenseInstances.length;i++) {
            licenseInstances[i] = getLicenseInstance(ownedLicenseInstances[i]);
        }
        return licenseInstances;
    }

    function getAvailableCredits(address account) public view returns(uint tokens, uint creditCents, uint creditOther) {
        return ICollectorCredit(global.collectorCreditContract).getAvailableCredits(account);
    }

    function getAvailableLicense(string calldata assetKey, uint licenseTypeId, uint64 quantity) public view returns(LicenseInfo memory) {
        require(licenseTypeId > 0, "License Type not found");
        require(global.licenseTypes[licenseTypeId].isActive, "License Type not active");
        require(global.licenseTypes[licenseTypeId].isMintable, "Only mintable licenses currently supported");

        LicenseInfo memory license;
        ICreatorData.LicenseInfo[] memory licenses = IAssetRegistry(global.assetRegistryContract).getAssetLicenses(assetKey);
        for(uint i=0;i<licenses.length;i++) {
            if (licenses[i].licenseTypeId == licenseTypeId) {
                require(licenses[i].available >= quantity, "Insufficient editions available");
                license = licenses[i];
                break;
            }
        }
        return license;
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