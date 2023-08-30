# Implementation of D21 voting method as solidity smart contract
"Janečkova metoda D21" @see https://www.ih21.org/o-metode

## Task description
This project was created as part applicaation to *Ethereum Summer Trainee Program*

You can find full description of task here https://courses.fit.cvut.cz/NIE-BLO/tutorials/05/index.html#_semestral-work-implementation-of-d21-voting-method

Project was created using `brownie` framework, `python3`.8 and deprecated `ganache-cli` (needed for testing and deployement in brownie)

## Resources
### These links are left here as learning resources that I have gone though in order to create this project, and that I personaly recommend to check out
Project implemetation was inspired by Lottery smart contract:
- video: https://www.youtube.com/watch?v=HR679xTt8tg
- repo: https://github.com/jspruance/block-explorer-tutorials/blob/main/smart-contracts/solidity/Lottery.sol

Brownie learning resource:
- https://www.youtube.com/watch?v=OeHYm7CXNsw
- https://github.com/smartcontractkit/full-blockchain-solidity-course-py#lesson-5-brownie-simple-storage

Contract security check (basicly video from where I took how to use `slither`):
- https://www.youtube.com/watch?v=TmZ8gH-toX0
- https://github.com/PatrickAlphaC/hardhat-security-fcc/#tools

## Gas usage optimalizations
I did not use any specific tool to monitor gas usage of this contract

I only used tips from internet