//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


interface NFTAddress {
    function tokenURI(uint256) external view returns (string memory);
    function uri(uint256) external view returns (string memory);
}

interface TokenBalance {
    function balanceOf(address) external view returns (uint256); 
}

interface OpenSea {
    function getOrderStatus(bytes32 orderHash) external view returns (
        bool, bool, uint256, uint256);
}

interface LooksRare {
    function isUserOrderNonceExecutedOrCancelled(address, uint256) external view returns (bool);
}

interface X2Y2 {
    function inventoryStatus(bytes32) external view returns (uint8);
}

interface NFTBalance {
    function balanceOf(address) external view returns (uint256);
    function ownerOf(uint256) external view returns (address); 
}

interface ERC1155 {
    function balanceOf(address, uint256) external view returns (uint256);
}

contract UtilityContract is Ownable {

    address private _weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // mainnet
    address private _usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // mainnet
    address private _usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7; // mainnet

    // address private _usdt = 0x3B00Ef435fA4FcFF5C209a37d1f3dcff37c705aD; // Rinkeby
    // address private _usdc = 0xeb8f08a975Ab53E34D8a0330E0D34de942C95926; // Rinkeby 
    // address private _weth = 0xc778417E063141139Fce010982780140Aa0cD5Ab; // Rinkeby

    address public openseaAddress = 0x00000000006c3852cbEf3e08E8dF289169EdE581; // Mainnet
    address public looksRareAddress = 0x59728544B08AB483533076417FbBB2fD0B17CE3a; // Mainnet 
    address public x2y2Address = 0x74312363e45DCaBA76c59ec49a7Aa8A65a67EeD3; // Mainnet
    
    struct tokenBalances {
        uint256 ETH;
        uint256 WETH;
        uint256 USDC;
        uint256 USDT;
    }

    struct OrderStatus {
        bool isValidated;
        bool isCancelled;
        uint256 totalFilled;
        uint256 totalSize;
    }

    struct BluechipContract {
        address _address;
        string _name;
        string _image;
    } 

    BluechipContract[] public bluechipAddress;

    mapping (address => BluechipContract) public getBluechipContract;

    constructor() {}

    function updateOpenSeaAddress(address _address) external onlyOwner {
        openseaAddress = _address;
    }

    function updateLooksRareAddress(address _address) external onlyOwner {
        looksRareAddress = _address;
    }

    function updateX2Y2Address(address _address) external onlyOwner {
        x2y2Address = _address;
    }

    function updateTokenAddress(address _wethAddress, address _usdcAddress, address _usdtAddress) external onlyOwner {
        _weth = _wethAddress;
        _usdc = _usdcAddress;
        _usdt = _usdtAddress;
    }

    function getTokenUri(address _address, uint256[] memory _tokenID) public view returns (string[] memory) {
        string[] memory listOfTokenURI = new string[](_tokenID.length);
        for(uint256 i=0; i<_tokenID.length; i++){
            try NFTAddress(_address).tokenURI(_tokenID[i]) {
                listOfTokenURI[i] =  NFTAddress(_address).tokenURI(_tokenID[i]);
            }
            catch {
                try NFTAddress(_address).uri(_tokenID[i]) {
                    listOfTokenURI[i] = NFTAddress(_address).uri(_tokenID[i]);
                }
                catch {
                    listOfTokenURI[i] = "Error in Token";
                }
            }
        }
        return listOfTokenURI; 
    }

    function addBluechipAddress(address[] memory _address, string[] memory _name, string[] memory _image) external onlyOwner {
        require(_address.length == _name.length, "Array length not equal");
        require(_image.length == _name.length, "Array length not equal");
        for(uint256 i=0; i<_address.length; i++){
            require(getBluechipContract[_address[i]]._address == address(0), "Address Already Exists");
            BluechipContract memory _bluechipContract;
            _bluechipContract._address = _address[i];
            _bluechipContract._name = _name[i];
            _bluechipContract._image = _image[i];
            getBluechipContract[_address[i]] = _bluechipContract;
            bluechipAddress.push(_bluechipContract);
        }
    }

    function removeBluechipAddress(address _address) external onlyOwner {
        require(getBluechipContract[_address]._address != address(0), "Address Does Not Exists");
        uint256 index = 0;
        bool flag = false;
        for(uint256 i=0; i<bluechipAddress.length; i++)
        {
            if(bluechipAddress[i]._address == _address){
                index = i;
                flag = true;
                BluechipContract storage _BluechipContract = getBluechipContract[_address];
                _BluechipContract._address = address(0);
                _BluechipContract._image = "";
                _BluechipContract._name = "";
                getBluechipContract[_address] = _BluechipContract;
            }
        }
        if(flag)
        {
            bluechipAddress[index] = bluechipAddress[bluechipAddress.length -1];
            bluechipAddress.pop();
        }
    }

    function getTokenBalances(address _address) public view returns (tokenBalances memory) {
        tokenBalances memory _tokenBalance;
        _tokenBalance.ETH = address(_address).balance;
        _tokenBalance.WETH = TokenBalance(_weth).balanceOf(_address);
        _tokenBalance.USDC = TokenBalance(_usdc).balanceOf(_address);
        _tokenBalance.USDT = TokenBalance(_usdt).balanceOf(_address);
        return _tokenBalance;
    }

    function getNFTBalances(address _address, address _contractAddress) public view returns (BluechipContract[] memory, uint256[] memory, uint256) {
        uint256[] memory nftBalances = new uint256[](bluechipAddress.length);
        for(uint256 i=0; i<bluechipAddress.length; i++){
            nftBalances[i] = NFTBalance(bluechipAddress[i]._address).balanceOf(_address);
        }
        uint256 _contractNFTBalance =  NFTBalance(_contractAddress).balanceOf(_address);
        return (bluechipAddress, nftBalances, _contractNFTBalance);
    }

    function getUserData(address _address, address _contractAddress) external view returns (tokenBalances memory, BluechipContract[] memory, uint256[] memory, uint256) {
        uint256[] memory nftBalances = new uint256[](bluechipAddress.length);
        uint256 _contractNFTBalance;
        (,nftBalances,_contractNFTBalance) = getNFTBalances(_address, _contractAddress);
        return (getTokenBalances(_address),bluechipAddress,nftBalances,_contractNFTBalance);
    }

    function getOrderStatus(bytes32 _orderHash) public view returns (OrderStatus memory) {
        OrderStatus memory orderStatus; 
        (orderStatus.isValidated,orderStatus.isCancelled, orderStatus.totalFilled, orderStatus.totalSize) = OpenSea(openseaAddress).getOrderStatus(_orderHash);
        return orderStatus;
    }

    function getMultipleOrderStatus(bytes32[] memory _orderHash) public view returns (OrderStatus[] memory){
        OrderStatus[] memory orderStatus = new OrderStatus[](_orderHash.length);
        for(uint256 i=0; i<_orderHash.length; i++){
            orderStatus[i] = getOrderStatus(_orderHash[i]);
        } 
        return orderStatus;
    }

    function getUserOrderNonceExecutedOrCancelled(address _address, uint256 _orderNonce) public view returns (bool) {
        return LooksRare(looksRareAddress).isUserOrderNonceExecutedOrCancelled(_address, _orderNonce);
    }

    function getMultipleUserOrderNonce(address[] memory _address, uint256[] memory _orderNonce) public view returns (bool[] memory) {
        require(_address.length == _orderNonce.length, "Length of Array's Passed not equal");
        bool[] memory status = new bool[](_address.length);
        for(uint256 i=0; i<_address.length; i++) {
            status[i] = getUserOrderNonceExecutedOrCancelled(_address[i], _orderNonce[i]);
        }
        return status;
    }

    function getInventoryStatusX2Y2(bytes32 _bytes) public view returns (uint8) {
        return X2Y2(x2y2Address).inventoryStatus(_bytes);
    }

    function getMultipleInventoryStatusX2Y2(bytes32[] memory _bytes) public view returns (uint8[] memory) {
        uint8[] memory _int8 = new uint8[](_bytes.length);
        for(uint256 i=0; i<_bytes.length; i++) {
            _int8[i] = getInventoryStatusX2Y2(_bytes[i]);
        }
        return _int8;
    }

    function getAllMarketData(bytes32[] memory _seaportBytes, address[] memory _looksrareAddress, uint256[] memory _looksRareOrderNonce, bytes32[] memory _x2y2Bytes) 
    external view returns (OrderStatus[] memory, bool[] memory, uint8[] memory) {
        require(_looksrareAddress.length == _looksRareOrderNonce.length, "Length should be equal");
        // OrderStatus[] memory seaPortOrder = new OrderStatus[](_seaportBytes.length);
        OrderStatus[] memory seaportOrder = getMultipleOrderStatus(_seaportBytes);
        bool[] memory looksrareStatus = getMultipleUserOrderNonce(_looksrareAddress, _looksRareOrderNonce);
        uint8[] memory _x2y2Int8 = getMultipleInventoryStatusX2Y2(_x2y2Bytes);
        return (seaportOrder, looksrareStatus, _x2y2Int8);
    }

    function getERC721Balance(address[] memory _address, address _contractAddress) public view returns (uint256[] memory) {
        uint256[] memory _balanceERC721 = new uint256[](_address.length);
        for(uint256 i=0; i < _address.length; i++) {
            _balanceERC721[i] = NFTBalance(_contractAddress).balanceOf(_address[i]);
        }
        return _balanceERC721;
    }

    function getERC721Owner(uint256[] memory _tokenId, address _contractAddress) public view returns (address[] memory) {
        address[] memory _addressERC721 = new address[](_tokenId.length);
        for(uint256 i=0; i < _tokenId.length; i++) {
            _addressERC721[i] = NFTBalance(_contractAddress).ownerOf(_tokenId[i]);
        }
        return _addressERC721;
    }

    function getERC1155Balance(address[] memory _address, uint256[] memory _tokenId, address _contractAddress) public view returns (uint256[] memory) {
        require(_address.length == _tokenId.length, "Length Should be equal");
        uint256[] memory _balanceERC1155 = new uint256[](_address.length);
        for(uint256 i=0; i < _address.length; i++) {
            _balanceERC1155[i] = ERC1155(_contractAddress).balanceOf(_address[i],_tokenId[i]);
        }
        return _balanceERC1155;
    }

}