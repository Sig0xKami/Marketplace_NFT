// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;
import "forge-std/Test.sol";
import "../src/Marketplace.sol";
import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
contract TestNFT is ERC721 {
    constructor() ERC721("TestNFT", "TNFT") {}

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }

    function approve(address to, uint256 tokenId) public virtual override {
        super.approve(to, tokenId);
    }
}

contract MockERC20 is ERC20 {
    constructor(address to, uint256 _much) ERC20("Mock Token", "MKT") {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount * 10 **  decimals());
    }
}
contract MarketplaceTest is Test{
    // uint256 priceNFT = 1 * 10 ** 18;// 1 es el precio del NFT en Ether. priceNFT es el precio en wei;
    Marketplace public marketplace;
    MockERC20 public token;
    TestNFT public nft;
    address public user;
    address public buyer;
   // Lo que hace este test es crear un contrato de Marketplace y luego probar que se puede publicar un NFT en el mercado.
    function setUp() public {
        
        nft = new TestNFT();
        token = new MockERC20(buyer, 1000);// Simulamos supplay de 1000 tokens para el buyer
        marketplace = new Marketplace(address(token));
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
      uint256 priceNFT = 100 * 1e18;
      //user lista NFT 
      vm.prank(user);
       
      marketplace.PublishNFT(address(nft), 1, priceNFT);
      // verificamos que se guardo correctamente
      (address owner, address nftContract, uint256 tokenId, uint256 price) = marketplace.listings(1);
      assertEq(owner, user);
      assertEq(price, priceNFT);
      // Verificamos que el contrato del NFT sea el mismo que el del NFT de prueba
      assertEq(nftContract, address(nft));
      assertEq(tokenId, 1); // El tokenId debe ser 1
      // Verificamos que el NFT se haya transferido al marketplace
      assertEq(nft.ownerOf(1), address(marketplace));
      //owner of es la dirección que posee el NFT
        // En este caso, el owner del NFT es el marketplace porque el user lo puso en venta
        // El NFT se transfiere al marketplace cuando se publica
    }

    
    function testBuyNFT() public {
        // 1 Preparar el `escenario: dar Ether al buyer
        //Aprueba  // el marketplace para que pueda mover el NFT del user
        // 1. El user aprueba el marketplace para mover su NFT
        // Cambiamos el contexto a user para simular que el user llama a la función
        // approve del NFT
        // Esto es necesario para que el marketplace pueda transferir el NFT del user al buyer
        vm.prank(user);
        nft.approve(address(marketplace), 1);
        // 2. El user publica el NFT (lo pone en venta)
        
        uint256 priceNFT = 100 * 1e18; // El precio del NFT  100 MKT
        vm.prank(user);
        //1 es el precio del NFT en Ether. priceNFT es el precio en wei
        marketplace.PublishNFT(address(nft), 1, priceNFT);

        // 3. Verificamos que la publicación se guardó correctamente
        (address owner, address nftContract, uint256 tokenId, uint256 price) = marketplace.listings(1);
        assertEq(price, priceNFT); // El precio debe ser 100 ether
        assertEq(nftContract, address(nft)); // El contrato del NFT debe ser el mismo que el del NFT de prueba
        assertEq(tokenId, 1); // El tokenId debe ser 1
        // Verificamos que el owner sea el user
        // Esto significa que el NFT está en venta y el owner es el user
        assertEq(owner, user);
        // 4. El buyer compra el NFT
        token.mint(buyer, 500 * 1e18);
        vm.prank(buyer);
        token.approve(address(marketplace), 100 * 1e18 ); //El buyer aprueba el marketplace para mover sus tokens 
        
        // Cambiamos el contexto a buyer para simular que el buyer llama a la función buyNFT
        vm.prank(buyer);
        marketplace.buyNFT(1);
        
         
        //  5. Verificamos que el NFT se transfirió al buyer
        assertEq(nft.ownerOf(1), buyer);
        // 6. Verificamos que el dinero se transfirió al user
        assertEq(token.balanceOf(user), 100 * 1e18); // ✅ CORRECTO 
        (address ownerAfter ,address nftContractAfter  , uint256 tokenIdAfter , uint256 priceAfter) = marketplace.listings(1);


        assertEq(ownerAfter, address(0)); // El NFT ya no está en venta
        assertEq(nftContractAfter, address(0)); // El contrato del NFT ya no está en venta
        assertEq(tokenIdAfter, 0); // El tokenId ya no está en venta
        assertEq(priceAfter, 0); // El precio debe ser 0 porque ya se
        
        

        // 7. Verificamos que el NFT se eliminó de la lista de ventas
        
    }
   // No podés publicar un NFT que no es tuyo
    function testCannotPublishNFTIfNotOwner() public {
    address atacante = address(0x999);
    vm.prank(atacante);
    uint256 priceNFT = 100 * 10 ** 18; // El precio del NFT  100 MKT
    // Atacante intenta publicar un NFT que no posee
    vm.expectRevert("You are not the owner of this NFT");
    marketplace.PublishNFT(address(nft), 1, priceNFT);
}
   //No podés comprar tu propio NFT
    function testCannotBuyOwnNFT() public {
        vm.prank(user);
        nft.approve(address(marketplace), 1);

        vm.prank(user);
        uint256 priceNFT = 100 * 10 ** 18; // El precio del NFT  100 MKT
        // El user publica su propio NFT en el marketplace
        marketplace.PublishNFT(address(nft), 1, priceNFT);
        vm.prank(user);
        vm.expectRevert("You cannot buy your own NFT");
        marketplace.buyNFT(1);
    }
    //No podés comprar un NFT que no esta en la venta 
    function testCannotBuyNFTNotForSale() public {
        vm.prank(buyer);
        // El buyer intenta comprar un NFT que no está en venta
        vm.expectRevert("NFT is not for sale");
        marketplace.buyNFT(1);
    }
//     //No podes comprar un NFT si mandas menos Ether del precio
    function testCannotWithIncorrectPrice() public {
        vm.prank(user);
        // Le damos permiso al marketplace para mover el NFT del user
        nft.approve(address(marketplace), 1);
        uint256 priceNFT = 100 * 10 ** 18; // El precio del NFT  100 MKT 
        vm.prank(user);
        marketplace.PublishNFT(address(nft), 1, priceNFT);

        //Simulamos que el buyer tiene SOLO 20  MKT
        token.mint(buyer, 20 * 10 ** 18);

        vm.prank(buyer);
        token.approve(address(marketplace), 20 * 10 ** 18); // Solo aprueba 0.5 MKT
        
        vm.prank(buyer);
        vm.expectRevert("Insufficient allowance");
        marketplace.buyNFT(1);
    }
} 
