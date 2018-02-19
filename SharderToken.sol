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
*/
pragma solidity ^0.4.11;

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
 * @title Standard ERC20 token
 *
 * @dev Implemantation of the basic standart token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract TokenERC20  {
    using SafeMath for uint;

    uint public totalSupply;

    mapping (address => mapping (address => uint)) allowed;
    mapping(address => uint) balances;

    // This notifies clients about the amount to transfer
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount to approve
    event Approval(address indexed owner, address indexed spender, uint value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    /**
    * @dev Fix for the ERC20 short address attack.
    */
    modifier onlyPayloadSize(uint size) {
        require(msg.data.length < size + 4);
        _;
    }

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint _value) internal onlyPayloadSize(2 * 32) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
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
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint the amout of tokens to be transfered
     */
    function transferFrom(address _from, address _to, uint _value) internal onlyPayloadSize(3 * 32) {
        var _allowance = allowed[_from][msg.sender];

        // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
    }

    /**
     * @dev Aprove the passed address to spend the specified amount of tokens on beahlf of msg.sender.
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint _value) public {
        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require((_value != 0) && (allowed[msg.sender][_spender] != 0));

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
    }

    /**
     * @dev Function to check the amount of tokens than an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint specifing the amount of tokens still avaible for the spender.
     */
    function allowance(address _owner, address _spender) public constant returns (uint remaining) {
        return allowed[_owner][_spender];
    }


    /**
       * Destroy tokens
       * Remove `_value` tokens from the system irreversibly
       *
       * @param _value the amount of money to burn
       */
    function burn(uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);   /// Check if the sender has enough
        balances[msg.sender] -= _value;            /// Subtract from the sender
        totalSupply -= _value;                      /// Updates totalSupply
        Burn(msg.sender, _value);
        return true;
    }

    /**
     * Destroy tokens from other account
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value);                /// Check if the targeted balance is enough
        require(_value <= allowed[_from][msg.sender]);    /// Check allowance
        balances[_from] -= _value;                         /// Subtract from the targeted balance
        allowed[_from][msg.sender] -= _value;             /// Subtract from the sender's allowance
        totalSupply -= _value;                              /// Update totalSupply
        Burn(_from, _value);
        return true;
    }

}


/// @title Sharder Protocol Token.
/// For more information about this token sale, please visit https://sharder.org
/// @author Ben - <xy@sharder.org>.
contract SharderToken is TokenERC20 {
    string public constant NAME = "SharderStorageTester";
    string public constant SYMBOL = "SST";
    uint public constant DECIMALS = 18;

    ///   +-----------------------------------------------------------------------------------+
    ///   |                        SS Token Issue Plan - First Round                          |
    ///   +-----------------------------------------------------------------------------------+
    ///   |  Total Sale  |   Airdrop    |  Community Reserve  |  Team Reserve | System Reward |
    ///   +-----------------------------------------------------------------------------------+
    ///   |     50%      |     10%      |         10%         |  Don't Issued | Don't Issued  |
    ///   +-----------------------------------------------------------------------------------+
    ///   | 250,000,000  |  50,000,000  |     50,000,000      |      None     |      None     |
    ///   +-----------------------------------------------------------------------------------+
    uint256 public constant FIRST_ROUND_ISSUED_SS = 300000000;

    /// Max promotion
    uint256 public constant MAX_PROMOTION_SS = 2000000;

    /// Maximum amount of fund to be raised, the sale ends on reaching this amount.
    /// We'll adjust hard cap in Feb. 21.
    uint256 public constant HARD_CAP = 3 ether;

    /// We split the entire token sale period into 2 phases.
    /// The real price for phase is `(1 + bonusPercentages[i]/100.0) * BASE_RATE`.
    /// The first phase of crowdsale has a much higher bonus.
    uint8[2] public bonusPercentages = [
    20,
    0
    ];

    /// Base exchange rate is set to 1 ETH = 32000 SS.
    /// We'll adjust rate base the 7-day average close price (Feb.15 through Feb.21, 2018) on CoinMarketCap.com at Feb.21.
    /// Test network set to 1 ETH = 66666666 SS.
    uint256 public constant BASE_RATE = 66666666;

    uint public constant NUM_OF_PHASE = 2;

    /// Each phase contains exactly 15250 Ethereum blocks, which is roughly 3 days,
    /// See https://www.ethereum.org/crowdsale#scheduling-a-call
    /// Test network set to 0.25 hour = 53 blocks, total time is 1 hour.
    uint16 public constant BLOCKS_PER_PHASE = 53;

    /// Min gas.
    uint256 public constant GAS_MIN = 1;

    /// Max gas.
    uint256 public constant GAS_MAX = 6000000;

    /// Min contribution: 0.01
    uint256 public constant CONTRIBUTION_MIN = 10000000000000000;

    /// Max contribution: 0.5
    uint256 public constant CONTRIBUTION_MAX = 500000000000000000;


    /// This is where we hold ETH during this token sale. We will not transfer any Ether
    /// out of this address before we invocate the `close` function to finalize the sale.
    /// This promise is not guanranteed by smart contract by can be verified with public
    /// Ethereum transactions data available on several blockchain browsers.
    /// This is the only address from which `start` and `close` can be invocated.
    ///
    /// Note: this will be initialized during the contract deployment.
    address public target;

    /// `firstblock` specifies from which block our token sale starts.
    /// This can only be modified once by the owner of `target` address.
    uint public firstblock = 0;

    /// Indicates whether unsold token have been issued. This part of LRC token
    /// is managed by the project team and is issued directly to `target`.
    bool public unsoldTokenIssued = false;

    /// Received Ether
    uint256 public totalEthReceived = 0;

    /// Sold SS
    uint256 public soldSS = 0;

    /// Issue event index starting from 0.
    uint256 public issueIndex = 0;

    /*
     * EVENTS
     */
    /// Emitted only once after token sale starts.
    event SaleStarted();

    /// Emitted only once after token sale ended (all token issued).
    event SaleEnded();

    /// Emitted when a function is invocated by unauthorized addresses.
    event InvalidCaller(address caller);

    /// Emitted when a function is invocated without the specified preconditions.
    /// This event will not come alone with an exception.
    event InvalidState(bytes msg);

    /// Emitted for each sucuessful token purchase.
    event Issue(uint issueIndex, address addr, uint ethAmount, uint tokenAmount);

    /// Emitted if the token sale succeeded.
    event SaleSucceeded();

    /// Emitted if the token sale failed.
    /// When token sale failed, all Ether will be return to the original purchasing
    /// address with a minor deduction of transaction fee（gas)
    event SaleFailed();

    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);

    /*
     * MODIFIERS
     */
    modifier onlyOwner {
        require(msg.sender == target);
        _;
    }

    modifier beforeStart {
        require(!saleStarted());
        _;
    }

    modifier inProgress {
        require(saleStarted() && !saleEnded());
        _;
    }

    modifier afterEnd {
        require(saleEnded());
        _;
    }

    /**
     * CONSTRUCTOR
     *
     * @dev Initialize the Sharder Token
     */
    function SharderToken() public {
        target = msg.sender;
        totalSupply = FIRST_ROUND_ISSUED_SS;
    }

    /*
     * PUBLIC FUNCTIONS
     * @dev Start the token sale.
     */
    function startCrowdsale(uint _firstblock) public onlyOwner beforeStart {
        require(_firstblock > block.number);
        firstblock = _firstblock.add(12);
        SaleStarted();
    }

    /// @dev Triggers unsold tokens to be issued to `target` address.
    function closeCrowdsale() public onlyOwner afterEnd {
        require(!unsoldTokenIssued);
        issueUnsoldToken();
        SaleSucceeded();
    }

    /// @dev Returns the current price.
    function price() public view returns (uint tokens) {
        return computeTokenAmount(1 ether);
    }

    /// @dev This default function allows token to be purchased by directly
    /// sending ether to this smart contract.
    function () public payable {
        issueToken(msg.sender);
    }

    /// @dev Issue token based on Ether received.
    /// @param recipient Address that newly issued token will be sent to.
    function issueToken(address recipient) public payable inProgress {
        //amount check:  We only accept 0.01ETH <= contribution <= 0.5ETH.
        assert(CONTRIBUTION_MIN <=  msg.value && msg.value <= CONTRIBUTION_MAX);

//        //gas check: We only accept 21000 <= gas <= 60000.
//        assert(GAS_MIN <= msg.gas && msg.gas <= GAS_MAX);

        uint tokens = computeTokenAmount(msg.value);

        totalEthReceived = totalEthReceived.add(msg.value);

        soldSS = soldSS.add(tokens.div(1000000000000000000));

        balances[recipient] = balances[recipient].add(tokens);

        Issue(issueIndex++,recipient,msg.value,tokens);

        require(target.send(msg.value));
    }

    /// @dev Issue token for reserve.
    /// @param recipient Address that newly issued token will be sent to.
    function issueReserveToken(address recipient, uint256 issueTokenAmount) onlyOwner public {
        uint256 ssAmount = issueTokenAmount.mul(1000000000000000000);
        balances[recipient] = balances[recipient].add(ssAmount);
        totalSupply = totalSupply.add(issueTokenAmount);
        Issue(issueIndex++,recipient,0,ssAmount);
    }

    /*
     * INTERNAL FUNCTIONS
     */
    /// @dev Compute the amount of SS token that can be purchased.
    /// @param ethAmount Amount of Ether to purchase SS.
    /// @return Amount of SS token to purchase
    function computeTokenAmount(uint ethAmount) internal view returns (uint tokens) {
        uint phase = (block.number - firstblock).div(BLOCKS_PER_PHASE);

        // A safe check
        if (phase >= bonusPercentages.length) {
            phase = bonusPercentages.length - 1;
        }

        uint tokenBase = ethAmount.mul(BASE_RATE);

        //Check promotion supply and phase bonus
        uint tokenBonus = 0;
        if(totalEthReceived * BASE_RATE < MAX_PROMOTION_SS) {
            tokenBonus = tokenBase.mul(bonusPercentages[phase]).div(100);
        }

        tokens = tokenBase.add(tokenBonus);
    }

    /// @dev Issue unsold token to `target` address.
    function issueUnsoldToken() internal {
        if (unsoldTokenIssued) {
            InvalidState("Unsold token has been issued already");
        } else {
            // Add another safe guard
            require(soldSS > 0);

            uint256 unsoldSS = totalSupply.sub(soldSS).mul(1000000000000000000);
            // Issue 'unsoldToken' to the target account.
            balances[target] = balances[target].add(unsoldSS);
            Issue(issueIndex++,target,0,unsoldSS);

            unsoldTokenIssued = true;
        }
    }


    /// @return true if sale has started, false otherwise.
    function saleStarted() public constant returns (bool) {
        return (firstblock > 0 && block.number >= firstblock);
    }

    /// @return true if sale has ended, false otherwise.
    function saleEnded() public constant returns (bool) {
        return firstblock > 0 && (saleDue() || hardCapReached());
    }

    /// @return true if sale is due when the last phase is finished.
    function saleDue() public constant returns (bool) {
        return block.number >= firstblock + BLOCKS_PER_PHASE * NUM_OF_PHASE;
    }

    /// @return true if the hard cap is reached.
    function hardCapReached() public constant returns (bool) {
        return totalEthReceived >= HARD_CAP;
    }
}

