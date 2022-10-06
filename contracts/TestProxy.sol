//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract TestProxyContract is Ownable {

    constructor() {}

    struct PairSwapSpecific {
        address pair;
        uint256[] nftIds;
    }

    function testFunction(
        PairSwapSpecific[] calldata swapList,
        address payable ethRecipient,
        address nftRecipient,
        uint256 deadline
    ) payable external returns (uint256) {
        uint256 remValue = _address.call{value: msg.value}(abi.encodedWithSignature("swapETHForSpecificNFTs(PairSwapSpecific[], address, address, uint256))", swapList, ethRecipient, nftRecipient, deadline));
        return remValue;
    }
}