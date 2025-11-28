// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title SimpleVotingSystem
 * @dev Basic single-poll voting contract with one vote per address
 * @notice Deployer defines options; users vote once; contract tracks tallies and winning option
 */
contract SimpleVotingSystem {
    address public owner;

    struct Option {
        string name;
        uint256 voteCount;
    }

    Option[] public options;

    // voter => hasVoted
    mapping(address => bool) public hasVoted;
    // voter => option index
    mapping(address => uint256) public voteOf;

    event OptionAdded(uint256 indexed index, string name);
    event Voted(address indexed voter, uint256 indexed optionIndex);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    constructor(string[] memory optionNames) {
        owner = msg.sender;
        for (uint256 i = 0; i < optionNames.length; i++) {
            options.push(Option({name: optionNames[i], voteCount: 0}));
            emit OptionAdded(i, optionNames[i]);
        }
    }

    /**
     * @dev Add a new option (owner only) before voting or even during voting
     */
    function addOption(string calldata name) external onlyOwner {
        options.push(Option({name: name, voteCount: 0}));
        emit OptionAdded(options.length - 1, name);
    }

    /**
     * @dev Cast a vote for an option index
     * @param optionIndex Index in options array
     */
    function vote(uint256 optionIndex) external {
        require(!hasVoted[msg.sender], "Already voted");
        require(optionIndex < options.length, "Invalid option");

        hasVoted[msg.sender] = true;
        voteOf[msg.sender] = optionIndex;

        options[optionIndex].voteCount += 1;

        emit Voted(msg.sender, optionIndex);
    }

    /**
     * @dev Get number of options
     */
    function getOptionsCount() external view returns (uint256) {
        return options.length;
    }

    /**
     * @dev Compute current winning option index and its vote count
     */
    function winningOption() public view returns (uint256 winningIndex, uint256 winningVotes) {
        uint256 count = options.length;
        for (uint256 i = 0; i < count; i++) {
            if (options[i].voteCount > winningVotes) {
                winningVotes = options[i].voteCount;
                winningIndex = i;
            }
        }
    }

    /**
     * @dev Get name of winning option
     */
    function winnerName() external view returns (string memory) {
        (uint256 idx, ) = winningOption();
        if (options.length == 0) return "";
        return options[idx].name;
    }

    /**
     * @dev Transfer contract ownership
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Zero address");
        address prev = owner;
        owner = newOwner;
        emit OwnershipTransferred(prev, newOwner);
    }
}
