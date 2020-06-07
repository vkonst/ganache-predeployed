# ganache-predeployed

Extends [trufflesuite/ganache-cli](https://github.com/trufflesuite/ganache-cli#docker) Docker image by supporting deployment of smart contracts (libs) on the start of the development node.  

The image supports:
- declarative list of smart contracts to deploy
- built-in HTTP-server to list pre-deployed smart contracts (and their addresses)
- validation of actual addresses of deployed smart contracts against expected addresses     
 
__Limitation:__
smart contract constructor params unsupported.

### Smart contract ABI
The byte code of a smart contract must be provided to deploy the contract.  
Therefore the ABI-file with (at least) the "bytecode" property must be mounted/copied inside a container.  
_(see [GCP_ABI_FILES_FOLDER](#GCP_ABI_FILES_FOLDER))_

```shell script
# ABI-file MUST be a valid JSON-file and it MUST contain the "bytecode" property  
$ cat build/contracts/ProxyAdmin.json

{
    ...
    "bytecode": "0x6080604081905260...",
    ...
}
```

### To run the Docker image (container)

__Prerequisites__
1. A folder with [smart contracts ABI-files](#Smart contract ABI) must be mounted/copied to the container  
_(see [GCP_ABI_FILES_FOLDER](#GCP_ABI_FILES_FOLDER))_
2. If not all smart contracts in that folder shall be deployed, a list of smart contracts to deploy shall be defined  
_(see [GCP_LIBS_NAMES](#GCP_LIBS_NAMES), [GCP_EXPECTED_LIBS_FILE](#GCP_EXPECTED_LIBS_FILE))_

```shell script
# Providing ABI-files are in the `./contracts/` folder
$ docker run -v ./contracts/:/app/build/contracts vkonst/ganache-predeployed
```

Expose the rpc server on the port 8565
```shell script
# Providing ABI-files are in the `./contracts/` folder
$ docker run -d --rm --name ganache \
  -v ./contracts/:/app/build/contracts \
  -p 8565:8555 \
  vkonst/ganache-predeployed
```

Serve a list of deployed contracts on the port 8089
```shell script
# Providing ABI-files are in the `./contracts/` folder
$ docker run -d --rm --name ganache \
  -v ./contracts/:/app/build/contracts \
  -p 8089:8080 -p 8565:8555 \
  -e GDEV_SERVE_DEPLOYED_LIBS_FILE=yes \
  vkonst/ganache-predeployed

# to get the list:
$ curl localhost:8089
ProxyAdmin=0x9c47796bc1e469a60dcbf680273ff011e45a1327
CollaborationImpl=0x0f5ea0a652e851678ebf77b69484bfcd31f9459b
LaborLedgerImpl=0x85a84691547b7ccf19d7c31977a7f8c0af1fb25a
```

### To build the Docker image
```shell script
$ docker build -t vkonst/ganache-predeployed . 
```

#### Environmental params 

##### GCP_ABI_FILES_FOLDER
__default__: /app/build/contracts

Path to a folder (inside the container) with ABI-files of contracts.

```shell script
# For example:
$ docker exec -it ganache ls -1 /app/build/contracts

CollaborationImpl.json
CollaborationProxy.json
LaborLedgerImpl.json
LaborLedgerProxy.json
ProxyAdmin.json
```

##### GCP_LIBS_NAMES
__default__: void

List (delimited by ';' ) of contracts names or a single contract name to deploy.  
Contract names are names of the ABI-files, w/o ".json" extensions.

```shell script
# For example:
$ export GCP_LIBS_NAMES="ProxyAdmin;CollaborationImpl"
```

##### GCP_EXPECTED_LIBS_FILE
__default__: /tmp/expected_contracts

File with  the list and expected addresses of smart contracts to deploy.  
If a contract is on the list, the actual address the contract is deployed at is verified against the expected address.

```
# One contract per line: `<contractName>=<expectedAddress>`
# Example:
$ cat > /tmp/expected_contracts << '_EOF_'
ProxyAdmin=0x9c47796bc1e469a60dcbf680273ff011e45a1327
CollaborationImpl=0x0f5ea0a652e851678ebf77b69484bfcd31f9459b
LaborLedgerImpl=0x85a84691547b7ccf19d7c31977a7f8c0af1fb25a
_EOF_
```

##### GCP_DEPLOYED_LIBS_FILE
_default: /tmp/deployed_contracts_

File to write (addresses of) deployed smart contracts in.  
```shell script
# Example:
$ docker exec -it ganache cat /tmp/expected_contracts
ProxyAdmin=0x9c47796bc1e469a60dcbf680273ff011e45a1327
CollaborationImpl=0x0f5ea0a652e851678ebf77b69484bfcd31f9459b
LaborLedgerImpl=0x85a84691547b7ccf19d7c31977a7f8c0af1fb25a
```
If [GCP_SERVE_DEPLOYED_LIBS_LIST](#GCP_SERVE_DEPLOYED_LIBS_LIST) set, this file is served by the built-in http-server.    
One may want to re-define it with another mounted (sharable) file or pipe.

##### GCP_EXPECTED_LIBS_ADRS
_default: undefined_

List (delimited by ';') of expected addresses for the deployed contracts.

```shell script
# For example:
$ export GCP_EXPECTED_LIBS_ADRS="ProxyAdmin=0x9c47796bc1e469a60dcbf680273ff011e45a1327;CollaborationImpl=0x0f5ea0a652e851678ebf77b69484bfcd31f9459b"
```

##### GCP_SERVE_DEPLOYED_LIBS_LIST
_default: undefined_

If defined, the list of the deployed contracts is served on the port 8080.  
So dependent containers/processes may set/update addresses of deployed contracts.  

```shell script
$ export GCP_SERVE_DEPLOYED_LIBS_LIST=yes

# to get the list:
$ curl localhost:8080
ProxyAdmin=0x9c47796bc1e469a60dcbf680273ff011e45a1327
CollaborationImpl=0x0f5ea0a652e851678ebf77b69484bfcd31f9459b
LaborLedgerImpl=0x85a84691547b7ccf19d7c31977a7f8c0af1fb25a
```

The server starts listening the port as soon as the smart contracts get deployed.  
Use it to synchronise dependent containers.  

##### GCP_TIMEOUT_SECONDS
_default: 15_

Timeout in seconds for starting `ganache-cli` and deploying smart contracts.

##### Other params
```shell script
- GCP_ROOT, default: /app/gcp-scripts
```
