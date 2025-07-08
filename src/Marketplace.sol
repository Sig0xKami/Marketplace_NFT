// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;
 import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
 import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";


contract Marketplace{
  IERC20 public token;
  constructor(address _tokenAddress){
    token = IERC20(_tokenAddress);
  }
  struct Listing {
    address owner;
    address nftContract;
    uint256 tokenId;
    uint256 price;
  }
   mapping(uint256 => Listing) public listings;
    
   function PublishNFT(address _nftContract, uint256 _tokenId, uint256 _price) public {
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
    // Check if the NFT is listed for sale
    require(_tokenId > 0, "Invalid token ID");
    // Listing hace referencia al NFT que se quiere comprar
    Listing memory l = listings[_tokenId];
    // Verificamos que el NFT esté listado
    require(l.price > 0, "NFT is not for sale");
    // Verificamos que el comprador tenga suficiente saldo
    require(l.owner != msg.sender, "You cannot buy your own NFT");
    
    // Verificamos que el comprador tenga suficiente saldo en el token
    // El allowance es la cantidad de tokens que el comprador ha aprobado para que el contrato los mueva
    uint256 allowance = token.allowance(msg.sender, address(this));
    require(allowance >= l.price, "Insufficient allowance");

    // Hacemos la transferencia del token al owner del NFT
    bool sent = token.transferFrom(msg.sender, l.owner, l.price);
    require(sent, "Token transfer failed");



    // IERC721(l.nftContract).safeTransferFrom(address(this), msg.sender, _tokenId); produccion 
    IERC721(l.nftContract).transferFrom(address(this), msg.sender, _tokenId);//test
    delete listings[_tokenId];
   }
}