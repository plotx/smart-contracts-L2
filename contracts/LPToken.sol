pragma solidity 0.5.7;


import "./external/openzeppelin-solidity/token/ERC20/ERC20.sol";
import "./external/NativeMetaTransaction.sol";
import "./external/openzeppelin-solidity/access/AccessControlMixin.sol";


contract LPToken is
    ERC20,
    AccessControlMixin,
    NativeMetaTransaction
{
    bytes32 public constant DEPOSITOR_ROLE = keccak256("DEPOSITOR_ROLE");

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) public ERC20(name_, symbol_) {
        _setupContractId("LPToken");
        _setupDecimals(decimals_);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(DEPOSITOR_ROLE, _msgSender());
        _initializeEIP712(name_);
    }

    // This is to support Native meta transactions
    // never use msg.sender directly, use _msgSender() instead
    function _msgSender()
        internal
        view
        returns (address payable sender)
    {
        return NativeMetaTransaction._msgSender();
    }

    /**
     * @notice called when token need to mint
     * @dev Should be callable only by PooledMarketCreation
     * Should mint the required amount for user
     * @param account user address for whom minting is being done
     * @param amount amount to be minted
     */
    function mint(address account, uint256 amount) 
        public
        only(DEPOSITOR_ROLE)
    {
        _mint(account, amount);
    }

    /**
     * @notice called when user wants to sell LP tokens 
     * @dev Should burn user's tokens. 
     * @param amount amount of tokens to burn
     */
    function burnFrom(address account, uint256 amount) public {
        _burn(account, amount);
        _approve(account, _msgSender(), allowance(account,_msgSender()).sub(amount));
    }
}