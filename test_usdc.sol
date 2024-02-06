// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract USDCTest is ERC20 {
    uint8 private _decimals = 6;
    
    constructor() ERC20("USDC Test", "USDC") {
        
    }
    
    function mint(address to, uint256 amount) public {
        _mint(to,amount);
    }

    function decimals() public override view returns (uint8){
         return _decimals;
    }
}