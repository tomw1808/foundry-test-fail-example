// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test, console2 } from "forge-std/Test.sol";
import { UnsafeUpgrades } from "openzeppelin-foundry-upgrades/Upgrades.sol";
import { OwnableUpgradeable } from "lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol"; // Error is defined inside

import { MyTokenV1 } from "../src/MyTokenV1.sol";
import { MyTokenV2 } from "../src/MyTokenV2.sol";

contract MyTokenUpgradeTest is Test {
    MyTokenV1 internal tokenV1Impl;
    MyTokenV2 internal tokenV2Impl;
    MyTokenV1 internal proxyV1; // Interface to interact with the proxy using V1 ABI
    MyTokenV2 internal proxyV2; // Interface to interact with the proxy using V2 ABI
    address internal proxyAddress;

    address internal owner;
    address internal nonOwner;

    // Define the error locally to access its selector
    error OwnableUnauthorizedAccount(address account);

    function setUp() public {
        owner = makeAddr("owner");
        nonOwner = makeAddr("nonOwner");

        // 1. Deploy implementations FIRST (required for UnsafeUpgrades)
        tokenV1Impl = new MyTokenV1();
        tokenV2Impl = new MyTokenV2();

        // 2. Prepare initializer data for V1
        bytes memory initializerData = abi.encodeWithSelector(
            MyTokenV1.initialize.selector,
            "My Test Token",
            "MTT",
            owner // Set the owner during initialization
        );

        // 3. Deploy the UUPS proxy using UnsafeUpgrades
        // We link it to the V1 implementation initially
        proxyAddress = UnsafeUpgrades.deployUUPSProxy(address(tokenV1Impl), initializerData);

        // 4. Create contract instances at the proxy address to interact with
        proxyV1 = MyTokenV1(proxyAddress);
        proxyV2 = MyTokenV2(proxyAddress); // Can also create V2 instance for later

        // Sanity check: Ensure owner is set correctly
        assertEq(proxyV1.owner(), owner, "Initial owner should be set correctly");
        assertEq(proxyV1.version(), "V1", "Initial version should be V1");
    }

    function test_Upgrade_Success_WhenOwner() public {
        // Check initial state
        assertEq(UnsafeUpgrades.getImplementationAddress(proxyAddress), address(tokenV1Impl), "Initial implementation should be V1");
        assertEq(proxyV1.version(), "V1", "Version before upgrade should be V1");

        // Perform upgrade using UnsafeUpgrades, simulating call from owner
        // Pass empty bytes "" for the upgrade call data (no function to call on upgrade)
        UnsafeUpgrades.upgradeProxy(
            proxyAddress,
            address(tokenV2Impl),
            bytes(""),
            owner // Simulate the call coming from owner
        );

        // Check state after upgrade
        assertEq(UnsafeUpgrades.getImplementationAddress(proxyAddress), address(tokenV2Impl), "Implementation after upgrade should be V2");

        // Interact with the proxy using the V2 ABI now
        assertEq(proxyV2.version(), "V2", "Version after upgrade should be V2");

        // Test owner remains the same
        assertEq(proxyV2.owner(), owner, "Owner should remain the same after upgrade");

        // Test new V2 function (optional)
        vm.prank(owner); // Mint needs owner
        proxyV2.mint(address(this), 100 ether);
        assertEq(proxyV2.balanceOf(address(this)), 100 ether, "Balance should be minted");
        vm.prank(address(this)); // Burn needs token holder
        proxyV2.burn(50 ether);
        assertEq(proxyV2.balanceOf(address(this)), 50 ether, "Balance should be reduced after burn");
    }

    function testFail_Upgrade_WhenNotOwner() public {
        // Prepare the expected revert data for OwnableUnauthorizedAccount error
        bytes memory expectedRevertData = abi.encodeWithSelector(
            OwnableUnauthorizedAccount.selector,
            nonOwner // The account that is not authorized
        );

        // Expect the specific revert from Ownable's modifier used in _authorizeUpgrade
        vm.expectRevert(expectedRevertData);

        // Attempt upgrade using UnsafeUpgrades, specifying the nonOwner as the caller
        // Pass empty bytes "" for the upgrade call data
        UnsafeUpgrades.upgradeProxy(
            proxyAddress,
            address(tokenV2Impl),
            bytes(""),
            nonOwner // Simulate the call coming from nonOwner
        );

        // Check that implementation did not change
         assertEq(UnsafeUpgrades.getImplementationAddress(proxyAddress), address(tokenV1Impl), "Implementation should still be V1 after failed upgrade attempt");
    }
}
