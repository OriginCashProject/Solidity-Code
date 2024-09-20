// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract FeeCalculator {
    // 30 = 0.3% fee, and it's fixed (not updatable).
    uint256 private feePercentage = 30;

    /**
     * @dev Calculates the amount after deducting the fee and the fee itself.
     * @param _amount The original amount before fee deduction.
     * @return amountAfterFee The amount after the fee is deducted.
     * @return fee The fee deducted from the original amount.
     */
    function calculateAmountAfterFeeAndFee(uint256 _amount)
        internal
        view
        returns (uint256 amountAfterFee, uint256 fee)
    {
        fee = (_amount * feePercentage) / 10000;
        amountAfterFee = _amount - fee;
        return (amountAfterFee, fee);
    }

    function getFeePercentage() external view returns (uint256) {
        return feePercentage;
    }
}
