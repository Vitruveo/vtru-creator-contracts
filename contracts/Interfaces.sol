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
}

interface ICreatorVault {
    function getCreatorCredits() external view returns(uint);
    function useCreatorCredits(uint) external;
    function isVaultWallet(address) external returns(bool);
    function mint(uint assetId) external returns(uint);
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

    struct AssetInfo {
        uint256 id;
        HeaderInfo header;
        CreatorInfo creator; 
        CreatorInfo[] collaborators; 
        uint[] licenses;
        string[] media;
        string assetCid;
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

    struct LicenseTypeInfo {
        uint256 id;
        string name;
        string info;
        bool isMintable;
        bool isElastic;
        bool isActive;
        address issuer;
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
        uint256 refId;
        string xRefId;
        string title;
        string description;
        uint256 metadataRefId;
        string metadataXRefId;
        string assetCid;
        string previewCid;
    }

    struct LicenseInstance {
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
    function getAssetAvailability(uint assetId, uint licenseId) external view returns(uint64);
}
