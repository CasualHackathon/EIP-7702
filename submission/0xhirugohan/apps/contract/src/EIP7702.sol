// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract SimpleDelegateContract {
    uint256 public counter;
    uint256 public counterReceive;
    uint256 public counterFallback;
    bytes[] public haltedTxes;
    uint256 public haltedTxesLength;

    event Executed(address indexed to, uint256 value, bytes data);

    struct Call {
        bytes data;
        address to;
        uint256 value;
    }

    function execute(Call[] memory calls) external payable {
        for (uint256 i = 0; i < calls.length; i++) {
            Call memory call = calls[i];
            (bool success, bytes memory result) = call.to.call{value: call.value}(call.data);
            require(success, string(result));
            emit Executed(call.to, call.value, call.data);
        }
    }

    function addCount() public {
        counter++;
    }

    receive() external payable {
        counterReceive += 1;
    }

    fallback(bytes calldata _input) external payable returns (bytes memory) {
        haltedTxes.push(_input);
        haltedTxesLength += 1;
        counterFallback += 1;
        return abi.encode();
    }
}

contract ERC20 {
    address public minter;
    mapping(address => uint256) private _balances;

    constructor(address _minter) {
        minter = _minter;
    }

    function mint(uint256 amount, address to) public {
        _mint(to, amount);
    }

    function balanceOf(address addr) public view returns (uint256) {
        return _balances[addr];
    }

    function _mint(address account, uint256 amount) internal {
        require(msg.sender == minter, "ERC20: msg.sender is not minter");
        require(account != address(0), "ERC20: mint to the zero address");
        unchecked {
            _balances[account] += amount;
        }
    }
}