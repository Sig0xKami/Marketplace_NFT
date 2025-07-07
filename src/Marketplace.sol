// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;
 import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";



contract Marketplace{
  struct Listing {
    address owner;
    address nftContract;
    uint256 tokenId;
    uint256 price;
  }
   mapping(uint256 => Listing) public listings;

   function PulishNFT(address _nftContract, uint256 _tokenId, uint256 _price) public {
         require(_price > 0, "Price must be greater than zero");
         IERC721 nftContract = IERC721(_nftContract);
         require(nftContract.ownerOf(_tokenId) == msg.sender, "You are not the owner of this NFT");
         nftContract.transferFrom(msg.sender, address(this), _tokenId);
         
         listings[_tokenId] = Listing({
              owner: msg.sender,
              nftContract: _nftContract,
              tokenId: _tokenId,
              price: _price
         });
   }
   function buyNFT(uint256 _tokenId) public payable {
     Listing memory l = listings[_tokenId];
     // Verificamos que el NFT este en venta
     //Como el precio es mayor a 0, significa que esta en venta
     require(l.price > 0, "NFT is not for sale");
      // Verificamos que el comprador envie el precio correcto
      require(msg.value == l.price, "Incorrect price sent");
      // Verificamos que el vendedor sea diferente al comprador 
      require(l.owner != msg.sender, "You cannot buy your own NFT");
      
       
       
      // Transferimos el NFT al comprador
      IERC721(l.nftContract).safeTransferFrom(address(this), msg.sender, _tokenId);
      //Transferimos el dinero al vendedor
      payable(l.owner).transfer(msg.value);
      // Eliminamos el NFT de la lista de ventas
      delete listings[_tokenId];
   }
}