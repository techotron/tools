import boto3


def get_temp_creds(roleArn, roleSessionName):
    sts_client = boto3.client('sts')
    assumed_role_object = sts_client.assume_role(
        RoleArn=roleArn,
        RoleSessionName=roleSessionName
    )
    temp_credentials = assumed_role_object['Credentials']
    return temp_credentials


def get_client(resource, credentials, region):
    client = boto3.client(
        resource,
        aws_access_key_id=credentials['AccessKeyId'],
        aws_secret_access_key=credentials['SecretAccessKey'],
        aws_session_token=credentials['SessionToken'],
        region_name=region
    )
    return client
