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

interface ILicenseRegistry {
    function getCreatorVaultFactoryContract() external view returns(address); 
    function getAssetRegistryContract() external view returns(address); 
    function getCollectorCreditContract() external view returns(address); 
    function getUsdVtruExchangeRate() external view returns(uint);
    function getStudioAccount() external view returns(address);
    function getAssetByKey(bytes32 key) external view returns(ICreatorData.AssetInfo memory);
}

interface ICreatorVault {
    function getCreatorCredits() external view returns(uint);
    function useCreatorCredits(uint) external;
    function isVaultWallet(address) external returns(bool);
    function mint(string calldata assetKey) external returns(uint);
}

interface ICreatorVaultFactory {
    function getLicenseRegistryContract() external view returns(address);
}

interface ICollectorCredit {
    function getAvailableCredit(address account) external view returns(uint tokens, uint usdCredit, uint otherCredit);
    function redeem(address account, uint256 licenseInstanceId, uint64 amount) external;
}

abstract contract ICreatorData {
    
    string public constant UNAUTHORIZED_USER = "Unauthorized user";
    uint public constant DECIMALS = 10 ** 18;
    bytes32 public constant STUDIO_ROLE = bytes32(uint(0x01));
    bytes32 public constant KEEPER_ROLE = bytes32(uint(0x02));
    bytes32 public constant UPGRADER_ROLE = bytes32(uint(0x03));
    bytes32 public constant LICENSOR_ROLE = bytes32(uint(0x04));

    struct AssetInfo {
        bytes32 key;
        HeaderInfo header;
        CreatorInfo creator; 
        CreatorInfo[] collaborators; 
        uint[] licenses;
        string[] media;
        Status status;
        Source originator;
        address editor;
        bool isPremium;
    }

    struct CreatorInfo {
        uint256 refId;
        string xRefId;
        address vault;
        uint256 split;
    }

    struct LicenseInfo {
        uint256 id;
        uint256 licenseTypeId;
        uint64 editions; 
        uint64 editionPriceUsd;
        uint64 discountEditions;
        uint64 discountBasisPoints;
        uint64 discountMaxBasisPoints;
        uint64 available;
        address[] licensees;
    }

    struct HeaderInfo {
        string title;
        string description;
        uint256 metadataRefId;
        string metadataXRefId;
        string tokenUri;
    }

    struct LicenseInstance {
        bytes32 assetKey;
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

    enum Status {
        DRAFT,
        PREVIEW,
        ACTIVE,
        HIDDEN,
        BLOCKED
    }

    enum Source {
        STUDIO,
        SELF,
        OTHER
    }
}

interface IAssetRegistry {
    function getAsset(string calldata assetKey) external view returns(ICreatorData.AssetInfo memory);
    function getAssetLicense(string calldata assetKey, uint licenseId) external view returns(ICreatorData.LicenseInfo memory);
    function consumeLicense(uint licenseId, uint64 quantity) external;
}
