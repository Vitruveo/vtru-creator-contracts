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
import "./UnorderedKeySet.sol";
import "./Interfaces.sol";

contract AssetRegistry is
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    ICreatorData
{

    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter public _assetId;
    CountersUpgradeable.Counter public _licenseTypeId;
    CountersUpgradeable.Counter public _licenseId;

    using UnorderedKeySetLib for UnorderedKeySetLib.Set;
    UnorderedKeySetLib.Set private assetList;

    struct GlobalInfo {
        uint256 assetsConsigned;
        uint256 premiumFee;
        uint256 creatorCreditsRequired;
        string assetBaseUri;
        mapping(uint256 => LicenseTypeInfo) licenseTypes;
        mapping(uint256 => AssetInfo) assets;
        mapping(uint256 => LicenseInfo) licenses;
    }

    GlobalInfo public global;

    event AssetConsigned(uint256 indexed assetId, address indexed creatorVault, uint[] licenses);
    event CollaboratorAdded(uint256 indexed assetId, address indexed collaboratorVault);
    event LicenseAdded(uint256 indexed assetId, uint256 licenseId, uint256 licenseTypeId);
   // event EditorChanged(uint256 indexed assetId, address indexed editor);
    event AssetStatusChanged(uint256 indexed assetId, Status indexed status);
    //event LicenseAvailabilityChanged(uint256 indexed assetId, uint256 licenseId, uint64 available);

    function initialize() public initializer {

        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
        _grantRole(STUDIO_ROLE, 0x88Eb3738dc7B13773F570458cbC932521431FeA7);

        registerLicenseType("NFT-ART-1", "NFT", true, true);
        registerLicenseType("STREAM-ART-1", "Stream", false, false);
        registerLicenseType("REMIX-ART-1", "Remix", false, false);
        registerLicenseType("PRINT-ART-1", "Print", false, false);

        global.premiumFee = 10 * DECIMALS;
        global.creatorCreditsRequired = 1;
    }

    function consign(
                            HeaderInfo calldata header, 
                            CreatorInfo calldata creator,
                            CreatorInfo calldata collaborator1,
                            CreatorInfo calldata collaborator2,
                            CreatorInfo calldata collaborator3,
                            LicenseInfo calldata license1,
                            LicenseInfo calldata license2,
                            LicenseInfo calldata license3,
                            LicenseInfo calldata license4,
                            string[] memory media
                        ) public payable whenNotPaused {

        require(isContract(creator.vault), "Creator Vault does not exist");
        ICreatorVault(creator.vault).useCreatorCredits(global.creatorCreditsRequired);

        _assetId.increment();
        AssetInfo storage asset = global.assets[_assetId.current()];
        asset.header = header;
        asset.media = media;
        asset.creator = creator;
        asset.editor = msg.sender;

        asset.originator = Source.OTHER;
        if (hasRole(STUDIO_ROLE, msg.sender)) {
            asset.originator = Source.STUDIO;
        } else if (ICreatorVault(creator.vault).isVaultWallet(msg.sender)) {
            asset.originator = Source.SELF;
        }
        require(asset.originator == Source.STUDIO || asset.originator == Source.SELF, UNAUTHORIZED_USER);


        if (msg.value == global.premiumFee) {
            asset.isPremium = true;   
        }

        addAssetCollaborator(_assetId.current(), collaborator1);
        addAssetCollaborator(_assetId.current(), collaborator2);
        addAssetCollaborator(_assetId.current(), collaborator3);

        addAssetLicense(_assetId.current(), license1);
        addAssetLicense(_assetId.current(), license2);
        addAssetLicense(_assetId.current(), license3);
        addAssetLicense(_assetId.current(), license4);

        assetList.insert(_assetId.current());
        global.assetsConsigned++;

        emit AssetConsigned(_assetId.current(), asset.creator.vault, global.assets[_assetId.current()].licenses);
    }

    function addAssetCollaborator(uint256 assetId, CreatorInfo calldata collaborator) public onlyEditor(assetId) whenNotPaused {
        // Don't use require because consign() does allow empty collaborator params
        if (collaborator.vault != address(0)) {
            require(isContract(collaborator.vault), "Collaborator Vault does not exist");
            global.assets[assetId].collaborators.push(collaborator);
            emit CollaboratorAdded(assetId, collaborator.vault);
        }
    }

    function addAssetLicense(uint256 assetId, LicenseInfo memory license) public onlyEditor(assetId) whenNotPaused {
        // Don't use require because consign() does allow empty licenseTypeId params
        if (license.licenseTypeId > 0 && global.licenseTypes[license.licenseTypeId].isActive) {
            _licenseId.increment();
            license.id = _licenseId.current();
            global.licenses[_licenseId.current()] = license;
            global.assets[assetId].licenses.push(_licenseId.current());

            emit LicenseAdded(assetId, _licenseId.current(), license.licenseTypeId);
        }
    }

    function getAssetLicenses(uint256 assetId) public view  onlyActiveAsset(assetId) returns(LicenseInfo[] memory) {
        LicenseInfo[] memory licenses = new LicenseInfo[](global.assets[assetId].licenses.length);
        for(uint a=0; a<global.assets[assetId].licenses.length; a++) {
            licenses[a] = global.licenses[a];
        }
        return licenses;
    }

    function getAssetAvailability(uint assetId, uint licenseId) public view onlyActiveAsset(assetId) returns(uint64, uint64) {

        LicenseInfo memory licenseInfo = global.licenses[licenseId];
        require(licenseInfo.licenseTypeId > 0, "License not found");
        require(licenseInfo.available > 0, "No editions available");

        LicenseTypeInfo memory licenseTypeInfo = global.licenseTypes[licenseInfo.licenseTypeId];
        require(licenseTypeInfo.isActive, "License Type not active");

        uint64 priceUsd = licenseInfo.editionPriceUsd;

        return(licenseInfo.available, priceUsd);
    }

    function changeAssetStatus(uint256 assetId, Status status) public whenNotPaused {
        if (status == Status.BLOCKED || global.assets[assetId].status == Status.BLOCKED) { // Only Studio can set or change from Blocked
            require(hasRole(STUDIO_ROLE, msg.sender), UNAUTHORIZED_USER);
        } else {
            require(msg.sender == global.assets[assetId].editor, UNAUTHORIZED_USER);
        }
        global.assets[assetId].status = status;
        emit AssetStatusChanged(assetId, status);
    }

    // function changeAssetEditor(uint256 assetId, address editor) public  onlyActiveAsset(assetId) onlyEditor(assetId) whenNotPaused {
    //     require(editor != global.assets[assetId].editor && editor != address(0), "Invalid editor address");

    //     global.assets[assetId].editor = editor;
    //     emit EditorChanged(assetId, editor);
    // }

    function upgradeAsset(uint256 assetId) public payable  onlyActiveAsset(assetId) whenNotPaused {
        require(!global.assets[assetId].isPremium, "Asset is already premium");
        require(msg.value == global.premiumFee, "Insufficient funds");

        global.assets[assetId].isPremium = true;
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

    function changeLicenseType(uint256 licenseTypeId, string memory name, string memory info, bool active) public onlyRole(DEFAULT_ADMIN_ROLE) {

        global.licenseTypes[licenseTypeId].name = name;
        global.licenseTypes[licenseTypeId].info = info;
        global.licenseTypes[licenseTypeId].isActive = active;
    }

    function changeAssetPremiumFee(uint256 fee) public onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        global.premiumFee = fee;
    }

    function changeCreatorCreditsRequired(uint256 credits) public onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        global.creatorCreditsRequired = credits;
    }

    function changeAssetBaseUri(string memory uri) public onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        global.assetBaseUri = uri;
    }

    function isContract(address account) public view returns (bool) { 
        uint size; 
        assembly { 
            size := extcodesize(account) 
        } 
        return size > 0; 
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

    function getAssetBatch(uint256 start, uint256 count) public view returns(AssetInfo[] memory) {
        AssetInfo[] memory result = new AssetInfo[](count);

        for(uint i=start; i<start+count; i++) {
           result[i - start] = getAssetAtIndex(i);
        }
        return(result);
    }

    function getAssetCount() public view returns(uint count) {
        return assetList.count();
    }

    function isAsset(uint key) public view returns(bool) {
        return assetList.exists(key);
    }

    function getAsset(uint key) public view returns(AssetInfo memory) {
        require(assetList.exists(key), "Can't get a holder that doesn't exist.");
        return(global.assets[key]);
    }

    function getAssetAtIndex(uint index) public view returns(AssetInfo memory) {
        uint key = assetList.keyAtIndex(index);
        return global.assets[key];
    }

    modifier onlyEditor(uint assetId) {
        require(msg.sender == global.assets[assetId].editor, UNAUTHORIZED_USER);
        _;
    }

    modifier onlyActiveAsset(uint assetId) {
        AssetInfo memory assetInfo = global.assets[assetId];
        require(assetInfo.status == Status.ACTIVE, "Asset not active");
        _;
    }
}