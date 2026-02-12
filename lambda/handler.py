import base64
import json
import os
import time
import uuid
import boto3

ddb = boto3.resource("dynamodb")
table = ddb.Table(os.environ["DDB_TABLE"])

def lambda_handler(event, context):
    """
    Kinesis event format:
    event["Records"] -> list of records
    Each record payload is base64-encoded in record["kinesis"]["data"]
    """

    written = 0

    for record in event.get("Records", []):
        raw = base64.b64decode(record["kinesis"]["data"]).decode("utf-8")

        # We expect JSON; if it isn't, we store it as a raw string payload
        try:
            payload = json.loads(raw)
        except json.JSONDecodeError:
            payload = {"raw": raw}

        # A simple NoSQL warehousing-friendly key design:
        # pk groups by site or region; sk sorts by time
        site = payload.get("site", "unknown-site")
        ts = payload.get("ts", int(time.time()))

        item = {
            "pk": f"SITE#{site}",
            "sk": f"TS#{ts}#{uuid.uuid4()}",
            "payload": payload
        }

        table.put_item(Item=item)
        written += 1

    return {"statusCode": 200, "records_written": written}
