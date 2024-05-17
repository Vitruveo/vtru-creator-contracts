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
    function getAsset(string calldata assetKey) external view returns(ICreatorData.AssetInfo memory);
}

interface ICreatorVault {
    function getCreatorCredits() external view returns(uint);
    function useCreatorCredits(uint) external;
    function isVaultWallet(address) external returns(bool);
    function licensedMint(ICreatorData.LicenseInstanceInfo memory licenseInstance, address licensee) external returns(uint);
}

interface ICreatorVaultFactory {
    function getLicenseRegistryContract() external view returns(address);
}

interface ICollectorCredit {
    function getAvailableCredits(address account) external view returns(uint tokens, uint creditCents, uint creditOther);
    function redeemUsd(address account, uint256 licenseInstanceId, uint64 amountCents) external returns(uint64 redeemedCents);
}

abstract contract ICreatorData {
    
    string public constant UNAUTHORIZED_USER = "Unauthorized user";
    uint public constant DECIMALS = 10 ** 18;
    bytes32 public constant STUDIO_ROLE = bytes32(uint(0x01));
    bytes32 public constant KEEPER_ROLE = bytes32(uint(0x02));
    bytes32 public constant UPGRADER_ROLE = bytes32(uint(0x03));
    bytes32 public constant LICENSOR_ROLE = bytes32(uint(0x04));

    struct AssetInfo {
        string key;
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
    struct HeaderInfo {
        string title;
        string description;
        uint256 metadataRefId;
        string metadataXRefId;
        string tokenUri;
        Status status;
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
        uint64 editionCents;
        uint64 discountEditions;
        uint64 discountBasisPoints;
        uint64 discountMaxBasisPoints;
        uint64 available;
        address[] licensees;
    }

    struct LicenseInstanceInfo {
        uint256 id;
        string assetKey;
        uint licenseId;
        uint tokenId;
        uint licenseFeeCents;
        uint amountPaidCents;
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
    function isAsset(string calldata assetKey) external view returns(bool);
    function getAsset(string calldata assetKey) external view returns(ICreatorData.AssetInfo memory);
    function getAssetLicense(uint licenseId) external view returns(ICreatorData.LicenseInfo memory);
    function getAssetLicenses(string calldata assetKey) external view returns(ICreatorData.LicenseInfo[] memory); 
    function acquireLicense(uint licenseId, uint64 quantity, address licensee) external;
    function changeAssetStatus(string calldata assetKey, ICreatorData.Status status) external;
}
