;; Innovation Registration Contract
;; Records and manages new technologies

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u200))
(define-constant err-not-found (err u201))
(define-constant err-unauthorized (err u202))
(define-constant err-invalid-status (err u203))

;; Data Variables
(define-data-var next-innovation-id uint u1)

;; Data Maps
(define-map innovations
  { innovation-id: uint }
  {
    innovator-id: uint,
    title: (string-ascii 100),
    description: (string-ascii 500),
    category: (string-ascii 50),
    technology-readiness-level: uint,
    patent-status: (string-ascii 50),
    registration-date: uint,
    status: (string-ascii 20)
  }
)

(define-map innovation-metadata
  { innovation-id: uint }
  {
    keywords: (string-ascii 200),
    potential-applications: (string-ascii 300),
    development-stage: (string-ascii 100)
  }
)

;; Public Functions

;; Register a new innovation
(define-public (register-innovation
  (innovator-id uint)
  (title (string-ascii 100))
  (description (string-ascii 500))
  (category (string-ascii 50))
  (trl uint)
  (patent-status (string-ascii 50))
)
  (let
    (
      (innovation-id (var-get next-innovation-id))
    )
    ;; Basic validation
    (asserts! (<= trl u9) err-invalid-status)

    (map-set innovations
      { innovation-id: innovation-id }
      {
        innovator-id: innovator-id,
        title: title,
        description: description,
        category: category,
        technology-readiness-level: trl,
        patent-status: patent-status,
        registration-date: block-height,
        status: "active"
      }
    )

    (var-set next-innovation-id (+ innovation-id u1))
    (ok innovation-id)
  )
)

;; Add metadata to innovation
(define-public (add-innovation-metadata
  (innovation-id uint)
  (keywords (string-ascii 200))
  (applications (string-ascii 300))
  (stage (string-ascii 100))
)
  (let
    (
      (innovation-data (unwrap! (map-get? innovations { innovation-id: innovation-id }) err-not-found))
    )
    (map-set innovation-metadata
      { innovation-id: innovation-id }
      {
        keywords: keywords,
        potential-applications: applications,
        development-stage: stage
      }
    )
    (ok true)
  )
)

;; Update innovation status
(define-public (update-innovation-status (innovation-id uint) (new-status (string-ascii 20)))
  (let
    (
      (innovation-data (unwrap! (map-get? innovations { innovation-id: innovation-id }) err-not-found))
    )
    (map-set innovations
      { innovation-id: innovation-id }
      (merge innovation-data { status: new-status })
    )
    (ok true)
  )
)

;; Read-only Functions

(define-read-only (get-innovation (innovation-id uint))
  (map-get? innovations { innovation-id: innovation-id })
)

(define-read-only (get-innovation-metadata (innovation-id uint))
  (map-get? innovation-metadata { innovation-id: innovation-id })
)

(define-read-only (get-innovation-count)
  (- (var-get next-innovation-id) u1)
)
