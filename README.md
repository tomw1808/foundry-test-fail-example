## Foundry Bug Report: `vm.expectRevert` with UUPS Upgrade Failure

This repository demonstrates a potential issue in Foundry where using `vm.expectRevert` to catch an expected authorization failure during a UUPS proxy upgrade (specifically, the revert originating from the `_authorizeUpgrade` function) leads to an unexpected internal error.

Instead of catching the intended `OwnableUnauthorizedAccount` error from the `_authorizeUpgrade` check (triggered via the `onlyOwner` modifier in this example), the test fails deeper within the upgrade process, seemingly when the `UUPSUpgradeable` contract attempts to call the `UPGRADE_INTERFACE_VERSION()` function on the *new* implementation *before* the authorization check fully completes or is correctly handled by `vm.expectRevert`.

The `test/MyTokenUpgrade.t.sol::testFail_Upgrade_WhenNotOwner` test case illustrates this. It correctly sets up `vm.expectRevert` for the `OwnableUnauthorizedAccount` error when a non-owner attempts the upgrade via `UnsafeUpgrades.upgradeProxy`. However, the test fails with the following stack trace:

```
[19746] MyTokenUpgradeTest::test_Revert_Upgrade_WhenNotOwner()
    ├─ [0] VM::expectRevert(custom error 0xf28dceb3: 00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000024118cdaa7000000000000000000000000cbf285639f952bb8fb557d0532e38219ca5133c300000000000000000000000000000000000000000000000000000000)
    │   └─ ← [Return]
    ├─ [0] VM::startPrank(nonOwner: [0xcBf285639F952Bb8fb557D0532E38219CA5133C3])
    │   └─ ← [Return]
    ├─ [0] VM::load(ERC1967Proxy: [0xF62849F9A0B5Bf2913b396098F7c7019b51A820a], 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103) [staticcall]
    │   └─ ← [Return] 0x0000000000000000000000000000000000000000000000000000000000000000
    ├─ [5675] ERC1967Proxy::fallback() [staticcall]
    │   ├─ [695] MyTokenV1::UPGRADE_INTERFACE_VERSION() [delegatecall]
    │   │   └─ ← [Return] "5.0.0"
    │   └─ ← [Return] "5.0.0"
    ├─ [697] ERC1967Proxy::fallback(MyTokenV2: [0x2e234DAe75C793f67A35089C9d99245E1C58470b])
    │   ├─ [222] MyTokenV1::upgradeTo(MyTokenV2: [0x2e234DAe75C793f67A35089C9d99245E1C58470b]) [delegatecall]
    │   │   └─ ← [Revert] EvmError: Revert
    │   └─ ← [Revert] EvmError: Revert
    └─ ← [Revert] EvmError: Revert
```

This suggests that `vm.expectRevert` might be interfering with the state handling or execution flow during the proxied delegatecall to the implementation's `upgradeToAndCall` (or similar UUPS function), causing it to proceed further than expected before reverting, or causing the revert reason to be incorrectly captured or reported.
