;; Simple Escrow Contract
;; Two-party escrow where buyer deposits and can release to seller or refund

;; Data Variables
(define-data-var escrow-count uint u0)

;; Constants for escrow status
(define-constant STATUS-PENDING u1)
(define-constant STATUS-COMPLETED u2)
(define-constant STATUS-REFUNDED u3)

;; Data Maps
;; Map for escrow details
(define-map escrows 
    uint 
    {
        buyer: principal,
        seller: principal,
        amount: uint,
        status: uint,
        created-at: uint
    }
)

;; Error Constants
(define-constant ERR-NOT-BUYER (err u400))
(define-constant ERR-NOT-FOUND (err u401))
(define-constant ERR-NOT-PENDING (err u402))
(define-constant ERR-TRANSFER-FAILED (err u403))
(define-constant ERR-INVALID-AMOUNT (err u404))

;; Private Functions

;; Check if caller is the buyer of an escrow
(define-private (is-buyer (escrow-id uint) (caller principal))
    (match (map-get? escrows escrow-id)
        escrow (is-eq caller (get buyer escrow))
        false
    )
)

;; Public Functions

;; Create an escrow and deposit STX
;; @param seller: the seller's principal
;; @param amount: amount of STX to escrow
;; @returns (ok escrow-id) on success
(define-public (create-escrow (seller principal) (amount uint))
    (let
        (
            (escrow-id (+ (var-get escrow-count) u1))
        )
        ;; Validate amount > 0
        (asserts! (> amount u0) ERR-INVALID-AMOUNT)
        
        ;; Transfer STX from buyer to this contract
        (unwrap! (stx-transfer? amount tx-sender (as-contract tx-sender)) ERR-TRANSFER-FAILED)
        
        ;; Store escrow data with STATUS-PENDING
        (map-set escrows escrow-id {
            buyer: tx-sender,
            seller: seller,
            amount: amount,
            status: STATUS-PENDING,
            created-at: block-height
        })
        
        ;; Increment escrow-count
        (var-set escrow-count escrow-id)
        
        (ok escrow-id)
    )
)

;; Buyer releases funds to seller
;; @param escrow-id: the escrow to release
;; @returns (ok true) on success
(define-public (release-funds (escrow-id uint))
    (let
        (
            (escrow (unwrap! (map-get? escrows escrow-id) ERR-NOT-FOUND))
            (seller (get seller escrow))
            (amount (get amount escrow))
        )
        ;; Verify caller is buyer
        (asserts! (is-eq tx-sender (get buyer escrow)) ERR-NOT-BUYER)
        
        ;; Verify status is pending
        (asserts! (is-eq (get status escrow) STATUS-PENDING) ERR-NOT-PENDING)
        
        ;; Transfer STX from contract to seller
        (unwrap! (as-contract (stx-transfer? amount tx-sender seller)) ERR-TRANSFER-FAILED)
        
        ;; Update escrow status to COMPLETED
        (map-set escrows escrow-id (merge escrow {status: STATUS-COMPLETED}))
        
        (ok true)
    )
)

;; Buyer cancels and gets refund
;; @param escrow-id: the escrow to refund
;; @returns (ok true) on success
(define-public (refund (escrow-id uint))
    (let
        (
            (escrow (unwrap! (map-get? escrows escrow-id) ERR-NOT-FOUND))
            (buyer (get buyer escrow))
            (amount (get amount escrow))
        )
        ;; Verify caller is buyer
        (asserts! (is-eq tx-sender buyer) ERR-NOT-BUYER)
        
        ;; Verify status is pending
        (asserts! (is-eq (get status escrow) STATUS-PENDING) ERR-NOT-PENDING)
        
        ;; Transfer STX from contract back to buyer
        (unwrap! (as-contract (stx-transfer? amount tx-sender buyer)) ERR-TRANSFER-FAILED)
        
        ;; Update escrow status to REFUNDED
        (map-set escrows escrow-id (merge escrow {status: STATUS-REFUNDED}))
        
        (ok true)
    )
)

;; Read-only Functions

;; Get escrow details
;; @param escrow-id: the escrow to look up
;; @returns escrow data or none
(define-read-only (get-escrow (escrow-id uint))
    ;; Return escrow data
    (map-get? escrows escrow-id)
)

;; Get total number of escrows created
;; @returns count
(define-read-only (get-escrow-count)
    (var-get escrow-count)
)