import aws_auth
import json


def deploy_dashboard(dashboard_body):
    response = cw_client.put_dashboard(
        DashboardName='0001_eddy-test',
        DashboardBody=dashboard_body
    )

    return(response)


def convert_dashboard(path):
    with open(path) as file:
        json_load = json.load(file)
        json_dump = json.dumps(json_load)
    return json_dump


if __name__ == "__main__":
    creds = aws_auth.get_temp_creds('SOME_ROLE_ARN', 'ROLE_NAME_IN_AWSCONFIG')
    cw_client = aws_auth.get_client('cloudwatch', creds, 'us-east-1')
    dashboard = convert_dashboard('/Users/edwardsnow/temp/test_large_with_region.json')

    deploy_dashboard(dashboard)
