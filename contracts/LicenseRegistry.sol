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
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/Base64Upgradeable.sol";
import "./Interfaces.sol";

contract LicenseRegistry is
    Initializable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    ICreatorData
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter public _licenseInstanceId;
    CountersUpgradeable.Counter public _licenseTypeId;

    event UsdVtruExchangeRateChanged(uint256 centsPerVtru);
    event LicenseIssued(string indexed assetKey, address licensee, uint indexed licenseId, uint indexed licenseInstanceId, uint256[] tokenIds);

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

        uint allowBlockNumber;
        mapping(address => bool) allowList;
    }

    GlobalInfo public global;

    struct OwnedTokenInfo {
        address vault;
        uint tokenId;
    }

    mapping(address => OwnedTokenInfo[]) mintRegistry;

    function initialize() public initializer {

        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);

        registerLicenseType("NFT-ART-1", "NFT", true, true);
        registerLicenseType("STREAM-ART-1", "Stream", false, false);
        registerLicenseType("REMIX-ART-1", "Remix", false, false);
        registerLicenseType("PRINT-ART-1", "Print", false, false);

        setAllowBlockNumber(block.number);
    }

    function version() public pure returns(string memory) {
        return "0.5.0";
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

    function issueLicenseUsingCredits(string calldata assetKey, uint256 licenseTypeId, uint64 quantity) public whenNotPaused nonReentrant isAllowed {
        _issueLicenseUsingCredits(msg.sender, assetKey, licenseTypeId, quantity);
    }
    function issueLicenseUsingCreditsStudio(address licensee, string calldata assetKey, uint256 licenseTypeId, uint64 quantity) public whenNotPaused nonReentrant isAllowed {
        require(msg.sender == global.studioAccount, UNAUTHORIZED_USER);
        _issueLicenseUsingCredits(licensee, assetKey, licenseTypeId, quantity);
    }

    function _issueLicenseUsingCredits(address licensee, string calldata assetKey, uint256 licenseTypeId, uint64 quantity) internal {
        require(IAssetRegistry(global.assetRegistryContract).isAsset(assetKey), "Asset not found");
        ICreatorData.AssetInfo memory asset = IAssetRegistry(global.assetRegistryContract).getAsset(assetKey);

        // 1) Check if asset license is available and get price
        ICreatorData.LicenseInfo memory licenseInfo = getAvailableLicense(assetKey, licenseTypeId, quantity);
        uint64 totalCents = licenseInfo.editionCents * quantity;

        // 2) Redeem credits and send VTRU to vault
        uint amountPaidCents = ICollectorCredit(global.collectorCreditContract).redeemUsd(licensee, _licenseInstanceId.current(), totalCents, global.usdVtruExchangeRate, asset.creator.vault);

        // 3) Update the license available amount
        IAssetRegistry(global.assetRegistryContract).acquireLicense(licenseInfo.id, quantity, licensee);

        // 4) Generate a license instance
        _licenseInstanceId.increment();
        global.licenseInstancesByOwner[msg.sender].push(_licenseInstanceId.current());
        ICreatorData.LicenseInstanceInfo storage licenseInstanceInfo = global.licenseInstances[_licenseInstanceId.current()];
        licenseInstanceInfo.id = _licenseInstanceId.current();
        licenseInstanceInfo.assetKey = assetKey;
        licenseInstanceInfo.licenseId = licenseInfo.id;
        licenseInstanceInfo.licenseFeeCents = totalCents;
        licenseInstanceInfo.amountPaidCents = amountPaidCents;
        licenseInstanceInfo.licenseQuantity = quantity;
        licenseInstanceInfo.licensees.push(licensee);
        // licenseInstanceInfo.platformBasisPoints;
        // licenseInstanceInfo.curatorBasisPoints;
        // licenseInstanceInfo.sellerBasisPoints;
        // licenseInstanceInfo.creatorRoyaltyBasisPoints;


        // 5) Mint assets
        if (global.licenseTypes[licenseTypeId].isMintable) {
            licenseInstanceInfo.tokenIds = ICreatorVault(asset.creator.vault).mintLicensedAssets(licenseInstanceInfo, licensee);
            require(licenseInstanceInfo.tokenIds.length > 0, "Asset minting failed");
            registerTokens(asset.creator.vault, licenseInstanceInfo.tokenIds, licensee);
        }
       
        // TODO: Credit fee splitter contract

        // 6) Emit event regarding license instance
        emit LicenseIssued(assetKey, licensee, licenseInfo.id,  licenseInstanceInfo.id, licenseInstanceInfo.tokenIds);    
    }

    function registerTokens(address vault, uint256[] memory tokenIds, address owner) internal {
        for(uint t=0; t<tokenIds.length; t++) {
            mintRegistry[owner].push(OwnedTokenInfo(vault, tokenIds[t]));
        }
    }

    function transferTokens(address vault, uint256[] memory tokenIds, address from, address to) public {
        require(msg.sender == vault, UNAUTHORIZED_USER);
        for(uint f=0; f<mintRegistry[from].length; f++) {
            if (mintRegistry[from][f].vault == vault) {
                for(uint t=0; t<tokenIds.length; t++) {
                    if (mintRegistry[from][f].tokenId == tokenIds[t]) {
                        mintRegistry[from][f] = OwnedTokenInfo(address(0), 0); // Zero out. Batch process and free up in future
                    }
                }
            }
        }
        registerTokens(vault, tokenIds, to);
    }   

    function getTokens(address owner) public view returns(OwnedTokenInfo[] memory) {
        return mintRegistry[owner];
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

    function addToAllowList(address allow) public  onlyRole(DEFAULT_ADMIN_ROLE) {
        global.allowList[allow] = true;
    }

    function removeFromAllowList(address allow) public  onlyRole(DEFAULT_ADMIN_ROLE) {
        delete global.allowList[allow];
    }

    function setAllowBlockNumber(uint blockNumber) public  onlyRole(DEFAULT_ADMIN_ROLE) {
        global.allowBlockNumber = blockNumber;
    }

    function getAllowBlockNumber() public view returns(uint) {
        return(global.allowBlockNumber);
    }

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    modifier isAllowed() {
        require(block.number >= global.allowBlockNumber || global.allowList[msg.sender] == true, "Licensing not permitted");
        _;
    }

    function recoverVTRU() external onlyRole(DEFAULT_ADMIN_ROLE) {
        (bool recovered, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(recovered, "Recovery failed"); 
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