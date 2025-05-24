;; Industry Matching Contract
;; Connects innovations with industry applications

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-found (err u300))
(define-constant err-already-exists (err u301))
(define-constant err-unauthorized (err u302))

;; Data Variables
(define-data-var next-match-id uint u1)

;; Data Maps
(define-map industry-needs
  { need-id: uint }
  {
    industry: (string-ascii 100),
    problem-description: (string-ascii 500),
    required-trl: uint,
    budget-range: uint,
    timeline: uint,
    contact: principal,
    status: (string-ascii 20)
  }
)

(define-map innovation-matches
  { match-id: uint }
  {
    innovation-id: uint,
    need-id: uint,
    compatibility-score: uint,
    match-date: uint,
    status: (string-ascii 20)
  }
)

(define-map industry-categories
  { category: (string-ascii 50) }
  { active: bool }
)

;; Public Functions

;; Register industry need
(define-public (register-industry-need
  (industry (string-ascii 100))
  (problem (string-ascii 500))
  (required-trl uint)
  (budget uint)
  (timeline uint)
)
  (let
    (
      (need-id (var-get next-match-id))
    )
    (map-set industry-needs
      { need-id: need-id }
      {
        industry: industry,
        problem-description: problem,
        required-trl: required-trl,
        budget-range: budget,
        timeline: timeline,
        contact: tx-sender,
        status: "open"
      }
    )

    (var-set next-match-id (+ need-id u1))
    (ok need-id)
  )
)

;; Create innovation match
(define-public (create-match
  (innovation-id uint)
  (need-id uint)
  (compatibility-score uint)
)
  (let
    (
      (match-id (var-get next-match-id))
    )
    ;; Validate score range
    (asserts! (<= compatibility-score u100) err-unauthorized)

    (map-set innovation-matches
      { match-id: match-id }
      {
        innovation-id: innovation-id,
        need-id: need-id,
        compatibility-score: compatibility-score,
        match-date: block-height,
        status: "pending"
      }
    )

    (var-set next-match-id (+ match-id u1))
    (ok match-id)
  )
)

;; Update match status
(define-public (update-match-status (match-id uint) (new-status (string-ascii 20)))
  (let
    (
      (match-data (unwrap! (map-get? innovation-matches { match-id: match-id }) err-not-found))
    )
    (map-set innovation-matches
      { match-id: match-id }
      (merge match-data { status: new-status })
    )
    (ok true)
  )
)

;; Add industry category
(define-public (add-industry-category (category (string-ascii 50)))
  (begin
    (map-set industry-categories
      { category: category }
      { active: true }
    )
    (ok true)
  )
)

;; Read-only Functions

(define-read-only (get-industry-need (need-id uint))
  (map-get? industry-needs { need-id: need-id })
)

(define-read-only (get-match (match-id uint))
  (map-get? innovation-matches { match-id: match-id })
)

(define-read-only (is-category-active (category (string-ascii 50)))
  (match (map-get? industry-categories { category: category })
    category-data (get active category-data)
    false
  )
)
