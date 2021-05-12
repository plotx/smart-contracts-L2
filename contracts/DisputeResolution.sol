/* Copyright (C) 2020 PlotX.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity 0.5.7;

import "./external/openzeppelin-solidity/math/SafeMath.sol";
import "./external/proxy/OwnedUpgradeabilityProxy.sol";
import "./external/NativeMetaTransaction.sol";
import "./interfaces/IMaster.sol";
import "./interfaces/IAllMarkets.sol";
import "./interfaces/IToken.sol";
import "./interfaces/IAuth.sol";

contract DisputeResolution is IAuth, NativeMetaTransaction {
  
  event DisputeRaised(uint256 indexed marketIndex, address indexed raisedBy, uint256 proposedValue, uint256 allowVoteUntil, string description);
  event DisputeResolved(uint256 indexed marketIndex, bool status);
  event Vote(uint256 indexed marketIndex, address indexed user, bool choice, uint256 voteValue, uint256 date);
  event WithdrawnTokens(uint256 indexed marketIndex, address indexed user, uint256 amount);
  event ClaimReward(address indexed user, uint256 amount);

  struct DisputeData {
    address raisedBy;
    uint256 proposedValue;
    uint256 allowVoteUntil;
    uint256 stakeAmount;
    uint256 totalVoteValue;
    uint256 acceptedVoteValue;
    uint256 rejectedVoteValue;
    uint256 tokensLockedUntill;
    uint256 rewardForVoting;
    bool closed;
    mapping (address => uint256) userVoteValue;
  }

  struct UserData {
    uint[] disputesParticipated;
    uint256 lastClaimedIndex;
    mapping (uint256 => bool) claimedReward;
  }

  IAllMarkets internal allMarkets;

  address internal plotToken;
  address internal masterAddress;
  uint256 internal drVotePeriod;
  uint256 internal tokenStakeForDispute;
  uint256 internal drTokenLockPeriod;
  uint256 internal voteThresholdMultiplier;
  uint256 internal rewardForVoting;

  mapping (uint256 => DisputeData) public marketDisputeData;
  mapping (address => UserData) public userData;

  /**
   * @dev Changes the master address and update it's instance
   * @param _authorizedMultiSig Authorized address to execute critical functions in the protocol.
   * @param _defaultAuthorizedAddress Authorized address to trigger initial functions by passing required external values.
   */
  function setMasterAddress(address _authorizedMultiSig, address _defaultAuthorizedAddress) public {
    OwnedUpgradeabilityProxy proxy =  OwnedUpgradeabilityProxy(address(uint160(address(this))));
    require(msg.sender == proxy.proxyOwner());
    IMaster ms = IMaster(msg.sender);
    address _plotToken = ms.dAppToken();
    authorized = _authorizedMultiSig;
    plotToken = _plotToken;
    allMarkets = IAllMarkets(ms.getLatestAddress("AM"));
    masterAddress = msg.sender;
    tokenStakeForDispute = 500 ether;
    rewardForVoting = 500 ether;
    drTokenLockPeriod = 10 days;
    voteThresholdMultiplier = 10;
    drVotePeriod = 3 days;
    _initializeEIP712("DR");
  }

  /**
    * @dev function to update integer parameters
    * @param code Code of the updating parameter.
    * @param value Value to which the parameter should be updated
    */
    function updateUintParameters(bytes8 code, uint256 value) external onlyAuthorized {
      if(code == "TSD") { // Token to stake for raising a dispute
        tokenStakeForDispute = value;
      } else if(code == "REWARD") { // Number of tokens to be rewarded for DR voters
        rewardForVoting = value;
      } else if(code == "DRLOCKP") { // Time for which tokens of DR voter are locked
        drTokenLockPeriod = value;
      } else if(code == "THMUL") { // Multiplier X, to be used to check if the voting has reached threshold for resolving dispute . Threshold = X times of Market Participation
        voteThresholdMultiplier = value;
      } else if(code == "VOTETIME") { // Time for which the voting in Dispute resolution is open
        drVotePeriod = value;
      } else {
        revert("Invalid code");
      }
    }

    /**
    * @dev function to get integer parameters
    * @param code Code of the parameter.
    * @return codeVal Code of the parameter.
    * @return value Value of the queried parameter.
    */
    function getUintParameters(bytes8 code) external view returns(bytes8 codeVal, uint256 value) {
      codeVal = code;
      if(code == "TSD") { // Token to stake for raising a dispute
        value = tokenStakeForDispute;
      } else if(code == "REWARD") { // Number of tokens to be rewarded for DR voters
        value = rewardForVoting;
      } else if(code == "DRLOCKP") { // Time for which tokens of DR voter are locked
        value = drTokenLockPeriod;
      } else if(code == "THMUL") { // Multiplier X, to be used to check if the voting has reached threshold for resolving dispute . Threshold = X times of Market Participation
        value = voteThresholdMultiplier;
      } else if(code == "VOTETIME") { // Time for which the voting in Dispute resolution is open
        value = drVotePeriod;
      }
    }

  /**
  * @dev Raise the dispute if wrong value passed at the time of market result declaration.
  * User should deposit `tokenStakeForDispute` number of tokens to raise a dispute
  * The deposited tokens can be claimable if the dispute is accepted,
  * If the dispute is rejected the deposited tokens will be sent to dao when the result is declared.
  * Users are allowed to vote to resolve the dispute by depositing their tokens, which can be claimable after some time
  * @param _marketId Index of market.
  * @param _proposedValue The proposed value of market currency.
  * @param _description The description of dispute.
  */
  function raiseDispute(uint256 _marketId, uint256 _proposedValue, string memory _description) public {
    address payable _msgSenderAddress = _msgSender();
    DisputeData storage _marketDisputeData = marketDisputeData[_marketId];
    require(allMarkets.marketStatus(_marketId) == IAllMarkets.PredictionStatus.Cooling);
    _transferTokenFrom(_msgSenderAddress, address(this), tokenStakeForDispute);
    _marketDisputeData.raisedBy = _msgSenderAddress;
    _marketDisputeData.proposedValue = _proposedValue;
    _marketDisputeData.allowVoteUntil = drVotePeriod.add(now);
    _marketDisputeData.stakeAmount = tokenStakeForDispute;
    _marketDisputeData.tokensLockedUntill = drTokenLockPeriod.add(now);
    _marketDisputeData.rewardForVoting = rewardForVoting;
    emit DisputeRaised(_marketId, _msgSenderAddress, _proposedValue, drVotePeriod.add(now), _description);
    _setMarketStatus(_marketId, IAllMarkets.PredictionStatus.InDispute);
  }

  /**
  * @dev Submit a vote to resolve a disputed market, by depositing tokens to the contract
  * deposited tokens will be locked for `drTokenLockPeriod` period of time and then they can be claimable
  * @param _marketId Index of market.
  * @param _voteValue The Number of tokens to deposit, these will be counted as the vote value of the user
  * @param _choice Boolean variable defining user accepting or rejecting the dispute
  */
  function submitVote(uint256 _marketId, uint256 _voteValue, bool _choice) external {
    address payable _msgSenderAddress = _msgSender();
    DisputeData storage _marketDisputeData = marketDisputeData[_marketId];
    require(now <= _marketDisputeData.allowVoteUntil);
    _transferTokenFrom(_msgSenderAddress, address(this), _voteValue);
    if(_marketDisputeData.userVoteValue[_msgSenderAddress] == 0) {
      userData[_msgSenderAddress].disputesParticipated.push(_marketId);
    }
    _marketDisputeData.userVoteValue[_msgSenderAddress] = _marketDisputeData.userVoteValue[_msgSenderAddress].add(_voteValue);
    _marketDisputeData.totalVoteValue = _marketDisputeData.totalVoteValue.add(_voteValue);
    if(_choice) {
      _marketDisputeData.acceptedVoteValue = _marketDisputeData.acceptedVoteValue.add(_voteValue);
    } else {
      _marketDisputeData.rejectedVoteValue = _marketDisputeData.rejectedVoteValue.add(_voteValue);
    }
    emit Vote(_marketId, _msgSenderAddress, _choice, _voteValue, now);
  }

  /**
  * @dev Declare the result of the disputed market after the voting time is completed
  * @param _marketId Index of market.
  */
  function declareResult(uint256 _marketId) external {
    DisputeData storage _marketDisputeData = marketDisputeData[_marketId];
    require(now > _marketDisputeData.allowVoteUntil);
    require(allMarkets.marketStatus(_marketId) == IAllMarkets.PredictionStatus.InDispute);
    uint256 plotStakedOnMarket = allMarkets.getTotalStakedWorthInPLOT(_marketId);
    _marketDisputeData.closed = true;
    if(
      (_marketDisputeData.totalVoteValue >= voteThresholdMultiplier.mul(plotStakedOnMarket)) &&
      (_marketDisputeData.acceptedVoteValue > _marketDisputeData.rejectedVoteValue)
    ) {
        _resolveDispute(_marketId, true, _marketDisputeData.proposedValue);
    } else {
      _resolveDispute(_marketId, false, 0);
    }
    if(_marketDisputeData.totalVoteValue > 0) {
      IMaster(masterAddress).withdrawForDRVotingRewards(_marketDisputeData.rewardForVoting);
    }
  }

  /**
  * @dev Resolve the dispute
  * @param _marketId Index of market.
  * @param accepted Flag mentioning if dispute is accepted or not
  * @param finalResult The final correct value of market currency.
  */
  function _resolveDispute(uint256 _marketId, bool accepted, uint256 finalResult) internal {
    DisputeData storage _marketDisputeData = marketDisputeData[_marketId];
    uint256 _tokensToTransfer = _marketDisputeData.stakeAmount;
    delete _marketDisputeData.stakeAmount;
    if(accepted) {
      allMarkets.postMarketResult(_marketId, finalResult);
      _transferAsset(_marketDisputeData.raisedBy, _tokensToTransfer);
    } else {
      _transferAsset(masterAddress, _tokensToTransfer);
    }
    _setMarketStatus(_marketId, IAllMarkets.PredictionStatus.Settled);
    emit DisputeResolved(_marketId, accepted);
  }

  /**
  * @dev Claim rewards earned by participating in the DR voting
  * @param _user Address of the user
  * @param _maxRecord Maximum number of records to claim reward for
  */
  function claimReward(address _user, uint256 _maxRecord) external {
    uint _incentive;
    UserData storage _userData = userData[_user];
    uint len = _userData.disputesParticipated.length;
    uint lastClaimed = len;
    uint count;
    uint _marketId;
    for(uint i = _userData.lastClaimedIndex; i < len && count < _maxRecord; i++) {
      _marketId = _userData.disputesParticipated[i];
      DisputeData storage _marketDisputeData = marketDisputeData[_marketId];
      if(_marketDisputeData.closed && now > _marketDisputeData.tokensLockedUntill) {
        if(!_userData.claimedReward[_marketId]) {
          _incentive = _incentive.add((_marketDisputeData.rewardForVoting.mul(_marketDisputeData.userVoteValue[_user])).div(_marketDisputeData.totalVoteValue));
          _userData.claimedReward[_marketId] = true;
          count++;
        }
      } else {
        if(lastClaimed == len) {
          lastClaimed = i;
        }
      }
    }
    require(_incentive > 0);
    _userData.lastClaimedIndex = lastClaimed;
    _transferAsset(_user, _incentive);
    emit ClaimReward(_user, _incentive);
  }

  /**
  * @dev Get pending rewards earned by participating in the DR voting
  * @param _user Address of the user
  * @return Pending reward for the user
  */
  function getPendingReward(address _user) external view returns(uint _pendingReward){
    UserData storage _userData = userData[_user];
    uint len = _userData.disputesParticipated.length;
    uint _marketId;
    for(uint i = _userData.lastClaimedIndex; i < len; i++) {
      _marketId = _userData.disputesParticipated[i];
      DisputeData storage _marketDisputeData = marketDisputeData[_userData.disputesParticipated[i]];
      if(!_userData.claimedReward[_marketId] && _marketDisputeData.closed && now > _marketDisputeData.tokensLockedUntill) {
        _pendingReward = _pendingReward.add((_marketDisputeData.rewardForVoting.mul(_marketDisputeData.userVoteValue[_user])).div(_marketDisputeData.totalVoteValue));
      }
    }
  }

  /**
  * @dev Function to withdraw tokens, deposited by user while submitting the vote
  * @param _marketId Index of market
  */ 
  function withdrawLockedTokens(uint256 _marketId) external {
    address payable _msgSenderAddress = _msgSender();
    DisputeData storage _marketDisputeData = marketDisputeData[_marketId];
    require(_marketDisputeData.closed && now > _marketDisputeData.tokensLockedUntill);
    uint256 _tokensToTransfer = _marketDisputeData.userVoteValue[_msgSenderAddress];
    require(_tokensToTransfer > 0);
    delete _marketDisputeData.userVoteValue[_msgSenderAddress];
    _transferAsset(_msgSenderAddress, _tokensToTransfer);
    emit WithdrawnTokens(_marketId, _msgSenderAddress, _tokensToTransfer);
  }

  /**
  * @dev Function to burn locked tokens of fraudulent voter and transfer them to DAO contract
  * @param _user User address to burn tokens
  * @param _marketId Index of market
  */ 
  function burnLockedTokens(address _user, uint256 _marketId) external onlyAuthorized {
    DisputeData storage _marketDisputeData = marketDisputeData[_marketId];
    require(allMarkets.marketStatus(_marketId) == IAllMarkets.PredictionStatus.Settled);
    require(now <= _marketDisputeData.tokensLockedUntill);
    uint256 _tokensToTransfer = _marketDisputeData.userVoteValue[_user];
    delete _marketDisputeData.userVoteValue[_user];
    _transferAsset(masterAddress, _tokensToTransfer);
  }

  /**
  * @dev Internal function set market status
  * @param _marketId Index of market
  * @param _status Status of market to set
  */    
  function _setMarketStatus(uint256 _marketId, IAllMarkets.PredictionStatus _status) internal {
    allMarkets.setMarketStatus(_marketId, _status);
  }

  /**
  * @dev Internal function to call transferFrom function of PLOT token
  * @param _from From address
  * @param _to Recipient Address
  * @param _amount Number of tokens in wei
  */
  function _transferTokenFrom(address _from, address _to, uint256 _amount) internal {
    IToken(plotToken).transferFrom(_from, _to, _amount);
  }

  /**
  * @dev Transfer PLOT to specified address.
  * @param _recipient The address to transfer the asset of
  * @param _amount The amount which is transfer.
  */
  function _transferAsset(address _recipient, uint256 _amount) internal {
    if(_amount > 0) { 
        require(IToken(plotToken).transfer(_recipient, _amount));
    }
  }

  /**
  * @dev Get user vote value of disputed market
  * @param _user The address to user
  * @param _marketId Index of market
  * @return User vote value of `_marketId`
  */
  function getUserVoteValue(address _user, uint256 _marketId) external view returns(uint256) {
    return marketDisputeData[_marketId].userVoteValue[_user];
  }
}