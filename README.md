## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```

## Foundry Bug Report: `vm.expectRevert` with UUPS Upgrade Failure

This repository demonstrates a potential issue in Foundry where using `vm.expectRevert` to catch an expected authorization failure during a UUPS proxy upgrade (specifically, the revert originating from the `_authorizeUpgrade` function) leads to an unexpected internal error.

Instead of catching the intended `OwnableUnauthorizedAccount` error from the `_authorizeUpgrade` check (triggered via the `onlyOwner` modifier in this example), the test fails deeper within the upgrade process, seemingly when the `UUPSUpgradeable` contract attempts to call the `UPGRADE_INTERFACE_VERSION()` function on the *new* implementation *before* the authorization check fully completes or is correctly handled by `vm.expectRevert`.

The `test/MyTokenUpgrade.t.sol::testFail_Upgrade_WhenNotOwner` test case illustrates this. It correctly sets up `vm.expectRevert` for the `OwnableUnauthorizedAccount` error when a non-owner attempts the upgrade via `UnsafeUpgrades.upgradeProxy`. However, the test fails with the following stack trace:

```
<<<<<<< STACK TRACE PLACEHOLDER >>>>>>>
```

This suggests that `vm.expectRevert` might be interfering with the state handling or execution flow during the proxied delegatecall to the implementation's `upgradeToAndCall` (or similar UUPS function), causing it to proceed further than expected before reverting, or causing the revert reason to be incorrectly captured or reported.
