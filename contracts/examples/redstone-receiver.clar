;; RedStone Clarity Connector project.
;; Example contract that can receive RedStone price packages and act on them.
;; The contract keeps a list of trusted RedStone oracle public keys.
;; By Marvin Janssen

(define-constant err-not-contract-owner (err u100))
(define-constant err-untrusted-oracle (err u101))
(define-constant err-stale-data (err u102))

(define-data-var contract-owner principal tx-sender)

;; A map of all trusted oracles, indexed by their 33 byte compressed public key.
(define-map trusted-oracles (buff 33) bool)

;; Last seen timestamp. The if clause is so that the contract can deploy on a Clarinet console session.
(define-data-var last-seen-timestamp uint (if (> block-height u0) (get-last-block-timestamp) u0))

(define-public (submit-price-data (timestamp uint) (entries (list 20 {symbol: (buff 32), value: uint})) (signature (buff 65)))
	(let
		(
			;; Recover the pubkey of the signer.
			(signer (try! (contract-call? .redstone-verify recover-signer timestamp entries signature)))
		)
		;; Check if the signer is a trusted oracle.
		(asserts! (is-trusted-oracle signer) err-untrusted-oracle)
		;; Check if the data is not stale, depending on how the app is designed.
		(asserts! (> timestamp (get-last-block-timestamp)) err-stale-data) ;; timestamp should be larger than the last block timestamp.
		(asserts! (>= timestamp (var-get last-seen-timestamp)) err-stale-data) ;; timestamp should be larger than or equal to the last seen timestamp.
		;; Do app-specific actions here.
		(print entries)
		;; Save last seen timestamp.
		(var-set last-seen-timestamp timestamp)
		(ok true)
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