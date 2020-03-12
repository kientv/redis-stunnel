# stunnel
Using stunnel for redis replication in ssl connection to disaster recovery (DR-DC)

                                                                                
                               |----------------------------|                   
                               |                            |                   
                               |                            |                   
                               |        Redis master        |                   
                               |                            |                   
                               |                            |                   
                               --------------|---------------                   
                                             |                                  
                                             |                                  
                                 +----------------------+                       
                                 |    Stunnel server    |                       
                                 +-----------|----------+                       
                                             |                                  
 DC                                          |                                  
                                             |                                  
 --------------------------------------------|----------------------------------
                                      SSL connection                            
 DR                                          |                                  
                                             |                                  
                                             |                                  
                                             |                                  
                                             |                                  
                                 +-----------|----------+                       
                                 |    Stunnel client    |                       
                                 +-----------|----------+                       
                                             |                                  
                                             |                                  
                              |--------------|-------------|                    
                              |                            |                    
                              |                            |                    
                              |        Redis slave         |                    
                              |                            |                    
                              |                            |                    
                              ------------------------------                    
                              
Docker image for providing a TLS endpoint for accessing Redis.

## Usage

The easiest setup is to have this running in parallel with a Redis container on a host machine. The basic gist is as follows:

* Start `redis` container
* Create a CA and server certificate
* Start `redis-stunnel` container and exposing the TLS port (stunnel server)

Details are below.


### CA and Certificate

This is a little more involved. These are roughly the steps:

```bash
# Generate a CA key - will ask for a passphrase
openssl genrsa -aes256 -out ca-key.pem 4096 
# Generate the CA - will ask for various details, defaults all fine
openssl req -new -x509 -days 365 -key ca-key.pem -sha256 -out ca.pem
# Generate a key for the server certificate
openssl genrsa -out server-key.pem 4096
# Generate a certificate signing request
HOST=localhost openssl req -subj "/CN=$HOST" -sha256 -new -key server-key.pem -out server.csr
# Generate a server certificate w/ appropriate options - will ask for passphrase
echo subjectAltName = IP:127.0.0.1 > extfile.cnf
openssl x509 -req -days 365 -sha256 -in server.csr -CA ca.pem -CAkey ca-key.pem \
  -CAcreateserial -out server-cert.pem -extfile extfile.cnf
# Combine key and certificate for stunnel server
cat server-key.pem server-cert.pem > rediscert.pem 
```

### stunnel Container

Start the new container with the certificate, and exposed ports:

```bash
docker build -t redis-stunnel .
docker run -d -v `pwd`/rediscert.pem:/stunnel/private.pem:ro redis-stunnel
```

### stunnel for redis client.
```bash
sudo vi /etc/stunnel/redis-cli.conf
```

Set the following properties in redis-cli.conf file
```
fips = no
setuid = root
setgid = root
pid = /var/run/stunnel.pid
debug = 7
options = NO_SSLv2
options = NO_SSLv3
[redis-cli]
client = yes
accept = 127.0.0.1:6380
connect = 172.17.0.2:6379
```
Start stunnel client
```bash
sudo stunnel /etc/stunnel/redis-cli.conf
```

Test ssl tunnel by redis-cli
```bash
redis-cli -h 172.17.0.1 -p 6380
```
