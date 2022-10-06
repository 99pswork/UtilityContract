//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

enum PoolType {
        TOKEN,
        NFT,
        TRADE
    }

interface proxyContract {
    function assetRecipient() external view returns (address); 
    function bondingCurve() external view returns (address); 
    function delta() external view returns (uint256); 
    function factory() external view returns (address); 
    function fee() external view returns (uint256); 
    function getAllHeldIds() external view returns (uint256[] memory);
    function getAssetRecipient() external view returns (address payable); 
    function nft() external view returns (address); 
    function owner() external view returns (address); 
    function pairVariant() external view returns (uint256); 
    function poolType() external view returns (PoolType);
    function spotPrice() external view returns (uint256);
}

contract ReadProxyContract {

    struct TempContract { 
        address assetRec;
        address bondingCurve;
        uint256 delta;
        address factory;
        uint256 fee;
        uint256[] getAllHeldIds;
        address payable getAssetRec;
        address nft;
        address owner;
        uint256 pairVariant;
        PoolType poolType;
        uint256 spotPrice;
    }

    constructor() {}

    function readProxyContract(address _contractAddress) view public returns (TempContract memory) {
        TempContract memory tempContract;
        tempContract.assetRec = proxyContract(_contractAddress).assetRecipient();
        tempContract.bondingCurve = proxyContract(_contractAddress).bondingCurve();
        tempContract.delta = proxyContract(_contractAddress).delta();
        tempContract.factory = proxyContract(_contractAddress).factory();
        tempContract.fee = proxyContract(_contractAddress).fee();
        tempContract.getAllHeldIds = proxyContract(_contractAddress).getAllHeldIds();
        // tempContract.getAssetRec = proxyContract(_contractAddress).getAssetRecipient();
        tempContract.nft = proxyContract(_contractAddress).nft();
        tempContract.owner = proxyContract(_contractAddress).owner();
        tempContract.pairVariant = proxyContract(_contractAddress).pairVariant();
        // tempContract.poolType = proxyContract(_contractAddress).poolType();
        tempContract.spotPrice = proxyContract(_contractAddress).spotPrice();
        return (tempContract);
    }

    function testPool(address _address) public view returns (PoolType) {
        return proxyContract(_address).poolType();
    }

    function testAssetRec(address _address) public view returns (address) {
        return proxyContract(_address).getAssetRecipient();
    }
}