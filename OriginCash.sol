// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./FeeCalculator.sol";
import "./Validator.sol";
import "./Statistics.sol";
import "./DynamicShieldWallet.sol";
import "./ReentrancyGuard.sol";
import "./ProofMapping.sol";

/*
  OOOOO  RRRRRR  IIIIIIII  GGGGGG   IIIIII  N   N       CCCCC  AAAAA  SSSSS  H    H
 O     O R     R    II    G           II    NN  N      C      A     A S      H    H
 O     O RRRRRR     II    G   GGG     II    N N N      C      AAAAAAA SSSSS  HHHHHH
 O     O R   R      II    G     G     II    N  NN      C      A     A      S H    H
  OOOOO  R    R  IIIIIIII  GGGGGG   IIIIII  N   N   ★   CCCCC A     A SSSSS  H    H
-----------------------------------------------------------------------------------
        Anonymous Transactions - Multiple Chains | Fast, Secure, and Private
-----------------------------------------------------------------------------------
*/

contract OriginCash is
    FeeCalculator,
    Validator,
    Statistics,
    ReentrancyGuard,
    ProofMapping,
    Ownable
{
    // transaction fee recipient address
    address public feeReceiptAddress;

    error Warning(string content);

    struct Account {
        uint256 balance;
        string privateKeyHash;
    }

    receive() external payable {
        require(msg.sender != address(0), "Invalid sender");
        require(msg.value != 0, "No asset sent");
    }

    fallback() external payable {
        revert Warning("Fallback triggered");
    }

    struct Deposit {
        uint256 amount;
        uint256 timestamp;
    }

    // Passes the address of this contract (OriginCash) to the Ownable constructor.
    constructor() Ownable(address(this)) {
        feeReceiptAddress = msg.sender;
    }

    // Stores only the last 10 transactions
    Deposit[] private deposits;

    // Mapping private keys to account balances
    mapping(string => Account) private accounts;

    event Message(address _anonymousWallet, uint256 _balance);

    function changeFeeReceiptAddress(address _newFeeReceiptAddress)
        public
        onlyOwner
    {
        require(
            _newFeeReceiptAddress != address(0),
            "FeeReceiptAddress: Zero address"
        );
        feeReceiptAddress = _newFeeReceiptAddress;
    }

    // Handles user deposits
    function deposit(
        string calldata _privateKeyHash,
        bytes32 _messageHash,
        bytes32 _commitment
    ) public payable nonReentrant {
        // Check Private format
        require(validatePrivateKey(_privateKeyHash), "Invalid private key");

        require(msg.value != 0, "Zero amount");
        // Ensure the proof is not reused
        require(
            !isProofUsed(_messageHash, _commitment),
            "Proof has already been used"
        );

        // Retrieve the messageHash and commitment
        bytes32 messageHash = getMessageHash(
            msg.value,
            msg.sender,
            _commitment
        );

        // Verify the hashes match, data integrity
        require(messageHash == _messageHash, "Invalid hash transaction");

        // Initialize account if not already done
        Account storage account = accounts[_privateKeyHash];
        if (bytes(account.privateKeyHash).length == 0) {
            account.privateKeyHash = _privateKeyHash;
        }

        // The anonymous wallet contract for you to interact with
        DynamicShieldWallet anonymousWallet = new DynamicShieldWallet(
            originCash // Pass the originCash object
        );

        // Transfer assets to anonymous wallet
        payable(anonymousWallet).transfer(msg.value);

        // Transfer assets to OriginCash
        bool transferSuccess = anonymousWallet.transferWhenUserDeposit(
            msg.value
        );

        if (!transferSuccess) {
            // If the transfer fails, refund the user
            anonymousWallet.returnFunds(payable(msg.sender));
            revert Warning("Deposit failed");
        }

        account.balance += msg.value; // Update account balance
        setTotalTransactions();

        // Stores only the last 10 transactions
        uint256 depositIndex;
        uint256 depositsLength = deposits.length;
        if (depositsLength < 10) {
            deposits.push(Deposit(msg.value, block.timestamp));
        } else {
            // When the array reaches 10 elements, overwrite the oldest element (circular buffer)
            deposits[depositIndex] = Deposit(msg.value, block.timestamp);
        }
        // Update the index to overwrite the next element (circular buffer)
        depositIndex = (depositIndex + 1) % 10;

        // Mark the proof as used
        markProofAsUsed(_messageHash, _commitment);
        emit Message(address(anonymousWallet), account.balance);
    }

    // Handles user withdrawals
    function withdraw(
        uint256 _amount,
        address payable _to,
        string calldata _privateKeyHash,
        bytes32 _commitment,
        bytes32 _messageHash
    ) public nonReentrant {
        // Check Private format
        require(validatePrivateKey(_privateKeyHash), "Invalid private key");

        Account storage account = accounts[_privateKeyHash];
        require(account.balance >= _amount, "Insufficient balance");

        // Ensure the proof is not reused
        require(
            !isProofUsed(_messageHash, _commitment),
            "Proof has already been used"
        );

        // Retrieve the messageHash
        bytes32 messageHash = getMessageHash(_amount, _to, _commitment);

        // Verify the hashes match, data integrity
        require(messageHash == _messageHash, "Invalid hash transaction");

        (uint256 amountAfterFee, uint256 fee) = calculateAmountAfterFeeAndFee(
            _amount
        );

        // The anonymous wallet contract for you to interact with
        DynamicShieldWallet anonymousWallet = new DynamicShieldWallet(
            originCash // Pass the originCash object
        );

        // Anonymous wallet receive
        payable(anonymousWallet).transfer(_amount);

        // Transfer assets to user
        bool transferSuccess = anonymousWallet.transferWhenUserWithdraw(
            _to,
            payable(feeReceiptAddress),
            amountAfterFee,
            fee
        );

        if (!transferSuccess) {
            // If the transfer fails, refund OriginCash
            anonymousWallet.returnFunds(payable(originCash));
            revert Warning("Withdrawal failed");
        }

        account.balance -= _amount; // Update account balance
        setTotalTransactions();

        // Mark the proof as used
        markProofAsUsed(_messageHash, _commitment);
        emit Message(address(anonymousWallet), account.balance);
    }

    // Get the latest transactions
    function getLatestDepositTransaction(uint256 _limit)
        public
        view
        returns (Deposit[] memory)
    {
        uint256 depoLength = deposits.length;
        uint256 count = depoLength > _limit ? _limit : depoLength;
        Deposit[] memory latestDeposits = new Deposit[](count);
        for (uint256 i = 0; i < count; ++i) {
            latestDeposits[i] = deposits[depoLength - count + i];
        }
        return latestDeposits;
    }

    // Get balance by private key
    function getBalance(string calldata _privateKeyHash)
        public
        view
        returns (uint256)
    {
        return accounts[_privateKeyHash].balance;
    }
}
