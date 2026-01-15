# Lambda handler for AWS Lambda container image
# We use aws-serverless-wsgi to adapt Flask to Lambda events.
import serverless_wsgi
from app import app


def lambda_handler(event, context):
    return serverless_wsgi.handle_request(app, event, context)
