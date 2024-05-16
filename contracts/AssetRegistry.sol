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
import "./UnorderedBytesKeySet.sol";
import "./Interfaces.sol";

contract AssetRegistry is
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    ICreatorData
{

    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter public _licenseId;

    using UnorderedBytesKeySetLib for UnorderedBytesKeySetLib.Set;
    UnorderedBytesKeySetLib.Set private assetList;

    struct GlobalInfo {
        uint assetsConsigned;
        uint premiumFee;
        uint creatorCreditsRequired;
        mapping(bytes32 => AssetInfo) assets;
        mapping(uint => LicenseInfo) licenses;
    }

    GlobalInfo public global;

    event AssetConsigned(string indexed assetKey, address indexed creatorVault, uint[] licenses);
    event CollaboratorAdded(string indexed assetKey, address indexed collaboratorVault);
    event LicenseAdded(string indexed assetKey, uint licenseId, uint licenseTypeId);
    event AssetChanged(string indexed assetKey, Status indexed status, address indexed editor);
    event LicenseAcquired(address indexed licensee, uint indexed licenseId, uint64 quantity);

    function initialize() public initializer {

        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);

        global.premiumFee = 10 * DECIMALS;
        global.creatorCreditsRequired = 1;
    }

    function consign(
                            string calldata assetKey,
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

        require(isContract(creator.vault), "Vault does not exist");
        ICreatorVault(creator.vault).useCreatorCredits(global.creatorCreditsRequired);

        bytes32 key = hash(assetKey);
        AssetInfo storage asset = global.assets[key];
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

        addAssetCollaborator(assetKey, collaborator1);
        addAssetCollaborator(assetKey, collaborator2);
        addAssetCollaborator(assetKey, collaborator3);

        addAssetLicense(assetKey, license1);
        addAssetLicense(assetKey, license2);
        addAssetLicense(assetKey, license3);
        addAssetLicense(assetKey, license4);

        assetList.insert(key);
        global.assetsConsigned++;

        emit AssetConsigned(assetKey, asset.creator.vault, global.assets[key].licenses);
    }

    function addAssetCollaborator(string calldata assetKey, CreatorInfo calldata collaborator) public onlyEditor(assetKey) whenNotPaused {
        // Don't use require because consign() does allow empty collaborator params
        if (collaborator.vault != address(0)) {
            require(isContract(collaborator.vault), "Collaborator Vault does not exist");
            global.assets[hash(assetKey)].collaborators.push(collaborator);
            emit CollaboratorAdded(assetKey, collaborator.vault);
        }
    }

    function addAssetLicense(string calldata assetKey, LicenseInfo memory license) public onlyEditor(assetKey) whenNotPaused {
        // Don't use require because consign() does allow empty licenseTypeId params
        if (license.licenseTypeId > 0) {
            _licenseId.increment();
            license.id = _licenseId.current();
            global.licenses[_licenseId.current()] = license;
            global.assets[hash(assetKey)].licenses.push(_licenseId.current());

            emit LicenseAdded(assetKey, _licenseId.current(), license.licenseTypeId);
        }
    }

    function getAssetLicense(uint licenseId) public view returns(LicenseInfo memory) {
        return (global.licenses[licenseId]);
    }

    function getAssetLicenses(string calldata assetKey) public view onlyActiveAsset(assetKey) returns(LicenseInfo[] memory licenses) {
        bytes32 key = hash(assetKey);
        licenses = new LicenseInfo[](global.assets[key].licenses.length);
        for(uint a=0; a<global.assets[key].licenses.length; a++) {
            licenses[a] = global.licenses[a];
        }
    }

    function acquireLicense(uint licenseId, uint64 quantity, address licensee) public onlyRole(LICENSOR_ROLE) whenNotPaused {
        require(global.licenses[licenseId].available >= quantity, "Insufficient license availability");
        global.licenses[licenseId].available -= quantity;
        global.licenses[licenseId].licensees.push(licensee);  
        emit LicenseAcquired(licensee, licenseId, quantity);      
    }

    function changeAsset(string calldata assetKey, Status status, address editor) public whenNotPaused {
        bytes32 key = hash(assetKey);
        if (status == Status.BLOCKED || global.assets[key].status == Status.BLOCKED) { // Only Studio can set or change from Blocked
            require(hasRole(STUDIO_ROLE, msg.sender), UNAUTHORIZED_USER);
        } else {
            require(msg.sender == global.assets[key].editor, UNAUTHORIZED_USER);
        }
        require(editor != global.assets[key].editor && editor != address(0), "Invalid editor address");

        global.assets[key].status = status;
        global.assets[key].editor = editor;

        emit AssetChanged(assetKey, status, editor);
    }

    function upgradeAsset(string calldata assetKey) public payable  onlyActiveAsset(assetKey) whenNotPaused {
        bytes32 key = hash(assetKey);
        require(!global.assets[key].isPremium, "Asset is already premium");
        require(msg.value == global.premiumFee, "Insufficient funds");

        global.assets[key].isPremium = true;
    }

    function changeAssetPremiumFee(uint fee) public onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        global.premiumFee = fee;
    }

    function changeCreatorCreditsRequired(uint credits) public onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        global.creatorCreditsRequired = credits;
    }

    function changeAssetTokenUri(string calldata assetKey, string memory uri) public onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        global.assets[hash(assetKey)].header.tokenUri = uri;
    }

    function hash(string calldata input) public pure returns(bytes32) {
        return(keccak256(bytes(input)));
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

    function isAsset(string calldata assetKey) public view returns(bool) {
        return assetList.exists(hash(assetKey));
    }

    function getAsset(string calldata assetKey) public view returns(AssetInfo memory) {
        bytes32 key = hash(assetKey);
        return getAssetByKey(key);
    }

    function getAssetByKey(bytes32 key) public view returns(AssetInfo memory) {
        require(assetList.exists(key), "Can't get an Asset that doesn't exist.");
        return(global.assets[key]);
    }

    function getAssetAtIndex(uint index) public view returns(AssetInfo memory) {
        bytes32 key = assetList.keyAtIndex(index);
        return global.assets[key];
    }

    modifier onlyEditor(string calldata assetKey) {
        require(msg.sender == global.assets[hash(assetKey)].editor, UNAUTHORIZED_USER);
        _;
    }

    modifier onlyActiveAsset(string calldata assetKey) {
        AssetInfo memory assetInfo = global.assets[hash(assetKey)];
        require(assetInfo.status == Status.ACTIVE, "Asset not active");
        _;
    }
}