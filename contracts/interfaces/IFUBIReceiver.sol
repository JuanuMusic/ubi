// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

interface IFUBIReceiver {
    function onDelegationCanceled(address tokenOwner, uint tokenId, bytes memory data) external;
}