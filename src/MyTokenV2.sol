// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Initializable } from "lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import { ERC20Upgradeable } from "lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import { OwnableUpgradeable } from "lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import { UUPSUpgradeable } from "lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title MyTokenV2
 * @dev Minimal UUPS upgradeable ERC20 token, version 2.
 * Compatible with MyTokenV1 for upgrade purposes.
 */
contract MyTokenV2 is Initializable, ERC20Upgradeable, OwnableUpgradeable, UUPSUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializes the contract (maintains compatibility, may not be called in upgrade).
     * @param name The name of the token.
     * @param symbol The symbol of the token.
     * @param initialOwner The address to set as the initial owner.
     */
    function initialize(string memory name, string memory symbol, address initialOwner) public initializer {
        __ERC20_init(name, symbol);
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
    }

    /**
     * @dev See {UUPSUpgradeable-_authorizeUpgrade}.
     * Requires the caller to be the owner.
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /**
     * @dev Mints tokens to a specified address. Only callable by the owner.
     * @param to The address to mint tokens to.
     * @param amount The amount of tokens to mint.
     */
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    // --- Version 2 Specific Function (Example) ---
    function version() public pure returns (string memory) {
        return "V2";
    }

    // --- New Function in V2 (Example) ---
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }
}
