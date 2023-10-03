// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title MyNFT - Custom ERC721 Token Contract with NFT Marketplace
 * @dev This contract allows users to mint, list, buy, update listings, and cancel listings of NFTs.
 */
contract MyNFT is ERC721Enumerable, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    struct ListedNFT {
        address seller;
        uint256 price;
        string url;
    }

    mapping(uint256 => ListedNFT) private _activeItem;
    mapping(address => uint8) private mintedAddress;
    uint256 public LIMIT_PER_ADDRESS = 2;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("MyNFT", "MNFT") {}

    /**
     * @dev Emitted when an NFT listing is canceled.
     * @param tokenId The ID of the canceled NFT.
     * @param caller The address of the caller canceling the listing.
     */
    event NftListingCancelled(uint256 indexed tokenId, address indexed caller);

    /**
     * @dev Emitted when an NFT is listed for sale.
     * @param tokenId The ID of the listed NFT.
     * @param buyer The address of the NFT owner.
     * @param price The listing price of the NFT.
     */
    event NftListed(uint256 indexed tokenId, address indexed buyer, uint256 price);

    /**
     * @dev Emitted when an NFT listing is updated.
     * @param tokenId The ID of the updated NFT listing.
     * @param caller The address of the caller updating the listing.
     * @param newPrice The new listing price.
     */
    event NftListingUpdated(uint256 indexed tokenId, address indexed caller, uint256 newPrice);

    /**
     * @dev Emitted when an NFT is bought.
     * @param tokenId The ID of the bought NFT.
     * @param seller The address of the NFT seller.
     * @param buyer The address of the NFT buyer.
     * @param price The purchase price of the NFT.
     */
    event NftBought(uint256 indexed tokenId, address indexed seller, address indexed buyer, uint256 price);

    /**
     * @dev Modifier to check if an NFT is not listed for sale.
     * @param tokenId The ID of the NFT to check.
     */
    modifier notListed(uint256 tokenId) {
        require(_activeItem[tokenId].price == 0, "Already listed");
        _;
    }

    /**
     * @dev Modifier to check if an NFT is listed for sale.
     * @param tokenId The ID of the NFT to check.
     */
    modifier isListed(uint256 tokenId) {
        require(_activeItem[tokenId].price > 0, "Not listed");
        _;
    }

    /**
     * @dev Modifier to check if the caller is the owner of an NFT.
     * @param tokenId The ID of the NFT to check ownership.
     * @param spender The address to check ownership against.
     */
    modifier isOwner(uint256 tokenId, address spender) {
        require(spender == ownerOf(tokenId), "You are not the owner");
        _;
    }

    /**
     * @dev Mint a new NFT and assign it to the provided address.
     * @param to The address to mint the NFT to.
     * @param uri The URL pointing to the NFT metadata.
     */
    function mintNft(address to, string calldata uri) public {
        require(mintedAddress[_msgSender()] < LIMIT_PER_ADDRESS, "Exceeded minting limit");
        require(to != address(0), "Zero address is not a valid minter address");
        require(bytes(uri).length > 0, "Empty URI");
        mintedAddress[_msgSender()] += 1;
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    /**
     * @dev Cancel the listing of an NFT, making it unlisted.
     * @param tokenId The ID of the NFT to cancel the listing for.
     */
    function cancelListing(uint256 tokenId) public isListed(tokenId) isOwner(tokenId, _msgSender()) {
        delete _activeItem[tokenId];
        emit NftListingCancelled(tokenId, _msgSender());
    }

    /**
     * @dev Update the listing price of an NFT.
     * @param tokenId The ID of the NFT to update the listing for.
     * @param newPrice The new listing price.
     */
    function updateListing(uint256 tokenId, uint256 newPrice) public isListed(tokenId) isOwner(tokenId, _msgSender()) {
        require(newPrice > 0, "Invalid new price");
        _activeItem[tokenId].price = newPrice;
        emit NftListingUpdated(tokenId, _msgSender(), newPrice);
    }

    /**
     * @dev List an NFT for sale in the marketplace.
     * @param tokenId The ID of the NFT to list for sale.
     * @param price The selling price of the NFT.
     */
    function listNft(uint256 tokenId, uint256 price) public notListed(tokenId) isOwner(tokenId, _msgSender()) {
        require(price > 0, "Invalid price");
        string memory _url = tokenURI(tokenId);
        _activeItem[tokenId] = ListedNFT(_msgSender(), price, _url);
        emit NftListed(tokenId, _msgSender(), price);
    }

    /**
     * @dev Get the minter limit for the caller.
     * @return The current minter limit for the caller's address.
     */
    function getMinterLimit() public view returns (uint8) {
        return mintedAddress[_msgSender()];
    }

    /**
     * @dev Buy an NFT listed in the marketplace.
     * @param tokenId The ID of the NFT to purchase.
     */
    function buyNft(uint256 tokenId) public payable isListed(tokenId) {
        ListedNFT storage currentNft = _activeItem[tokenId];
        require(_msgSender() != currentNft.seller, "Cannot buy your own NFT");
        require(msg.value == currentNft.price, "Incorrect payment amount");
        address seller = currentNft.seller;
        delete _activeItem[tokenId];
        _transfer(seller, _msgSender(), tokenId);

        (bool success, ) = payable(seller).call{value: msg.value}("");
        require(success, "Payment failed");
        emit NftBought(tokenId, seller, _msgSender(), msg.value);
    }

    /**
     * @dev Override of the tokenURI function to support ERC721URIStorage.
     */
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    /**
     * @dev Override of the supportsInterface function to support ERC721 and ERC721Enumerable interfaces.
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Get the details of an active listed NFT.
     * @param tokenId The ID of the NFT to query.
     * @return The details of the active listed NFT.
     */
    function getActiveItem(uint256 tokenId) public view returns (ListedNFT memory) {
        return _activeItem[tokenId];
    }

    /**
     * @dev Override of the transferFrom function to prevent transfers of listed NFTs.
     */
    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721) {
        require(_activeItem[tokenId].price == 0, "You can't transfer a listed NFT");
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev Override of the safeTransferFrom function to prevent transfers of listed NFTs.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override(ERC721) {
        require(_activeItem[tokenId].price == 0, "You can't transfer a listed NFT");
        super.safeTransferFrom(from, to, tokenId, data);
    }
}
