;; Data Collection Contract
;; Manages clinical trial data collection

(define-map clinical-trials
  { trial-id: uint }
  {
    title: (string-ascii 200),
    org-id: uint,
    start-date: uint,
    end-date: uint,
    status: (string-ascii 20),
    data-hash: (buff 32)
  }
)

(define-map trial-data-points
  { trial-id: uint, data-point-id: uint }
  {
    patient-id: (string-ascii 50),
    timestamp: uint,
    data-type: (string-ascii 50),
    data-hash: (buff 32),
    collector: principal
  }
)

(define-data-var next-trial-id uint u1)
(define-data-var next-data-point-id uint u1)

;; Create a new clinical trial
(define-public (create-trial (title (string-ascii 200)) (org-id uint) (end-date uint))
  (let ((trial-id (var-get next-trial-id)))
    (map-set clinical-trials
      { trial-id: trial-id }
      {
        title: title,
        org-id: org-id,
        start-date: block-height,
        end-date: end-date,
        status: "active",
        data-hash: 0x00
      }
    )
    (var-set next-trial-id (+ trial-id u1))
    (ok trial-id)
  )
)

;; Collect data point for a trial
(define-public (collect-data-point
  (trial-id uint)
  (patient-id (string-ascii 50))
  (data-type (string-ascii 50))
  (data-hash (buff 32))
)
  (let ((data-point-id (var-get next-data-point-id)))
    (match (map-get? clinical-trials { trial-id: trial-id })
      trial-data (begin
        (asserts! (is-eq (get status trial-data) "active") (err u400))
        (map-set trial-data-points
          { trial-id: trial-id, data-point-id: data-point-id }
          {
            patient-id: patient-id,
            timestamp: block-height,
            data-type: data-type,
            data-hash: data-hash,
            collector: tx-sender
          }
        )
        (var-set next-data-point-id (+ data-point-id u1))
        (ok data-point-id)
      )
      (err u404)
    )
  )
)

;; Get trial information
(define-read-only (get-trial (trial-id uint))
  (map-get? clinical-trials { trial-id: trial-id })
)

;; Get data point
(define-read-only (get-data-point (trial-id uint) (data-point-id uint))
  (map-get? trial-data-points { trial-id: trial-id, data-point-id: data-point-id })
)
