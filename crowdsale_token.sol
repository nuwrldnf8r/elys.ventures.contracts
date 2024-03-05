// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CrowdsaleToken is ERC721Enumerable, Ownable{
    string private _metadata;
    uint256 private _currentTokenId = 1;

    mapping (uint256 => uint256) private _timeStampMap;
    mapping (uint256 => bool) private _canTransfer;

    constructor(string memory metadata) ERC721("TOA Crowdsale Token", "TOAReceipt") Ownable(msg.sender) {
        _metadata = metadata;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory){
        _requireOwned(tokenId);
        return string(abi.encodePacked(_metadata));
    }

    function mint(address to) public{
        require(_msgSender()==owner(),"Unauthorized");
        _canTransfer[_currentTokenId] = true;
        _safeMint(to,_currentTokenId);
        _timeStampMap[_currentTokenId] = block.timestamp;
        _canTransfer[_currentTokenId] = false;
        _currentTokenId++;
    } 

    function timestamp(uint256 tokenId) public view returns (uint256){
        _requireOwned(tokenId);
        return _timeStampMap[tokenId];
    }

    function setLock(uint256 tokenId, bool lock) public{
        _requireOwned(tokenId);
        require(ownerOf(tokenId)==_msgSender(),"Unauthorized");
        _canTransfer[tokenId] = lock;
    }

    function burn(uint256 tokenId) public onlyOwner{
       _canTransfer[tokenId] = true;
        _burn(tokenId);
    }

    function _update(address to, uint256 tokenId, address auth) internal override returns (address){
        require(_canTransfer[tokenId],"Token is locked");        
        return super._update(to, tokenId, auth);
    }

    function updateMetadata(string memory metadata) public onlyOwner{
        _metadata = metadata;
    }

}