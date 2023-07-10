#!/usr/bin/env bash

if [ -f .env ]
then
  export $(cat .env | xargs) 
else
    echo "Please set your .env file"
    exit 1
fi

echo "Address of the contract do you want to verify?"
read contract

echo "ABI encoded arguments?"
read arguments

echo "Submitting verification request for $contract..."

forge verify-contract --constructor-args $arguments --compiler-version v0.8.20+commit.a1b79de6 $contract --num-of-optimizations 200 ./src/presale/Presale.sol:Presale --etherscan-api-key ${ETHERSCAN_API_KEY} --chain-id 80001
