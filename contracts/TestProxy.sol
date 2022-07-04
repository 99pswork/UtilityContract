//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract TestProxyContract is Ownable {

    constructor() {}

    function testFunction(address _address, bytes memory _tradeData) payable external returns (bool) {
        (bool result,) = _address.call{value:msg.value}(_tradeData);
        return result;
    }
}