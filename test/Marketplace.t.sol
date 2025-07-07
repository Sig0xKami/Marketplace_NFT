// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;
import "forge-std/Test.sol";
import "../src/Marketplace.sol";
import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

contract TestNFT is ERC721 {
    constructor() ERC721("TestNFT", "TNFT") {}

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }

    function approve(address to, uint256 tokenId) public virtual override {
        super.approve(to, tokenId);
    }
    
}
contract MarketplaceTest is Test{
    Marketplace public marketplace;
    TestNFT public nft;
    address public user;
    address public buyer;
   // Lo que hace este test es crear un contrato de Marketplace y luego probar que se puede publicar un NFT en el mercado.
    function setUp() public {
        marketplace = new Marketplace();
        nft = new TestNFT();
        user = address(0x123); // Simulate a user address
        buyer = address(0x456); // Simulate a buyer address
        //Mintiamos un nft para el usuario
        // Mint desde el contexto del user para que sea realmente el owner
        vm.prank(user);
        nft.mint(user, 1);
    }

    //Probar que se pueda publicar un NFT en el mercado
    function testPublishNFT() public {
      //Cambiar contexto a "user"
        vm.prank(user);
 
      //User aprueba el marketplace para mover su NFT 
      nft.approve(address(marketplace), 1);
      //  approve = hace que el marketplace pueda mover el NFT del usuario 
      // to(es donde se transfiere) es el contrato del marketplace
      // tokenId es el id del NFT que se quiere mover

      //user lista NFT 
      vm.prank(user);
      marketplace.PulishNFT(address(nft), 1, 1 ether);
      // verificamos que se guardo correctamente
      (address owner, address nftContract, uint256 tokenId, uint256 price) = marketplace.listings(1);
      assertEq(owner, user);
      assertEq(price, 1 ether);
    }

    // Probar que se pueda comprar un NFT en el mercado
    // Verificamos que el comprador pueda comprar un NFT publicado en el mercado
    // Verificamos que el NFT se transfiera al comprador y que el vendedor reciba el dinero
    // Verificamos que el NFT se elimine de la lista de ventas
    // Verificamos que el comprador no pueda comprar su propio NFT
    // Verificamos que el comprador no pueda comprar un NFT que no esta en venta
    // Verificamos que el comprador no pueda comprar un NFT por un precio incorrecto
    // Verificamos que el comprador no pueda comprar un NFT que no existe
    function testBuyNFT() public {
        // 1 Preparar el `escenario: dar Ether al buyer
        vm.deal(buyer, 1 ether);
        //Aprueba  // el marketplace para que pueda mover el NFT del user
        // 1. El user aprueba el marketplace para mover su NFT
        // Cambiamos el contexto a user para simular que el user llama a la función
        // approve del NFT
        // Esto es necesario para que el marketplace pueda transferir el NFT del user al buyer
        vm.prank(user);
        nft.approve(address(marketplace), 1);
        // 2. El user publica el NFT (lo pone en venta)
        vm.prank(user);
        marketplace.PulishNFT(address(nft), 1, 1 ether);

        // 3. Verificamos que la publicación se guardó correctamente
        (address owner, address nftContract, uint256 tokenId, uint256 price) = marketplace.listings(1);
        assertEq(price, 1 ether);
        assertEq(owner, user);
        // 4. El buyer compra el NFT
        vm.prank(buyer);
        
        // Cambiamos el contexto a buyer para simular que el buyer llama a la función buyNFT
        marketplace.buyNFT{value: 1 ether}(1);
        //enviamos un ether junto el id del NFT que se quiere comprar
         
        //  5. Verificamos que el NFT se transfirió al buyer
        assertEq(nft.ownerOf(1), buyer);
        // 6. Verificamos que el dinero se transfirió al user
        (address ownerAfter, , , uint256 priceAfter) = marketplace.listings(1);
        assertEq(ownerAfter, address(0)); // El NFT ya no está en venta
        assertEq(priceAfter, 0); // El precio debe ser 0 porque ya se

        // 7. Verificamos que el NFT se eliminó de la lista de ventas
        assertEq(user.balance, 1 ether); // El user debe tener el dinero de la venta
    }
    //No podés publicar un NFT que no es tuyo
    function testCannotPublishNFTIfNotOwner() public {
    address atacante = address(0x999);
    vm.prank(atacante);
    // Atacante intenta publicar un NFT que no posee
    vm.expectRevert("You are not the owner of this NFT");
    marketplace.PulishNFT(address(nft), 1, 1 ether);
}
   //No podés comprar tu propio NFT
    function testCannotBuyOwnNFT() public {
        vm.prank(user);
        nft.approve(address(marketplace), 1);

        vm.prank(user);
        marketplace.PulishNFT(address(nft), 1, 1 ether);

        vm.deal(user, 1 ether);

        vm.prank(user);
        vm.expectRevert("You cannot buy your own NFT");
        marketplace.buyNFT{value: 1 ether}(1);
    }
    //No podés comprar un NFT que no esta en la venta 
    function testCannotBuyNFTNotForSale() public {
        vm.deal(buyer, 1 ether);
        vm.prank(buyer);
        // El buyer intenta comprar un NFT que no está en venta
        vm.expectRevert("NFT is not for sale");
        marketplace.buyNFT(1);
    }
    //No podes comprar un NFT si mandas menos Ether del precio
    function testCannotWithIncorrectPrice() public {
        vm.prank(user);
        nft.approve(address(marketplace), 1);

        vm.prank(user);
        marketplace.PulishNFT(address(nft), 1 , 1 ether);

        vm.deal(buyer, 0.5 ether);
        vm.prank(buyer);
        //Tenes que decirle antes al vm que esperas un revert
        vm.expectRevert("Incorrect price sent");
        marketplace.buyNFT{value: 0.5 ether}(1);
    }


} 
