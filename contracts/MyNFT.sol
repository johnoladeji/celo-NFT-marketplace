// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "hardhat/console.sol";

contract MyNFT is ERC721Enumerable, ERC721URIStorage, Ownable {
    // contract inherits from ERC721, ERC721Enumerable, ERC721URIStorage and Ownable contracts
    using Counters for Counters.Counter;

    struct ListedNFT {
        // struct to store NFT details for sale1
        address seller; // seller address
        uint256 price; // sale price
        string url; // NFT URI
    }

    mapping(uint256 => ListedNFT) private _activeItem; // map NFT tokenId to ListedNFT struct, _activeItem store array of item listed into marketplace
    mapping(address => uint8) private mintedAddress;
    uint256 public LIMIT_PER_ADDRESS = 2; // limit NFT minting to 2 per account

    Counters.Counter private _tokenIdCounter; // counter to generate unique token ids

    constructor() ERC721("MyNFT", "MNFT") {} // constructor to initialize the contract with name "MyNFT" and symbol "MNFT"
    
    event NftListingCancelled(uint256 indexed tokenId, address indexed caller); 

    // event emitted when an NFT is listed for sale
    event NftListed(
        uint256 indexed tokenId,
        address indexed buyer,
        uint256 price
    ); 

// event emitted when an NFT listing is updated
    event NftListingUpdated(
        uint256 indexed tokenId,
        address indexed caller,
        uint256 newPrice
    ); 
    
    // event emitted when an NFT is bought
    event NftBought(
        uint256 indexed tokenId,
        address indexed seller,
        address indexed buyer,
        uint256 price
    ); 



    // modifier to check if an NFT is not listed for sale
    modifier notListed(uint256 tokenId) {
        require(_activeItem[tokenId].price == 0, "Already listed");
        _;
    }

    // modifier to check if an NFT is listed for sale
    modifier isListed(uint256 tokenId) {
        require(_activeItem[tokenId].price > 0, "Not listed");
        _;
    }
    // modifier to check if the caller is the owner of the NFT
    modifier isOwner(uint256 tokenId, address spender) {
        require(spender == ownerOf(tokenId), "You are not the owner");
        _;
    }

    /**
        * @notice function to mint a new NFT
        * @param to the address to mint the NFT to
        * @param uri the URL pointing to the metadata of the NFT
     */
    function mintNft(address to, string calldata uri) public {
        require(mintedAddress[msg.sender] < LIMIT_PER_ADDRESS, "You have exceeded minting limit");
        require(to != address(0), "Address zero is not a valid minter address");
        require(bytes(uri).length > 0, "Empty uri");
        mintedAddress[msg.sender] += 1;
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId); // mint a new NFT and assign it to the given address
        _setTokenURI(tokenId, uri); // set the URI of the NFT
    }


    function cancelListing(
       uint256 tokenId
    ) public isListed(tokenId) isOwner(tokenId, msg.sender) {
        // in front-end, we can check because _activeItem[tokenId].seller is "0x000000000000000000000000000000000000000"
       delete _activeItem[tokenId];

        emit NftListingCancelled(tokenId, msg.sender);
    }

    function updateListing(
        uint256 tokenId,
        uint256 newPrice
    ) public isListed(tokenId) isOwner(tokenId, msg.sender) {
       require(newPrice > 0, "Invalid new price");
        _activeItem[tokenId].price = newPrice;

        emit NftListingUpdated(
_activeItem[tokenId].price,
            msg.sender,
            newPrice
        );
    }



    /**
        * @notice function to list NFT into the marketplace
        * @dev The price set needs to be greater than zero to prevent issues with the notListed and isListed modifiers
        * @param tokenId the tokenId of the NFT to be listed
        * @param price the selling price of the NFT
     */
    function listNft(
        uint256 tokenId,
        uint256 price
    ) public notListed(tokenId) isOwner(tokenId, msg.sender) {
        require(price > 0, "Invalid price");
        string memory _url = tokenURI(tokenId);
        _activeItem[tokenId] = ListedNFT(msg.sender, price, _url); // push item into the array that store listedItem

        emit NftListed(tokenId, msg.sender, price);
    }

// Function to return mintedAddress[msg.sender]
    function getMinterLimit() public view returns (uint8) {
        console.log(mintedAddress[msg.sender]);        
        return mintedAddress[msg.sender];
    }
    
    

    /// function to transfer NFT ownership when bought 
    function buyNft(uint256 tokenId) public payable isListed(tokenId) {
        ListedNFT storage currentNft = _activeItem[tokenId];
        require(msg.sender != currentNft.seller, "Can Not buy your own NFT");

        require(msg.value == currentNft.price, "Not enough money!");
        address seller = currentNft.seller;
        delete _activeItem[tokenId]; 
        _transfer(seller, msg.sender, tokenId);

        // Send the correct amount of wei to the seller
        (bool success, ) = payable(seller).call{value: msg.value}("");
        require(success, "Payment failed");

        emit NftBought(tokenId, seller, msg.sender, msg.value);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(
        uint256 tokenId
    ) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    /// function go get URI of created NFT
    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721URIStorage, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /// function to get the array that store item that listed
    function getActiveItem(
        uint256 tokenId
    ) public view returns (ListedNFT memory) {
        return _activeItem[tokenId];
    }

        /**
     * @dev See {IERC721-transferFrom}.
     * Changes is made to transferFrom to prevent transfers of a listed NFT
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(IERC721, ERC721) {
        require(_activeItem[tokenId].price == 0, "You can't transfer a listed NFT");
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     * Changes is made to safeTransferFrom to prevent transfers of a listed NFT
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override(IERC721, ERC721) {
        require(_activeItem[tokenId].price == 0, "You can't transfer a listed NFT");
        _safeTransfer(from, to, tokenId, data);
    }
}
