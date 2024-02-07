// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./toa.sol";
import "./crowdsale_token.sol";

interface INFT {
    function mint(address to) external;
    function owner() external view returns (address);
}


interface IToken {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from,address to,uint256 amount) external returns (bool);
}


contract Crowdsale is Ownable{
    TOA private _toaContract;
    CrowdsaleToken private _crowdsaleTokenContract;
    address private _USDC;
    address private _adminAccount;
    uint256 private _adminWithdrawn = 0;

    uint256 private _maxTOAs;
    uint256 private _priceOfTOAs;
    uint256 private _minTOAsSoldThreshold;
    uint256 private _campaignLengthDays;

    uint256 private _startTime;

    constructor(address USDC, uint256 maxTOAs, uint256 priceOfTOAs, uint256 minTOAsSoldThreshold_, uint256 campaignLengthDays, string memory metadata) Ownable(msg.sender){
        _USDC = USDC;
        _maxTOAs = maxTOAs;
        _priceOfTOAs = priceOfTOAs;
        _minTOAsSoldThreshold = minTOAsSoldThreshold_;
        _campaignLengthDays = campaignLengthDays;
        _toaContract = new TOA(metadata);
        _crowdsaleTokenContract = new CrowdsaleToken(metadata);
    }

    function start(address adminAccount) public onlyOwner{
        _adminAccount = adminAccount;
        _startTime = block.timestamp;
    }

    function campaignLength() public view returns (uint256){
        return _campaignLengthDays * (1 days);
    }

    function timeLeft() public view returns (uint256){
        require(_startTime>0,"Campaign hasn't started yet");
        uint256 totalTime =  campaignLength();
        uint256 timePassed = block.timestamp - _startTime;
        if(timePassed>totalTime) return 0;
        return totalTime - timePassed;
    }

    function canPurchase(uint256 toPurchase) public view returns (bool){
        if(_startTime==0) return false;
        uint256 numPurchased = _crowdsaleTokenContract.totalSupply();
        if(timeLeft()==0) return false;
        if(numPurchased + toPurchase<_maxTOAs) return true;
        return false;
    }

    function minTOAsSoldThreshold() public view returns (uint256){
        return _minTOAsSoldThreshold;
    }

    function minSold() public view returns (bool){
        return (_crowdsaleTokenContract.totalSupply()>=_minTOAsSoldThreshold);
    }

    function numSold() public view returns (uint256){
        return _crowdsaleTokenContract.totalSupply();
    }

    function purchase(uint256 toPurchase) public {
        IToken usdcContract = IToken(_USDC);
        uint256 totalValue = toPurchase*_priceOfTOAs;
        require(canPurchase(toPurchase),"Cannot purchase TOAs");
        require(usdcContract.allowance(_msgSender(), address(this))>=totalValue, "Insufficient allowance for transaction");
        require(usdcContract.balanceOf(_msgSender())>=totalValue,"Insufficient balance for transaction");
        usdcContract.transferFrom(_msgSender(), address(this), totalValue);
        for(uint256 i=0;i<toPurchase;i++){
            _crowdsaleTokenContract.mint(_msgSender());
        }
    }

    function USDCBalance() public view returns (uint256){
        if(timeLeft()>0){
            if(!minSold()) return 0;
            if(_msgSender()!=owner() && _msgSender()!=_adminAccount) return 0;
            return numSold() * _priceOfTOAs - _adminWithdrawn;
        } else {
            if(minSold()){
                if(_msgSender()!=owner() && _msgSender()!=_adminAccount) return 0;
                return numSold() * _priceOfTOAs - _adminWithdrawn;
            } else {
                return _priceOfTOAs * _crowdsaleTokenContract.balanceOf(_msgSender());
            }
        }
    }

    function withdrawUSDC() public {
        uint256 balance = USDCBalance();
        require(balance>0,"no USDC to withdraw");
        IToken usdcContract = IToken(_USDC);
        if(_msgSender()==owner() || _msgSender()==_adminAccount){
            _adminWithdrawn += balance;
            usdcContract.transfer(_adminAccount,balance);
        } else {
            uint256 numTokens = _crowdsaleTokenContract.balanceOf(_msgSender());
            uint256[] memory tokenIds = new uint256[](numTokens);
            for(uint256 index=0;index<numTokens;index++){
                tokenIds[index] = _crowdsaleTokenContract.tokenOfOwnerByIndex(_msgSender(), index);
            }
            for(uint256 i=0;i<numTokens;i++){
                _crowdsaleTokenContract.burn(tokenIds[i]);
            }
            usdcContract.transfer(_msgSender(),balance);
        }
    }

    function assignTOAs() public {
        require(minSold(),"The minimum TOAs have to be sold in order to assign TOAs");
        uint256 numTokens = _crowdsaleTokenContract.balanceOf(_msgSender());
            uint256[] memory tokenIds = new uint256[](numTokens);
            for(uint256 index=0;index<numTokens;index++){
                tokenIds[index] = _crowdsaleTokenContract.tokenOfOwnerByIndex(_msgSender(), index);
            }
            for(uint256 i=0;i<numTokens;i++){
                _crowdsaleTokenContract.burn(tokenIds[i]);
                _toaContract.mint(_msgSender());
            }
    }

    function TOAAddress() public view returns (address){
        return address(_toaContract);
    }

    function crowdsaleTokenAddress() public view returns (address){
        return address(_crowdsaleTokenContract);
    }
    
}