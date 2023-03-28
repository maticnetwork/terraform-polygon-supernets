#!/bin/bash

nodes=4
prefix=test-chain

# Create node folder and generate key pairs
# Equivalent to running $ polygon-edge secrets init --data-dir <node-name>
function init_secrets {
	# Create node folders
	mkdir -p $1-$2/consensus $1-$2/libp2p

	# Generate keys
	polycli wallet create --raw-entropy --root-only --words 21 > $1-$2/poly-wallet.json
	polycli nodekey --protocol libp2p --key-type secp256k1 > $1-$2/poly-nodekey.json

	# Move keys to correct folders
	cat $1-$2/poly-wallet.json | jq -r '.BLS.HexPrivateKey' | tr -d "\n" > $1-$2/consensus/validator-bls.key
	cat $1-$2/poly-wallet.json | jq -r '.HexPrivateKey' | tr -d "\n" > $1-$2/consensus/validator.key
	cat $1-$2/poly-nodekey.json | jq -r '.FullPrivateKey' | tr -d "\n" > $1-$2/libp2p/libp2p.key

	# Display node keys data
	PUBLIC_KEY=$(jq --raw-output '.ETHAddress' <$1-$2/poly-wallet.json)
	BLS_PUBLIC_KEY=$(jq --raw-output '.BLS.HexPublicKey' <$1-$2/poly-wallet.json)
	NODE_ID=$(jq --raw-output '.PublicKey' <$1-$2/poly-nodekey.json)
	echo -e "Public key (address) \t= $PUBLIC_KEY" # keep only first 32 chars
	echo -e "BLS Public key \t\t= 0x$BLS_PUBLIC_KEY"
	echo -e "Node ID \t\t= $NODE_ID"
}

echo 🔐 Generating node keys...
for ((i = 1; i <= $nodes; i++ )); do
	echo [$prefix-$i]
	rm -r $prefix-$i
	init_secrets $prefix $i
done

echo; echo 📃 Generating genesis file...
rm genesis.json || true
echo polygon-edge genesis --consensus ibft --ibft-validators-prefix-path $prefix --bootnode /ip4/127.0.0.1/tcp/10001/p2p/...

echo; echo ✅ Run validator nodes...
for ((i = 1; i <= $nodes; i++ )); do
	echo polygon-edge server --data-dir ./$prefix-$i --chain genesis.json --grpc-address :${i}0000 --libp2p :${i}0001 --jsonrpc :${i}0002 --seal
done

echo; echo 🤖 Run a full-node...
rm -r $prefix || true
echo polygon-edge server --data-dir ./$prefix --chain genesis.json --grpc-address :$(( $nodes + 1 ))0000 --libp2p :$(( $nodes + 1 ))0001 --jsonrpc :$(( $nodes + 1 ))0002
