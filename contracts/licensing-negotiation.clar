;; Licensing Negotiation Contract
;; Manages technology transfer agreements

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-found (err u400))
(define-constant err-unauthorized (err u401))
(define-constant err-invalid-terms (err u402))
(define-constant err-already-signed (err u403))

;; Data Variables
(define-data-var next-license-id uint u1)

;; Data Maps
(define-map license-agreements
  { license-id: uint }
  {
    innovation-id: uint,
    licensor: principal,
    licensee: principal,
    license-type: (string-ascii 50),
    royalty-rate: uint,
    upfront-payment: uint,
    duration: uint,
    territory: (string-ascii 100),
    status: (string-ascii 20),
    creation-date: uint
  }
)

(define-map license-terms
  { license-id: uint }
  {
    exclusivity: bool,
    sublicensing-allowed: bool,
    field-of-use: (string-ascii 200),
    performance-milestones: (string-ascii 300)
  }
)

(define-map signatures
  { license-id: uint, signer: principal }
  { signed: bool, signature-date: uint }
)

;; Public Functions

;; Create license agreement
(define-public (create-license-agreement
  (innovation-id uint)
  (licensee principal)
  (license-type (string-ascii 50))
  (royalty-rate uint)
  (upfront-payment uint)
  (duration uint)
  (territory (string-ascii 100))
)
  (let
    (
      (license-id (var-get next-license-id))
    )
    ;; Validate royalty rate (max 50%)
    (asserts! (<= royalty-rate u5000) err-invalid-terms)

    (map-set license-agreements
      { license-id: license-id }
      {
        innovation-id: innovation-id,
        licensor: tx-sender,
        licensee: licensee,
        license-type: license-type,
        royalty-rate: royalty-rate,
        upfront-payment: upfront-payment,
        duration: duration,
        territory: territory,
        status: "draft",
        creation-date: block-height
      }
    )

    (var-set next-license-id (+ license-id u1))
    (ok license-id)
  )
)

;; Add license terms
(define-public (add-license-terms
  (license-id uint)
  (exclusivity bool)
  (sublicensing bool)
  (field-of-use (string-ascii 200))
  (milestones (string-ascii 300))
)
  (let
    (
      (license-data (unwrap! (map-get? license-agreements { license-id: license-id }) err-not-found))
    )
    ;; Only licensor can add terms
    (asserts! (is-eq tx-sender (get licensor license-data)) err-unauthorized)

    (map-set license-terms
      { license-id: license-id }
      {
        exclusivity: exclusivity,
        sublicensing-allowed: sublicensing,
        field-of-use: field-of-use,
        performance-milestones: milestones
      }
    )
    (ok true)
  )
)

;; Sign license agreement
(define-public (sign-license (license-id uint))
  (let
    (
      (license-data (unwrap! (map-get? license-agreements { license-id: license-id }) err-not-found))
      (existing-signature (map-get? signatures { license-id: license-id, signer: tx-sender }))
    )
    ;; Check if already signed
    (asserts! (is-none existing-signature) err-already-signed)

    ;; Only licensor or licensee can sign
    (asserts! (or
      (is-eq tx-sender (get licensor license-data))
      (is-eq tx-sender (get licensee license-data))
    ) err-unauthorized)

    (map-set signatures
      { license-id: license-id, signer: tx-sender }
      { signed: true, signature-date: block-height }
    )

    ;; Check if both parties have signed
    (let
      (
        (licensor-signed (is-some (map-get? signatures { license-id: license-id, signer: (get licensor license-data) })))
        (licensee-signed (is-some (map-get? signatures { license-id: license-id, signer: (get licensee license-data) })))
      )
      (if (and licensor-signed licensee-signed)
        (begin
          (map-set license-agreements
            { license-id: license-id }
            (merge license-data { status: "active" })
          )
          (ok "fully-executed")
        )
        (ok "partially-signed")
      )
    )
  )
)

;; Read-only Functions

(define-read-only (get-license-agreement (license-id uint))
  (map-get? license-agreements { license-id: license-id })
)

(define-read-only (get-license-terms (license-id uint))
  (map-get? license-terms { license-id: license-id })
)

(define-read-only (get-signature (license-id uint) (signer principal))
  (map-get? signatures { license-id: license-id, signer: signer })
)

(define-read-only (is-fully-executed (license-id uint))
  (match (map-get? license-agreements { license-id: license-id })
    license-data (is-eq (get status license-data) "active")
    false
  )
)
