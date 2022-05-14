import fs from "fs";
import EvmPriceSigner from "redstone-node/dist/src/signers/EvmPriceSigner";
import { bytesToHex } from "micro-stacks/common";
import { compressRedstonePubkey, hexToBytes, liteDataHash, liteDataHashPersonalSign, liteSignatureToStacksSignature } from "../src/stacks-redstone";

function readJsonFileSync(file: string) {
	const content = fs.readFileSync(file, "utf-8");
	return JSON.parse(content);
}

if (process.argv.length !== 4) {
	console.log(`Usage: ${process.argv0} <price_package.json file> <wallet.json file>`);
	process.exit(0);
}

const signer = new EvmPriceSigner();
const wallet = readJsonFileSync(process.argv[3]);
const privateKey = `0x${wallet.keyInfo.privateKey.substring(0, 64)}`;
const pricePackage = readJsonFileSync(process.argv[2]);

const serializedPriceData = signer.serializeToMessage(pricePackage);
const liteByteString = signer.getLiteDataBytesString(serializedPriceData);
const hashToSign = liteDataHash(hexToBytes(liteByteString));
const signaturePackage = signer.signPricePackage(pricePackage, privateKey);
const signatureCV = liteSignatureToStacksSignature(hexToBytes(signaturePackage.liteSignature));

console.log("serializedPriceData", serializedPriceData);
console.log("liteByteString", liteByteString);
console.log("hashToSign PrePersonalSign", `0x${bytesToHex(hashToSign)}`);
console.log("hashToSign PersonalSign", `0x${bytesToHex(liteDataHashPersonalSign(hashToSign))}`);
console.log("signer pubkey uncompressed", signaturePackage.signerPublicKey);
console.log("signer pubkey compressed", `0x${bytesToHex(compressRedstonePubkey(hexToBytes(signaturePackage.signerPublicKey)))}`);
console.log("liteSignature", signaturePackage.liteSignature);
console.log("signatureCV", `0x${bytesToHex(signatureCV)}`);
console.log(signer.verifyLiteSignature(signaturePackage));
