import os


def lambda_handler(event, context):
    print('This print is form lambda')
    return "{} from Lambda!!!".format(os.environ['environment'])
