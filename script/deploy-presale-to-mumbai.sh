#!/usr/bin/env bash

if [ -f .env ]
then
  export $(cat .env | xargs) 
else
    echo "Please set your .env file"
    exit 1
fi

echo "Address of the Token contract?"
read token
echo "Creating Presale contract for Token $token..."

forge create ./src/presale/Presale.sol:Presale -i --constructor-args $token --rpc-url ${RPC_URL} --private-key ${PRIVATE_KEY}