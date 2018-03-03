/*
  Copyright 2017 Sharder Foundation.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

  We upgrade the Sharder Token to v2.0:
    a) Adding the emergency transfer functionality for owner.
    b) Removing the logic of crowdsale according to standard MintToken in order to improve the neatness and
    legibility of the Sharder smart contract coding.
    c) Adding the broadcast event 'Frozen'.
    d) Changing the parameters of name, symbol, decimal, etc. to lower-case according to convention.
    e) The global parameter is added to our smart contact in order to avoid that the exchanges trade Sharder tokens
    before officials partnering with Sharder.
    f) Add SSHolders to facilitate the exchange of the current ERC-20 token to the Sharder Chain token later this year
    when Sharder Chain is online.
    g) Lockup and lock-up query functions.
  The deplyed online contract you can found at: https://etherscan.io/address/XXXXXX

  Sharder Token v1.0 is expired. You can check code and get details on branch 'sharder-token-v1.0'.
*/
pragma solidity ^0.4.18;

/**
 * Math operations with safety checks
 */
library SafeMath {
    function mul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

/**
* @title Sharder Token v2.0. SS(Sharder) is upgrade from SS(Sharder Storage).
* @author Ben - <xy@sharder.org>.
* @dev https://github.com/ethereum/EIPs/issues/20
* @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
*/
contract SharderToken {
    using SafeMath for uint;
    string public constant name = "Sharder";
    string public constant symbol = "SS";
    uint public constant decimals = 18;
    uint public totalSupply;

    mapping (address => mapping (address => uint256))  public allowed;
    mapping (address => uint) internal balances;

    /// The owner of contract
    address public owner;

    /// The admin account of contract
    address public admin;

    mapping (address => bool) internal accountLockup;
    mapping (address => uint) public accountLockupTime;
    mapping (address => bool) public frozenAccounts;

    ///   +--------------------------------------------------------------+
    ///   |                 SS(Sharder) Token Issue Plan                 |
    ///   +--------------------------------------------------------------+
    ///   |                    First Round(Crowdsale)                    |
    ///   +--------------------------------------------------------------+
    ///   |     Total Sale    |      Airdrop      |  Community Reserve   |
    ///   +--------------------------------------------------------------+
    ///   |       50%         |        10%        |         10%          |
    ///   +--------------------------------------------------------------+
    ///   |     250,000,000   |     50,000,000    |     50,000,000       |
    ///   +--------------------------------------------------------------+
    ///   | Team Reserve(10% - 50,000,000 SS): Realse in 3 years period  |
    ///   +--------------------------------------------------------------+
    ///   | System Reward(20% - 100,000,000 SS): Reward by Sharder Chain |
    ///   +--------------------------------------------------------------+
    uint256 internal constant CROWDSALE_ISSUED_SS = 350000000000000000000000000;

    ///First round tokens whether isssued.
    bool internal firstRoundTokenIssued = false;

    /// Issue event index starting from 0.
    uint256 internal issueIndex = 0;

    /// Emitted when a function is invocated by unauthorized addresses.
    event InvalidCaller(address caller);

    /// Emitted when a function is invocated without the specified preconditions.
    /// This event will not come alone with an exception.
    event InvalidState(bytes msg);

    /// Emitted for each sucuessful token purchase.
    event Issue(uint issueIndex, address addr, uint ethAmount, uint tokenAmount);

    // This notifies clients about the amount to transfer
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount to approve
    event Approval(address indexed owner, address indexed spender, uint value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal isNotFrozen {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balances[_from] >= _value);
        // Check for overflows
        require(balances[_to] + _value > balances[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balances[_from] + balances[_to];
        // Subtract from the sender
        balances[_from] -= _value;
        // Add the same to the recipient
        balances[_to] += _value;
        Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balances[_from] + balances[_to] == previousBalances);
    }

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _transferTokensWithDecimal The amount to be transferred.
    */
    function transfer(address _to, uint _transferTokensWithDecimal) public {
        _transfer(msg.sender, _to, _transferTokensWithDecimal);
    }

    /**
    * @dev Transfer tokens from one address to another
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _transferTokensWithDecimal uint the amout of tokens to be transfered
    */
    function transferFrom(address _from, address _to, uint _transferTokensWithDecimal) public returns (bool success) {
        require(_transferTokensWithDecimal <= allowed[_from][msg.sender]);     // Check allowance
        allowed[_from][msg.sender] -= _transferTokensWithDecimal;
        _transfer(_from, _to, _transferTokensWithDecimal);
        return true;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public constant returns (uint balance) {
        return balances[_owner];
    }

    /**
     * Set allowance for other address
     * Allows `_spender` to spend no more than `_approveTokensWithDecimal` tokens in your behalf
     *
     * @param _spender The address authorized to spend
     * @param _approveTokensWithDecimal the max amount they can spend
     */
    function approve(address _spender, uint256 _approveTokensWithDecimal) public isNotFrozen returns (bool success) {
        allowed[msg.sender][_spender] = _approveTokensWithDecimal;
        Approval(msg.sender, _spender, _approveTokensWithDecimal);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens than an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint specifing the amount of tokens still avaible for the spender.
     */
    function allowance(address _owner, address _spender) internal constant returns (uint remaining) {
        return allowed[_owner][_spender];
    }

    /**
       * Destroy tokens
       * Remove `_value` tokens from the system irreversibly
       *
       * @param _burnedTokensWithDecimal the amount of reserve tokens. !!IMPORTANT is 18 DECIMALS
       */
    function burn(uint256 _burnedTokensWithDecimal) public returns (bool success) {
        require(balances[msg.sender] >= _burnedTokensWithDecimal);   /// Check if the sender has enough
        balances[msg.sender] -= _burnedTokensWithDecimal;            /// Subtract from the sender
        totalSupply -= _burnedTokensWithDecimal;                      /// Updates totalSupply
        Burn(msg.sender, _burnedTokensWithDecimal);
        return true;
    }

    /**
     * Destroy tokens from other account
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _burnedTokensWithDecimal the amount of reserve tokens. !!! IMPORTANT is 18 DECIMALS
     */
    function burnFrom(address _from, uint256 _burnedTokensWithDecimal) public returns (bool success) {
        require(balances[_from] >= _burnedTokensWithDecimal);                /// Check if the targeted balance is enough
        require(_burnedTokensWithDecimal <= allowed[_from][msg.sender]);    /// Check allowance
        balances[_from] -= _burnedTokensWithDecimal;                        /// Subtract from the targeted balance
        allowed[_from][msg.sender] -= _burnedTokensWithDecimal;             /// Subtract from the sender's allowance
        totalSupply -= _burnedTokensWithDecimal;                            /// Update totalSupply
        Burn(_from, _burnedTokensWithDecimal);
        return true;
    }

    /*
     * MODIFIERS
     */
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyAdmin {
        require(msg.sender == owner || msg.sender == admin);
        _;
    }

    modifier isNotFrozen {
        require( frozenAccounts[msg.sender] != true && now > accountLockupTime[msg.sender] );
        _;
    }

    /**
     * CONSTRUCTOR
     * @dev Initialize the Sharder Token v2.0
     */
    function SharderToken() public {
        owner = msg.sender;
        admin = msg.sender;
        totalSupply = FIRST_ROUND_ISSUED_SS;
        issueFirstRoundToken();
        // Issue first round tokens
    }

    /*
     * PUBLIC FUNCTIONS
     */
    ///@dev Set admin account to manage contract.
    function setAdmin(address _address) public onlyOwner {
        admin = _address;
    }

    ///@dev Frozen or unfrozen account.
    function changeAccountFrozenStatus(address _address, bool _frozenStatus) public onlyAdmin {
        frozenAccounts[_address] = _frozenStatus;
    }

    /// @dev Lockup account till the date. Can't lock-up again when this account locked already.
    /// 1 year = 31536000 seconds
    /// 0.5 year = 15768000 seconds
    function lockupAccount(address _address, uint _lockupSeconds) public onlyAdmin {
        require((accountLockup[_address] && now > accountLockupTime[_address]) || !accountLockup[_address]);
        // Frozen
        accountLockupTime[_address] = now + _lockupSeconds;
        accountLockup[_address] = true;
    }

    /// @dev Issue first round tokens to `owner` address.
    function issueFirstRoundToken() onlyOwner internal {
        if (firstRoundTokenIssued) {
            InvalidState("First round tokens has been issued already");
        } else {
            balances[owner] = balances[owner].add(CROWDSALE_ISSUED_SS);
            Issue(issueIndex++, owner, 0, CROWDSALE_ISSUED_SS);
            firstRoundTokenIssued = true;
        }
    }

    /// @dev Issue tokens for reserve.
    /// @param _issueTokensWithDecimal the amount of reserve tokens. !!IMPORTANT is 18 DECIMALS
    function issueReserveToken(uint256 _issueTokensWithDecimal) onlyOwner public {
        balances[owner] = balances[owner].add(_issueTokensWithDecimal);
        totalSupply = totalSupply.add(_issueTokensWithDecimal);
        Issue(issueIndex++, owner, 0, _issueTokensWithDecimal);
    }

    /// @dev This default function reject anyone to purchase the SS(Sharder) token.
    function() public payable {
        revert();
    }

}

