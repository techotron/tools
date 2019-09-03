import aws_auth


def send_sqs_message(client, amount, msg_body, q_url):
    for i in range(0, amount):
        response = client.send_message(
            QueueUrl=q_url,
            MessageAttributes={},
            MessageBody=(msg_body)
        )

        print('Message ID: %s' % response['MessageId'])
        i = i + 1


if __name__ == "__main__":
    body = '''{                   
        "messageType": "NEW_ORDER",
        "metadata": {
            "accountId": "58c16b45-27a5-402f-a094-582f2d05c008",
            "isTest": true,
            "region": "us-east-1",
            "source": "order-submission",
            "timestamp": "2019-06-17T16:11:13.511Z",
            "traceId": "da30c042-7ea9-465e-afaa-3f4544b88a9d"
        },
        "payload": {
            "id": "urn:dss:espn:orders:d368b7b5-1480-4ade-b720-57fd24dc3a6f",
            "idempotencyKey": "d368b7b5-1480-4ade-b720-57fd24dc3a6f",
            "lineItems": [{
                "sku": "8400199910209919951899000"
            }],
            "messageType": "NEW_ORDER",
            "orderCampaigns": [{
                "campaignCode": "ESPN_FT_CMPGN",
                "voucherCode": "ESPN_FT_7D_VOCHR"
            }],
            "partner": "espn",
            "paymentMethodId": "0d4009d7-92af-4772-9f5c-900869155e24"
        }
    }'''

    creds = aws_auth.get_temp_creds('ROLE_ARN', 'ROLE_NAME')
    sqs_client = aws_auth.get_client('sqs', creds, 'us-east-1')

    send_sqs_message(sqs_client, 50, body, 'SQS_URL')
