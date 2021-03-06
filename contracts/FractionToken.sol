pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
contract baseFractionToken is ERC20, ERC20Burnable {
    address NFTOwner;
    address VaultContractAddress;
    uint RoyaltyPercentage;

    ERC721 NFT;

    address[] tokenOwners;
    mapping(address => bool) isHolding;

    constructor(address _NFTOwner, uint _royaltyPercentage, uint _supply, string memory _tokenName, string memory _tokenTicker, address _vaultContractAddress) ERC20(_tokenName, _tokenTicker) {
    NFTOwner = _NFTOwner;
    RoyaltyPercentage = _royaltyPercentage;
    _mint(_NFTOwner, _supply);
    VaultContractAddress = _vaultContractAddress;
    }

    function transfer(address to, uint256 amount) override public returns (bool) {
        uint royaltyFee = amount * RoyaltyPercentage / 100;
        uint afterRoyaltyFee = amount - royaltyFee;
        
        address owner = _msgSender();
        //send royalty
        _transfer(owner, NFTOwner, royaltyFee);
        //send to new owner
        _transfer(owner, to, afterRoyaltyFee);

        addNewUserRemoveOld(to, owner);
        
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);

        uint royaltyFee = amount * RoyaltyPercentage / 100;
        uint afterRoyaltyFee = amount - royaltyFee;
        //send royalty
        _transfer(from, NFTOwner, royaltyFee);
        //send to new owner
        _transfer(from, to, afterRoyaltyFee);

        addNewUserRemoveOld(to, from);

        return true;
    }

    function burn(uint256 amount) public virtual override {
        _burn(_msgSender(), amount);
    }

    function addNewUserRemoveOld(address newUser, address oldUser) public{
        tokenOwners.push(newUser);
        isHolding[newUser] = true;

        if (isHolding[oldUser] == true &&
            balanceOf(oldUser) == 0 ) {
            
            for (uint i = 0; i < tokenOwners.length; i++) {
                if (tokenOwners[i] == oldUser) {

                    delete tokenOwners[i];
                    isHolding[oldUser] = false;
                    break;
                }
            }
        }
    }

    function updateNFTOwner(address _newOwner) public {
        require(msg.sender == VaultContractAddress, "Only vault contract can update this nft owner");

        NFTOwner = _newOwner;
    }

    function returnTokenOwners() public view returns(address[] memory) {
        return tokenOwners;
    }
}