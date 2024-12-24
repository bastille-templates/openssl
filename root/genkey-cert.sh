# Message for the user before anything is done
echo "Make sure you have set this script with the correct -subj content, such as country, state, city, organization name, common name and email before its first use."

echo "In other words, don't use this script blindly without changing the -subj content first. Press Ctrl C to cancel this operation if in need. You have 10 seconds."

sleep 10
rm -rf /usr/local/etc/ssl

# Create the CA directory
mkdir -p /usr/local/etc/ssl

# Generate the CA primary key
echo "Generating the CA primary key"
openssl genrsa 2048 > /usr/local/etc/ssl/ca-key.pem

# Generate the CA certificate from the primary key
echo "Producing the primary certificate with the CA's key."
openssl req -new -x509 -nodes -days 730 -key /usr/local/etc/ssl/ca-key.pem -out /usr/local/etc/ssl/ca-cert.pem -subj "/C=US/ST=California/L=San Francisco/O=Adminbyaccident Ltd/CN=example.com/emailAddress=youremail@anymail.com"

# Generate the server's key and certificate pair
echo "Generating serve's key and certificate pair."

# 1.- Generate a new key for the server plus a certificate request
openssl req -newkey rsa:2048 -days 730 -nodes -keyout /usr/local/etc/ssl/server-key.pem -out /usr/local/etc/ssl/server-req.pem -subj "/C=US/ST=State/L=City/O=Adminbyaccident Ltd/CN=example.com/emailAddress=youremail@anymail.com"

# 2.- Strip out the passphrase within the key
openssl rsa -in /usr/local/etc/ssl/server-key.pem -out /usr/local/etc/ssl/server-key.pem

# 3.- Generate the server's certificate via the x509 protocol from the cert request plus the server's key with a serial number.
openssl x509 -req -in /usr/local/etc/ssl/server-req.pem -days 730 -CA /usr/local/etc/ssl/ca-cert.pem -CAkey /usr/local/etc/ssl/ca-key.pem -set_serial 0100 -out /usr/local/etc/ssl/server-cert.pem

echo "Server's certificate and key pair have been generated."

# Generate the client's certificate and key pairs
echo "Generating client's key and certificate pair."

# 1.- Generate a new key for the client plus a certificate request
openssl req -newkey rsa:2048 -days 730 -nodes -keyout /usr/local/etc/ssl/client-key.pem -out /usr/local/etc/ssl/client-req.pem -subj "/C=US/ST=California/L=San Francisco/O=Adminbyaccident Ltd/CN=client.example.com/emailAddress=youremail@anymail.com"

# 2.- Strip out the passphrase within the key
openssl rsa -in /usr/local/etc/ssl/client-key.pem -out /usr/local/etc/ssl/client-key.pem

# 3.- Generate the client's certificate via the x509 protocol from the cert request plus the client's key with a serial number.
openssl x509 -req -in /usr/local/etc/ssl/client-req.pem -days 730 -CA /usr/local/etc/ssl/ca-cert.pem -CAkey /usr/local/etc/ssl/ca-key.pem -set_serial 0101 -out /usr/local/etc/ssl/client-cert.pem

echo "Client's certificate and key pair have been generated."

# Check the integrity of the final certificate's with the CA's primary certificate
echo "Verifying the final certificates for the client and server are intact derivatives from the CA's certificate"
openssl verify -CAfile /usr/local/etc/ssl/ca-cert.pem /usr/local/etc/ssl/server-cert.pem /usr/local/etc/ssl/client-cert.pem

echo "If the check response was a pair of OKs, you're done. If otherwise check what went wrong and start it all over again."

chmod 640 /usr/local/etc/ssl
