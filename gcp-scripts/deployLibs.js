#!/usr/bin/env node

const {readdirSync, readFileSync, writeFileSync} = require('fs');
const {join} = require("path");
const http = require('http');

// optional env params
const {
    GCP_ABI_FILES_FOLDER,   // path to a folder with ".json"-files of contracts
    GCP_LIBS_NAMES,         // ';'-delimited list of contracts names to deploy
                            // contract names are names of ".json"-files, w/o ending ".json"
    GCP_EXPECTED_LIBS_ADRS, // ';'-delimited list of expected `<contractName>=<expectedAddress>`
    GCP_DEPLOYED_LIBS_FILE, // file to write actual `<contractName>=<expectedAddress>` values in
} = process.env;

const libsFolder = GCP_ABI_FILES_FOLDER || join(__dirname, '../', 'build/contracts/');
const expected = parseExpectedAddresses(GCP_EXPECTED_LIBS_ADRS);
const libs = GCP_LIBS_NAMES
    ? GCP_LIBS_NAMES.replace(/;\s?$/, '').split(';').map(s => s.trim())
    : (expected ? Object.keys(expected) : listJsonFilesNames(libsFolder));
const exportFile = GCP_DEPLOYED_LIBS_FILE;

if (libs.length === 0){
    console.log('WARNING: no contracts to pre-deploy');
    process.exit();
}

let counter = 1;

return Promise.all(libs.map(
        name => deployContract(name)
            .then(deployed => panicIfUnexpected(deployed, expected))
    ))
    .then(contracts => exportFile ?
        exportToFile(contracts, exportFile) : contracts
    )
    .catch(terminate);

async function deployContract(name) {
    const path = join(libsFolder, `${name}.json`);
    const {bytecode} = JSON.parse(readFileSync(path, 'utf-8'));

    return {
        contract: name,
        address: (await deploy(bytecode)).contractAddress,
    };
}

async function deploy(bytecode) {
    return request(castSendTxData(bytecode, counter++))
        .then(txHash => getReceipt(txHash));
}

async function getReceipt(txHash) {
    return request(castGetReceiptData(txHash, counter++));
}

async function request(data) {
    const postData = JSON.stringify(data);
    const options = castOptions(postData);

    return new Promise((resolve, reject) => {
        let statusCode, body = '';
        const req = http.request(options, (res) => {
            statusCode = res.statusCode;
            res.setEncoding('utf8');
            res.on('data', chunk => body += `${chunk}`);
            res.on('end', () => (statusCode * 1 !== 200)
                ? reject(body)
                : resolve(JSON.parse(body).result)
            );
        });
        req.on('error', (e) => reject(e));
        req.write(postData);
        req.end();
    });
}

function castSendTxData(data, id) {
    // https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sendtransaction
    return {
        jsonrpc: "2.0",
        method: "eth_sendTransaction",
        id,
        params: [{
            from: "0xDf08F82De32B8d460adbE8D72043E3a7e25A3B39",
            gas: "0x4c4b40",            // 5Mio
            gasPrice: "0x9184e72a000",  // 10Gwei
            data
        }],
    };
}

function castGetReceiptData(txHash, id) {
    // https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_gettransactionreceipt
    return {
        jsonrpc: "2.0",
        method: "eth_getTransactionReceipt",
        id,
        params: [txHash],
    };
}

function castOptions(postData) {
    return {
        host: '127.0.0.1',
        port: process.env.GANACHE_PORT || '8545',
        method: 'POST',
        path: '/',
        headers: {
            'Content-Type': 'application/json',
            'Content-Length': Buffer.byteLength(postData)
        },
    };
}

function panicIfUnexpected(instance, expected) {
    console.log(`${instance.contract} deployed at ${instance.address}`);
    if (expected) {
        const expAddr = expected[instance.contract] || {};
        if (expAddr && instance.address.toLowerCase() !== expAddr.toLowerCase()) {
            terminate(`unexpected address of ${instance.contract}: ${instance.address} != ${expAddr}`);
        }
    }
    return instance;
}

function exportToFile(contracts, file) {
    const content = contracts.reduce(
        (acc, c) => acc + `${c.contract}=${c.address}\n`, "",
    );
    writeFileSync(file, content);
    return contracts;
}

function parseExpectedAddresses(str = '') {
    return str === ''
        ? null
        : str.replace(/;\s?$/, '')
            .split(';')
            .map(s => s.trim())
            .reduce((acc, v) => {
                const [name, address] = v.split('=').map(s => s.trim());
                if (!name || !address) {
                    terminate(`failed to parse expected address (${v})`);
                }
                acc[name] = address;
                return acc;
            }, {});
}

function listJsonFilesNames(folder) {
    return readdirSync(folder)
        .filter(f => f.endsWith('.json'))
        .map(f => f.replace(/\.json$/i, ''));
}

function terminate(err = '', exitCode = 1) {
    if (err) console.error(err);
    console.error('terminating due to error ...');
    process.exit(exitCode);
}
