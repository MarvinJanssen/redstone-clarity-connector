//TODO turn into proper CLI script.

import EvmPriceSigner from "redstone-node/dist/src/signers/EvmPriceSigner";
import { PricePackage } from "redstone-node/dist/src/types";
import { bytesToHex } from "micro-stacks/common";
import { compressRedstonePubkey, hexToBytes, liteDataHash, liteDataHashPersonalSign, liteSignatureToStacksSignature } from "../src/stacks-redstone";

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

const serializedPriceData = signer.serializeToMessage(testPricePackage);
const liteByteString = signer.getLiteDataBytesString(serializedPriceData);
const hashToSign = liteDataHash(hexToBytes(liteByteString));
const signaturePackage = signer.signPricePackage(testPricePackage, privateKey);
const signatureCV = liteSignatureToStacksSignature(hexToBytes(signaturePackage.liteSignature));

console.log("serializedPriceData", serializedPriceData);
console.log("liteByteString", liteByteString);
console.log("hashToSign PrePersonalSign", `0x${bytesToHex(hashToSign)}`);
console.log("hashToSign PersonalSign", `0x${bytesToHex(liteDataHashPersonalSign(hashToSign))}`);
console.log("signer pubkey uncompressed", signaturePackage.signerPubKey);
console.log("signer pubkey compressed", `0x${bytesToHex(compressRedstonePubkey(hexToBytes(signaturePackage.signerPubKey)))}`);
console.log("liteSignature", signaturePackage.liteSignature);
console.log("signatureCV", `0x${bytesToHex(signatureCV)}`);

console.log(signer.verifyLiteSignature(signaturePackage))
