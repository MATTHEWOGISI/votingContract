// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/** 
 * @title Ballot
 * @dev Implements voting process along with vote delegation
 */
import "./IVotingContract.sol";

contract VotingContract is IVotingContract {
   
    struct Voter {
        uint weight; // weight is accumulated by delegation
        bool voted;  // if true, that person already voted
        address delegate; // person delegated to
        uint vote;   // index of the voted proposal
    }

    struct candidate {
        // If you can limit the length to a certain number of bytes, 
        // always use one of bytes1 to bytes32 because they are much cheaper
        uint candidateId;
        bytes32 candidateName;   // short name (up to 32 bytes)
        uint voteCount; // number of accumulated votes
    }

    address public chairMan;

    mapping(address => Voter) public voters;

    candidate[] public candidates;

    constructor() {
        chairMan = msg.sender;
        voters[chairMan].weight = 1;       
    }
    
    /** 
     * @dev Give 'voter' the right to vote on this ballot. May only be called by 'chairperson'.
     * @param voter address of voter
     */
    function giveRightToVote(address voter) public {
        require(
            msg.sender == chairMan,
            "Only chairMan can give right to vote."
        );
        require(
            !voters[voter].voted,
            "The voter already voted."
        );
        require(voters[voter].weight == 0);
        voters[voter].weight = 1;
    }

    /**
     * @dev Delegate your vote to the voter 'to'.
     * @param to address to which vote is delegated
     */
    function delegate(address to) public {
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "You already voted.");
        require(to != msg.sender, "Self-delegation is disallowed.");

        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;

            // We found a loop in the delegation, not allowed.
            require(to != msg.sender, "Found loop in delegation.");
        }
        sender.voted = true;
        sender.delegate = to;
        Voter storage delegate_ = voters[to];
        if (delegate_.voted) {
            // If the delegate already voted,
            // directly add to the number of votes
            candidates[delegate_.vote].voteCount += sender.weight;
        } else {
            // If the delegate did not vote yet,
            // add to her weight.
            delegate_.weight += sender.weight;
        }
    }
        
    function winningCandidate() public view
            returns (uint winningCandidate_)
    {
        uint winningVoteCount = 0;
        for (uint p = 0; p < candidates.length; p++) {
            if (candidates[p].voteCount > winningVoteCount) {
                winningVoteCount = candidates[p].voteCount;
                winningCandidate_ = p;
            }
        }
    }

    /** 
     * @dev Calls winningProposal() function to get the index of the winner contained in the proposals array and then
     * @return winnerName_ the name of the winner
     */
    function winnerName() public view
            returns (bytes32 winnerName_)
    {
        winnerName_ = candidates[winningCandidate()].candidateName;
    }

  function addCandidate(bytes32 name) external override returns(bool)
  {       
            // 'Proposal({...})' creates a temporary
            // Proposal object and 'proposals.push(...)'
            // appends it to the end of 'proposals'.
            uint newCandidateId = candidates.length + 1 ;

            candidates.push(candidate({
                candidateId: newCandidateId,
                candidateName: name ,
                voteCount: 0
            }));       

        return true; 
  }
    
    function voteCandidate(uint candidateId) external override returns(bool)
    {
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "Has no right to vote");
        require(!sender.voted, "Already voted.");
        sender.voted = true;
        sender.vote = candidateId;

        // If 'proposal' is out of the range of the array,
        // this will throw automatically and revert all
        // changes.
        candidates[candidateId].voteCount += sender.weight;

        return true;
    }

    //getWinner returns the name of the winner
    function getWinner() external override view returns(bytes32)
    {
        return candidates[winningCandidate()].candidateName;
    }


}