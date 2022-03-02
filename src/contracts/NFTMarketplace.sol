// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NFTCollection.sol";
import "hardhat/console.sol";

contract NFTMarketplace {
  uint public offerCount;
  mapping (uint => _Offer) public offers;
  mapping (address => uint) public userFunds;
  NFTCollection nftCollection;

  struct _Offer {
    uint offerId;
    uint id;
    address user;
    uint price;
    bool fulfilled;
    bool cancelled;
    uint lentStatus;      // 1-collateral, 2-lent, 0-returned(normal)
  }

  event Offer(
    uint offerId,
    uint id,
    address user,
    uint price,
    bool fulfilled,
    bool cancelled
  );
  event collateralOffered(uint tokenId, uint id, address owner);
  event OfferFilled(uint offerId, uint id, address newOwner);
  event OfferCancelled(uint offerId, uint id, address owner);
  event ClaimFunds(address user, uint amount);

  constructor(address _nftCollection) {
    nftCollection = NFTCollection(_nftCollection);
  }
  
  function makeOffer(uint _id, uint _price) public {

    nftCollection.transferFrom(
            msg.sender,     // from
            address(this),  // to         // this class contract address
            _id);           // tokenId
    offerCount ++;
    offers[offerCount] = _Offer(offerCount, _id, msg.sender, _price, false, false, 0);
    emit Offer(offerCount, _id, msg.sender, _price, false, false);
  }

  function fillOffer(uint _offerId) public payable {
    _Offer storage _offer = offers[_offerId];
    require(_offer.offerId == _offerId, 'The offer must exist');
    require(_offer.user != msg.sender, 'The owner of the offer cannot fill it');
    require(!_offer.fulfilled, 'An offer cannot be fulfilled twice');
    require(!_offer.cancelled, 'A cancelled offer cannot be fulfilled');
    require(msg.value == _offer.price, 'The ETH amount should match with the NFT Price');
    nftCollection.transferFrom(address(this), msg.sender, _offer.id);     // this class contract address
    _offer.fulfilled = true;
    userFunds[_offer.user] += msg.value;
    emit OfferFilled(_offerId, _offer.id, msg.sender);
  }

  function cancelOffer(uint _offerId) public {
    _Offer storage _offer = offers[_offerId];
    require(_offer.offerId == _offerId, 'The offer must exist');
    require(_offer.user == msg.sender, 'The offer can only be canceled by the owner');
    require(_offer.fulfilled == false, 'A fulfilled offer cannot be cancelled');
    require(_offer.cancelled == false, 'An offer cannot be cancelled twice');
    nftCollection.transferFrom(address(this), msg.sender, _offer.id);       // this class contract address
    _offer.cancelled = true;
    emit OfferCancelled(_offerId, _offer.id, msg.sender);
  }
  
  function offerCollateral(uint _offerId, address lentContractAddress) public {
    _Offer storage _offer = offers[_offerId];
    require(_offer.offerId == _offerId, 'The offer must exist');
    require(_offer.user == msg.sender, 'The offer can only be canceled by the owner');
    require(_offer.fulfilled == false, 'A fulfilled offer cannot be cancelled');
    require(_offer.cancelled == false, 'An offer cannot be cancelled twice');
    nftCollection.transferFrom(address(this), lentContractAddress, _offer.id);       // this class contract address
    _offer.lentStatus = 1;
    emit collateralOffered(_offerId, _offer.id, msg.sender);
  }
  
  function claimFunds() public {
    require(userFunds[msg.sender] > 0, 'This user has no funds to be claimed');
    payable(msg.sender).transfer(userFunds[msg.sender]);
    emit ClaimFunds(msg.sender, userFunds[msg.sender]);
    userFunds[msg.sender] = 0;    
  }



  // Fallback: reverts if Ether is sent to this smart-contract by mistake
  fallback () external {
    revert();
  }
}