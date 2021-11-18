pragma solidity 0.5.7;

import "./PooledMarketCreation.sol";

contract PooledMarketCreation_2 is PooledMarketCreation {

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(userLastStaked[sender].add(unstakeRestrictTime) < now,"Can not transfer in restricted period");

        super._transfer(sender, recipient, amount);
    }
}
