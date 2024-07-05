#!/bin/bash

echo "Demo deployment starting...."

KEYFILE=ssl/ca/rootCA.key

if [ -f "$KEYFILE" ]; then
    echo "ssl/ca/rootCA.key exists, skipping generation of new CA and certificates"
else
    if [ -x "$(command -v openssl)" ]; then
        echo "OpenSSL is installed and available on the path"
        # proceed
    else
        echo "OpenSSL is not installed, exiting."
        exit 1
    fi

    if [ -x "$(command -v certutil)" ]; then
        echo "certutil is installed and available on the path"
        # proceed
    else
        echo "certutil is not available on the path, exiting."
        exit 1
    fi

    echo "Creating CA using OpenSSL"

    mkdir ssl
    cd ssl

    mkdir ca
    cd ca

    openssl genrsa -out rootCA.key 4096

    openssl req -x509 -new -nodes -key rootCA.key -sha256 \
      -days 1024 -out rootCA.crt -subj "/C=AU/ST=NSW/O=Identify/CN=Identify Root CA (DEV)"

    echo "Creating client & server certificates"

    mkdir -p ../api/client
    cd ../api/client

    # Create client key and CSR
    openssl genrsa -out client.key 4096
    openssl req -new -sha256 -key client.key -subj "/C=AU/ST=NSW/O=Identify/CN=api" \
      -addext "extendedKeyUsage = clientAuth" -out client.csr

    # Sign csr & key with CA
    openssl x509 -req -in client.csr -CA ../../ca/rootCA.crt -copy_extensions copyall \
      -CAkey ../../ca/rootCA.key -CAcreateserial -out client.crt -days 500 -sha256

    echo "We will now import the CA certificate into the JRE's 'cacerts' keystore"
    echo "If you are prompted for Enter password:, enter your user account's password (sudo)"
    echo "When prompted Enter keystore password:, enter 'changeit' - this will be asked twice"
    echo "When prompted Trust this certificate? [no]:, enter 'yes'."
    read -p "Press enter to continue"

    sudo keytool -delete -alias identify_dev -cacerts
    sudo keytool -cacerts -import -file ../../ca/rootCA.crt -trustcacerts -alias identify_dev

    mkdir ../server
    cd ../server

    # Create server key and CSR
    openssl genrsa -out server.key 4096
    openssl req -new -sha256 -key server.key -subj "/C=AU/ST=NSW/O=Identify/CN=api.identify.rodeo" \
      -addext "extendedKeyUsage = serverAuth" -out server.csr

    # Sign csr & key with CA
    openssl x509 -req -in server.csr -CA ../../ca/rootCA.crt -copy_extensions copyall \
      -CAkey ../../ca/rootCA.key -CAcreateserial -out server.crt -days 500 -sha256

    # Create server cert for RabbitMQ
    mkdir -p ../../rabbitmq/server
    cd ../../rabbitmq/server

    # Create server key and CSR
    openssl genrsa -out server.key 4096
    openssl req -new -sha256 -key server.key -subj "/C=AU/ST=NSW/O=Identify/CN=rabbitmq" \
      -addext "extendedKeyUsage = serverAuth" -out server.csr

    # Sign csr & key with CA
    openssl x509 -req -in server.csr -CA ../../ca/rootCA.crt -copy_extensions copyall \
      -CAkey ../../ca/rootCA.key -CAcreateserial -out server.crt -days 500 -sha256

    # Create client cert for IPS
    mkdir -p ../../ips/client
    cd ../../ips/client

    # Create client keypair for local IPS
    openssl genrsa -out client.key 4096
    openssl req -new -sha256 -key client.key -subj "/C=AU/ST=NSW/O=Identify/CN=ips_server" \
      -addext "extendedKeyUsage = clientAuth" -out client.csr

    # Sign csr & key with CA
    openssl x509 -req -in client.csr -CA ../../ca/rootCA.crt -copy_extensions copyall \
      -CAkey ../../ca/rootCA.key -CAcreateserial -out client.crt -days 500 -sha256

    cd ../../..
fi

### START API DEPLOYMENT ###

echo "Extracting IdentifyAPI tarball"

mkdir installed

tar -xf IdentifyAPI.tar.gz -C installed/

cd installed/identifyapi

echo "Installing CA certficate"
cp -f ../../ssl/ca/rootCA.crt docker/ca.crt

echo "Installing API's server certificate"

cp -f ../../ssl/api/server/server.crt docker/server.crt
cp -f ../../ssl/api/server/server.key docker/serverkey.pem
cat docker/server.crt docker/ca.crt > docker/fullchain.pem

echo "Installing API's client certficate for rabbitmq"

rm -f docker/api/*

cp ../../ssl/api/client/client.crt docker/api/client.crt
cp ../../ssl/api/client/client.key docker/api/client.key

# Convert PEM files to PKCS#12 format
openssl pkcs12 -export -out docker/api/APIClient.p12 \
  -in docker/api/client.crt -inkey docker/api/client.key \
  -passout "pass:ChangeMe123!"


echo "Installing rabbitmq's server certificate"

# cleanup any old certs
rm -f docker/rabbitmq_ssl/ssl/*

cp ../../ssl/rabbitmq/server/server.crt docker/rabbitmq_ssl/ssl/rabbitmq.crt
cp ../../ssl/rabbitmq/server/server.key docker/rabbitmq_ssl/ssl/key.pem
cp ../../ssl/ca/rootCA.crt docker/rabbitmq_ssl/ssl/RootCA.crt

find . -type d -exec chmod 755 {} \;
find . -type f -exec chmod 766 {} \;

echo "Building IdentifyAPI"

./mvnw compile

cd ../../scripts

### START IPS DEPLOYMENT ###

echo "Extracting image_processor tarball"
cd ../
tar -xf image_processor.tar.gz -C installed/

cd installed/image_processor

echo "Installing client certificates"

cp -f ../../ssl/ips/client/client.crt data/ssl/clientcert/certificate.crt
cp -f ../../ssl/ips/client/client.key data/ssl/clientcert/certificate.key
cp -f ../../ssl/ca/rootCA.crt data/ssl/ca.crt

echo "Creating python 3 virtual environment"

python3 -m venv ../python_virtualenv

. ../python_virtualenv/bin/activate

echo "Installing python dependencies"

pip install -r requirements.txt

cd ../../scripts

echo "Demo deployment complete, use the scripts in scripts/ to start the services (api first, then IPS)"