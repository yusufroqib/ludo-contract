// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract LudoGame {
    uint8 public constant WINNING_POSITION = 52;
    uint256 public gameId;
    uint256 public lastRollTime;
    uint8 public currentPlayerTurn;
    uint8 public constant NUM_PLAYERS = 4;
    struct Player {
        uint8 position;
        bool hasStarted;
        bool hasFinished;
    }
    address[] public playerAddresses;
    mapping(address => Player) public players;

    event DiceRolled(
        address indexed player,
        uint8 indexed playerIndex,
        uint8 roll
    );
    event PlayerMoved(
        address indexed player,
        uint8 indexed playerIndex,
        uint8 newPosition
    );
    event GameWon(address indexed player, uint8 indexed playerIndex);

    constructor() {
        gameId = block.timestamp;
        currentPlayerTurn = 0;
        lastRollTime = block.timestamp;
    }

    function joinGame() external {
        require(
            playerAddresses.length < NUM_PLAYERS,
            "Total players filled up"
        );
        require(
            players[msg.sender].hasStarted == false,
            "You have already joined the game."
        );

        Player memory newPlayer = Player({
            position: 0,
            hasStarted: true,
            hasFinished: false
        });

        players[msg.sender] = newPlayer;
        playerAddresses.push(msg.sender);
    }

    function rollDice() public returns (uint8) {
        require(
            playerAddresses.length == NUM_PLAYERS,
            "Number of players not reached yet"
        );
        require(
            msg.sender == playerAddresses[currentPlayerTurn],
            "Not yet your turn"
        );
        require(
            block.timestamp > lastRollTime + 5 seconds,
            "Wait 5 seconds between rolls"
        );

        uint256 randomNumber = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.prevrandao,
                    msg.sender,
                    gameId
                )
            )
        );
        uint8 roll = uint8(randomNumber % 6) + 1;

        lastRollTime = block.timestamp;
        emit DiceRolled(
            playerAddresses[currentPlayerTurn],
            currentPlayerTurn,
            roll
        );

        movePlayer(roll);
        currentPlayerTurn = (currentPlayerTurn + 1) % NUM_PLAYERS;
        return roll;
    }

    function movePlayer(uint8 steps) private {
        Player storage currentPlayer = players[
            playerAddresses[currentPlayerTurn]
        ];

        if (currentPlayer.hasFinished) {
            return;
        }

        uint8 newPosition = currentPlayer.position + steps;

        if (newPosition > WINNING_POSITION) {
            newPosition = WINNING_POSITION - (newPosition - WINNING_POSITION);
        }

        currentPlayer.position = newPosition;
        emit PlayerMoved(
            playerAddresses[currentPlayerTurn],
            currentPlayerTurn,
            newPosition
        );

        if (newPosition == WINNING_POSITION) {
            currentPlayer.hasFinished = true;
            emit GameWon(playerAddresses[currentPlayerTurn], currentPlayerTurn);
        }
    }

    function getGameState()
        public
        view
        returns (
            uint8[NUM_PLAYERS] memory positions,
            bool[NUM_PLAYERS] memory finished
        )
    {
        for (uint8 i = 0; i < NUM_PLAYERS; i++) {
            positions[i] = players[playerAddresses[i]].position;
            finished[i] = players[playerAddresses[i]].hasFinished;
        }
    }

    function resetGame() public {
        gameId = block.timestamp;
        currentPlayerTurn = 0;
        lastRollTime = block.timestamp;

        for (uint8 i = 0; i < NUM_PLAYERS; i++) {
            players[playerAddresses[i]].position = 0;
            players[playerAddresses[i]].hasFinished = false;
            players[playerAddresses[i]].hasStarted = false;
        }
    }
}
