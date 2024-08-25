// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.26;

import {TicketsNFTCollection} from "contracts/TicketsNFTCollection.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

contract Eventynamics is Ownable, Pausable {
    uint256 private _nextCollectionId;

    constructor()
    Ownable(msg.sender)
    {

    }


    struct collectionsStruct {
        mapping(address => mapping(uint256 => TicketsNFTCollection)) collectionMapping;
        mapping(address => TicketsNFTCollection[]) userCollections;  // Maps token IDs to their respective listings
        address[] collectionAddresses;  // Array to keep track of all token IDs
        mapping(uint256 => address) tokenIdToCollectionAddress;
    }

    collectionsStruct private allCollections;
    TicketsNFTCollection[] public listOfTicketsNFTCollection;


    event CollectionPublished (uint256 tokenId, address indexed owner, uint256 listPrice, string tokenName, string tokenSymbol);


    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }


    function publishCollection(uint256 _listPrice, uint8 _transferFeeRate, string memory tokenName, string memory tokenSymbol) public {

        TicketsNFTCollection nftCollectionContractVariable = new TicketsNFTCollection(
            _listPrice,
            _transferFeeRate,
            tokenName,
            tokenSymbol,
            msg.sender
        );

        uint256 collectionId = _nextCollectionId;
        _nextCollectionId++;

        allCollections.collectionMapping[msg.sender][collectionId] = nftCollectionContractVariable;
        allCollections.collectionAddresses.push(address(nftCollectionContractVariable));
        allCollections.tokenIdToCollectionAddress[collectionId] = address(nftCollectionContractVariable);
        allCollections.userCollections[msg.sender].push(nftCollectionContractVariable);

        listOfTicketsNFTCollection.push(nftCollectionContractVariable);

        emit CollectionPublished(collectionId, msg.sender, _listPrice, tokenName, tokenSymbol);
    }

    function getCollection(uint256 collectionId) public view returns (TicketsNFTCollection) {
        return allCollections.collectionMapping[msg.sender][collectionId];
    }

    function getThisUserCollections() public view returns (TicketsNFTCollection[] memory) {
        return allCollections.userCollections[msg.sender];
    }

}