;; RedStone Clarity Connector project.
;; Example SIP009 NFT contract that is minted with STX
;; but priced in USD. It only accepts price information
;; for the STXUSD pair from (a) specific oracle(s).
;; By Marvin Janssen

(impl-trait .sip009-nft-trait.sip009-nft-trait)

(define-constant err-not-contract-owner (err u100))
(define-constant err-untrusted-oracle (err u101))
(define-constant err-stale-rate (err u102))
(define-constant err-no-known-price (err u103))
(define-constant err-not-token-owner (err u104))

(define-constant price-in-usd u10000000) ;; 10 USD

(define-constant symbol-stxusd 0x535458555344) ;; "STXUSD" as a buff
(define-constant redstone-value-shift u100000000)
(define-constant stacks-base u1000000)
(define-constant redstone-stacks-base-diff (/ redstone-value-shift stacks-base))

(define-data-var contract-owner principal tx-sender)
(define-data-var token-id-nonce uint u0)

(define-non-fungible-token usd-nft uint)

;; A map of all trusted oracles, indexed by their 33 byte compressed public key.
(define-map trusted-oracles (buff 33) bool)
(map-set trusted-oracles 0x035ca791fed34bf9e9d54c0ce4b9626e1382cf13daa46aa58b657389c24a751cc6 true)

;; Last seen timestamp. The if clause is so that the contract can deploy on a Clarinet console session.
(define-data-var last-seen-timestamp uint (if (> block-height u0) (get-last-block-timestamp) u0))
(define-data-var last-stxusd-rate (optional uint) none)

(define-read-only (get-last-token-id)
	(ok (var-get token-id-nonce))
)

(define-read-only (get-token-uri (token-id uint))
	(ok none)
)

(define-read-only (get-owner (token-id uint))
	(ok (nft-get-owner? usd-nft token-id))
)

;; #[allow(unchecked_data)]
(define-public (transfer (token-id uint) (sender principal) (recipient principal))
	(begin
		(asserts! (or (is-eq sender tx-sender) (is-eq sender contract-caller)) err-not-token-owner)
		(nft-transfer? usd-nft token-id sender recipient)
	)
)

;; #[allow(unchecked_data)]
(define-public (mint (timestamp uint) (stxusd-rate uint) (signature (buff 65)))
	(let
		(
			;; Recover the pubkey of the signer.
			(signer (try! (contract-call? .redstone-verify recover-signer timestamp (list {value: stxusd-rate, symbol: symbol-stxusd}) signature)))
			;; Get the latest price using the rate.
			(price (try! (get-update-latest-price-in-stx timestamp stxusd-rate)))
			(token-id (+ (var-get token-id-nonce) u1))
		)
		;; Check if the signer is a trusted oracle. If it fails, then the possible price
		;; update via get-update-latest-price-in-stx is also reverted. This is important.
		(asserts! (is-trusted-oracle signer) err-untrusted-oracle)

		;; Update the token ID nonce.
		(var-set token-id-nonce token-id)

		;; Send the STX equivalent to the contract owner.
		(try! (stx-transfer? price tx-sender (var-get contract-owner)))

		;; Mint the NFT.
		(try! (nft-mint? usd-nft token-id tx-sender))
		(ok token-id)
	)
)

(define-private (get-update-latest-price-in-stx (timestamp uint) (current-stxusd-rate uint))
	(let
		(
			(last-timestamp (var-get last-seen-timestamp))
			(last-block-timestamp (get-last-block-timestamp))
			(newer-data (> timestamp last-timestamp))
		)
		;; If the newest timestamp is older than the timestamp of the last block, then
		;; the data is stale and will not be used.
		(asserts! (> (if newer-data timestamp last-timestamp) last-block-timestamp) err-stale-rate)

		;; If the submitted timestamp is older, use the last known rate. Otherwise,
		;; store the new rate and use it.
		(asserts! newer-data (get-last-price-in-stx))

		(var-set last-seen-timestamp timestamp)
		(var-set last-stxusd-rate (some current-stxusd-rate))
		(ok (usd-to-stx price-in-usd current-stxusd-rate))
	)
)

(define-read-only (usd-to-stx (usd uint) (stxusd-rate uint))
	(/ (* usd stacks-base) (/ stxusd-rate redstone-stacks-base-diff))
)

(define-read-only (get-usd-price)
	price-in-usd
)

(define-read-only (get-last-price-in-stx)
	(match (var-get last-stxusd-rate)
		stxusd-rate (ok (usd-to-stx price-in-usd stxusd-rate))
		err-no-known-price
	)
)

(define-private (get-last-block-timestamp)
	(default-to u0 (get-block-info? time (- block-height u1)))
)

(define-read-only (is-trusted-oracle (pubkey (buff 33)))
	(default-to false (map-get? trusted-oracles pubkey))
)

;; #[allow(unchecked_data)]
(define-public (set-trusted-oracle (pubkey (buff 33)) (trusted bool))
	(begin
		(asserts! (is-eq (var-get contract-owner) tx-sender) err-not-contract-owner)
		(ok (map-set trusted-oracles pubkey trusted))
	)
)

(define-public (set-contract-owner (new-owner principal))
	(begin
		(asserts! (is-eq (var-get contract-owner) tx-sender) err-not-contract-owner)
		(ok (var-set contract-owner tx-sender))
	)
)

(define-public (get-contract-owner)
	(ok (var-get contract-owner))
)