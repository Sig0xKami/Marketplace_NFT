// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../src/Marketplace.sol";

contract DeployMarketplace is Script {
    function run() external {
        vm.startBroadcast();

        //Dirección del token ERC20 ya desplegado en Sepolia
        address mkt = 0x2755256acA141AC049d9BabDfd236d9C56fac39b;
        //Desplegar el contrato Marketplace con el token como parámetro
        Marketplace marketplace = new Marketplace(mkt);
        // ✅ Log de la address desplegada del contrato Marketplace
        console.log("Marketplace deployed at:", address(marketplace));

        vm.stopBroadcast();
        // broadcast es el comando que se usa para desplegar el contrato en la red
        // forge script script/DeployMarketplace.s.sol --broadcast --rpc-url https://sepolia.infura.io/v3/tu_project_id --private-key 0xTU_LLAVE_PRIVADA
        // Reemplaza "tu_project_id" y "TU_LLAVE_PRIVADA"
        // Si no tenés un token ERC20, podés usar el de la clase
    }
}