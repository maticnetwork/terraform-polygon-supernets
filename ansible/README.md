```bash
# install the required ansible-galaxy roles and collections
ansible-galaxy install -r requirements.yml

# check the inventory
ansible-inventory --graph --inventory inventory/aws_ec2.yml

# create some aliases to shorten commands
alias ansible-playbook='ansible-playbook --inventory inventory/aws_ec2.yml --vault-password-file=password.txt --extra-vars "@local-extra-vars.yml"'
alias ansible='ansible --inventory inventory/aws_ec2.yml --vault-password-file=password.txt --extra-vars "@local-extra-vars.yml"'

# confirm we can ping everything
ansible all -m ping

# run the full play book
ansible-playbook site.yml

# run the just the edge playbook
ansible-playbook --tags edge site.yml

ansible validator:fullnode -m shell -b -a 'systemctl stop edge'
ansible validator:fullnode -m shell -b -a 'rm -rf /var/lib/edge'
ansible validator:fullnode -m shell -b -a 'rm -rf /var/lib/bootstrap'
ansible validator:fullnode -m shell -b -a 'rm -rf /opt/polygon-edge'

ansible validator:fullnode -m shell -b -a 'systemctl stop edge; rm -rf /var/lib/edge; rm -rf /var/lib/bootstrap; rm -rf /opt/polygon-edge; rm -rf /usr/local/go'


# A desperate attempt to make things faster
ansible validator:fullnode -m shell -b -a 'mkdir /var/lib/edge'
ansible validator:fullnode -m shell -b -a 'mount -t tmpfs -o size=64g tmpfs /var/lib/edge'
ansible validator:fullnode -m shell -b -a 'systemctl stop edge; rm -rf /var/lib/edge/*; rm -rf /var/lib/bootstrap; rm -rf /opt/polygon-edge; rm -rf /usr/local/go'
ansible validator:fullnode -m shell -b -a 'systemctl stop edge; rm -rf /var/lib/bootstrap; rm -rf /var/lib/edge/*'

ansible validator -m setup -a 'filter=ansible_architecture'

# state reset
ansible validator:fullnode -m shell -b -a 'systemctl stop edge; rm -rf /var/lib/edge/blockchain; rm -rf /var/lib/edge/trie; rm -rf /var/lib/edge/consensus/polybft; systemctl start edge'


ansible-playbook --tags explorer site.yml
ansible explorer -m shell -b -a 'systemctl stop explorer; rm -rf /opt/blockscout/*; rm -rf /usr/local/bin/*; rm -rf /opt/elixir; rm -f /opt/.initial-blockscout-db-migration'
```


Flame Graph Profile:

```
# First Run the Load
polycli loadtest --chain-id 100 --verbosity 700 --mode t --concurrency 100 --requests 100000 --rate-limit 1900 --time-limit 60 http://int-rpc.devnet04.edge.polygon.private:10002
polycli loadtest --chain-id 100 --verbosity 700 --mode t --concurrency 100 --requests 1000 --rate-limit 1900 --to-random=false http://int-rpc.devnet04.edge.polygon.private:10002


polycli monitor http://int-rpc.devnet04.edge.polygon.private:10002

# Then capture the system profile while the load is processing
/usr/share/bcc/tools/profile -F 999 -adf 60 --stack-storage-size 4194304 > out.profile-folded
/opt/FlameGraph/flamegraph.pl --title="CPU for Edge" --colors=java out.profile-folded > profile.svg

/usr/share/bcc/tools/offcputime -K -p `pgrep -nx polygon-edge`
/usr/share/bcc/tools/offcputime -p `pgrep -nx polygon-edge` -f > off-cpu.out
/usr/share/bcc/tools/offcputime -U -p `pgrep -nx polygon-edge` -f 30 > off-cpu.out
/opt/FlameGraph/flamegraph.pl --color=io --title="Off-CPU Time Edge" --countname=us off-cpu.out > off-cpu.svg
```



### Load Tests

These are the test scripts that I'm using for the more official numbers:


polycli loadtest --chain-id 100 --verbosity 700 --mode t --concurrency 250 --requests 120 --rate-limit 1900 --to-random=false --summarize=true http://127.0.0.1:10222
polycli loadtest --chain-id 100 --verbosity 700 --mode 2 --concurrency 250 --requests 200 --rate-limit 700 --to-random=false --summarize=true --send-amount 0x1 http://127.0.0.1:10222
polycli loadtest --chain-id 100 --verbosity 700 --mode 7 --concurrency 250 --requests 120 --rate-limit 700 --to-random=false --summarize=true http://127.0.0.1:10222

export LOADBOT_0x85dA99c8a7C2C95964c8EfD687E95E632Fc533D6=0x42b6e34dc21598a807dc19d7784c71b2a7a01f6480dc6f58258f78e539f1a1fa

polygon-edge loadbot  --jsonrpc http://127.0.0.1:10002 --grpc-address 127.0.0.1:10000 --sender 0x85da99c8a7c2c95964c8efd687e95e632fc533d6 --count 30000 --value 0x100 --tps 1428
polygon-edge loadbot  --jsonrpc http://127.0.0.1:10002 --grpc-address 127.0.0.1:10000 --sender 0x85da99c8a7c2c95964c8efd687e95e632fc533d6 --count 50000 --value 0x100 --tps 1111 --mode erc20
polygon-edge loadbot  --jsonrpc http://127.0.0.1:10002 --grpc-address 127.0.0.1:10000 --sender 0x85da99c8a7c2c95964c8efd687e95e632fc533d6 --count 30000 --value 0x100 --tps 714 --mode erc721



polycli loadtest --chain-id 100 --verbosity 700 --mode r --concurrency 1 --requests 50 --rate-limit 1 --to-random=true --summarize=true http://127.0.0.1:10222


### Test 10

polycli loadtest --chain-id 100 --verbosity 400 --mode t --concurrency 250 --requests 400 --rate-limit 2250 --to-random=false --summarize=true http://127.0.0.1:10222

