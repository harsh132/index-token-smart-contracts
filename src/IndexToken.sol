// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract IndexToken is Initializable, ERC20Upgradeable, OwnableUpgradeable, ERC20PermitUpgradeable {
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner) initializer public {
        __ERC20_init("IndexETH", "IETH");
        __Ownable_init(initialOwner);
        __ERC20Permit_init("IndexETH");
    }

    function deposit() public payable {
        uint256 amount = msg.value * totalSupply() / address(this).balance;
        _mint(msg.sender, amount);
    }

    function withdraw(uint256 amount) public {
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        _burn(msg.sender, amount);

        uint256 ethAmount = amount * address(this).balance / totalSupply();
        payable(msg.sender).transfer(ethAmount);
    }
}
