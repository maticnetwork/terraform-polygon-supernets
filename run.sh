### Creating resources with Terraform
terraform init
terraform plan
terraform apply -auto-approve

### Output the private key for instances
terraform output pk_ansible > ~/devnet_private.key
chmod 600 ~/devnet_private.key
ssh-add ~/devnet_private.key

cd ansible

### Run ansible to configure the nodes
ansible all -m ping
ansible-galaxy install -r requirements.yml
# if this step fails due to "sudo: a password is required", make sure you are in sudo mode in the terminal you are running this on
ansible-playbook site.yml
