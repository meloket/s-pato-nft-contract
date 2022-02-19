import { useContext, useRef, createRef } from 'react';

import web3 from '../../../connection/web3';
import Web3Context from '../../../store/web3-context';
import CollectionContext from '../../../store/collection-context';
import MarketplaceContext from '../../../store/marketplace-context';
import { formatPrice } from '../../../helpers/utils';
import eth from '../../../img/eth.png';

// import LOANCONTACT_ABI from '../../../abis/test_abi.json';
// import LOANCONTACT_ABI from '../../../abis/Collateralizer.json';
import LOANCONTACT_ABI from '../../../import_abi/Collateralizer';
import { COLLATERAL_CONTACT_ADDRESS }  from '../../../config';

import Web3 from 'web3';
import { useEffect, useState } from 'react';


const LoanCollection = () => {
  const web3Ctx = useContext(Web3Context);
  const collectionCtx = useContext(CollectionContext);
  const marketplaceCtx = useContext(MarketplaceContext);
  const priceRefs = useRef([]);



  // ########## ---> added
  const [account, setAccount] = useState();
	const [LoanContactObject, setContactList] = useState();
	const [contacts, setContacts] = useState([]);
  useEffect(() => {
		async function load() {
          const web3Bridge = new Web3(Web3.givenProvider || 'http://rinkeby.etherscan.io/');
          // console.log(web3Bridge);

          const accounts = await web3Bridge.eth.requestAccounts();
          setAccount(accounts[0]);
          //console.log(accounts[0]); // 0x2Bb9454D0be9d010aa7E99dE517da9E66452b51b
          

          // Instantiate smart contract using ABI and address.
          const LoanContract = new web3Bridge.eth.Contract(LOANCONTACT_ABI, COLLATERAL_CONTACT_ADDRESS);
          // set contact list to state variable.
          setContactList(LoanContract);
          // console.log(LoanContract);  // Contract
          // console.log(LoanContract.methods);
          console.log(LoanContract.methods.repay);


          // Then we get total number of contacts for iteration
          // const counter = await contactList.methods.count().call();          console.log(counter);


        }

        load();
      }, []);
    
  // <--- ###########




  if (priceRefs.current.length !== collectionCtx.collection.length) {
    priceRefs.current = Array(collectionCtx.collection.length).fill().map(
          (_, i) => priceRefs.current[i] || createRef());
  }
  
  const OfferCollateralHandler = (event, id, key, owner, price) => {
    event.preventDefault();
    const enteredPrice = web3.utils.toWei(priceRefs.current[key].current.value, 'ether');
    console.log("OfferCollateralHandler, marketplaceCtx : " + enteredPrice);
    //console.log(LoanContactObject); return; 
    //console.log(key); return;
    //address nftContract, uint nftId, uint endTime
    //  , uint borrowCeiling, uint interestPerEthPerDay
    //  , address payable currentOwner
    var nftContract = COLLATERAL_CONTACT_ADDRESS;
    var nftId = id;
    var endTime = Date.now() + 10*60*60*24;
    var borrowCeiling = enteredPrice;
    var interestPerEthPerDay = 1;
    var NftOwner = owner;
    LoanContactObject.methods.lend(nftContract,
        nftId,
        endTime,
        borrowCeiling,
        interestPerEthPerDay,
        NftOwner,
            ).send({ from: NftOwner })
      .on('transactionHash', (hash) => {
        marketplaceCtx.setMktIsLoading(true);
      })
      .on('receipt', (receipt) => {      
          alert("NFT locking is ok, you can craete lending funds.");
          // marketplaceCtx.contract.methods.fundLoan(id, enteredPrice)
          //     .send({ from: web3Ctx.account })
          //     .on('transactionHash', (hash) => {
          //       marketplaceCtx.setMktIsLoading(true);
          //     })
          //     .on('error', (error) => {
          //       window.alert('Something went wrong when pushing a Collateral Offer Request to the blockchain');
          //       marketplaceCtx.setMktIsLoading(false);
          //     });            
      });           
    
  };
  
  const AcceptLendHandler = (event) => {    
    // const buyIndex = parseInt(event.target.value);      
    // marketplaceCtx.contract.methods.fillOffer(marketplaceCtx.offers[buyIndex].offerId)
    //  .send({ from: web3Ctx.account, value: marketplaceCtx.offers[buyIndex].price })
    // .on('transactionHash', (hash) => {
    //   marketplaceCtx.setMktIsLoading(true);
    // })
    // .on('error', (error) => {
    //   window.alert('Something went wrong when pushing a Offer Request to the blockchain');
    //   marketplaceCtx.setMktIsLoading(false);
    // });            
  };

  const cancelHandler = (event) => {    
    // const cancelIndex = parseInt(event.target.value);
    // marketplaceCtx.contract.methods.cancelOffer(marketplaceCtx.offers[cancelIndex].offerId).send({ from: web3Ctx.account })
    // .on('transactionHash', (hash) => {
    //   marketplaceCtx.setMktIsLoading(true);
    // })
    // .on('error', (error) => {
    //   window.alert('Something went wrong when pushing to the blockchain');
    //   marketplaceCtx.setMktIsLoading(false);
    // });    
  };
 
  //console.log("collectionCtx.collection:"); console.log(collectionCtx.collection);
  var iCount = 0;

  return(
    <div className="row text-center">
      { 
        collectionCtx.collection.map((NFT, key) => {
        if(iCount++>=10)  return;
          //console.log(key);          console.log(NFT);
        const index = marketplaceCtx.offers ? marketplaceCtx.offers.findIndex(offer => offer.id === NFT.id) : -1;
        const owner = index === -1 ? NFT.owner : marketplaceCtx.offers[index].user;
        const price = index !== -1 ? formatPrice(marketplaceCtx.offers[index].price).toFixed(2) : null;

        return(
          <div key={key} className="col-md-2 m-3 pb-3 card border-info">
            <div className={"card-body"}>       
              <h5 className="card-title">{NFT.title}</h5>
            </div>
            <img src={`https://ipfs.infura.io/ipfs/${NFT.img}`} className="card-img-bottom" alt={`NFT ${key}`} />
            <p className="fw-light fs-6">{`${owner.substr(0,7)}...${owner.substr(owner.length - 7)}`}</p>
            {index !== -1 ?
              owner !== web3Ctx.account ?
                <div className="row">
                  <div className="d-grid gap-2 col-5 mx-auto">
                    <button onClick={AcceptLendHandler} value={index} className="btn btn-success">Accept Lending</button>
                  </div>
                  <div className="col-7 d-flex justify-content-end">
                    <img src={eth} width="25" height="25" className="align-center float-start" alt="price icon"></img>                
                    <p className="text-start"><b>{`${price}`}</b></p>
                  </div>
                </div> :
                <div className="row">
                  <div className="d-grid gap-2 col-5 mx-auto">
                    <button onClick={cancelHandler} value={index} className="btn btn-danger">CANCEL</button>
                  </div>
                  <div className="col-7 d-flex justify-content-end">
                    <img src={eth} width="25" height="25" className="align-center float-start" alt="price icon"></img>                
                    <p className="text-start"><b>{`${price}`}</b></p>
                  </div>
                </div> :
              owner === web3Ctx.account ?              
                <form className="row g-2" onSubmit={(e) => OfferCollateralHandler(e, NFT.id, key, owner, price)}>                
                  <div className="col-5 d-grid gap-2">
                    <button type="submit" className="btn btn-secondary">Collateral</button>
                  </div>
                  <div className="col-7">
                    <input
                      type="number"
                      step="0.01"
                      placeholder="ETH..."
                      className="form-control"
                      ref={priceRefs.current[key]}
                    />
                  </div>                                  
                </form> :
                <p><br/></p>}
          </div>
        );
      })}
    </div>
  );
};

export default LoanCollection;