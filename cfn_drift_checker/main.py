import json


def parse_change_set(cs):
    response = ""
    response = response + "|Logical ID|Type|Action|Replacement?|Change|Requires Recreation?|\n"
    response = response + "|---|---|---|---|---|---|\n"
    json_cs = json.loads(cs)
    for item in json_cs:
        resource_change = item["resourceChange"]
        details = resource_change["details"]
        for detail in details:
            resource_id = resource_change["logicalResourceId"]
            resource_type = resource_change["resourceType"]
            resource_action = resource_change["action"]
            replacement = resource_change["replacement"]
            change = detail["causingEntity"]
            req_recreation = detail["target"]["requiresRecreation"]
            if detail["evaluation"] != "asdasda":
                response = response + ("|{}|{}|{}|{}|\n".format(
                    resource_id,
                    resource_type,
                    resource_action,
                    replacement,
                    change,
                    req_recreation
                ))

    file_object = open(r"temp.md", "w+")
    file_object.write(response)
    file_object.close()


if __name__ == "__main__":
    change_set = '''
[
  {
    "resourceChange": {
      "logicalResourceId": "AAutoScalingGroup",
      "action": "Modify",
      "physicalResourceId": "skynet-bamtech-prod-hermes-repl-monitor-default-AAutoScalingGroup-1BZCOO6LL8IXB",
      "resourceType": "AWS::AutoScaling::AutoScalingGroup",
      "replacement": "Conditional",
      "details": [
        {
          "target": {
            "name": "TerminationPolicies",
            "requiresRecreation": "Never",
            "attribute": "Properties"
          },
          "causingEntity": null,
          "evaluation": "Static",
          "changeSource": "DirectModification"
        },
        {
          "target": {
            "name": "LoadBalancerNames",
            "requiresRecreation": "Never",
            "attribute": "Properties"
          },
          "causingEntity": null,
          "evaluation": "Dynamic",
          "changeSource": "DirectModification"
        },
        {
          "target": {
            "name": "HealthCheckType",
            "requiresRecreation": "Never",
            "attribute": "Properties"
          },
          "causingEntity": null,
          "evaluation": "Static",
          "changeSource": "DirectModification"
        },
        {
          "target": {
            "name": "LaunchConfigurationName",
            "requiresRecreation": "Conditionally",
            "attribute": "Properties"
          },
          "causingEntity": "ALaunchConfiguration",
          "evaluation": "Static",
          "changeSource": "ResourceReference"
        },
        {
          "target": {
            "name": "LoadBalancerNames",
            "requiresRecreation": "Never",
            "attribute": "Properties"
          },
          "causingEntity": "AAwsElasticloadbalancingLoadbalancer",
          "evaluation": "Static",
          "changeSource": "ResourceReference"
        }
      ],
      "scope": [
        "Properties"
      ]
    },
    "type": "Resource"
  },
  {
    "resourceChange": {
      "logicalResourceId": "AAwsElasticloadbalancingLoadbalancer",
      "action": "Add",
      "physicalResourceId": null,
      "resourceType": "AWS::ElasticLoadBalancing::LoadBalancer",
      "replacement": null,
      "details": [],
      "scope": []
    },
    "type": "Resource"
  },
  {
    "resourceChange": {
      "logicalResourceId": "ALaunchConfiguration",
      "action": "Modify",
      "physicalResourceId": "skynet-bamtech-prod-hermes-repl-monitor-default-ALaunchConfiguration-1HQD9T6JA1OV4",
      "resourceType": "AWS::AutoScaling::LaunchConfiguration",
      "replacement": "True",
      "details": [
        {
          "target": {
            "name": "ImageId",
            "requiresRecreation": "Always",
            "attribute": "Properties"
          },
          "causingEntity": null,
          "evaluation": "Static",
          "changeSource": "DirectModification"
        }
      ],
      "scope": [
        "Properties"
      ]
    },
    "type": "Resource"
  },
  {
    "resourceChange": {
      "logicalResourceId": "ALoadBalancer",
      "action": "Remove",
      "physicalResourceId": "skynet-ba-ALoadBal-1UBXL0YK36L3P",
      "resourceType": "AWS::ElasticLoadBalancing::LoadBalancer",
      "replacement": null,
      "details": [],
      "scope": []
    },
    "type": "Resource"
  }
]
  
    '''
    parse_change_set(change_set)