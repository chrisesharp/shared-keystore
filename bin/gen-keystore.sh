#!/bin/bash

# Generate keystores  - based on https://github.com/gameontext/gameon/blob/master/bin/gen-keystore.sh


if (( $# != 1))
then
  echo "Usage: ./bin/gen-keystore.sh <IP>"
  exit 1
fi

IP=$1

if [ -z ${JAVA_HOME} ]
then
  echo "JAVA_HOME is not set. Please set and re-run this script."
  exit 1
fi

echo "Checking for keytool..."
keytool -help > /dev/null 2>&1
if [ $? != 0 ]
then
  echo "Error: keytool is missing from the path, please correct this, then retry"
  exit 1
fi

echo "Checking for openssl..."
openssl version > /dev/null 2>&1
if [ $? != 0 ]
then
  echo "Error: openssl is missing from the path, please correct this, then retry"
  exit 1
fi

echo "Generating key stores using ${IP}"

#create a ca cert we'll import into all our trust stores..
keytool -genkeypair \
  -alias scoreboardca \
  -keypass scoreboardca \
  -storepass scoreboardca \
  -keystore keystore/cakey.jks \
  -keyalg RSA \
  -keysize 2048 \
  -dname "CN=LocalDevCA, OU=Local Certificate Authority, O=NA, L=Earth, ST=Happy, C=CA" \
  -ext KeyUsage="keyCertSign" \
  -ext BasicConstraints:"critical=ca:true" \
  -validity 9999

#export the ca cert so we can add it to the trust stores
keytool -exportcert \
  -alias scoreboardca \
  -keypass scoreboardca \
  -storepass scoreboardca \
  -keystore keystore/cakey.jks \
  -file keystore/scoreboardca.crt \
  -rfc

#create the keypair we plan to use for our ssl/jwt signing
keytool -genkeypair \
  -alias scoreboardappkey \
  -keypass secret \
  -storepass secret \
  -keystore keystore/key.jks \
  -keyalg RSA \
  -sigalg SHA256withRSA \
  -dname "CN=${IP},OU=Local Certificate Authority, O=NA, L=Earth, ST=Happy, C=CA" \
  -validity 365

#create the signing request for the app key
keytool -certreq \
  -alias scoreboardappkey \
  -keypass secret \
  -storepass secret \
  -keystore keystore/key.jks \
  -file keystore/appsignreq.csr

#sign the cert with the ca
keytool -gencert \
  -alias scoreboardca \
  -keypass scoreboardca \
  -storepass scoreboardca \
  -keystore keystore/cakey.jks \
  -infile keystore/appsignreq.csr \
  -outfile keystore/app.cer

#import the ca cert
keytool -importcert \
  -alias scoreboardca \
  -storepass secret \
  -keypass secret \
  -keystore keystore/key.jks \
  -noprompt \
  -file keystore/scoreboardca.crt

#import the signed cert
keytool -importcert \
  -alias scoreboardappkey \
  -storepass secret \
  -keypass secret \
  -keystore keystore/key.jks \
  -noprompt \
  -file keystore/app.cer

#change the alias of the signed cert
keytool -changealias \
  -alias scoreboardappkey \
  -destalias default \
  -storepass secret \
  -keypass secret \
  -keystore keystore/key.jks

#export the signed cert in pem format for proxy to use
#keytool -exportcert \
#  -alias default \
#  -storepass secret \
#  -keypass secret \
#  -keystore keystore/key.jks \
#  -file keystore/app.pem \
#  -rfc

#export the private key in pem format for proxy to use
#keytool -importkeystore \
#  -srckeystore keystore/key.jks \
#  -destkeystore keystore/key.p12 \
#  -srcstoretype jks \
#  -deststoretype pkcs12 \
#  -srcstorepass secret \
#  -deststorepass secret \
#  -srckeypass secret \
#  -destkeypass secret \
#  -srcalias default
#openssl pkcs12 \
#  -in keystore/key.p12 \
#  -out keystore/private.pem \
#  -nocerts \
#  -nodes \
#  -password pass:secret

#concat the public and private key for haproxy
#cat keystore/app.pem keystore/private.pem > keystore/proxy.pem

#add the cacert to the truststore
keytool -importcert \
  -alias scoreboardca \
  -storepass truststore \
  -keypass truststore \
  -keystore keystore/truststore.jks \
  -noprompt \
  -trustcacerts \
  -file keystore/scoreboardca.crt

#add all jvm cacerts to the truststore.
keytool -importkeystore \
  -srckeystore $JAVA_HOME/lib/security/cacerts \
  -destkeystore keystore/truststore.jks \
  -srcstorepass changeit \
  -deststorepass truststore

#clean up the public cert..
rm -f keystore/public.crt