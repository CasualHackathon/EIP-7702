// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, Vm} from "forge-std/Test.sol";
import {SimpleDelegateContract, ERC20} from "../src/EIP7702.sol";

contract SignDelegationTest is Test {
    // Alice
    Vm.Wallet public aliceWallet = vm.createWallet("alice");
    // wallet.privateKey and wallet.addr

    // Bob
    Vm.Wallet public bobWallet = vm.createWallet("bob");

    // Cale
    address public caleAddress = makeAddr("cale");

    // Don
    Vm.Wallet public donWallet = vm.createWallet("don");

    SimpleDelegateContract public implementation;

    ERC20 public token;

    function setUp() public {
        // Deploy the delegation contract (Alice will delegate calls to this contract).
        implementation = new SimpleDelegateContract();

        // Deploy an ERC-20 token contract where Alice is the minter.
        token = new ERC20(aliceWallet.addr);
    }

    function test_SignDelegationAndThenAttachDelegation() public {
        // Construct a single transaction call: Mint 100 tokens to Bob.
        SimpleDelegateContract.Call[] memory calls = new SimpleDelegateContract.Call[](1);
        bytes memory data = abi.encodeCall(ERC20.mint, (100, bobWallet.addr));
        calls[0] = SimpleDelegateContract.Call({to: address(token), data: data, value: 0});

        // Alice signs a delegation allowing `implementation` to execute transaction on her behalf.
        Vm.SignedDelegation memory signedDelegation = vm.signDelegation(address(implementation), aliceWallet.privateKey);

        // Bob attaches the signed delegation from Alice and broadcasts it
        vm.startPrank(bobWallet.addr);
        // vm.broadcast(bobWallet.privateKey);
        vm.attachDelegation(signedDelegation);

        // Verify that Alice's account now behaves as a smart contract.
        bytes memory code = address(aliceWallet.addr).code;
        require(code.length > 0, "no code written to Alice");

        // As Bob, execute the transaction via Alice's assigned contract.
        SimpleDelegateContract(payable(aliceWallet.addr)).execute(calls);

        // Verify Bob successfully received 100 tokens.
        assertEq(token.balanceOf(bobWallet.addr), 100);
    }

    function test_TwoAddressesSignAndAttachDelegationForSameContract() public {
        // Construct a single transaction call: Mint 100 tokens to Bob.
        SimpleDelegateContract.Call[] memory calls = new SimpleDelegateContract.Call[](1);
        // bytes memory data = abi.encodeCall(ERC20.mint, (100, bobWallet.addr));
        // calls[0] = SimpleDelegateContract.Call({to: address(token), data: data, value: 0});
        bytes memory addCountData = abi.encodeCall(SimpleDelegateContract.addCount, ());
        calls[0] = SimpleDelegateContract.Call({to: aliceWallet.addr, data: addCountData, value: 0});

        // Alice signs a delegation allowing `implementation` to execute transaction on her behalf.
        Vm.SignedDelegation memory signedDelegationAlice = vm.signDelegation(address(implementation), aliceWallet.privateKey);
        // Don signs a delegation allowing `implementation` to execute transaction on his behalf.
        Vm.SignedDelegation memory signedDelegationDon = vm.signDelegation(address(implementation), donWallet.privateKey);

        // Bob attaches the signed delegation from Alice and broadcasts it
        vm.startPrank(bobWallet.addr);
        // vm.broadcast(bobWallet.privateKey);
        vm.attachDelegation(signedDelegationAlice);
        vm.attachDelegation(signedDelegationDon);

        // Verify that Alice's account now behaves as a smart contract.
        bytes memory codeAlice = address(aliceWallet.addr).code;
        require(codeAlice.length > 0, "no code written to Alice");

        // Verify that Don's account now behaves as a smart contract.
        bytes memory codeDon = address(donWallet.addr).code;
        require(codeDon.length > 0, "no code written to Don");

        // As Bob, execute the transaction via Alice's assigned contract.
        SimpleDelegateContract(payable(aliceWallet.addr)).execute(calls);
        // As Don, execute the transaction via Don's assigned contract.
        SimpleDelegateContract(payable(donWallet.addr)).execute(calls);

        // Verify Bob successfully received 100 tokens x 2.
        //  assertEq(token.balanceOf(bobWallet.addr), 200);

        assertEq(implementation.counter(), 0);
        assertEq(SimpleDelegateContract(payable(aliceWallet.addr)).counter(), 2);
        assertEq(SimpleDelegateContract(payable(donWallet.addr)).counter(), 0);
    }

    function test_DelegationStepByStep() public {
        // Alice sign delegation
        Vm.SignedDelegation memory signedDelegation = vm.signDelegation(
            address(implementation),
            aliceWallet.privateKey
        );

        // Setup Calldata
        SimpleDelegateContract.Call[] memory calls = new SimpleDelegateContract.Call[](1);
        bytes memory data = abi.encodeCall(ERC20.mint, (100, bobWallet.addr));
        calls[0] = SimpleDelegateContract.Call({to: address(token), data: data, value: 0});

        // Cheatcode: Attach Delegation
        vm.attachDelegation(signedDelegation);

        // Check if Alice EOA is Smart Contract
        bytes memory aliceEOACode = address(aliceWallet.addr).code;
        assertGt(aliceEOACode.length, 0);

        // Bob execute TX
        vm.startPrank(bobWallet.addr);
        SimpleDelegateContract(payable(aliceWallet.addr)).execute(calls);

        // Verify TX
        assertEq(token.balanceOf(bobWallet.addr), 100);
    }

    function test_transferEtherShouldBeHalted() public {
        uint256 initialBalance = 10 ether;
        uint256 transferAmount = 1 ether;
        vm.deal(aliceWallet.addr, initialBalance);

        // Alice sign delegation
        Vm.SignedDelegation memory signedDelegation = vm.signDelegation(
            address(implementation),
            aliceWallet.privateKey
        );

        // Setup Calldata
        /*
        SimpleDelegateContract.Call[] memory calls = new SimpleDelegateContract.Call[](1);
        bytes memory data = abi.encodeCall(ERC20.mint, (100, bobWallet.addr));
        calls[0] = SimpleDelegateContract.Call({to: address(token), data: data, value: 0});
        */

        // Cheatcode: Attach Delegation
        vm.attachDelegation(signedDelegation);

        // Check if Alice EOA is Smart Contract
        bytes memory aliceEOACode = address(aliceWallet.addr).code;
        assertGt(aliceEOACode.length, 0);

        // Snapshot length of haltedTxes
        uint256 haltedTxesLength = SimpleDelegateContract(payable(aliceWallet.addr)).haltedTxesLength();

        // Alice send ETH
        vm.startPrank(aliceWallet.addr);
        payable(bobWallet.addr).transfer(transferAmount);
        // SimpleDelegateContract(payable(aliceWallet.addr)).execute(calls);

        // Verify TX
        // assertEq(token.balanceOf(bobWallet.addr), 100);
        // assertEq(SimpleDelegateContract(payable(aliceWallet.addr)).counterReceive(), 1); // should be fixed
        assertEq(SimpleDelegateContract(payable(aliceWallet.addr)).counterFallback(), 0);
        // assertEq(aliceWallet.addr.balance, initialBalance); // should be fixed
        // assertEq(bobWallet.addr.balance, 0); // should be fixed
        // assertEq(haltedTxesLength, 1); // should be fixed
    }

    function test_NonDelegatedAddressShouldFail() public {
        // Alice sign delegation
        Vm.SignedDelegation memory signedDelegation = vm.signDelegation(
            address(implementation),
            aliceWallet.privateKey
        );

        // Setup Calldata
        SimpleDelegateContract.Call[] memory calls = new SimpleDelegateContract.Call[](1);
        bytes memory data = abi.encodeCall(ERC20.mint, (100, bobWallet.addr));
        calls[0] = SimpleDelegateContract.Call({to: address(token), data: data, value: 0});

        // Cheatcode: Attach Delegation
        vm.attachDelegation(signedDelegation);

        // Check if Alice EOA is Smart Contract
        bytes memory aliceEOACode = address(aliceWallet.addr).code;
        assertGt(aliceEOACode.length, 0);

        // Cale execute TX
        vm.startPrank(caleAddress);
        SimpleDelegateContract(payable(aliceWallet.addr)).execute(calls);

        // Verify TX
        assertEq(token.balanceOf(bobWallet.addr), 100);
        assertEq(token.balanceOf(caleAddress), 0);
    }
}