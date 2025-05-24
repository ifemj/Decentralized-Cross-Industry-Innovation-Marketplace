;; Commercialization Tracking Contract
;; Monitors market adoption and success metrics

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-found (err u500))
(define-constant err-unauthorized (err u501))
(define-constant err-invalid-data (err u502))

;; Data Variables
(define-data-var next-metric-id uint u1)

;; Data Maps
(define-map commercialization-metrics
  { innovation-id: uint }
  {
    market-entry-date: uint,
    revenue-generated: uint,
    units-sold: uint,
    market-penetration: uint,
    customer-adoption-rate: uint,
    last-updated: uint,
    status: (string-ascii 20)
  }
)

(define-map milestone-tracking
  { metric-id: uint }
  {
    innovation-id: uint,
    milestone-type: (string-ascii 50),
    target-value: uint,
    achieved-value: uint,
    target-date: uint,
    achieved-date: uint,
    status: (string-ascii 20)
  }
)

(define-map market-feedback
  { innovation-id: uint, feedback-id: uint }
  {
    feedback-type: (string-ascii 50),
    rating: uint,
    comments: (string-ascii 300),
    source: (string-ascii 100),
    date: uint
  }
)

;; Public Functions

;; Initialize commercialization tracking
(define-public (initialize-tracking (innovation-id uint))
  (begin
    (map-set commercialization-metrics
      { innovation-id: innovation-id }
      {
        market-entry-date: u0,
        revenue-generated: u0,
        units-sold: u0,
        market-penetration: u0,
        customer-adoption-rate: u0,
        last-updated: block-height,
        status: "pre-market"
      }
    )
    (ok true)
  )
)

;; Update commercialization metrics
(define-public (update-metrics
  (innovation-id uint)
  (revenue uint)
  (units uint)
  (penetration uint)
  (adoption-rate uint)
)
  (let
    (
      (existing-metrics (unwrap! (map-get? commercialization-metrics { innovation-id: innovation-id }) err-not-found))
    )
    ;; Validate penetration and adoption rate (0-100%)
    (asserts! (<= penetration u10000) err-invalid-data)
    (asserts! (<= adoption-rate u10000) err-invalid-data)

    (map-set commercialization-metrics
      { innovation-id: innovation-id }
      (merge existing-metrics {
        revenue-generated: revenue,
        units-sold: units,
        market-penetration: penetration,
        customer-adoption-rate: adoption-rate,
        last-updated: block-height
      })
    )
    (ok true)
  )
)

;; Set market entry date
(define-public (set-market-entry (innovation-id uint))
  (let
    (
      (existing-metrics (unwrap! (map-get? commercialization-metrics { innovation-id: innovation-id }) err-not-found))
    )
    (map-set commercialization-metrics
      { innovation-id: innovation-id }
      (merge existing-metrics {
        market-entry-date: block-height,
        status: "in-market",
        last-updated: block-height
      })
    )
    (ok true)
  )
)

;; Add milestone
(define-public (add-milestone
  (innovation-id uint)
  (milestone-type (string-ascii 50))
  (target-value uint)
  (target-date uint)
)
  (let
    (
      (metric-id (var-get next-metric-id))
    )
    (map-set milestone-tracking
      { metric-id: metric-id }
      {
        innovation-id: innovation-id,
        milestone-type: milestone-type,
        target-value: target-value,
        achieved-value: u0,
        target-date: target-date,
        achieved-date: u0,
        status: "pending"
      }
    )

    (var-set next-metric-id (+ metric-id u1))
    (ok metric-id)
  )
)

;; Update milestone achievement
(define-public (update-milestone
  (metric-id uint)
  (achieved-value uint)
)
  (let
    (
      (milestone-data (unwrap! (map-get? milestone-tracking { metric-id: metric-id }) err-not-found))
    )
    (map-set milestone-tracking
      { metric-id: metric-id }
      (merge milestone-data {
        achieved-value: achieved-value,
        achieved-date: block-height,
        status: (if (>= achieved-value (get target-value milestone-data)) "achieved" "in-progress")
      })
    )
    (ok true)
  )
)

;; Add market feedback
(define-public (add-market-feedback
  (innovation-id uint)
  (feedback-id uint)
  (feedback-type (string-ascii 50))
  (rating uint)
  (comments (string-ascii 300))
  (source (string-ascii 100))
)
  (begin
    ;; Validate rating (1-5 scale)
    (asserts! (and (>= rating u1) (<= rating u5)) err-invalid-data)

    (map-set market-feedback
      { innovation-id: innovation-id, feedback-id: feedback-id }
      {
        feedback-type: feedback-type,
        rating: rating,
        comments: comments,
        source: source,
        date: block-height
      }
    )
    (ok true)
  )
)

;; Read-only Functions

(define-read-only (get-commercialization-metrics (innovation-id uint))
  (map-get? commercialization-metrics { innovation-id: innovation-id })
)

(define-read-only (get-milestone (metric-id uint))
  (map-get? milestone-tracking { metric-id: metric-id })
)

(define-read-only (get-market-feedback (innovation-id uint) (feedback-id uint))
  (map-get? market-feedback { innovation-id: innovation-id, feedback-id: feedback-id })
)

(define-read-only (calculate-success-score (innovation-id uint))
  (match (map-get? commercialization-metrics { innovation-id: innovation-id })
    metrics-data
      (let
        (
          (revenue-score (if (> (get revenue-generated metrics-data) u0) u25 u0))
          (penetration-score (/ (get market-penetration metrics-data) u400))
          (adoption-score (/ (get customer-adoption-rate metrics-data) u400))
          (market-score (if (> (get market-entry-date metrics-data) u0) u25 u0))
        )
        (+ revenue-score penetration-score adoption-score market-score)
      )
    u0
  )
)
