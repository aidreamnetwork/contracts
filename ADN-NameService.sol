
// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts@4.7.3/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts@4.7.3/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: ADN-NameService.sol


pragma solidity ^0.8.4;


contract ADNNameService is Ownable {
    address public FINANCE_VAULT;
    uint public USERNAME_PRICE = 10 ** 18;

    mapping(string => address) public UserNameToAddress;
    mapping(address => string) public UserAddressToName;

    constructor() {
        FINANCE_VAULT = _msgSender();
    }

    function setFinanceVault(address newAddress) public onlyOwner {
        FINANCE_VAULT = newAddress;
    }

    function setPrice(uint userNamePrice) public onlyOwner {
        USERNAME_PRICE = userNamePrice;
    }

    function checkString(string memory str) public pure returns (bool) {
        bytes memory b = bytes(str);
        if (b.length == 0 || b.length > 64) return false;

        for (uint i; i < b.length; i++) {
            bytes1 char = b[i];

            if (
                !(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x61 && char <= 0x7A) //a-z
            ) return false;
        }
        return true;
    }

    function buyUserName(string memory newUserName) public payable {
        require(checkString(newUserName), "Invalid string, accept 0-9 a-z");
        require(
            UserNameToAddress[newUserName] == address(0),
            "This name is taken"
        );
        require(msg.value == USERNAME_PRICE, "Payment error");
        payable(FINANCE_VAULT).transfer(USERNAME_PRICE);
        UserNameToAddress[UserAddressToName[msg.sender]] = address(0);
        UserNameToAddress[newUserName] = msg.sender;
        UserAddressToName[msg.sender] = newUserName;
    }
}