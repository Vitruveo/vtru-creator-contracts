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
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/Base64Upgradeable.sol";

contract CollectorCredit is
    Initializable,
    ERC721Upgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    
    /****************************************************************************/
    /*                                  COUNTERS                                */
    /****************************************************************************/
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _creditClassId;
    CountersUpgradeable.Counter private _tokenId;

    uint public constant DECIMALS = 10 ** 18;

    /****************************************************************************/
    /*                                  ROLES                                   */
    /****************************************************************************/
    bytes32 public constant GRANTER_ROLE = bytes32(uint256(0x01));
    bytes32 public constant UPGRADER_ROLE = bytes32(uint256(0x02));
    bytes32 public constant REEDEEMER_ROLE = bytes32(uint256(0x03));

    /****************************************************************************/
    /*                                 TOKENS                                   */
    /****************************************************************************/

    struct CreditNFTClass {
        uint256 id;
        string  name; 
        bool isUSD;
        uint256 value;
    }

    struct CreditNFT {
        uint256 id;
        uint256 classId;
        bool isUSD;
        uint256 value;  
        uint256 activeBlock;
    }

    struct GlobalData {
        string classImageURI;
        
        mapping(uint256 => CreditNFT) CreditNFTs;
        mapping(uint256 => CreditNFTClass) CreditNFTClasses;
        mapping(address => uint256[]) CreditNFTsByOwner;
        mapping(uint256 => uint256) TotalNFTsByClass;
    }
    
    GlobalData public global;
    uint256 public totalRedeemedCents;

    event CollectorCreditGranted(uint256 indexed tokenId, address indexed account, bool isUSD, uint256 value);
    event CollectorCreditRedeemed(address indexed account, uint64 amountCents, uint256 licenseInstanceId, uint256 indexed redeemedTokens, uint64 redeemedCents);

    function initialize() public initializer {
        __ERC721_init("Vitruveo Collector Credit", "VCOLC");
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
        _grantRole(GRANTER_ROLE, msg.sender);
        _grantRole(REEDEEMER_ROLE, msg.sender);
        initClasses();
    }

    function initClasses() internal {
        global.classImageURI = "https://nftstorage.link/ipfs/bafybeicjca46w5djtghbdbjuv2up4diftcu4abm52kv2my3mmtslzmnnju/";
        registerCreditClass(1, "USD10", true, 10);
    }

    function grantCreditNFT(
        uint256 classId,
        address account,
        uint256 activeBlock,
        uint256 quantity
    ) public onlyRole(GRANTER_ROLE) whenNotPaused {

        CreditNFTClass memory creditNFTClass = global.CreditNFTClasses[classId];

        require(
            creditNFTClass.value > 0, 
            "Specified token class not active."
        );

        for(uint256 i=0;i<quantity;i++) {
            _tokenId.increment();

            CreditNFT storage newCreditNFT = global.CreditNFTs[_tokenId.current()];
            newCreditNFT.id = _tokenId.current();
            newCreditNFT.classId = classId;
            newCreditNFT.isUSD = creditNFTClass.isUSD;
            newCreditNFT.value = creditNFTClass.value;
            newCreditNFT.activeBlock = activeBlock;

            addTokenToOwner(newCreditNFT.id, account);
            global.TotalNFTsByClass[classId]++;

            _mint(account, newCreditNFT.id);

            emit CollectorCreditGranted(newCreditNFT.id, account, newCreditNFT.isUSD, newCreditNFT.value);
        }
    }

    function redeemUsd(address account, uint256 licenseInstanceId, uint64 amountCents) onlyRole(REEDEEMER_ROLE) public whenNotPaused returns(uint64 redeemedCents) {

        uint256 redeemedTokens;
        for(uint f=0; f<global.CreditNFTsByOwner[account].length; f++) {
            uint tokenId = global.CreditNFTsByOwner[account][f];
            CreditNFT memory creditNFT = global.CreditNFTs[tokenId];
            if (creditNFT.activeBlock <= block.number && creditNFT.isUSD) {
                redeemedCents += uint64(creditNFT.value) * 100;
                removeTokenFromOwner(tokenId, account);
                delete global.CreditNFTs[tokenId];
                global.TotalNFTsByClass[creditNFT.classId]--;
                _burn(tokenId);      
                redeemedTokens++;       
            }
            if (redeemedCents >= amountCents) {
                break;
            }
        }

        require(redeemedCents >= amountCents, "Failed to redeem credits");
        totalRedeemedCents += redeemedCents;  

        emit CollectorCreditRedeemed(account, amountCents, licenseInstanceId, redeemedTokens, redeemedCents);
    }


    function removeTokenFromOwner(uint256 tokenId, address account) internal {
        for(uint256 n=0;n<global.CreditNFTsByOwner[account].length;n++) {
            if (global.CreditNFTsByOwner[account][n] == tokenId) {
                global.CreditNFTsByOwner[account][n] = global.CreditNFTsByOwner[account][global.CreditNFTsByOwner[account].length-1];
                global.CreditNFTsByOwner[account].pop();
                break;
            }
        }        
    }

    function addTokenToOwner(uint256 tokenId, address account) internal {
        global.CreditNFTsByOwner[account].push(tokenId); 
    }

    function getAccountTokens(address account) public view returns(CreditNFT[] memory){

        uint256[] memory nfts = global.CreditNFTsByOwner[account];
        CreditNFT[] memory creditNFTs = new CreditNFT[](nfts.length);
        for(uint f=0; f<nfts.length; f++) {
            creditNFTs[f] = global.CreditNFTs[nfts[f]];
        }
        return creditNFTs;
    }

    function getActiveAccountTokens(address account) public view returns(CreditNFT[] memory){

        uint256[] memory nfts = global.CreditNFTsByOwner[account];
        CreditNFT[] memory creditNFTs = new CreditNFT[](nfts.length);
        for(uint f=0; f<nfts.length; f++) {
            if (global.CreditNFTs[nfts[f]].activeBlock <= block.number) {
                creditNFTs[f] = global.CreditNFTs[nfts[f]];
            }
        }
        return creditNFTs;
    }

    function getAvailableCredits(address account) public view returns(uint tokens, uint creditCents, uint creditOther) {

        CreditNFT[] memory creditNFTs = getActiveAccountTokens(account);
        for(uint256 n=0;n<creditNFTs.length;n++) {
            tokens++;
            if (creditNFTs[n].isUSD) {
                creditCents += creditNFTs[n].value * 100;
            } else {
                creditOther +=  creditNFTs[n].value;
            }
        }     
    }

    function updateTransfers(address from, address to, uint tokenId) public onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        removeTokenFromOwner(tokenId, from);
        addTokenToOwner(tokenId, to);
    }

    function getCreditTokenInfo(uint256 id) public view  returns (CreditNFT memory)
    {
        return global.CreditNFTs[id];
    }

    function getCreditClassInfo(uint256 id) public view  returns (CreditNFTClass memory)
    {
        return global.CreditNFTClasses[id];
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory){

        CreditNFT memory creditNFT = global.CreditNFTs[tokenId];    
        require(creditNFT.classId > 0, "Token ID does not exist");

        CreditNFTClass memory creditNFTClass = global.CreditNFTClasses[creditNFT.classId];

	    string memory json = Base64Upgradeable.encode(bytes(string(abi.encodePacked('{"name": "', creditNFTClass.name, '", "description": "Vitruveo Collector Credit NFT", "image": "', global.classImageURI, creditNFTClass.name, '.png"}'))));
	
        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        
        removeTokenFromOwner(tokenId, from);
        addTokenToOwner(tokenId, to);
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        removeTokenFromOwner(tokenId, from);
        addTokenToOwner(tokenId, to);
        _safeTransfer(from, to, tokenId, data);
    }

    function currentSupply() public view returns (uint256) {
        return _tokenId.current();
    }

    // Registers a Credit NFT Class
    function registerCreditClass(
        uint256 id,
        string memory name,
        bool isUSD,
        uint256 value
    ) public onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused returns (CreditNFTClass memory) {

        global.CreditNFTClasses[id] = CreditNFTClass(id, name, isUSD, value);
  
        return global.CreditNFTClasses[id];
    }

    function setClassImageURI(string memory uri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        global.classImageURI = uri;
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
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

}

