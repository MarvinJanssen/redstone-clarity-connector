import { toBuffer, bufferToHex, keccak256 } from "ethereumjs-util";
import EvmPriceSigner from "redstone-node/dist/src/signers/EvmPriceSigner";
import { PricePackage } from "redstone-node/dist/src/types";
import { compressPublicKey, createStacksPrivateKey, getPublicKeyFromStacksPrivateKey, isCompressed, publicKeyToString, serializePublicKey, StacksPrivateKey } from "micro-stacks/transactions";
import { bytesToHex } from "micro-stacks/common";
import { bufferCV } from "micro-stacks/clarity";

const privateKey = "0x46c6cdcac4b09b38574d26a113bdb68c76af1a95283733216929aade69bffb11";

const signer = new EvmPriceSigner();

const testPricePackage: PricePackage = {
	prices: [
		{
			symbol: "STX",
			value: 50
		},
		{
			symbol: "USD",
			value: 55443322
		}
	],
	timestamp: 10001234
};

function liteDataHash(liteByteString: string): Uint8Array {
	return keccak256(toBuffer(`0x${liteByteString}`));
}

function liteDataHashPersonalSign(liteDataHash: Uint8Array): Uint8Array {
	const ethPersonalSignPrefix = new Uint8Array([0x19, 0x45, 0x74, 0x68, 0x65, 0x72, 0x65, 0x75, 0x6D, 0x20, 0x53, 0x69, 0x67, 0x6E, 0x65, 0x64, 0x20, 0x4D, 0x65, 0x73, 0x73, 0x61, 0x67, 0x65, 0x3A, 0x0A, 0x33, 0x32]);
	return keccak256(Buffer.from([...ethPersonalSignPrefix, ...liteDataHash]));
}

function compressRedstonePubkey(pubKey: Uint8Array): Uint8Array {
	if (pubKey.length === 33)
		return pubKey;
	else if (pubKey.length === 64)
		pubKey = new Uint8Array([0x04, ...pubKey]);
	return serializePublicKey(compressPublicKey(pubKey));
}

function redstoneLiteSignatureToStacksSignature(liteSignature: Uint8Array) {
	if (liteSignature.byteLength !== 65)
		throw new Error(`Invalid liteSignature, expected 65 bytes got ${liteSignature.byteLength}`);
	let converted = new Uint8Array(liteSignature);
	converted[64] -= 27; // subtract from V
	return converted;
}

const serializedPriceData = signer.serializeToMessage(testPricePackage);
const liteByteString = signer.getLiteDataBytesString(serializedPriceData);
const hashToSign = liteDataHash(liteByteString);
const signaturePackage = signer.signPricePackage(testPricePackage, privateKey);
const signatureCV = redstoneLiteSignatureToStacksSignature(toBuffer(signaturePackage.liteSignature));

console.log("serializedPriceData", serializedPriceData);
console.log("liteByteString", liteByteString);
console.log("hashToSign PrePersonalSign", `0x${bytesToHex(hashToSign)}`);
console.log("hashToSign PersonalSign", `0x${bytesToHex(liteDataHashPersonalSign(hashToSign))}`);
console.log("signer pubkey uncompressed", signaturePackage.signerPubKey);
console.log("signer pubkey compressed", `0x${bytesToHex(compressRedstonePubkey(toBuffer(signaturePackage.signerPubKey)))}`);
console.log("liteSignature", signaturePackage.liteSignature);
console.log("signatureCV", `0x${bytesToHex(signatureCV)}`);

console.log(signer.verifyLiteSignature(signaturePackage))
