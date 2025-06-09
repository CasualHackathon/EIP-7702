// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract WalletKidsDelegate {
    // assumption: this contract when delegated, its only the implementation.
    // but the storage used is in the user's wallet
    struct Call {
        bytes data;
        address to;
        uint256 value;
    }

    struct TxQueue {
        bytes txCalldata;
        uint256 totalApproves;
        Call data;
        bool isExecuted;
    }

    address public userEOA; // user owned wallet
    address[] public approvers; // address of approvers, in this case guardian
    bytes[] public proposedTxQueues;
    mapping(uint256 => TxQueue) proposedTxes;

    event Registered(address indexed userEOA, address firstSignature);
    event Proposed(address indexed userEOA, bytes txCalldata);
    event Executed(address indexed to, uint256 value, bytes data);

    error ApproversNotEmpty();
    error NotUserEOA();
    error CalldataIsEmpty();
    error InvalidProposedTxQueuesIndex();
    error ProposedTxAlreadyExecuted();
    error ApproversNotEnough();

    modifier onlyUserEOA {
        if (msg.sender != userEOA) {
            revert NotUserEOA();
        }

        _;
    }

    function register(address[] memory _approvers) public {
        if (_approvers.length == 0) {
            revert ApproversNotEmpty();
        }

        userEOA = msg.sender;
        approvers = _approvers;

        emit Registered(msg.sender, _approvers[0]);
    }

    function proposeTX(bytes calldata _txCalldata, address _to, uint256 _value) public onlyUserEOA {
        if (_txCalldata.length == 0) {
            revert CalldataIsEmpty();
        }

        uint256 _txQueueIndex = proposedTxQueues.length;

        proposedTxQueues.push(_txCalldata);
        proposedTxes[_txQueueIndex] = TxQueue({
            txCalldata: _txCalldata,
            totalApproves: 0,
            data: Call({
                data: _txCalldata,
                to: _to,
                value: _value // native token, in wei
            }),
            isExecuted: false
        });

        emit Proposed(msg.sender, _txCalldata);
    }

    // it should allow any approvers/signers to execute this TX
    // but I don't know a way other than loop the array to check, its costly
    function executeTX(uint256 index) public onlyUserEOA payable {
        if (proposedTxQueues.length < index) {
            revert InvalidProposedTxQueuesIndex();
        }

        TxQueue memory _proposedTx = proposedTxes[index];

        if (_proposedTx.isExecuted) {
            revert ProposedTxAlreadyExecuted();
        }

        if (_proposedTx.totalApproves < approvers.length) {
            revert ApproversNotEnough();
        }

        (bool success, bytes memory result) = _proposedTx.data.to.call{value: _proposedTx.data.value}(_proposedTx.data.data);
        require(success, string(result));

        emit Executed(_proposedTx.data.to, _proposedTx.data.value, _proposedTx.data.data);
    }

    function getProposedTxQueueByIndex(uint256 _index) public view returns (TxQueue memory) {
        if (proposedTxQueues.length < _index) {
            revert InvalidProposedTxQueuesIndex();
        }

        return proposedTxes[_index];
    }

    function getCalldataByProposedTxIndex(uint256 _index) public view returns (bytes memory) {
        if (proposedTxQueues.length < _index) {
            revert InvalidProposedTxQueuesIndex();
        }

        return proposedTxQueues[_index];
    }

    function getProposedTxLength() public view returns (uint256) {
        return proposedTxQueues.length;
    }

    receive() external payable {}
}