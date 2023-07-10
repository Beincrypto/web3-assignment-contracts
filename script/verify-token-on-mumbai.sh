#!/usr/bin/env bash

if [ -f .env ]
then
  export $(cat .env | xargs) 
else
    echo "Please set your .env file"
    exit 1
fi

echo "Which contract do you want to verify?"
read contract
echo "Submitting verification request for $contract..."

forge verify-contract --compiler-version v0.8.20+commit.a1b79de6 $contract --num-of-optimizations 200 ./src/token/Token.sol:Token --etherscan-api-key ${ETHERSCAN_API_KEY} --chain-id 80001
