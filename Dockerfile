FROM python:3.9
FROM gcr.io/google.com/cloudsdktool/google-cloud-cli:latest

ARG DBT_PROJECT="jaffle_shop"

# Install jq for working with JSONs
RUN apt-get update && apt-get install -y jq

# Copy all dbt files into /home
COPY . /home/

# run requirments script
RUN pip3 install -r /home/requirements.txt
