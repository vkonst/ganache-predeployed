# ganache-predeployed

Extends [trufflesuite/ganache-cli](https://github.com/trufflesuite/ganache-cli#docker) Docker image with smart contracts (libs) pre-deployment.  

The image supports:
- (pre-)deployment as a part of the image (container) start process
- declarative list of smart contracts to pre-deploy
- built-in HTTP-server that allows
    - serving the list of pre-deployed smart contracts (and their addresses)
    - killing the container
- validation of actual addresses of pre-deployed smart contracts against expected addresses     

__Limitation:__ smart contract constructor params unsupported.

### ABI-files
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

### Images

- _vkonst/ganache-predeployed (default)_  
The image does not includes the ["tini" utility](https://github.com/krallin/tini).     
Use it if the built-in docker `--init` flag is available (Docker 1.13 or greater, `docker stack` rather then `docker-compose`).

- _vkonst/ganache-predeployed:tiny_  
The image includes the ["tini" utility - "a tiny but valid init for containers"](https://github.com/krallin/tini).   
For use in docker environments where the built-in docker `--init` flag is unavailable (`docker-compose`).

### To run the Docker image (container)

#### Prerequisite  
A folder with [ABI-files](#ABI-files) must be mounted to the container  
_(see [GCP_ABI_FILES_FOLDER](#GCP_ABI_FILES_FOLDER))_

#### Smart contract to deploy
By default, all smart contracts found in the [ABI-files folder](#ABI-files) will be deployed.

To deploy some of contracts only, either define [GCP_LIBS_NAMES](#GCP_LIBS_NAMES) param or list contracts in the [GCP_EXPECTED_LIBS_FILE](#GCP_EXPECTED_LIBS_FILE).

#### Examples

Mount [ABI-files folder](#ABI-files) (`./contracts/`)
```shell script
$ docker run -v ./contracts/:/app/build/contracts -p 8545:8545 vkonst/ganache-predeployed
```

Expose the rpc server on the port 8555
```shell script
# Run in background, remove container when stopped,
# name it `ganache` and make `default signal handlers` work
$ docker run -d --rm --name ganache --init \
  -v ./contracts/:/app/build/contracts \
  -p 8555:8545 \
  vkonst/ganache-predeployed

# the same using  `tini` image
$ docker run -d --rm --name ganache \
  -v ./contracts/:/app/build/contracts \
  -p 8555:8545 \
  vkonst/ganache-predeployed:tini
```

Serve a list of deployed contracts on the port 8089
```shell script
$ docker run -d --rm --name ganache --init \
  -v ./contracts/:/app/build/contracts \
  -p 8089:8080 -p 8555:8545 \
  -e GCP_SERVE_DEPLOYED_LIBS_FILE=yes \
  vkonst/ganache-predeployed

# using image with `tini`:
$ docker run -d --rm --name ganache \
  -v ./contracts/:/app/build/contracts \
  -p 8089:8080 -p 8555:8545 \
  -e GCP_SERVE_DEPLOYED_LIBS_FILE=yes \
  vkonst/ganache-predeployed:tini

# to get the list:
$ curl localhost:8089
ProxyAdmin=0x9c47796bc1e469a60dcbf680273ff011e45a1327
CollaborationImpl=0x0f5ea0a652e851678ebf77b69484bfcd31f9459b
LaborLedgerImpl=0x85a84691547b7ccf19d7c31977a7f8c0af1fb25a
```

### To build the Docker image
```shell script

# default image - w/o `tini` (https://github.com/krallin/tini) 
$ docker build -t vkonst/ganache-predeployed .

# image with `tini` (https://github.com/krallin/tini)
$ docker build -f ./Dockerfile-tini -t vkonst/ganache-predeployed:tiny .
```

#### Environmental params 

##### GCP_ABI_FILES_FOLDER
_default:_ `/app/build/contracts`

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
_default_: `undefined`

List (delimited by `;` ) of contracts names or a single contract name to deploy.  
Contract names are names of the ABI-files, w/o ".json" extensions.

```shell script
# For example:
$ export GCP_LIBS_NAMES="ProxyAdmin;CollaborationImpl"
```

##### GCP_EXPECTED_LIBS_FILE
_default_: `/tmp/expected_contracts`

File with  the list and expected addresses of smart contracts to deploy.  
If a contract is on the list, the actual address the contract is deployed at is verified against the expected address.

Should the address a contract is deployed at mismatches the expected address, the error is logged.  
NOTE: Pass the `--init` flag to docker `run` command to make the error kill the running container.
If your docker environment does not support `--tini` flag, use the `tini` image.
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
_default_: `/tmp/deployed_contracts`

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
_default_: `undefined`

List (delimited by `;`) of expected addresses of pre-deployed contracts.  
Should the address a contract is deployed at mismatches the expected address, the error is logged.  
NOTE: Pass the `--init` flag to docker `run` command to make the error kill the running container.
If your docker environment does not support `--tini` flag, use the `tini` image.

```shell script
# For example:
$ export GCP_EXPECTED_LIBS_ADRS="ProxyAdmin=0x9c47796bc1e469a60dcbf680273ff011e45a1327;CollaborationImpl=0x0f5ea0a652e851678ebf77b69484bfcd31f9459b"
```

##### GCP_SERVE_DEPLOYED_LIBS_LIST
_default_: `undefined`

If defined, the list of the deployed contracts is served on the port 8080.  
So dependent containers/processes may set/update addresses of deployed contracts.  

```shell script
$ export GCP_SERVE_DEPLOYED_LIBS_LIST=yes

# to get the list:
$ curl localhost:8080
ProxyAdmin=0x9c47796bc1e469a60dcbf680273ff011e45a1327
CollaborationImpl=0x0f5ea0a652e851678ebf77b69484bfcd31f9459b
LaborLedgerImpl=0x85a84691547b7ccf19d7c31977a7f8c0af1fb25a

# to kill the container:
curl localhost:8080/kill-container
```

The server starts listening the port as soon as the smart contracts get deployed.  
Use it to synchronise dependent containers.  

##### GCP_TIMEOUT_SECONDS
_default_: `15`

Timeout in seconds for starting `ganache-cli` and deploying smart contracts.

##### GCP_STOP_ON_ERRORS
_default_: `yes`

If set to "no", mismatching expected addresses of deployed contracts do not kill the running container.  
(See [GCP_EXPECTED_LIBS_ADRS](#GCP_EXPECTED_LIBS_ADRS) and [GCP_EXPECTED_LIBS_FILE](#GCP_EXPECTED_LIBS_FILE))

##### Other params
```shell script
- GCP_ROOT, default: /app/gcp-scripts
```
