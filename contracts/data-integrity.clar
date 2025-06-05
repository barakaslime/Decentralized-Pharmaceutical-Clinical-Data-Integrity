;; Data Integrity Contract
;; Ensures clinical data integrity through cryptographic verification

(define-map data-integrity-records
  { record-id: uint }
  {
    trial-id: uint,
    data-hash: (buff 32),
    merkle-root: (buff 32),
    timestamp: uint,
    verifier: principal,
    integrity-score: uint
  }
)

(define-map audit-trail
  { record-id: uint, audit-id: uint }
  {
    action: (string-ascii 50),
    timestamp: uint,
    auditor: principal,
    details: (string-ascii 200)
  }
)

(define-data-var next-record-id uint u1)
(define-data-var next-audit-id uint u1)

;; Create integrity record
(define-public (create-integrity-record
  (trial-id uint)
  (data-hash (buff 32))
  (merkle-root (buff 32))
)
  (let ((record-id (var-get next-record-id)))
    (map-set data-integrity-records
      { record-id: record-id }
      {
        trial-id: trial-id,
        data-hash: data-hash,
        merkle-root: merkle-root,
        timestamp: block-height,
        verifier: tx-sender,
        integrity-score: u100
      }
    )
    (var-set next-record-id (+ record-id u1))
    (ok record-id)
  )
)

;; Verify data integrity
(define-public (verify-data-integrity (record-id uint) (provided-hash (buff 32)))
  (match (map-get? data-integrity-records { record-id: record-id })
    record-data (begin
      (let ((stored-hash (get data-hash record-data)))
        (if (is-eq stored-hash provided-hash)
          (ok true)
          (ok false)
        )
      )
    )
    (err u404)
  )
)

;; Add audit entry
(define-public (add-audit-entry
  (record-id uint)
  (action (string-ascii 50))
  (details (string-ascii 200))
)
  (let ((audit-id (var-get next-audit-id)))
    (map-set audit-trail
      { record-id: record-id, audit-id: audit-id }
      {
        action: action,
        timestamp: block-height,
        auditor: tx-sender,
        details: details
      }
    )
    (var-set next-audit-id (+ audit-id u1))
    (ok audit-id)
  )
)

;; Get integrity record
(define-read-only (get-integrity-record (record-id uint))
  (map-get? data-integrity-records { record-id: record-id })
)

;; Get audit entry
(define-read-only (get-audit-entry (record-id uint) (audit-id uint))
  (map-get? audit-trail { record-id: record-id, audit-id: audit-id })
)
