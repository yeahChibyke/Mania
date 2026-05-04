// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {BaseHook} from "v4-hooks-public/src/base/BaseHook.sol";
import {Currency} from "v4-core/types/Currency.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "v4-core/types/PoolId.sol";
import {BalanceDelta} from "v4-core/types/BalanceDelta.sol";
import {SwapParams, ModifyLiquidityParams} from "v4-core/types/PoolOperation.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";

contract HookMania is ERC721, Ownable, BaseHook {
    using PoolIdLibrary for PoolKey;

    uint256 private _nextTokenId;
    string private _tokenURI = "Hook Mania 4 Life";

    constructor(IPoolManager poolManager) ERC721("Hook Mania", "MANIA") Ownable(msg.sender) BaseHook(poolManager) {}

    function setTokenURI(string memory tokenURI_) external onlyOwner {
        _tokenURI = tokenURI_;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        return _tokenURI;
    }

    function totalMinted() external view returns (uint256) {
        return _nextTokenId;
    }

    // function _mintMania(PoolId _poolId, bytes calldata _hookData) internal {
    function _mintMania(bytes calldata _hookData) internal {
        // If no _hookData is passed in, no Hook Mania will be minted to anyone
        if (_hookData.length == 0) return;

        // // Pool ID is available for future mint rules, but every Mania NFT is identical for now.
        // _poolId;

        // // abi.decode would revert unless the address is ABI-encoded as a full 32-byte word.
        // if (_hookData.length != 32) return;

        // Extract user address from _hookData
        address _user = abi.decode(_hookData, (address));

        // If there is _hookData but not in the format we're expecting and user address is zero
        // nobody gets any Hook Mania NFTs
        if (_user == address(0)) return;

        // Mint Hook Mania to the user
        uint256 tokenId = ++_nextTokenId;
        _safeMint(_user, tokenId);
    }

    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: false,
            afterAddLiquidity: false,
            beforeRemoveLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: false,
            afterSwap: true,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    function _afterSwap(
        address,
        PoolKey calldata _key,
        SwapParams calldata _params,
        BalanceDelta _delta,
        bytes calldata _hookData
    ) internal override returns (bytes4, int128) {
        _delta;

        // If this is not an ETH-TOKEN pool with this hook attached, ignore
        if (!_key.currency0.isAddressZero()) return (this.afterSwap.selector, 0);

        // We only mint Hook Mania if user is buying TOKEN with ETH
        if (!_params.zeroForOne) return (this.afterSwap.selector, 0);

        // Mint Hook Mania
        // _mintMania(_key.toId(), _hookData);
        _mintMania(_hookData);

        return (this.afterSwap.selector, 0);
    }
}
