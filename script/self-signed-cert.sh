set -eu

OWNER=/L=HIC/O=HIC-infra
CN=localhost

PREFIX=aws-self-signed

if [ ! -f ${PREFIX}-key.pem ]; then
  echo "Generating private key..."
  openssl genrsa 2048 > "aws-self-signed-private.key"
fi

openssl req -new -x509 \
  -subj "${OWNER}/CN=${CN}" \
  -nodes \
  -sha1 \
  -days 365 \
  -extensions v3_ca \
  -addext "subjectAltName = DNS:localhost" \
  -key "aws-self-signed-private.key" \
  -out "aws-self-signed-public.crt"

echo "Run 'aws acm import-certificate --certificate ${PREFIX}-public.crt --private-key ${PREFIX}-private.key'"