// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract CrowdFunding {
    address public manager;

    struct Compaign {
        address owner; // Every compaign has a owner
        address payable recipient;
        string cause;
        uint target;
        uint deadline;
        uint minContribution;
        uint totalContributors;
        uint amountRaised;
        uint allowWithdraw;
        bool isCompaignExists;
        bool isCompaignActive;
        bool isVotingOpen;

        mapping (address => uint) contributors;
        mapping (address => bool) hasVoted;
    }
    uint public compaignId;
    mapping (uint => Compaign) public compaigns;

    constructor() {
        manager = msg.sender;
    }

    // Events
    event FundingStarted(uint _compaignID, address _compaignOwner, address _recipient, uint _minCon, uint _target, uint _deadline);
    event VotingStarted(uint _compaignID, address _recipient, string _cause, uint target);
    event VotingEnded(uint _compaignID, address _recipient, string _cause, uint target);

    // Modifiers
    modifier onlyCompaignOwner(uint _compaignID) {
        require (msg.sender == compaigns[_compaignID].owner, "Only compaign owner can access");
        _;
    }

    modifier compaignExists(uint _compaignID) {
        require (compaigns[_compaignID].isCompaignExists == true, "the compaign doesn't exist");
        _;
    }

    // Check function
    function isDeadlineMet(uint _compaignID) public view returns(bool){
        if(compaigns[_compaignID].deadline > block.timestamp){
            return false;
        }
        return true;
    }

    // Methods
    function startCompaign(string calldata _cause, uint _deadline, uint _target, uint _minCont, address payable _recipient) public {
        // target amount shouldnt be equal to 0
        require(_target != 0, "The target amount is equals to 0");

        // minimum contribution shouldnt be equal to 0
        require(_minCont != 0, "The target amount is equals to 0");
        
        // minimum contribution should be greater than target amount
        require(_minCont < _target, "Target is less than minimum contribution");
        
        // recipient shouldnt be zero address
        require(_recipient != address(0), "Recipient address is equals to zero address");
        
        // recipient address shouldnt be equal to contract managers address
        require(_recipient != manager, "Contract owner cant be recipient");

        // recipient address shouldnt be equal to compaign owners address
        require(_recipient != msg.sender, "Compaign owner cant be recipient");

        Compaign storage newComapign = compaigns[compaignId];
        compaignId++;
        newComapign.cause = _cause;
        newComapign.target = _target;
        newComapign.deadline = block.timestamp + _deadline;
        newComapign.minContribution = _minCont;
        newComapign.recipient = _recipient;
        newComapign.isCompaignActive = true;
        newComapign.isCompaignExists = true;
        newComapign.owner = msg.sender;

        emit FundingStarted(compaignId, msg.sender, _recipient, _minCont, _target, _deadline);
    }    

    /*Contributers can send money that should be greater than minimum contribution 
    and owner/manager can not contribute to this crowd funding.*/
    function contribute(uint _compaignID) external payable compaignExists(_compaignID) {        
        // deadline hasnt met
        require(isDeadlineMet(_compaignID) == false, "You cannot contribute now, deadline has passed.");
        
        // owner cant contribute
        require(msg.sender != compaigns[_compaignID].owner, "Compaign owner can't contribute");
        
        // msg.value should be greater than minContribution
        require(msg.value >= compaigns[_compaignID].minContribution, "Contributed amount should be greater than minimum contribution");
        
        // msg.sender shouldnt be zero address
        require(msg.sender != address(0), "Invalid address of the contributor");
        
        // the compaign should be active
        require(compaigns[_compaignID].isCompaignActive == true, "The compaign you're are trying to contribute is not active");

        
        if(compaigns[_compaignID].contributors[msg.sender] == 0) {
            compaigns[_compaignID].totalContributors += 1;
            compaigns[_compaignID].hasVoted[msg.sender] = false;
        }
        compaigns[_compaignID].contributors[msg.sender] += msg.value;
        compaigns[_compaignID].amountRaised += msg.value;
    }

    function checkContribution(uint _compaignID) public view returns(uint) {
        return (compaigns[_compaignID].contributors[msg.sender]);
    }

    // Contributors can withdraw money if deadline has passed and target is not reached.
    function recoverContribution(uint _compaignID) public compaignExists(_compaignID) {        
        // deadline has met
        require(isDeadlineMet(_compaignID) == true, "Deadline hasnt passed");
        
        // target hasnt reached
        require(compaigns[_compaignID].amountRaised < compaigns[_compaignID].target, "The target has reached");
        
        // only contributors can withdraw their contributions
        require(compaigns[_compaignID].contributors[msg.sender] > 0, "Your contribution is 0");

        uint value = compaigns[_compaignID].contributors[msg.sender];
        compaigns[_compaignID].contributors[msg.sender] = 0;
        payable(msg.sender).transfer(value);
    }   

    // voting
    function vote(uint _compaignID) public compaignExists(_compaignID) {
        //voting should be open 
        require(compaigns[_compaignID].isVotingOpen == true, "The voting isn't opened yet.");
        
        // only contributors can vote
        require(compaigns[_compaignID].contributors[msg.sender] > 0, "Your contribution is 0");
        
        // a contributor can only vote once
        require(compaigns[_compaignID].hasVoted[msg.sender] == false, "Youve already voted.");

        compaigns[_compaignID].allowWithdraw++;
        compaigns[_compaignID].hasVoted[msg.sender] = true;
    }

    function openVoting(uint _compaignID) public compaignExists(_compaignID) onlyCompaignOwner(_compaignID){        
        // deadline has passed
        require(isDeadlineMet(_compaignID) == true, "The deadline hasnt passed");
        
        // target has reached
        require(compaigns[_compaignID].amountRaised >= compaigns[_compaignID].target, "The target hasnt reached");
        
        // voting shouldnt be already open
        require (compaigns[_compaignID].isVotingOpen == false, "The voting is already opened.");

        // compaigns[_compaignID].isCompaignActive = false;
        compaigns[_compaignID].isVotingOpen = true;

        emit VotingStarted(_compaignID, compaigns[_compaignID].recipient, compaigns[_compaignID].cause, compaigns[_compaignID].target);
    }

    function closeVoting(uint _compaignID) public compaignExists(_compaignID) onlyCompaignOwner(_compaignID){
        require(compaigns[_compaignID].isVotingOpen == true, "The voting is already closed");

        compaigns[_compaignID].isVotingOpen = false;
        compaigns[_compaignID].isCompaignActive = false;

        emit VotingEnded(_compaignID, compaigns[_compaignID].recipient, compaigns[_compaignID].cause, compaigns[_compaignID].target);

    }

    function withdrawContribution(uint _compaignID) public compaignExists(_compaignID) onlyCompaignOwner(_compaignID) {        
        // deadline has passed
        require(isDeadlineMet(_compaignID) == true, "The deadline hasnt passed");
        
        // target has reached
        require(compaigns[_compaignID].amountRaised >= compaigns[_compaignID].target, "The target hasnt reached");

        // voting shouldnt be open
        require (compaigns[_compaignID].isVotingOpen == false, "The voting is open");
        
        // votes in favor are more than 50%
        //(compaigns[_compaignID].allowWithdraw / compaigns[_compaignID].totalContributors) * 100 > 50 - why no this?
        // 3/5 = 0.6 * 100 - there is no floating point in Solidity
        require(((compaigns[_compaignID].allowWithdraw * 100) / compaigns[_compaignID].totalContributors) > 50, "Less than 51% contributors voted for allowWithdraw");

        // the recipient is defined as payable
        (compaigns[_compaignID].recipient).transfer(compaigns[_compaignID].amountRaised);

    }
    
}