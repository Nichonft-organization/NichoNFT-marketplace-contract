// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Nicho is ERC20, Ownable {
    constructor(uint256 initialSupply) ERC20("Nicho", "Nicho") {
        _mint(msg.sender, initialSupply);
    }
}