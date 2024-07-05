#!/bin/bash

cd ../installed/image_processor

export API_USERNAME=ips_server
export API_PASSWORD="ips"
export API_URL="https://localhost:8080"
export LOG_LEVEL="DEBUG"
export RABBIT_URL="amqps://localhost/"
export SSL_KEYFILE=$(realpath data/ssl/clientcert/certificate.key)
export SSL_CERTFILE=$(realpath data/ssl/clientcert/certificate.crt)
export SSL_CACERT=$(realpath data/ssl/ca.crt)

. ../python_virtualenv/bin/activate

cd src/

python run.py