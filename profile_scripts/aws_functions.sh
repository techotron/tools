# AWS Helper Functions

## Quickly create EC2 instance in default VPC:

### 
# 1. Create new sec group (if not already exists)
# 2. Create keypair and export name of key as SANDBOX_PRIVATE_KEY
# 3. Create new instance in region
# 4. Log onto instance using key (needs to be saved as SANDBOX_PRIVATE_KEY_regionname.pem)
# 5. Delete instance when finished

function get-latest-ami() {
  aws ec2 describe-images --owners amazon --filters "Name=name,Values=amzn2-ami-hvm-2.0.*-x86_64-gp2" --query 'sort_by(Images, &CreationDate)[-1].ImageId' --output text --region $1
}

function create-new-ssh-sec-group() {
  aws ec2 create-security-group --group-name eddys-allow-ssh --vpc-id $(get-vpc $1) --description "Allow SSH from my IP" --region $1
}

function get-sec-group-id() {
  aws ec2 describe-security-groups --filter Name=vpc-id,Values=$(get-vpc $1) Name=group-name,Values=eddys-allow-ssh --region $1 --query 'SecurityGroups[].GroupId' --output text
}

function create-new-instance() {
  aws ec2 run-instances --image-id $(get-latest-ami $1) --count 1 --instance-type t2.micro --key-name "$SANDBOX_PRIVATE_KEY"_$1 --security-group-ids $(get-sec-group-id $1) --subnet-id $(get-subnet-id $1) --region $1 --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=eddy-temp-instance}]'
}

function get-subnet-id() {
  aws ec2 describe-subnets --region $1 --filter Name=vpc-id,Values=$(get-vpc $1) --query 'Subnets[0].SubnetId' --output text
}

function get-temp-instance-id() {
  aws ec2 describe-instances --region $1 --query 'Reservations[].Instances[?Tags[?Key==`Name`]|[?Value==`eddy-temp-instance`]].InstanceId' --output text
}

function get-temp-instance-ip() {
  aws ec2 describe-instances --region $1 --instance-ids $(get-temp-instance-id $1) --query 'Reservations[].Instances[].PublicIpAddress' --output text
}

function logon-temp-instance() {
  ssh -i ~/.ssh/"$SANDBOX_PRIVATE_KEY"_$1.pem ec2-user@$(get-temp-instance-ip $1)
}

function delete-temp-instance() {
  aws ec2 terminate-instances --instance-ids $(get-temp-instance-id $1) --region $1
}

function add-local-ip-to-sec-group() {
  aws ec2 authorize-security-group-ingress --group-id $(get-sec-group-id $1) --protocol tcp --port 22 --cidr $(curl -s https://checkip.amazonaws.com)/32 --region $1
}

function get-vpc() {
  aws ec2 describe-vpcs --region $1 --filter Name=tag:Name,Values=sandbox_dev --query 'Vpcs[0].VpcId' --output text
}
