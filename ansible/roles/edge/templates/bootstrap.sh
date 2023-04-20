#!/bin/bash

main() {
    if [[ -d "/var/lib/bootstrap" ]]; then
        echo "It appears this network has already been boot strapped"
        exit
    fi
    mkdir /var/lib/bootstrap
    pushd /var/lib/bootstrap

{% for item in hostvars %}
{% if (hostvars[item].tags.Role == "fullnode" or hostvars[item].tags.Role == "validator") %}
    polygon-edge polybft-secrets init --data-dir {{ hostvars[item].tags["Name"] }} \
    --chain-id {{ chain_id }} \
    --json \
    --insecure > {{ hostvars[item].tags["Name"] }}.json
{% endif %}
{% endfor %}

    apt update
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt-get install -y nodejs

    pushd /opt/polygon-edge/
    make compile-core-contracts
    cp -r /opt/polygon-edge/core-contracts /var/lib/bootstrap/core-contracts/
    popd

    polygon-edge manifest {% for item in hostvars %}{% if (hostvars[item].tags.Role == "validator") %} --validators /dns4/{{ hostvars[item].tags["Name"] }}/tcp/{{ edge_p2p_port }}/p2p/$(cat {{ hostvars[item].tags["Name"] }}.json | jq -r '.[0].node_id'):$(cat {{ hostvars[item].tags["Name"] }}.json | jq -r '.[0].address'):$(cat {{ hostvars[item].tags["Name"] }}.json | jq -r '.[0].bls_pubkey'):$(cat {{ hostvars[item].tags["Name"] }}.json | jq -r '.[0].bls_signature') {% endif %}{% endfor %} \
                 --path ./manifest.json \
                 --premine-validators 1000000000000000000000000000 \
                 --chain-id {{ chain_id }}

    polygon-edge genesis \
                {% for item in hostvars %}{% if (hostvars[item].tags.Role == "validator") %} --validators /dns4/{{ hostvars[item].tags["Name"] }}/tcp/{{ edge_p2p_port }}/p2p/$(cat {{ hostvars[item].tags["Name"] }}.json | jq -r '.[0].node_id'):$(cat {{ hostvars[item].tags["Name"] }}.json | jq -r '.[0].address'):$(cat {{ hostvars[item].tags["Name"] }}.json | jq -r '.[0].bls_pubkey'):$(cat {{ hostvars[item].tags["Name"] }}.json | jq -r '.[0].bls_signature') {% endif %}{% endfor %} \
                 --consensus polybft \
                 --grpc-address {{ rootchain_json_rpc }} \
                 {% for item in hostvars %}{% if (hostvars[item].tags.Role == "fullnode" or hostvars[item].tags.Role == "validator") %} --bootnode /dns4/{{ hostvars[item].tags["Name"] }}/tcp/{{ edge_p2p_port }}/p2p/$(cat {{ hostvars[item].tags["Name"] }}.json | jq -r '.[0].node_id') {% endif %}{% endfor %} \
                 {% for address in premine_address %} --premine {{ address }}:1000000000000000000000000000 {% endfor %}
                 --premine 0x0000000000000000000000000000000000000000 \
                 --block-gas-limit {{ block_gas_limit }} \
                 --block-time {{ block_time }}s \
                 --chain-id {{ chain_id }} \
                 --epoch-size 10

    polycli wallet create --words 12 --language english | jq '.Addresses[0]' > rootchain-wallet.json
    COINBASE_ADDRESS=$(curl -H "Content-Type: application/json" -X POST --data '{"jsonrpc":"2.0","method":"eth_coinbase","params":[],"id":1}' {{ rootchain_json_rpc }} | jq -r '.result')
    curl -X POST --data '{"jsonrpc":"2.0","method":"eth_sendTransaction","params":[{"from":"'"$COINBASE_ADDRESS"'","to":"'"$(cat rootchain-wallet.json | jq -r '.ETHAddress')"'","value":"0x3635C9ADC5DEA00000"}],"id":1}' -H "Content-Type: application/json" {{ rootchain_json_rpc }}
    sleep 5
    polygon-edge rootchain deploy \
      --deployer-key $(cat rootchain-wallet.json | jq -r '.HexPrivateKey') \
      --json-rpc {{ rootchain_json_rpc }}      

{% for item in hostvars %}
{% if (hostvars[item].tags.Role == "validator") %}
    polygon-edge rootchain fund --data-dir {{ hostvars[item].tags["Name"] }} --json-rpc {{ rootchain_json_rpc }}
{% endif %}
{% endfor %}

    tar czf {{ base_dn }}.tar.gz validator* fullnode* genesis.json
    popd
}

main
