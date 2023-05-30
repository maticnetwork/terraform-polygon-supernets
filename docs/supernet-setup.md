# Supernet Set Up

- State Directory : `/var/lib/edge`
- Bootstrap Directory (only present in `validator-001`): `/var/lib/bootstrap`
- `polygon-edge`: `/opt/polygon-edge`
- `polygon-cli`: `/opt/polygon-cli`

## Bootstrapping Polygon Edge
The Edge bootstrap script ([ansible/roles/edge/templates/bootstrap.sh](https://github.com/maticnetwork/terraform-polygon-supernets/blob/main/ansible/roles/edge/templates/bootstrap.sh)) uses the Edge CLI to prepare initiate a new chain with PolyBFT consensus and prepare the initial Supernet nodes. 

The bootstrap steps follows what's listed on our [official docs](https://wiki.polygon.technology/docs/supernets/operate/supernets-local-deploy-supernet). The Edge bootstrap script is adjusted for cloud deployment needs and also customizable L1 root chain.

## Running `ansible` after the first run
### Run specific playbooks with tags
The ansible playbook ([ansible/site.yml](https://github.com/maticnetwork/terraform-polygon-supernets/blob/main/ansible/site.yml)) file defines a playbook that configures the servers. It targets the hosts specified in [ansible/inventory/aws_ec2.yml](https://github.com/maticnetwork/terraform-polygon-supernets/blob/main/ansible/inventory/aws_ec2.yml). You will come across the need to run ansible for only specific steps. This can be done with running with tags. 

For example, this command will only run the ansible steps with the tag `edge`.
```
ansible-playbook --inventory inventory/aws_ec2.yml --extra-vars "@local-extra-vars.yml" --tags edge site.yml
```
### Stop / Start / Restart the Polygon Edge Server
Run the following on a server
- `sudo systemctl stop edge`
- `sudo systemctl start edge`
- `sudo systemctl restart edge`

or you can use ansible to run it on all servers
```
ansible --inventory inventory/aws_ec2.yml --extra-vars "@local-extra-vars.yml" validator:fullnode -m shell -b -a 'systemctl stop edge;'
```
### State reset with same `genesis.json` and secrets
To reset the state of the current network
1. stop the `edge` process
2. remove the state directory (specifically `blockchain`, `consensus` and `trie` directory)
3. restart the `edge` process
```
ansible --inventory inventory/aws_ec2.yml --extra-vars "@local-extra-vars.yml" validator:fullnode -m shell -b -a 'systemctl stop edge; rm -rf /var/lib/edge/blockchain; rm -rf /var/lib/edge/trie; rm -rf /var/lib/edge/consensus/polybft; systemctl start edge''
```
### State reset with new `genesis.json` and secrets
To reset the state of the current network with a new `genesis.json`
1. stop the `edge` process
2. remove the state directory and the bootstrap directory
3. `polygon-edge` and `go` binaries are also removed to ensure clean install
4. run the entire playbook again

After this, you will need to run the full playbook again which will start the `edge` process again.
```
ansible --inventory inventory/aws_ec2.yml --extra-vars "@local-extra-vars.yml" validator:fullnode -m shell -b -a 'systemctl stop edge; rm -rf /var/lib/edge/*; rm -rf /var/lib/bootstrap; rm -rf /opt/polygon-edge; rm -rf /usr/local/go"
```
## Checking logs on the server
### On validator nodes or full nodes
Run the following command on a specific server to check the systemd logs. If there is server setup issues, the error would most likely show up here. The actual log files are stored at `/var/log/journal/`.
```
sudo journalctl -u edge -f
```