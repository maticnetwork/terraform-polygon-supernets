#!/bin/bash -x

main() {
    if [[ -d "/var/lib/bootstrap" ]]; then
        echo "It appears this network has already been boot strapped"
        exit
    fi
    mkdir /var/lib/bootstrap
    pushd /var/lib/bootstrap

{% for item in hostvars %}
{% if (hostvars[item].tags.Role == "fullnode" or hostvars[item].tags.Role == "validator") %}
    polygon-edge polybft-secrets --data-dir {{ hostvars[item].tags["Name"] }} --json --insecure > {{ hostvars[item].tags["Name"] }}.json
{% endif %}
{% endfor %}
    polygon-edge genesis \
                 --consensus polybft \
                 {% for item in hostvars %}{% if (hostvars[item].tags.Role == "fullnode" or hostvars[item].tags.Role == "validator") %} --bootnode /dns4/{{ hostvars[item].tags["Name"] }}/tcp/{{ edge_p2p_port }}/p2p/$(cat {{ hostvars[item].tags["Name"] }}.json | jq -r '.[0].node_id') {% endif %}{% endfor %} \
                 {% for item in hostvars %}{% if (hostvars[item].tags.Role == "fullnode" or hostvars[item].tags.Role == "validator") %} --premine $(cat {{ hostvars[item].tags["Name"] }}.json | jq -r '.[0].address'):1000000000000000000000000 {% endif %}{% endfor %} \
                 --premine {{ loadtest_account }}:1000000000000000000000000000 \
                 --reward-wallet 0x0101010101010101010101010101010101010101:1000000000000000000000000000 \
                 --premine 0xA39Fed214820cF843E2Bcd6cA1759257a530894B:1000000000000000000000000000 \
                 --premine 0x181d9fEc79EC674DD3cB30dd9dd4188E737939FE:1000000000000000000000000000 \
		 --block-gas-limit {{ block_gas_limit }} --block-time {{ block_time }}s \
                 {% for item in hostvars %}{% if (hostvars[item].tags.Role == "validator") %} --validators /dns4/{{ hostvars[item].tags["Name"] }}/tcp/{{ edge_p2p_port }}/p2p/$(cat {{ hostvars[item].tags["Name"] }}.json | jq -r '.[0].node_id'):$(cat {{ hostvars[item].tags["Name"] }}.json | jq -r '.[0].address' | sed 's/^0x//'):$(cat {{ hostvars[item].tags["Name"] }}.json | jq -r '.[0].bls_pubkey') {% endif %}{% endfor %} \
                 --chain-id  {{ chain_id }} \
                 --epoch-size 10

    polycli wallet create --words 12 --language english | jq '.Addresses[0]' > rootchain-wallet.json

    COINBASE_ADDRESS=$(cast rpc --rpc-url {{ rootchain_json_rpc }} eth_coinbase | sed 's/"//g')

    cast send --rpc-url {{ rootchain_json_rpc }} --from $COINBASE_ADDRESS --value 100ether $(cat rootchain-wallet.json | jq -r '.ETHAddress')

    polygon-edge rootchain deploy \
                 --deployer-key $(cat rootchain-wallet.json | jq -r '.HexPrivateKey') \
                 --json-rpc {{ rootchain_json_rpc }}

{% for item in hostvars %}
{% if (hostvars[item].tags.Role == "validator") %}
    cast send --rpc-url {{ rootchain_json_rpc }} --from $COINBASE_ADDRESS --value 100ether $(cat {{ hostvars[item].tags["Name"] }}.json | jq -r '.[0].address')
{% endif %}
{% endfor %}

    polygon-edge polybft whitelist-validators \
                 --private-key $(cat rootchain-wallet.json | jq -r '.HexPrivateKey') \
                 --addresses $(cat validator-*.json | jq -r ".[].address" | tr "\n" ",") \
                 --supernet-manager $(cat genesis.json | jq -r '.params.engine.polybft.bridge.customSupernetManagerAddr') \
                 --json-rpc {{ rootchain_json_rpc }}


{% for item in hostvars %}
{% if (hostvars[item].tags.Role == "validator") %}
    polygon-edge polybft register-validator --data-dir {{ hostvars[item].tags["Name"] }} \
                 --supernet-manager $(cat genesis.json | jq -r '.params.engine.polybft.bridge.customSupernetManagerAddr') \
                 --json-rpc {{ rootchain_json_rpc }}
{% endif %}
{% endfor %}

{% for item in hostvars %}
{% if (hostvars[item].tags.Role == "validator") %}
    polygon-edge polybft stake --data-dir {{ hostvars[item].tags["Name"] }} --chain-id {{ chain_id }} \
                 --amount 10 \
                 --stake-manager $(cat genesis.json | jq -r '.params.engine.polybft.bridge.stakeManagerAddr') \
                 --native-root-token $(cat genesis.json | jq -r '.params.engine.polybft.bridge.nativeERC20Address') \
                 --json-rpc {{ rootchain_json_rpc }}
{% endif %}
{% endfor %}

    polygon-edge polybft supernet --private-key $(cat rootchain-wallet.json | jq -r '.HexPrivateKey') \
                 --supernet-manager $(cat genesis.json | jq -r '.params.engine.polybft.bridge.customSupernetManagerAddr') \
                 --stake-manager $(cat genesis.json | jq -r '.params.engine.polybft.bridge.stakeManagerAddr') \
                 --finalize-genesis --enable-staking \
                 --json-rpc {{ rootchain_json_rpc }}

    tar czf {{ base_dn }}.tar.gz *.json *.private
    popd
}

main
