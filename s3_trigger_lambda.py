import os

ENV = os.environ.get('environment')


def lambda_handler(event, context):
    print('This print is form lambda')
    file_name = event['Records'][0]['s3']['object'].get('key')
    return f"{file_name} is added to s3 on {ENV}"


# if __name__ == '__main__':
#     value = lambda_handler({"Records":[{"s3":{"object":{"key":"text.txt"}}}]},{})
#     print(value)
