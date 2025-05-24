;; Innovator Verification Contract
;; Validates and manages technology creators

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-already-verified (err u101))
(define-constant err-not-found (err u102))
(define-constant err-unauthorized (err u103))

;; Data Variables
(define-data-var next-innovator-id uint u1)

;; Data Maps
(define-map innovators
  { innovator-id: uint }
  {
    wallet: principal,
    name: (string-ascii 100),
    expertise: (string-ascii 200),
    verified: bool,
    verification-date: uint,
    reputation-score: uint
  }
)

(define-map innovator-by-wallet
  { wallet: principal }
  { innovator-id: uint }
)

;; Public Functions

;; Register as an innovator
(define-public (register-innovator (name (string-ascii 100)) (expertise (string-ascii 200)))
  (let
    (
      (innovator-id (var-get next-innovator-id))
      (caller tx-sender)
    )
    (asserts! (is-none (map-get? innovator-by-wallet { wallet: caller })) err-already-verified)

    (map-set innovators
      { innovator-id: innovator-id }
      {
        wallet: caller,
        name: name,
        expertise: expertise,
        verified: false,
        verification-date: u0,
        reputation-score: u0
      }
    )

    (map-set innovator-by-wallet
      { wallet: caller }
      { innovator-id: innovator-id }
    )

    (var-set next-innovator-id (+ innovator-id u1))
    (ok innovator-id)
  )
)

;; Verify an innovator (owner only)
(define-public (verify-innovator (innovator-id uint))
  (let
    (
      (innovator-data (unwrap! (map-get? innovators { innovator-id: innovator-id }) err-not-found))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)

    (map-set innovators
      { innovator-id: innovator-id }
      (merge innovator-data {
        verified: true,
        verification-date: block-height
      })
    )
    (ok true)
  )
)

;; Update reputation score
(define-public (update-reputation (innovator-id uint) (new-score uint))
  (let
    (
      (innovator-data (unwrap! (map-get? innovators { innovator-id: innovator-id }) err-not-found))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)

    (map-set innovators
      { innovator-id: innovator-id }
      (merge innovator-data { reputation-score: new-score })
    )
    (ok true)
  )
)

;; Read-only Functions

(define-read-only (get-innovator (innovator-id uint))
  (map-get? innovators { innovator-id: innovator-id })
)

(define-read-only (get-innovator-by-wallet (wallet principal))
  (match (map-get? innovator-by-wallet { wallet: wallet })
    innovator-ref (map-get? innovators { innovator-id: (get innovator-id innovator-ref) })
    none
  )
)

(define-read-only (is-verified (innovator-id uint))
  (match (map-get? innovators { innovator-id: innovator-id })
    innovator-data (get verified innovator-data)
    false
  )
)
