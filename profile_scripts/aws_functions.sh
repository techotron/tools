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
  aws ec2 run-instances --image-id $(get-latest-ami $1) --count 1 --instance-type t2.micro --key-name "$SANDBOX_PRIVATE_KEY"_$1 --security-group-ids $(get-sec-group-id $1) --subnet-id $(get-subnet-id $1) --region $1 --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=eddy-temp-instance}]' --associate-public-ip-address
}

function get-subnet-id() {
  aws ec2 describe-subnets --region $1 --filter Name=vpc-id,Values=$(get-vpc $1) Name=tag:type,Values=pub --query 'Subnets[0].SubnetId' --output text
}

function get-temp-instance-id() {
  aws ec2 describe-instances --region $1 --filter Name=instance-state-name,Values=running --query 'Reservations[].Instances[?Tags[?Key==`Name`]|[?Value==`eddy-temp-instance`]].InstanceId' --output text
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

function aws-populate-tokens() {
	export AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id --profile $1)
	export AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key --profile $1)
	export AWS_SESSION_TOKEN=$(aws configure get aws_session_token --profile $1)
}

# @source - https://github.com/antonbabenko/awsp

function _awsListAll() {
    credentialFileLocation=$(env | grep AWS_SHARED_CREDENTIALS_FILE | cut -d= -f2);
    if [ -z $credentialFileLocation ]; then
        credentialFileLocation=~/.aws/credentials
    fi
    while read line; do
        if [[ $line == "["* ]]; then echo "$line"; fi;
    done < $credentialFileLocation;
};

function _awsSwitchProfile() {
   if [ -z $1 ]; then  echo "Usage: awsp profilename"; return; fi
   exists="$(aws configure get aws_access_key_id --profile $1)"
   role_arn="$(aws configure get role_arn --profile $1)"
   if [[ -n $exists || -n $role_arn ]]; then
       if [[ -n $role_arn ]]; then
           mfa_serial="$(aws configure get mfa_serial --profile $1)"
           if [[ -n $mfa_serial ]]; then
               echo "Please enter your MFA token for $mfa_serial:"
               read mfa_token
           fi

           source_profile="$(aws configure get source_profile --profile $1)"
           if [[ -n $source_profile ]]; then
               profile=$source_profile
           else
               profile=$1
           fi

           echo "Assuming role $role_arn using profile $profile"
           if [[ -n $mfa_serial ]]; then
               JSON="$(aws sts assume-role --profile=$profile --role-arn $role_arn --role-session-name "$profile" --serial-number $mfa_serial --token-code $mfa_token)"
           else
               JSON="$(aws sts assume-role --profile=$profile --role-arn $role_arn --role-session-name "$profile")"
           fi

           aws_access_key_id="$(echo $JSON | jq -r '.Credentials.AccessKeyId')"
           aws_secret_access_key="$(echo $JSON | jq -r '.Credentials.SecretAccessKey')"
           aws_session_token="$(echo $JSON | jq -r '.Credentials.SessionToken')"
       else
           aws_access_key_id="$(aws configure get aws_access_key_id --profile $1)"
           aws_secret_access_key="$(aws configure get aws_secret_access_key --profile $1)"
           aws_session_token=""
       fi
       export AWS_DEFAULT_PROFILE=$1
       export AWS_PROFILE=$1
       export AWS_ACCESS_KEY_ID=$aws_access_key_id
       export AWS_SECRET_ACCESS_KEY=$aws_secret_access_key
       [[ -z "$aws_session_token" ]] && unset AWS_SESSION_TOKEN || export AWS_SESSION_TOKEN=$aws_session_token

       echo "Switched to AWS Profile: $1";
       aws configure list
   fi
};
