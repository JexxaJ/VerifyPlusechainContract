// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract FluffySlippersEdition0 is ERC20, ERC20Burnable {
    constructor() ERC20("Fluffy Slippers Edition 0", "FLUFFY") {
        _mint(msg.sender, 500 * 10 ** decimals());
    }
}
