// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NFTCollection.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract NFTCreator is ReentrancyGuardUpgradeable {
  uint256 listingPrice = 0.025 ether; // minimum price, change for what you want
  NFTCollection nftContract;

  uint public creatorCount;
  using Counters for Counters.Counter;
  Counters.Counter private _items;
  Counters.Counter private _soldItems;

  address payable owner;

  // interface to marketplace item
    struct CreatorItem {
        uint256 itemId;
        // address nftContract;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }
    mapping(uint256 => CreatorItem) private idToCreatorItem;

    // declare a event for when a item is created on marketplace
    event CreatorItemCreated(
        uint256 indexed itemId,
        // address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );

    constructor(address _nftCollection) {
        // owner = payable(msg.sender);
        nftContract = NFTCollection(_nftCollection);
    }
  // places an item for sale on the marketplace
  function createCreatorItem(
        // address nftContract,
        uint256 tokenId,
        uint256 price
    ) public payable nonReentrant {
        require(price > 0, "Price must be at least 1 wei");
        require(
            msg.value == listingPrice,
            "Price must be equal to listing price"
        );

        _items.increment();
        uint256 itemId = _items.current();

        idToCreatorItem[itemId] = CreatorItem(
            itemId,                     //item registerd id
            // nftContract,                //nftContract       -- 
            tokenId,                    //nft item token    --
            payable(msg.sender),        //seller
            payable(address(0)),        //owner
            price,                      //                  --
            false
        );

        //IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
        nftContract.transferFrom(msg.sender, address(this), tokenId);

        emit CreatorItemCreated(
            itemId,
            // nftContract,
            tokenId,
            msg.sender,
            address(0),
            price,
            false
        );
    }
  
    // creates the sale of a marketplace item
    // transfers ownership of the item, as well as funds between parties
    function createCreatorSale(
            //address nftContract, 
            uint256 itemId)
        public
        payable
        nonReentrant
    {
        uint256 price = idToCreatorItem[itemId].price;
        uint256 tokenId = idToCreatorItem[itemId].tokenId;

        require(
            msg.value == price,
            "Please submit the asking price in order to complete the purchase"
        );

        idToCreatorItem[itemId].seller.transfer(msg.value);
        //IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
        nftContract.transferFrom(address(this), msg.sender, tokenId);
        idToCreatorItem[itemId].owner = payable(msg.sender);
        idToCreatorItem[itemId].sold = true;

        _soldItems.increment();

        payable(owner).transfer(listingPrice);
    }

    // returns all unsold marketplace items
    function fetchCreatorItems()
        public
        view
        returns (CreatorItem[] memory)
    {
        uint256 itemCount = _items.current();
        uint256 unsoldItemCount = _items.current() - _soldItems.current();
        uint256 currentIndex = 0;

        CreatorItem[] memory items = new CreatorItem[](unsoldItemCount);
        for (uint256 i = 0; i < itemCount; i++) {
            if (idToCreatorItem[i + 1].owner == address(0)) {
                uint256 currentId = i + 1;
                CreatorItem storage currentItem = idToCreatorItem[
                    currentId
                ];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    // returns only items that a user has purchased
    function fetchMyNFTs() public view returns (CreatorItem[] memory) {
        uint256 totalItemCount = _items.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToCreatorItem[i + 1].owner == msg.sender) {
                itemCount += 1;
            }
        }

        CreatorItem[] memory items = new CreatorItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToCreatorItem[i + 1].owner == msg.sender) {
                uint256 currentId = i + 1;
                CreatorItem storage currentItem = idToCreatorItem[
                    currentId
                ];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    // returns only items a user has created
    function fetchItemsCreated()
        public
        view
        returns (CreatorItem[] memory)
    {
        uint256 totalItemCount = _items.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToCreatorItem[i + 1].seller == msg.sender) {
                itemCount += 1;
            }
        }

        CreatorItem[] memory items = new CreatorItem[](itemCount);

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToCreatorItem[i + 1].seller == msg.sender) {
                uint256 currentId = i + 1;
                CreatorItem storage currentItem = idToCreatorItem[
                    currentId
                ];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return items;
    }
}