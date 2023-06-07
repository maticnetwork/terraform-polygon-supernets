### Creating resources with Terraform
terraform init
terraform plan
terraform apply -auto-approve

### Output the private key for instances
terraform output pk_ansible > ~/devnet_private.key
chmod 600 ~/devnet_private.key
ssh-add ~/devnet_private.key

### Save the rootchain rpc address
ROOTCHAIN_RPC=$(terraform output -raw geth_private_ip)

cd ansible

### Run ansible to configure the nodes
ansible --inventory inventory/aws_ec2.yml --vault-password-file=password.txt --extra-vars "@local-extra-vars.yml" all -m ping
ansible-galaxy install -r requirements.yml
# if this step fails due to "sudo: a password is required", make sure you are in sudo mode in the terminal you are running this on
ansible-playbook --inventory inventory/aws_ec2.yml --vault-password-file=password.txt --extra-vars "@local-extra-vars.yml" site.yml
