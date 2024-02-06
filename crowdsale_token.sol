// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CrowdsaleToken is ERC721Enumerable, Ownable{
    string private _metadata;
    uint256 private _currentTokenId = 1;

    constructor(string memory metadata) ERC721("TOA Crowdsale Token", "TOAReceipt") Ownable(msg.sender) {
        _metadata = metadata;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory){
        _requireOwned(tokenId);
        return string(abi.encodePacked("ipfs://", _metadata));
    }

    function mint(address to) public{
        require(_msgSender()==owner(),"Unauthorized");
        _safeMint(to,_currentTokenId);
        _currentTokenId++;
    } 

    function burn(uint256 tokenId) public onlyOwner{
        _burn(tokenId);
    }

}