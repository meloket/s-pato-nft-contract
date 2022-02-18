// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
//import "./ERC721/token/ERC20/ERC20.sol";
// import "@nomiclab/builder/console.sol";


contract PersonalLoanNFTCollateral is ERC20 {   //ERC20

    uint256 interestAmountETH_val = 0.002 ether;
    address payable public lenderAddress;
    address payable public borrowerAddress;
    address public contractAddress;

    struct Terms {
        uint totalLoanAmountETH;
        uint interestAmountETH;
        uint repayByTimestamp;
        uint collateralAmountNFT;
    }
    Terms public terms;

    // There are 5 states this contract can be in: Created, Funded, Taken, Repayed, Liquidated.
        // Only 3 are listed as the latter 2 will result in the termination of the contract.
    enum LoanState {
        Created, Funded, Taken
    }
    LoanState public state;

    modifier onlyInState(LoanState expectedState) {
        require(state == expectedState,
        "Not allowed: This function can only be performed in a different contract state."
        );
        _;
    }


    // // added contruct by josh
    constructor(
        // string memory name,
        // string memory symbol,
        uint256 initialSupply
    ) public ERC20("name", "symbol") {
        // _mint(msg.sender, initialSupply);


        terms = Terms(initialSupply, interestAmountETH_val, block.timestamp, initialSupply);
        contractAddress = address(this);
        lenderAddress = payable(msg.sender); //msg.sender;
        state = LoanState.Created;
        // console.log(LoanState);
    }

    // added contruct by josh
    // constructor(Terms memory _terms, address _contractAddress) public {
    //     terms = _terms;
    //     contractAddress =  _contractAddress ;
    //     lenderAddress = payable(msg.sender); //msg.sender;
    //     state = LoanState.Created;
    // }
    
    
    // constructor(uint totalLoanAmountETH, uint collateralAmountNFT, address _contractAddress) public {
    //     terms = Terms(totalLoanAmountETH, interestAmountETH_val, block.timestamp, collateralAmountNFT);
    //     contractAddress =  _contractAddress ;
    //     lenderAddress = payable(msg.sender); //msg.sender;
    //     state = LoanState.Created;
    // }


    function fundLoan() public onlyInState(LoanState.Created) {
        state = LoanState.Funded;
        ERC20(contractAddress).transferFrom(
            payable(msg.sender), //msg.sender,
            address(this),
            terms.totalLoanAmountETH
        ); 
        // external returns (bool);
    }

    function takeLoanAndAcceptTerms() public payable onlyInState(LoanState.Funded) {
        require(msg.value == terms.collateralAmountNFT, 
        "Invalid collateral amount. Please match to the agreed upon terms."
        );
        borrowerAddress = payable(msg.sender); //msg.sender;
        state = LoanState.Taken;
        ERC20(contractAddress).transfer(
            borrowerAddress,
            terms.totalLoanAmountETH
        );
        // external returns (bool);
    }

    function repayLoan() public onlyInState(LoanState.Taken) {
        require(payable(msg.sender) == borrowerAddress,
        "Only the borrower can repay this loan and collect their collateral."
        );
        ERC20(contractAddress).transferFrom(
            borrowerAddress,
            lenderAddress,
            terms.totalLoanAmountETH
        );
        // external returns (bool);
        // Sends collateral back to borrower and fulfills (destroys) the contract.
        selfdestruct(borrowerAddress);
    }

    function liquidateLoan() public onlyInState(LoanState.Taken) {
        require(payable(msg.sender) == lenderAddress,
        "Only the lender can liquidate this loan and collect the collateral."
        );
        require(block.timestamp > terms.repayByTimestamp,
        "You cannot liquidate this loan until the repayment due date has passed."
        );
        // Sends collateral to lender and liquidates (destroys) the contract.
        selfdestruct(lenderAddress);
    }
    fallback () external {
        revert();
    }

}