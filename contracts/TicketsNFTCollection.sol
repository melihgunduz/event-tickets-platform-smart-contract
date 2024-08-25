// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @custom:security-contact melih__gunduz@outlook.com
contract TicketsNFTCollection is ERC721, ERC721URIStorage, ERC721Pausable, Ownable {
    uint256 private _nextTokenId;
    uint256 public listPrice;
    uint8 public transferFeeRate; // Max 8%

    // string memory tokenName, string memory tokenSymbol will added constructor
    constructor(uint256 _listPrice, uint8 _transferFeeRate, string memory tokenName, string memory tokenSymbol, address owner)
    ERC721(tokenName, tokenSymbol)
    Ownable(owner)
    {
        require(_transferFeeRate > 0 && _transferFeeRate <= 8, "Royal rate could be max 8% and bigger than 0");
        listPrice = _listPrice;
        transferFeeRate = _transferFeeRate;
    }


    event SafeMintExecuted(address indexed to, uint256 indexed tokenId);
    event MintExecuted(address indexed to, uint256 indexed tokenId);
    event TransferNFTExecuted(address indexed from, address indexed to, uint256 indexed tokenId, uint256 price);

    struct Listing {
        uint256 price;
        address seller;
        uint256 tokenId;
    }

    struct Listings {
        mapping(uint256 => Listing) listings;  // Maps token IDs to their respective listings
        uint256[] tokenIds;  // Array to keep track of all token IDs
    }

    struct Token {
        uint256 tokenId;
        address owner;
    }

    struct User {
        address owner;
        Token[] tokens;
    }

    Listings private allListings;
    mapping(address => User) private users;

    modifier transferNFTConditions(address from, address to, uint256 tokenId) {
        require(ownerOf(tokenId) != to, "You can't transfer to yourself");
        require(ownerOf(tokenId) == from, "Only NFT owner can make transfer");
        require(from != address(0) && to != address(0), "Please enter valid address");
        _;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // Cancel listing
    function _cancelListing(address from, uint256 tokenId) public {
        require(_ownerOf(tokenId) == from, "You can't delist this NFT");
        require(allListings.listings[tokenId].tokenId == tokenId, "This token is not listed");
        delete allListings.listings[tokenId];

        uint256[] storage tokens = allListings.tokenIds;
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == tokenId) {
                tokens[i] = tokens[tokens.length - 1];  // Move the last element to the deleted spot
                tokens.pop();  // Remove the last element
                break;
            }
        }

    }

    // Return all NFT's that user have
    function _getAllTokensOfUser(address user) public view returns (Token[] memory) {
        return users[user].tokens;
    }

    // Return all NFT's that listed
    function _getAllListings() public view returns (Listing[] memory) {
        uint256 count = allListings.tokenIds.length;
        Listing[] memory listingsArray = new Listing[](count);

        for (uint256 i = 0; i < count; i++) {
            uint256 tokenId = allListings.tokenIds[i];
            listingsArray[i] = allListings.listings[tokenId];
        }

        return listingsArray;
    }

    // List token in marketplace
    function _listToken(address from, uint256 tokenId, uint256 tokenPrice) public {
        require(_ownerOf(tokenId) == from, "You can't list this NFT");
        require(tokenPrice > 0, "You should set price bigger than 0");
        allListings.listings[tokenId] = Listing(tokenPrice, from, tokenId);
        allListings.tokenIds.push(tokenId);
    }

    // Create NFT and mint to the user
    function _mintNFT(address to, string calldata uri) public payable {
        require(msg.value == listPrice, "Value is not equal to list price");
        uint256 tokenId = _nextTokenId++;
        _mint(to, tokenId);
        _setTokenURI(tokenId, uri);
        payable(owner()).transfer(msg.value);
        Token memory newToken = Token({
            tokenId: tokenId,
            owner: to
        });
        users[to].tokens.push(newToken);
        emit MintExecuted(to, tokenId);
    }

    // Create NFT and mint to the user as contract owner
    function _safeMintNFT(address to, string memory uri) public onlyOwner {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        Token memory newToken = Token({
            tokenId: tokenId,
            owner: to
        });
        users[to].tokens.push(newToken);
        emit SafeMintExecuted(to, tokenId);
    }

    // Transfer an exist NFT to another user with given price
    function _transferNFT(address payable from, address to, uint256 NFTListPrice, uint256 tokenId) public payable transferNFTConditions(from, to, tokenId) {
        require(NFTListPrice == msg.value, "Wrong balance");
        uint256 transferFee = NFTListPrice * (transferFeeRate / 100);
        payable(from).transfer(NFTListPrice - transferFee);
        payable(owner()).transfer(transferFee);
        _transferTokenBetweenUserStructs(tokenId, from, to);
        _transfer(from, to, tokenId);
        emit TransferNFTExecuted(from, to, tokenId, NFTListPrice);
    }

    // Delete NFT from owner struct then add to buyer struct
    function _transferTokenBetweenUserStructs(uint256 _tokenId, address from, address to) private {
        User storage user = users[from];
        uint256 tokenCount = user.tokens.length;

        for (uint256 i = 0; i < tokenCount; i++) {
            if (users[from].tokens[i].tokenId == _tokenId) {
                // Replace the token to be deleted with the last token
                user.tokens[i] = user.tokens[tokenCount - 1];
                user.tokens.pop(); // Remove the last token (now a duplicate)
                break;
            }
        }

        Token memory newToken = Token({
            tokenId: _tokenId,
            owner: to
        });

        users[to].tokens.push(newToken);
    }

    // The following functions are overrides required by Solidity.
    function _update(address to, uint256 tokenId, address auth)
    internal
    override(ERC721, ERC721Pausable)
    returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}