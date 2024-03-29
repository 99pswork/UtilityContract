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
    function isApprovedForAll(address account, address operator) external view returns (bool);
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

    struct ListingValidator {
        address ERC721Owner;
        uint256 ERC1155Quantity;
        OrderStatus seaportOrderStatus;
        bool looksRareOrderStatus;
        uint8 x2y2OrderStatus;
        bool IsApprovedForAll;
    }

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

    function getTokenBalances(address _address) public view returns (tokenBalances memory) {
        tokenBalances memory _tokenBalance;
        _tokenBalance.ETH = address(_address).balance;
        _tokenBalance.WETH = TokenBalance(_weth).balanceOf(_address);
        _tokenBalance.USDC = TokenBalance(_usdc).balanceOf(_address);
        _tokenBalance.USDT = TokenBalance(_usdt).balanceOf(_address);
        return _tokenBalance;
    }

    function getUserData(address _address, address[] memory _contractAddress) external view returns (tokenBalances memory, uint256[] memory, bool[] memory) {
        uint256[] memory nftBalances = new uint256[](_contractAddress.length);
        bool[] memory failedTx = new bool[](_contractAddress.length);
        (nftBalances, failedTx) = accessBalanceNFT721(_address, _contractAddress);
        return (getTokenBalances(_address),nftBalances, failedTx);
    }

    function getOrderStatus(bytes32 _orderHash) public view returns (OrderStatus memory, bool) {
        OrderStatus memory orderStatus; 
        bool failedTx;
        try OpenSea(openseaAddress).getOrderStatus(_orderHash) {
            (orderStatus.isValidated,orderStatus.isCancelled, orderStatus.totalFilled, orderStatus.totalSize) = OpenSea(openseaAddress).getOrderStatus(_orderHash);
            failedTx = false;
        }
        catch {
            failedTx = true;
        }
        return (orderStatus,failedTx);
    }

    function getMultipleOrderStatus(bytes32[] memory _orderHash) public view returns (OrderStatus[] memory, bool[] memory){
        OrderStatus[] memory orderStatus = new OrderStatus[](_orderHash.length);
        bool[] memory failedTx = new bool[](_orderHash.length);
        for(uint256 i=0; i<_orderHash.length; i++){
            (orderStatus[i], failedTx[i]) = getOrderStatus(_orderHash[i]);
        } 
        return (orderStatus, failedTx);
    }

    function getUserOrderNonceExecutedOrCancelled(address _address, uint256 _orderNonce) public view returns (bool, bool) {
        bool failedTx;
        bool result;
        try LooksRare(looksRareAddress).isUserOrderNonceExecutedOrCancelled(_address, _orderNonce) {
            result = LooksRare(looksRareAddress).isUserOrderNonceExecutedOrCancelled(_address, _orderNonce);
            failedTx = false;
        }
        catch {
            failedTx = true;
        }
        return (result, failedTx);
    }

    function getMultipleUserOrderNonce(address[] memory _address, uint256[] memory _orderNonce) public view returns (bool[] memory, bool[] memory) {
        require(_address.length == _orderNonce.length, "Length of Array's Passed not equal");
        bool[] memory status = new bool[](_address.length);
        bool[] memory failedTx = new bool[](_address.length);
        for(uint256 i=0; i<_address.length; i++) {
            (status[i], failedTx[i]) = getUserOrderNonceExecutedOrCancelled(_address[i], _orderNonce[i]);
        }
        return (status, failedTx);
    }

    function getInventoryStatusX2Y2(bytes32 _bytes) public view returns (uint8, bool) {
        uint8 result;
        bool failedTx;
        try X2Y2(x2y2Address).inventoryStatus(_bytes) {
            result = X2Y2(x2y2Address).inventoryStatus(_bytes);
            failedTx = false;
        }
        catch {
            failedTx = true;
        }
        return (result, failedTx);
    }

    function getMultipleInventoryStatusX2Y2(bytes32[] memory _bytes) public view returns (uint8[] memory, bool[] memory) {
        uint8[] memory _int8 = new uint8[](_bytes.length);
        bool[] memory failedTx = new bool[](_bytes.length);
        for(uint256 i=0; i<_bytes.length; i++) {
            (_int8[i], failedTx[i]) = getInventoryStatusX2Y2(_bytes[i]);
        }
        return (_int8, failedTx);
    }

    function getAllMarketData(bytes32[] memory _seaportBytes, address[] memory _looksrareAddress, uint256[] memory _looksRareOrderNonce, bytes32[] memory _x2y2Bytes) 
    external view returns (OrderStatus[] memory, bool[] memory, uint8[] memory, bool[] memory, bool[] memory, bool[] memory) {
        require(_looksrareAddress.length == _looksRareOrderNonce.length, "Length should be equal");
        // OrderStatus[] memory seaPortOrder = new OrderStatus[](_seaportBytes.length);
        (OrderStatus[] memory seaportOrder,bool[] memory failedTx1) = getMultipleOrderStatus(_seaportBytes);
        (bool[] memory looksrareStatus, bool[] memory failedTx2) = getMultipleUserOrderNonce(_looksrareAddress, _looksRareOrderNonce);
        (uint8[] memory _x2y2Int8, bool[] memory failedTx3) = getMultipleInventoryStatusX2Y2(_x2y2Bytes);
        return (seaportOrder, looksrareStatus, _x2y2Int8, failedTx1, failedTx2, failedTx3);
    }

    function getERC721Owner(uint256[] memory _tokenId, address _contractAddress) public view returns (address[] memory, bool[] memory) {
        address[] memory _addressERC721 = new address[](_tokenId.length);
        bool[] memory failedTx = new bool[](_tokenId.length);
        for(uint256 i=0; i < _tokenId.length; i++) {
            try NFTBalance(_contractAddress).ownerOf(_tokenId[i]) {
                _addressERC721[i] = NFTBalance(_contractAddress).ownerOf(_tokenId[i]);
                failedTx[i] = false;
            }
            catch {
                failedTx[i] = true;
            }
        }
        return (_addressERC721, failedTx);
    }

    function checkIsApprovedForAll(address _owner, address _operator, address _contract) public view returns (bool, bool) {
        try ERC1155(_contract).isApprovedForAll(_owner, _operator) {
            return (ERC1155(_contract).isApprovedForAll(_owner, _operator), false);
        }
        catch {
            return (false, true);
        }
    }

    function checkMultipleIsApprovedForAll(address[] memory _owner, address[] memory _operator, address _contract) public view returns (bool[] memory, bool[] memory) {
        require(_owner.length == _operator.length, "Length of Owner Array & Operator Not the same");
        bool[] memory _status = new bool[](_owner.length);
        bool[] memory failedTx = new bool[](_owner.length);
        for(uint256 i=0; i<_owner.length; i++) {
            (_status[i], failedTx[i]) = checkIsApprovedForAll(_owner[i], _operator[i], _contract);
        }
        return (_status, failedTx);
    }

    function compareStrings(string memory a, string memory b) public pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function validateContractListing(address contract_address, uint256 token_id, string memory token_standard, address from_address, address operator_address, string memory marketPlace, bytes32 order_hash, uint256 nonce) public view returns (ListingValidator memory, bool) {
        ListingValidator memory _listingValidator;
        bool failedTx = false;
        bool failedTx2 = false;
        
        if(compareStrings(token_standard, "ERC721")){
            _listingValidator.ERC721Owner = NFTBalance(contract_address).ownerOf(token_id);
        }
        else if(compareStrings(token_standard, "ERC1155")){
            _listingValidator.ERC1155Quantity = ERC1155(contract_address).balanceOf(from_address,token_id);
        }

        if(compareStrings(marketPlace, "Seaport")){
            (_listingValidator.seaportOrderStatus, failedTx) = getOrderStatus(order_hash);
        }
        else if(compareStrings(marketPlace, "LooksRare")){
            (_listingValidator.looksRareOrderStatus, failedTx) = getUserOrderNonceExecutedOrCancelled(contract_address, nonce);
        }
        else if(compareStrings(marketPlace, "X2Y2")){
            (_listingValidator.x2y2OrderStatus, failedTx) = getInventoryStatusX2Y2(order_hash);
        }

        (_listingValidator.IsApprovedForAll, failedTx2) = checkIsApprovedForAll(from_address, operator_address, contract_address);

        return (_listingValidator, failedTx || failedTx2);
    }

    function accessBalanceNFT721(address _address, address[] memory _contractAddress) view public returns (uint256[] memory, bool[] memory) {
        uint256[] memory nftBalances = new uint256[](_contractAddress.length);
        bool[] memory failedTx = new bool[](_contractAddress.length);

        for(uint256 i=0; i<_contractAddress.length; i++){
            try NFTBalance(_contractAddress[i]).balanceOf(_address) {
                nftBalances[i] = NFTBalance(_contractAddress[i]).balanceOf(_address);
                failedTx[i] = false;
            }
            catch {
                nftBalances[i] = 0;
                failedTx[i] = true;
            }
        }
        return (nftBalances, failedTx);
    }

    function accessBalanceNFT1155(address _address, address[] memory _contractAddress, uint256[] memory _tokenIds) view public returns (uint256[] memory, bool[] memory) {
        require(_contractAddress.length == _tokenIds.length, "Length of contract address and token id's need to be same");
        uint256[] memory nftBalances = new uint256[](_contractAddress.length);
        bool[] memory failedTx = new bool[](_contractAddress.length);
        for(uint256 i=0; i<_contractAddress.length; i++){
            try ERC1155(_contractAddress[i]).balanceOf(_address,_tokenIds[i]) {
                nftBalances[i] = ERC1155(_contractAddress[i]).balanceOf(_address,_tokenIds[i]);
                failedTx[i] = false;
            }
            catch {
                failedTx[i] = true;
            }
        }
        return (nftBalances, failedTx);
    }

}