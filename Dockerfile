# Use the official AWS Lambda Python base image
FROM public.ecr.aws/lambda/python:3.11

# Copy requirements and install
COPY requirements.txt  .
RUN python -m pip install --upgrade pip
RUN pip install -r requirements.txt

# Copy app and handler
COPY app.py lambda_function.py ${LAMBDA_TASK_ROOT}/

# Command tells Lambda which handler to run (module.function)
CMD ["lambda_function.lambda_handler"]
