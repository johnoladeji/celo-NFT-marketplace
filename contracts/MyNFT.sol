// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

/**
 * @dev External dependencies for the MyNFT contract.
 *
 * These import statements bring in external dependencies from the OpenZeppelin library
 * and Hardhat development tool for the MyNFT contract. They include the ERC721, ERC721Enumerable,
 * ERC721URIStorage, and Ownable contracts, as well as the Counters library for managing counters.
 */
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "hardhat/console.sol";

/**
 * @dev MyNFT is an Ethereum smart contract that represents non-fungible tokens (NFTs).
 *
 * This contract inherits functionality from three OpenZeppelin contracts: ERC721Enumerable,
 * ERC721URIStorage, and Ownable. It allows users to mint NFTs, list them in a marketplace,
 * update their listings, cancel listings, and transfer ownership of NFTs.
 */
contract MyNFT is ERC721Enumerable, ERC721URIStorage, Ownable {
    // contract inherits from ERC721, ERC721Enumerable, ERC721URIStorage and Ownable contracts
    /**
    * @dev Using statement for the Counters library to manage counters.
    *
    * This statement allows the contract to use the Counters library to manage counters.
    * Specifically, it enables the usage of the `Counters.Counter` type to maintain and manipulate
    * counters used within the contract, such as token IDs.
    */
    using Counters for Counters.Counter;

    /**
    * @dev A data structure to store details of an NFT listed for sale in the marketplace.
    *
    * The ListedNFT struct is used to represent NFTs that are listed for sale in the marketplace.
    * It stores information about the seller's address, the sale price of the NFT, and the URI
    * pointing to the NFT's metadata.
    *
    * - `seller`: The address of the seller listing the NFT for sale.
    * - `price`: The selling price of the NFT in the marketplace.
    * - `url`: The URI pointing to the metadata of the NFT.
    */
    struct ListedNFT {
        // struct to store NFT details for sale1
        address seller; // seller address
        uint256 price; // sale price
        string url; // NFT URI
    }

    /**
    * @dev Data structures and state variables for managing NFTs in the marketplace.
    *
    * The contract uses these state variables to manage NFT listings in the marketplace and to track
    * the number of NFTs minted by each address, subject to a predefined limit.
    *
    * - `_activeItem`: A mapping that associates NFT token IDs with their corresponding ListedNFT struct,
    *   allowing the contract to store information about NFTs listed for sale.
    * - `mintedAddress`: A mapping that tracks the number of NFTs minted by each address.
    * - `LIMIT_PER_ADDRESS`: A public constant defining the maximum number of NFTs that can be minted
    *   by a single address.
    */
    mapping(uint256 => ListedNFT) private _activeItem; // map NFT tokenId to ListedNFT struct, _activeItem store array of item listed into marketplace
    mapping(address => uint8) private mintedAddress;
    uint256 public LIMIT_PER_ADDRESS = 2; // limit NFT minting to 2 per account

    /**
    * @dev A Counter to generate unique token IDs for minted NFTs.
    *
    * This Counter is used to generate unique token IDs for the NFTs minted by the contract.
    * It ensures that each minted NFT receives a distinct and incrementing token ID.
    */
    Counters.Counter private _tokenIdCounter; // counter to generate unique token ids

    /**
    * @dev Initializes the MyNFT contract with a name and symbol.
    *
    * This constructor is responsible for initializing the contract by setting its name and symbol.
    * The name and symbol are used to uniquely identify the NFTs created by this contract on the blockchain.
    * 
    * @notice The contract's name is set to "MyNFT" and its symbol to "MNFT".
    */
    constructor() ERC721("MyNFT", "MNFT") {} // constructor to initialize the contract with name "MyNFT" and symbol "MNFT"
    
    /**
    * @dev Emitted when a listing for an NFT is canceled by the owner.
    *
    * This event is emitted when the owner of an NFT cancels its listing in the marketplace.
    *
    * @param tokenId The ID of the canceled NFT.
    * @param caller The address of the caller who canceled the listing.
    */
    event NftListingCancelled(uint256 indexed tokenId, address indexed caller); 

    /**
    * @dev Emitted when an NFT is listed for sale in the marketplace.
    *
    * This event is emitted when an NFT is listed for sale by its owner in the marketplace.
    *
    * @param tokenId The ID of the listed NFT.
    * @param buyer The address of the owner listing the NFT for sale.
    * @param price The selling price of the NFT.
    */
    event NftListed(
        uint256 indexed tokenId,
        address indexed buyer,
        uint256 price
    ); 

    /**
    * @dev Emitted when the listing price of an NFT is updated.
    *
    * This event is emitted when the owner of an NFT updates its listing price in the marketplace.
    *
    * @param tokenId The ID of the NFT for which the listing price was updated.
    * @param caller The address of the caller who updated the listing price.
    * @param newPrice The new selling price of the NFT.
    */
    event NftListingUpdated(
        uint256 indexed tokenId,
        address indexed caller,
        uint256 newPrice
    ); 
    
    /**
    * @dev Emitted when an NFT is successfully purchased from the marketplace.
    *
    * This event is emitted when a user successfully purchases an NFT from the marketplace.
    *
    * @param tokenId The ID of the purchased NFT.
    * @param seller The address of the NFT's previous owner (seller).
    * @param buyer The address of the user who bought the NFT.
    * @param price The purchase price of the NFT.
    */
    event NftBought(
        uint256 indexed tokenId,
        address indexed seller,
        address indexed buyer,
        uint256 price
    ); 



    /**
    * @dev Modifier to check if an NFT is not listed for sale in the marketplace.
    *
    * This modifier is used to restrict access to functions, ensuring that they can only be executed
    * if the specified NFT is not currently listed for sale. It checks whether the NFT with the given
    * `tokenId` is not listed, and if it is listed, it raises an error.
    *
    * @param tokenId The ID of the NFT being checked.
    *
    * Requirements:
    * - The NFT must not be listed for sale.
    */
    modifier notListed(uint256 tokenId) {
        require(_activeItem[tokenId].price == 0, "Already listed");
        _;
    }

    /**
    * @dev Modifier to check if an NFT is listed for sale in the marketplace.
    *
    * This modifier is used to restrict access to functions, ensuring that they can only be executed
    * if the specified NFT is currently listed for sale. It checks whether the NFT with the given
    * `tokenId` is listed for sale, and if it is not listed, it raises an error.
    *
    * @param tokenId The ID of the NFT being checked.
    *
    * Requirements:
    * - The NFT must be listed for sale.
    */
    modifier isListed(uint256 tokenId) {
        require(_activeItem[tokenId].price > 0, "Not listed");
        _;
    }

    /**
    * @dev Modifier to check if the caller is the owner of a specified NFT.
    *
    * This modifier is used to restrict access to functions, ensuring that only the owner of a specific
    * NFT can perform certain actions. It checks whether the provided `spender` address is the owner
    * of the NFT with the given `tokenId`. If not, it raises an error.
    *
    * @param tokenId The ID of the NFT to be checked.
    * @param spender The address being checked for ownership.
    *
    * Requirements:
    * - The `spender` address must be the owner of the NFT with the specified `tokenId`.
    */
    modifier isOwner(uint256 tokenId, address spender) {
        require(spender == ownerOf(tokenId), "You are not the owner");
        _;
    }

    /**
    * @dev Mints a new NFT and assigns it to the specified recipient.
    *
    * This function allows users to mint a new NFT, which will be assigned to the specified recipient's
    * address. The function checks if the caller has exceeded the minting limit, ensures a valid recipient
    * address is provided, and requires a non-empty URI for the NFT's metadata.
    *
    * @param to The address to which the newly minted NFT will be assigned.
    * @param uri The URI pointing to the metadata of the NFT.
    *
    * Requirements:
    * - The caller must not have exceeded the minting limit.
    * - The recipient address must be valid and not the contract's address.
    * - The URI must not be empty.
    *
    * Emits a {Transfer} event upon successfully minting and assigning the NFT.
    */
    function mintNft(address to, string calldata uri) public {
        require(mintedAddress[msg.sender] < LIMIT_PER_ADDRESS, "You have exceeded minting limit");
        require(to != address(0) && to != address(this), "Invalid recipient address");
        require(bytes(uri).length > 0, "Empty uri");
        mintedAddress[msg.sender] += 1;
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId); // mint a new NFT and assign it to the given address
        _setTokenURI(tokenId, uri); // set the URI of the NFT
    }

    /**
    * @dev Cancels the listing of an NFT in the marketplace.
    *
    * This function allows the owner of a listed NFT to cancel its listing in the marketplace.
    * The NFT's token ID must be provided, and the caller must be the owner of the NFT.
    *
    * @param tokenId The ID of the NFT to be removed from the marketplace.
    *
    * Requirements:
    * - The NFT must be listed in the marketplace.
    * - The caller must be the owner of the NFT.
    * - The specified token ID must be greater than zero.
    *
    * Emits a {NftListingCancelled} event upon successfully canceling the listing.
    */
    function cancelListing(
       uint256 tokenId
    ) public isListed(tokenId) isOwner(tokenId, msg.sender) {
        // in front-end, we can check because _activeItem[tokenId].seller is "0x000000000000000000000000000000000000000"
        require(tokenId > 0, "Invalid tokenId"); 
        delete _activeItem[tokenId];

        emit NftListingCancelled(tokenId, msg.sender);
    }

    /**
    * @dev Updates the listing price of an NFT in the marketplace.
    *
    * This function allows the owner of a listed NFT to update its sale price in the marketplace.
    * The NFT's token ID and the new price must be provided, and the caller must be the owner of the NFT.
    *
    * @param tokenId The ID of the NFT for which the listing price will be updated.
    * @param newPrice The new selling price of the NFT.
    *
    * Requirements:
    * - The NFT must be listed in the marketplace.
    * - The caller must be the owner of the NFT.
    * - The specified new price must be greater than zero.
    *
    * Emits a {NftListingUpdated} event upon successfully updating the listing price.
    */
    function updateListing(
        uint256 tokenId,
        uint256 newPrice
    ) public isListed(tokenId) isOwner(tokenId, msg.sender) {
       require(newPrice > 0, "Invalid new price");
        _activeItem[tokenId].price = newPrice;

        emit NftListingUpdated(
            tokenId,
            msg.sender,
            newPrice
        );
    }


    /**
    * @dev Lists an NFT in the marketplace for sale.
    *
    * This function allows the owner of an NFT to list it for sale in the marketplace by specifying
    * the NFT's token ID and the sale price. The NFT must not be already listed, and it should exist
    * with a valid URI. Additionally, the owner must be the caller of this function.
    *
    * @param tokenId The ID of the NFT to be listed for sale.
    * @param price The selling price of the NFT.
    *
    * Requirements:
    * - The NFT must not be already listed.
    * - The NFT must exist with a valid URI.
    * - The caller must be the owner of the NFT.
    * - The specified price must be greater than zero.
    *
    * Emits a {NftListed} event upon successfully listing the NFT for sale.
    */

    function listNft(
        uint256 tokenId,
        uint256 price
    ) public notListed(tokenId) isOwner(tokenId, msg.sender) {
        require(price > 0, "Invalid price");
        require(_exists(tokenId), "NFT does not exist");
        string memory _url = tokenURI(tokenId);
        require(bytes(_url).length > 0, "Invalid URI");
        require(_activeItem[tokenId].seller == address(0), "NFT is already listed");
        _activeItem[tokenId] = ListedNFT(msg.sender, price, _url); // push item into the array that store listedItem

        emit NftListed(tokenId, msg.sender, price);
    }

    /**
    * @dev Retrieves the current NFT minting limit for the caller's address.
    *
    * This function allows a user to check the current number of NFTs they have minted, which is
    * subject to a predefined limit set by the contract. The minting limit is typically used to
    * restrict the number of NFTs a single address can create.
    *
    * @return The current NFT minting limit for the caller's address.
    */
    function getMinterLimit() public view returns (uint8) {
        console.log(mintedAddress[msg.sender]);        
        return mintedAddress[msg.sender];
    }
    
    

    /**
    * @dev Allows a user to purchase an NFT listed for sale in the marketplace.
    *
    * This function enables users to buy NFTs that are listed for sale by transferring the NFT's
    * ownership to the buyer and sending the appropriate amount of Ether to the seller. It also
    * prevents buyers from purchasing their own NFTs.
    *
    * @param tokenId The ID of the NFT being purchased.
    *
    * Requirements:
    * - The NFT must be listed for sale in the marketplace.
    * - The buyer cannot be the seller.
    * - The sent Ether must match the NFT's sale price.
    * - The seller's address must be valid.
    *
    * Emits a {NftBought} event upon a successful purchase.
    */
    function buyNft(uint256 tokenId) public payable isListed(tokenId) {
        ListedNFT storage currentNft = _activeItem[tokenId];
        require(msg.sender != currentNft.seller, "Can Not buy your own NFT");

        require(msg.value == currentNft.price, "Not enough money!");
        require(currentNft.seller != address(0), "NFT is not listed");
        address seller = currentNft.seller;
        delete _activeItem[tokenId]; 
        _transfer(seller, msg.sender, tokenId);

        // Send the correct amount of wei to the seller
        (bool success, ) = payable(seller).call{value: msg.value}("");
        require(success, "Payment failed");

        emit NftBought(tokenId, seller, msg.sender, msg.value);
    }

    /**
    * @dev Hook function called before any token transfer.
    *
    * This internal function is invoked before any token transfer operation, allowing for custom
    * logic to be executed. It is an override of the `_beforeTokenTransfer` function from both
    * the ERC721 and ERC721Enumerable contracts.
    *
    * @param from The address from which the NFT is being transferred.
    * @param to The address to which the NFT is being transferred.
    * @param tokenId The ID of the NFT being transferred.
    * @param batchSize The size of the batch transfer (usually 1 for single transfers).
    *
    * Implement custom logic in this function to handle any requirements or actions needed
    * before the token transfer.
    */

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }


    /**
     * @dev Burns (destroys) an NFT with a specified token ID.
     *
     * This internal function is used to permanently remove an NFT from the ownership and existence
     * within the contract. It is an override of the `_burn` function from both the ERC721 and
     * ERC721URIStorage contracts.
     *
     * @param tokenId The ID of the NFT to be burned (destroyed).
     */
    function _burn(
        uint256 tokenId
    ) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    /**
    * @dev Retrieves the URI for a specific token's metadata.
    *
    * This function allows you to retrieve the URI that points to the metadata of a given NFT
    * specified by its `tokenId`. It is an override of the `tokenURI` function from both the
    * ERC721 and ERC721URIStorage contracts.
    *
    * @param tokenId The ID of the NFT for which you want to retrieve the metadata URI.
    *
    * @return A string representing the URI to the metadata of the specified NFT.
    */
    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    /**
    * @dev Checks whether a contract implements a given interface.
    *
    * This function determines whether the contract supports a specific interface by checking
    * the provided `interfaceId`. It is an override of the `supportsInterface` function from
    * both ERC721URIStorage and ERC721Enumerable contracts.
    *
    * @param interfaceId The ID of the interface to check.
    *
    * @return `true` if the contract supports the interface, otherwise `false`.
    */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721URIStorage, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
    * @dev Retrieves information about a listed NFT based on its token ID.
    *
    * This function allows you to retrieve details about an NFT that is currently listed for sale
    * in the marketplace, including the seller's address, the sale price, and the NFT's URI.
    *
    * @param tokenId The ID of the NFT for which you want to retrieve information.
    *
    * @return A `ListedNFT` struct containing the seller's address, sale price, and NFT URI.
    */
    function getActiveItem(
        uint256 tokenId
    ) public view returns (ListedNFT memory) {
        return _activeItem[tokenId];
    }

    /**
    * @dev Transfers an NFT from one address to another, preventing transfers of listed NFTs.
    *
    * This function is an override of the {IERC721-transferFrom} function with added protection
    * to prevent the transfer of NFTs that are currently listed for sale in the marketplace.
    *
    * @param from The current owner of the NFT.
    * @param to The address to which the NFT will be transferred.
    * @param tokenId The ID of the NFT to be transferred.
    *
    * Requirements:
    * - The NFT must not be listed for sale in the marketplace.
    *
    * Emits a {Transfer} event.
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
    * @dev Safely transfers an NFT to another address, preventing transfers of listed NFTs.
    *
    * This function is an override of the {IERC721-safeTransferFrom} function with added protection
    * to prevent the transfer of NFTs that are currently listed for sale in the marketplace.
    *
    * @param from The current owner of the NFT.
    * @param to The address to which the NFT will be transferred.
    * @param tokenId The ID of the NFT to be transferred.
    * @param data Additional data with no specified format, usually containing a message.
    *
    * Requirements:
    * - The NFT must not be listed for sale in the marketplace.
    *
    * Emits a {Transfer} event.
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