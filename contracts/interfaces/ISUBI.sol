// SPDX-License-Identifier: MIT
pragma solidity >=0.5.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IUBIDelegator.sol";

/**
 * @title IStreamable Types
 * @author Sablier - juanu.eth
 */
library Types {
    struct Stream {
        uint256 ratePerSecond; // The rate of UBI to drip to this stream from the current accrued value
        uint256 startTime;
        uint256 stopTime;
        address sender;
        bool isActive;
        uint256 accruedSince;
        bool isCancellable;
    }
}

/**
 * @title IStreamable
 * @author Sablier - juanu.eth
 */
interface ISUBI is IERC721, IUBIDelegator {
    
    function balanceOfStream(uint256 streamId)
        external
        view
        returns (uint256 balance);

    function getStream(uint256 streamId)
        external
        view
        returns (uint256 ratePerSecond, // The rate of UBI to drip to this stream from the current accrued value
        uint256 startTime,
        uint256 stopTime,
        address sender,
        bool isActive,
        uint256 accruedSince,
        bool isCancellable);

    function getStreamsOf(address _human) external view returns (uint256[] memory);

    function maxStreamsAllowed() external view returns (uint256); 
    /**
     * @notice Returns either the delta in seconds between `block.timestamp` and `startTime` or
     *  between `stopTime` and `startTime, whichever is smaller. If `block.timestamp` is before
     *  `startTime`, it returns 0.
     * @dev Throws if the id does not point to a valid stream.
     * @param streamId ID of the stream for which to query the delta.
     */
    function accruedTime(uint256 streamId) external view returns (uint256);

    //function streamExists(uint256 streamId) external view returns (bool);
    //function withdrawFromStream(uint256 streamId) external;

    //function cancelStream(uint256 streamId) external

    /**
     * @dev gets the delegated accrued value.
     * This sums the accrued value of all active streams from the human's `accruedSince` to `block.timestamp`
     */
    //function getDelegatedAccruedValue(address _human) external view returns (uint256);

    /// @dev Callback for when UBI contract has withdrawn from a Stream.
    //function onWithdrawnFromStream(uint256 streamId) external;
    
    /// @dev Callback for when UBI contract has cancelled a stream.
    //function onCancelStream(uint256 streamId) external;


    /// @dev Callback for when reportRemoval is executed on UBI.
    //function onReportRemoval(address human) external;

    // function getDelegatedValue(address _sender, uint256 startTime, uint256 stopTime) external view returns (uint256);

    // function getDelegatedValue(address _sender) external view returns (uint256);
}
