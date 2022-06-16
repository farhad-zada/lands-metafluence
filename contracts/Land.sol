//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract Land is ERC721Enumerable, Ownable  {

    IERC20Upgradeable meto;
    IERC20Upgradeable busd;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    enum ASSET {METO, BUSD}

    struct OptionLaunchpadLand{
        uint ClaimableCount;
        uint ClaimedCount;
    }

    //keeps user minted nfts ids
    mapping(address => uint256[]) public collection;
    //keep disabled lands ids
    uint256[] public disabledLands;
    //keep investors lands. These lands do not require payment.
    mapping(uint256 => address) public privateSaleLands;
    //keep whitelist users list. Whitelist users can buy nfts earlier than others.
    mapping(address => bool) public whiteListAddresses;
    mapping(address => OptionLaunchpadLand) public launchpadLands;
    // use as the index if item not found in array
    uint256 private ID_NOT_FOUND = 9999999999999999;
    //block transaction or  set new land price if argument = ID_SKIP_PRICE_VALUE
    uint256 private ID_SKIP_PRICE_VALUE = 9999999999999999;
    uint256 public LAND_PRICE_METO = 95;
    uint256 public LAND_PRICE_BUSD = 1;
    uint256 public WHITELIST_PRICE_METO = 85;
    uint256 public WHITELIST_PRICE_BUSD = 1;
    uint256 public ONE_BUSD_PRICE = 100; //1 busd value by meto
             
    string public baseTokenURI;
    bool private launchpadSaleStatus;
    bool private whiteListSaleStatus;
    bool private privateSaleStatus;
    bool private publicSaleStatus;

    event MultipleMint(address indexed _from, uint256[] tokenIds, uint256 _price);
    // event Claim(address indexed _from, uint256 _tid, uint256 claimableCount, uint256 claimedCount);

    modifier Claimable () {
        require(launchpadSaleStatus, "Launchad sale not opened yet.");
        _;
    }

    constructor() ERC721("Land Collection", "LND") {
        meto = IERC20Upgradeable(0xc39A5f634CC86a84147f29a68253FE3a34CDEc57);
        busd = IERC20Upgradeable(0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee);
        setBaseURI("ipfs://QmeYyiEmYhGmEuMU8q9uMs7Uprs7KGdEiKBwRpSsoapn2K/");
    }

    function _baseURI() internal view  virtual override returns (string memory) {
         return baseTokenURI;
    }
    
    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    /* Start of Administrative Functions */
    function setLandPriceWithMeto(uint256 _price, uint256 _whiteListPrice) public onlyOwner {   
        if (_price != ID_SKIP_PRICE_VALUE || _price == LAND_PRICE_METO) {
            LAND_PRICE_METO = _price;
        }
        if ( _whiteListPrice != ID_SKIP_PRICE_VALUE || _whiteListPrice == WHITELIST_PRICE_METO) {
            WHITELIST_PRICE_METO = _whiteListPrice;
        }
    }
    
    function setOneBUSDPrice(uint256 _price) public onlyOwner {
        ONE_BUSD_PRICE = _price;
    }
    function withdrawMeto(address payable addr, uint256 _amount) external onlyOwner {
        SafeERC20Upgradeable.safeTransfer(meto, addr, _amount);
    }
    function withdrawBusd(address payable addr, uint256 _amount) external onlyOwner {
        SafeERC20Upgradeable.safeTransfer(busd, addr, _amount);
    }
    function setLandAsDisabled(uint256[] memory _tids) public onlyOwner {
        for (uint i = 0; i < _tids.length; i++) {
            disabledLands.push(_tids[i]);
        }
    }

    function removeDisableLand(uint256 _tid) public onlyOwner {
        uint256 _index = getDisabledLandIndex(_tid);
        require(_index != ID_NOT_FOUND, "index out of bound.");

        for (uint i = _index; i < disabledLands.length - 1; i++) {
            disabledLands[i] = disabledLands[i + 1];
        }

        disabledLands.pop();
    }

    function getDisabledLandIndex(uint256 _tid) private view returns(uint256) {
        for (uint256 i = 0; i < disabledLands.length; i++) {
            if (disabledLands[i] == _tid) {
                return i;
            }
        }

        return ID_NOT_FOUND;
    }

    //todo allow multiple launchad address insertation
    function setLaunchpadAddresses(address[] memory  _addrs, OptionLaunchpadLand[] memory _options) public onlyOwner{
        for (uint256 i = 0; i < _addrs.length; i++) {
            launchpadLands[_addrs[i]] = _options[i];
        }
    }

    function setWhitelistAddresses(address[] memory _addrs, bool[] memory _values) public onlyOwner 
    {
        for (uint i = 0; i < _addrs.length; i++) {
            whiteListAddresses[_addrs[i]] = _values[i]; 
        }
    }
    
    function setSaleStatus(bool _launchpadSaleStatus, bool _publicSaleStatus, bool _whiteListSaleStatus) public onlyOwner{
        launchpadSaleStatus = _launchpadSaleStatus;
        publicSaleStatus = _publicSaleStatus;
        whiteListSaleStatus = _whiteListSaleStatus;
    }

    /* End of Administrative Functions */

    // return user nft collection 
    function myCollection() public view returns(uint256[] memory) {
        return collection[msg.sender];
    }

    function mintWithMeto(uint256[] memory _tids) public {
        uint256[] memory filteredLands = filterAvailableLands(_tids);
        uint256 totalPrice = calculateTotalPrice(filteredLands, ASSET.METO);
        require(meto.balanceOf(msg.sender) > totalPrice,  "User has not enough balance.");

        SafeERC20Upgradeable.safeTransferFrom(meto, msg.sender, address(this), totalPrice);
    
        for (uint i = 0; i < filteredLands.length; i++) {

            if (filteredLands[i] == 0) {
                continue;
            }

            _safeMint(msg.sender, filteredLands[i]);
            //insert minted nft to user collection
            collection[msg.sender].push(filteredLands[i]);
        }

        emit MultipleMint(msg.sender, filteredLands, totalPrice);
    }

    function mintWithBusd(uint256[] memory _tids) public {
        uint256[] memory filteredLands = filterAvailableLands(_tids);
        uint256 totalPrice = calculateTotalPrice(filteredLands, ASSET.BUSD);
        require(busd.balanceOf(msg.sender) > totalPrice,  "User has not enough balance.");

        SafeERC20Upgradeable.safeTransferFrom(busd, msg.sender, address(this), totalPrice);
    
        for (uint i = 0; i < filteredLands.length; i++) {

            if (filteredLands[i] == 0) {
                continue;
            }
            
            _safeMint(msg.sender, filteredLands[i]);
            //insert minted nft to user collection
            collection[msg.sender].push(filteredLands[i]);
        }

        emit MultipleMint(msg.sender, filteredLands, totalPrice);
    }

    // claim mint single nft without payment and available from launchpad
    function claim(uint256[] memory _ids)
        public Claimable
    {
        require(_ids.length <= launchpadLands[msg.sender].ClaimableCount, 'user reaches claim limit');
        for (uint256 i = 0; i < _ids.length; i++) {
            require(launchpadLands[msg.sender].ClaimedCount < launchpadLands[msg.sender].ClaimableCount, "reach calimable limit.");
            _safeMint(msg.sender, _ids[i]);
            //increase user claimed land count
            launchpadLands[msg.sender].ClaimedCount++;
            //insert minted nft to user collection
            collection[msg.sender].push(_ids[i]);
        }

        //todo add emit
    }

    // check given _tid inside disabledLand or not
    function isDisabledLand(uint256 _tid) private view returns(bool) {
        for (uint256 i = 0; i < disabledLands.length; i++) {
            if (disabledLands[i] == _tid) {
                return true;
            }
        }

        return false;
    }

    function _isSaleOpened() internal view returns(bool) {
        if (publicSaleStatus) {
            return true;
        }
        
        if (whiteListAddresses[msg.sender] && whiteListSaleStatus) {
            return true;
        }

        return false;
    }
    
    function filterAvailableLands(uint256[] memory _tids) private view returns(uint256[] memory) {

        uint256[] memory filteredLands = new uint256[](_tids.length);

        for (uint i = 0; i < _tids.length; i++) {
            if (isDisabledLand(_tids[i])) {
                continue;
            }

            filteredLands[i] = _tids[i];
        }

        return filteredLands;
    }

    function decimals() internal pure returns(uint256) {
        return 10 ** 18;
    }

    function getMetoPublicPrice() internal view returns(uint256) {
        return LAND_PRICE_METO * ONE_BUSD_PRICE * decimals();
    }

    function getMetoWhitelistPrice() internal view returns(uint256) {
        return WHITELIST_PRICE_METO * ONE_BUSD_PRICE * decimals();
    }

    function calculateTotalPrice(uint256[] memory _tids, ASSET _asset) internal view returns(uint256) {
        uint256 _price = 0;
        uint256 cnt = 0;

        if (whiteListAddresses[msg.sender] && !publicSaleStatus && whiteListSaleStatus) {
            if (_asset == ASSET.METO) {
                _price = getMetoWhitelistPrice();
            } else if (_asset == ASSET.BUSD) {
                _price = WHITELIST_PRICE_BUSD * decimals();
            }
        } else {
            if (_asset == ASSET.METO) {
                _price = getMetoPublicPrice();
            } else if (_asset == ASSET.BUSD) {
                _price = LAND_PRICE_BUSD * decimals();
            }
        }


        for (uint256 i = 0; i<_tids.length; i++) {
            if (_tids[i] > 0) {
                cnt++;
            }
        }

        return _price * cnt;
    }
}