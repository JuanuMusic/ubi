// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

/**
 * This code contains elements of ERC20BurnableUpgradeable.sol https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/token/ERC20/ERC20BurnableUpgradeable.sol
 * Those have been inlined for the purpose of gas optimization.
 */

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @title ProofOfHumanity Interface
 * @dev See https://github.com/Proof-Of-Humanity/Proof-Of-Humanity.
 */
interface IProofOfHumanity {
  function isRegistered(address _submissionID)
    external
    view
    returns (
      bool registered
    );
}


/**
 * @title Poster Interface
 * @dev See https://github.com/auryn-macmillan/poster
 */
interface IPoster {
  event NewPost(bytes32 id, address user, string content);

  function post(string memory content) external;
}


/**
 * @title Universal Basic Income
 * @dev UBI is an ERC20 compatible token that is connected to a Proof of Humanity registry.
 *
 * Tokens are issued and drip over time for every verified submission on a Proof of Humanity registry.
 * The accrued tokens are updated directly on every wallet using the `balanceOf` function.
 * The tokens get effectively minted and persisted in memory when someone interacts with the contract doing a `transfer` or `burn`.
 */
contract UBI is Initializable {

  /* Events */

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to another (`to`).
   *
   * Note that `value` may be zero.
   * Also note that due to continuous minting we cannot emit transfer events from the address 0 when tokens are created.
   * In order to keep consistency, we decided not to emit those events from the address 0 even when minting is done within a transaction.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);

  /**
   * @dev Emitted when the `delegator` delegates its UBI accruing to the `receiver` by
   * a call to {sender}.
   */
  event Delegate(address indexed sender, address indexed receiver);  

  /**
   * @dev Emitted when the `delegator` revokes its UBI delegation to the `receiver` by
   * a call to {sender}.
   */
  event Revoke(address indexed sender, address indexed receiver);  

  using SafeMath for uint256;

  /* Storage */

  mapping (address => uint256) private balance;

  mapping (address => mapping (address => uint256)) public allowance;

  /// @dev A lower bound of the total supply. Does not take into account tokens minted as UBI by an address before it moves those (transfer or burn).
  uint256 public totalSupply;

  /// @dev Name of the token.
  string public name;

  /// @dev Symbol of the token.
  string public symbol;

  /// @dev Number of decimals of the token.
  uint8 public decimals;

  /// @dev How many tokens per second will be minted for every valid human.
  uint256 public accruedPerSecond;

  /// @dev The contract's governor.
  address public governor;

  /// @dev The Proof Of Humanity registry to reference.
  IProofOfHumanity public proofOfHumanity;

  /// @dev Timestamp since human started accruing.
  mapping(address => uint256) public accruedSince;

  /// @dev Data relative to each specific stream in the network.
  struct Stream {
    address delegate;
    uint256 strength;
    uint256 timestamp;
  }

  /// @dev Persists the sources of an address receiving a stream.
  mapping (address => Stream[]) public streamSources;

  /// @dev Persists the targets of an address sending a stream.
  mapping (address => Stream[]) public streamTargets;

  /// @dev Percentage multiplier based on how many delegations an address receives.
  mapping (address => uint256) public delegationStrength;

  /// @dev Accrual time that should not be computed in the balance of a delegate.
  mapping (address => uint256) public discountedAccrual;

  /// @dev Useful to calculate percentages.
  uint256 private BASIS_POINTS;

  /* Modifiers */

  /// @dev Verifies that the sender has ability to modify governed parameters.
  modifier onlyByGovernor() {
    require(governor == msg.sender, "The caller is not the governor.");
    _;
  }

  /* Initializer */

  /** @dev Constructor.
  *  @param _initialSupply for the UBI coin including all decimals.
  *  @param _name for UBI coin.
  *  @param _symbol for UBI coin ticker.
  *  @param _accruedPerSecond How much of the token is accrued per block.
  *  @param _proofOfHumanity The Proof Of Humanity registry to reference.
  */
  function initialize(uint256 _initialSupply, string memory _name, string memory _symbol, uint256 _accruedPerSecond, IProofOfHumanity _proofOfHumanity) public initializer {
    name = _name;
    symbol = _symbol;
    decimals = 18;
    BASIS_POINTS = 10000;

    accruedPerSecond = _accruedPerSecond;
    proofOfHumanity = _proofOfHumanity;
    governor = msg.sender;

    balance[msg.sender] = _initialSupply;
    totalSupply = _initialSupply;
  }

  /* External */

  /** @dev Starts accruing UBI for a registered submission.
  *  @param _human The submission ID.
  */
  function startAccruing(address _human) external {
    require(proofOfHumanity.isRegistered(_human), "The submission is not registered in Proof Of Humanity.");
    require(accruedSince[_human] == 0, "The submission is already accruing UBI.");
    accruedSince[_human] = block.timestamp;
    delegationStrength[_human] = BASIS_POINTS;
  }

  /** @dev Allows anyone to report a submission that
  *  should no longer receive UBI due to removal from the
  *  Proof Of Humanity registry. The reporter receives any
  *  leftover accrued UBI.
  *  @param _human The submission ID.
  */
  function reportRemoval(address _human) external  {
    require(!proofOfHumanity.isRegistered(_human), "The submission is still registered in Proof Of Humanity.");
    require(accruedSince[_human] != 0, "The submission is not accruing UBI.");
    uint256 newSupply = accruedPerSecond.mul(block.timestamp.sub(accruedSince[_human]));

    accruedSince[_human] = 0;

    balance[msg.sender] = balance[msg.sender].add(newSupply);
    totalSupply = totalSupply.add(newSupply);
  }

  /** @dev Changes `governor` to `_governor`.
  *  @param _governor The address of the new governor.
  */
  function changeGovernor(address _governor) external onlyByGovernor {
    governor = _governor;
  }

  /** @dev Changes `proofOfHumanity` to `_proofOfHumanity`.
  *  @param _proofOfHumanity Registry that meets interface of Proof of Humanity.
  */
  function changeProofOfHumanity(IProofOfHumanity _proofOfHumanity) external onlyByGovernor {
    proofOfHumanity = _proofOfHumanity;
  }

  /** @dev Transfers `_amount` to `_recipient` and withdraws accrued tokens.
  *  @param _recipient The entity receiving the funds.
  *  @param _amount The amount to tranfer in base units.
  */
  function transfer(address _recipient, uint256 _amount) public returns (bool) {
    uint256 newSupplyFrom;
    if (accruedSince[msg.sender] != 0 && proofOfHumanity.isRegistered(msg.sender)) {
        newSupplyFrom = accruedPerSecond.mul(block.timestamp.sub(accruedSince[msg.sender]));
        totalSupply = totalSupply.add(newSupplyFrom);
        accruedSince[msg.sender] = block.timestamp;
    }
    balance[msg.sender] = balance[msg.sender].add(newSupplyFrom).sub(_amount, "ERC20: transfer amount exceeds balance");
    balance[_recipient] = balance[_recipient].add(_amount);
    emit Transfer(msg.sender, _recipient, _amount);
    return true;
  }

  /** @dev Transfers `_amount` from `_sender` to `_recipient` and withdraws accrued tokens.
  *  @param _sender The entity to take the funds from.
  *  @param _recipient The entity receiving the funds.
  *  @param _amount The amount to tranfer in base units.
  */
  function transferFrom(address _sender, address _recipient, uint256 _amount) public returns (bool) {
    uint256 newSupplyFrom;
    allowance[_sender][msg.sender] = allowance[_sender][msg.sender].sub(_amount, "ERC20: transfer amount exceeds allowance");
    if (accruedSince[_sender] != 0 && proofOfHumanity.isRegistered(_sender)) {
        newSupplyFrom = accruedPerSecond.mul(block.timestamp.sub(accruedSince[_sender]));
        totalSupply = totalSupply.add(newSupplyFrom);
        accruedSince[_sender] = block.timestamp;
    }
    balance[_sender] = balance[_sender].add(newSupplyFrom).sub(_amount, "ERC20: transfer amount exceeds balance");
    balance[_recipient] = balance[_recipient].add(_amount);
    emit Transfer(_sender, _recipient, _amount);
    return true;
  }

  /** @dev Approves `_spender` to spend `_amount`.
  *  @param _spender The entity allowed to spend funds.
  *  @param _amount The amount of base units the entity will be allowed to spend.
  */
  function approve(address _spender, uint256 _amount) public returns (bool) {
    allowance[msg.sender][_spender] = _amount;
    emit Approval(msg.sender, _spender, _amount);
    return true;
  }

  /** @dev Increases the `_spender` allowance by `_addedValue`.
  *  @param _spender The entity allowed to spend funds.
  *  @param _addedValue The amount of extra base units the entity will be allowed to spend.
  */
  function increaseAllowance(address _spender, uint256 _addedValue) public returns (bool) {
    uint256 newAllowance = allowance[msg.sender][_spender].add(_addedValue);
    allowance[msg.sender][_spender] = newAllowance;
    emit Approval(msg.sender, _spender, newAllowance);
    return true;
  }

  /** @dev Decreases the `_spender` allowance by `_subtractedValue`.
  *  @param _spender The entity whose spending allocation will be reduced.
  *  @param _subtractedValue The reduction of spending allocation in base units.
  */
  function decreaseAllowance(address _spender, uint256 _subtractedValue) public returns (bool) {
    uint256 newAllowance = allowance[msg.sender][_spender].sub(_subtractedValue, "ERC20: decreased allowance below zero");
    allowance[msg.sender][_spender] = newAllowance;
    emit Approval(msg.sender, _spender, newAllowance);
    return true;
  }

  /** @dev Burns `_amount` of tokens and withdraws accrued tokens.
  *  @param _amount The quantity of tokens to burn in base units.
  */
  function burn(uint256 _amount) public {
    uint256 newSupplyFrom;
    if(accruedSince[msg.sender] != 0 && proofOfHumanity.isRegistered(msg.sender)) {
      newSupplyFrom = accruedPerSecond.mul(block.timestamp.sub(accruedSince[msg.sender]));
      accruedSince[msg.sender] = block.timestamp;
    }
    balance[msg.sender] = balance[msg.sender].add(newSupplyFrom).sub(_amount, "ERC20: burn amount exceeds balance");
    totalSupply = totalSupply.add(newSupplyFrom).sub(_amount);
    emit Transfer(msg.sender, address(0), _amount);
  }

  /** @dev Burns `_amount` of tokens and posts content in a Poser contract.
  *  @param _amount The quantity of tokens to burn in base units.
  *  @param _poster the address of the poster contract.
  *  @param content bit of strings to signal.
  */
  function burnAndPost(uint256 _amount, address _poster, string memory content) public {
    burn(_amount);
    IPoster poster = IPoster(_poster);
    poster.post(content);
  }

  /** @dev Burns `_amount` of tokens from `_account` and withdraws accrued tokens.
  *  @param _account The entity to burn tokens from.
  *  @param _amount The quantity of tokens to burn in base units.
  */
  function burnFrom(address _account, uint256 _amount) public {
    uint256 newSupplyFrom;
    allowance[_account][msg.sender] = allowance[_account][msg.sender].sub(_amount, "ERC20: burn amount exceeds allowance");
    if (accruedSince[_account] != 0 && proofOfHumanity.isRegistered(_account)) {
        newSupplyFrom = accruedPerSecond.mul(block.timestamp.sub(accruedSince[_account]));
        accruedSince[_account] = block.timestamp;
    }
    balance[_account] = balance[_account].add(newSupplyFrom).sub(_amount, "ERC20: burn amount exceeds balance");
    totalSupply = totalSupply.add(newSupplyFrom).sub(_amount);
    emit Transfer(_account, address(0), _amount);
  }

  /* Getters */

  /** @dev Calculates how much UBI a submission has available for withdrawal.
  *  @param _human The submission ID.
  *  @return accrued The available UBI for withdrawal.
  */
  function getAccruedValue(address _human) public view returns (uint256 accrued) {
    // If this human have not started to accrue, or is not registered, return 0.
    if (accruedSince[_human] == 0 || !proofOfHumanity.isRegistered(_human)) return 0;

    uint256 factor = (delegationStrength[_human] == 0) ? BASIS_POINTS : delegationStrength[_human];

    return accruedPerSecond.mul(block.timestamp.sub(accruedSince[_human]).sub(discountedAccrual[_human])).mul(factor.div(BASIS_POINTS));
  }

  /**
  * @dev Calculates the current user accrued balance.
  * @param _human The submission ID.
  * @return The current balance including accrued Universal Basic Income of the user.
  **/
  function balanceOf(address _human) public view returns (uint256) {
    return getAccruedValue(_human).add(balance[_human]);
  }

  /**
  * @dev Delegate the UBI stream to another recipient than the current human.
  * @param _receiver The new delegate address to delegate stream UBI.
  */
  function delegate(address _receiver, uint256 _percentage) public {
    // Only humans can delegate their accruance
    require(proofOfHumanity.isRegistered(msg.sender), "The sender is not registered in Proof Of Humanity.");
    // TODO: What if sender want to burn a percentage of his UBIs consistently? Maybe, if the only way is by burning
    //   specific amounts manually or delegating them to other 'valid' address, will make him avoid the burn.
    //   I think letting sender burn a percentage would be an interesting feature (maybe you prefer a different function
    //   instead of masking it as a delegation to zero-address). 
    require(_receiver != address(0), "Delegate cannot be an empty address");
    require(_receiver != msg.sender, "Invalid circular delegation");
    // TODO: Maybe would be better to override old percentage with the new one instead of denying the action.
    require(checkDelegation(msg.sender, _receiver) == false, "Delegation already exists.");

    // Set new delegation
    // TODO: Maybe a 'renounce to delegation' function would be great for some cases. Even the address receiving the
    //   UBI through delegation could choose the new percentage of that delegation, obviously letting choose only
    //   percentages lower than the currently set, where choosing percentage = 0 would be a particular case for
    //   renouncing to the entire delegation.
    // TODO: What if sender is receiving more than BASIS_POINTS, for example through delegations.
    //   And now sender wants to delegate a percentage of all his UBI including delegations that targeted him.
    //   Would be great that delegations always uses percentages instead of fixed UBI amounts (aka strengths)
    //   and be calculated dynamically over the total accrued UBI.
    //   - Why delegating delegations could be useful: Because humans that don't know where to delegate their UBI,
    //   or don't want to be updating their delegations, could delegate them to a trusted human, trusting in the 
    //   delegation decisions he will choose.
    //   - Approach: All delegations has a constant 'strength' until a new delegation is added/revoked. 
    //   So, when a delegation is modified/added, it must calculate the new strengths, but for that, we need to have all
    //   delegations stored as percentages instead of fixed amounts.
    //   - Warning: A cycle of delegations (i.e. a->b->c->...->a) could lead to problems, needs more brainstorming.
    // TODO: How about _percentage being greater than 100? strength would be greater than BASIS_POINTS.
    //   If delegations percentages are stored, we could require: currentDelegatedPercentage + _percentage <= 100
    uint256 strength = BASIS_POINTS.mul(_percentage).div(100);
    streamSources[_receiver].push(Stream(msg.sender, strength, block.timestamp));
    streamTargets[msg.sender].push(Stream(_receiver, strength, block.timestamp));

    // A delegate should have a stream multiplier based on how many delegations it got according to the aggregated percentages from each.
    delegationStrength[_receiver] = (delegationStrength[_receiver] == 0) ? BASIS_POINTS.add(strength) : delegationStrength[_receiver].add(strength);
    delegationStrength[msg.sender] = (delegationStrength[msg.sender] == 0) ? BASIS_POINTS.sub(strength) : delegationStrength[msg.sender].sub(strength);

    // The accrual during the time previous to a delegation should be discounted from the balance of the delegate.
    uint256 discountedTime = (accruedSince[_receiver] != 0) ? block.timestamp.sub(accruedSince[_receiver]) : block.timestamp.sub(accruedSince[msg.sender]);
    discountedAccrual[_receiver] = (discountedAccrual[_receiver] == 0) ? discountedTime : discountedAccrual[_receiver].add(discountedTime);

    emit Delegate(msg.sender, _receiver);
  }

  /**
  * @dev Revoke an existing delegation entirely.
  * @param _receiver The delegate address to revoke the stream of UBI.
  */
  function revoke(address _receiver) public {
    require(proofOfHumanity.isRegistered(msg.sender), "The sender is not registered in Proof Of Humanity.");
    require(_receiver != address(0), "Delegate cannot be an empty address");
    require(checkDelegation(msg.sender, _receiver) == true, "Delegation not found.");

    (uint index, ,uint256 strength, uint256 timestamp) = getDelegationData(msg.sender, _receiver);

    // Restore the relative strength of the stream corresponding to this delegation.
    delegationStrength[_receiver] = delegationStrength[_receiver].sub(strength);
    delegationStrength[msg.sender] = delegationStrength[msg.sender].add(strength);

    // Restore any accrual discounts based on the time of the stream.
    uint256 discountedTime = (accruedSince[_receiver] != 0) ? timestamp.sub(accruedSince[_receiver]) : timestamp.sub(accruedSince[msg.sender]);
    discountedAccrual[_receiver] = discountedAccrual[_receiver].sub(discountedTime);

    // Delete the stream from the array corresponding to the receiver.
    streamSources[_receiver][index] = streamSources[_receiver][streamSources[_receiver].length - 1];
    delete streamSources[_receiver][streamSources[_receiver].length - 1];
    // streamSources[_receiver].length--; @TODO: Revisar esto

    emit Revoke(msg.sender, _receiver);
  }

  /**
  * @dev Get the delegation data from an existing delegation.
  * @param _sender The delegator.
  * @param _receiver The delegate.
  * @return index of the delegation stream array.
  * @return sender of the delegation stream.
  * @return strength of the delegation stream.
  * @return timestamp of when the delegation stream began.
  */
  function getDelegationData(address _sender, address _receiver) public view returns (uint index, address sender, uint256 strength, uint256 timestamp) {
    for (uint i = 0; i < streamSources[_receiver].length; i++) {
      if (streamSources[_receiver][i].delegate == _sender) {
        Stream memory stream = streamSources[_receiver][i];
        return (i, stream.delegate, stream.strength, stream.timestamp);
      }
    }
  }

  /**
  * @dev Checks if a delegation betweent two parties is already configured.
  * @param _sender The delegator.
  * @param _receiver The delegate.
  * @return A boolean once verified.
  */
  function checkDelegation(address _sender, address _receiver) public view returns (bool) {
    for (uint i = 0; i < streamSources[_receiver].length; i++) {
      if (streamSources[_receiver][i].delegate == _sender) return true;
    }
    return false;
  }
}
