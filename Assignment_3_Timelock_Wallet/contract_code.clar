;; Time-locked Wallet Contract
;; Deposit STX that can only be withdrawn after a specified block height

;; Data Maps
;; Map to track each user's locked balance
(define-map balances principal uint)

;; Map to track each user's unlock block height
(define-map unlock-heights principal uint)

;; Data Variable for total locked
(define-data-var total-locked uint u0)

;; Error Constants
(define-constant ERR-NOTHING-TO-WITHDRAW (err u300))
(define-constant ERR-STILL-LOCKED (err u301))
(define-constant ERR-TRANSFER-FAILED (err u302))
(define-constant ERR-NO-BALANCE (err u303))
(define-constant ERR-INVALID-AMOUNT (err u304))

;; Public Functions

;; Deposit STX with a lock period
;; @param amount: amount of STX to deposit (in micro-STX)
;; @param lock-blocks: number of blocks to lock for
;; @returns (ok true) on success
(define-public (deposit (amount uint) (lock-blocks uint))
    (let
        (
            ;; Calculate unlock height (current block + lock-blocks)
            (unlock-height (+ block-height lock-blocks))
            (current-balance (default-to u0 (map-get? balances tx-sender)))
            (new-balance (+ current-balance amount))
        )
        ;; Validate amount > 0
        (asserts! (> amount u0) ERR-INVALID-AMOUNT)
        
        ;; Transfer STX from tx-sender to this contract
        (unwrap! (stx-transfer? amount tx-sender (as-contract tx-sender)) ERR-TRANSFER-FAILED)
        
        ;; Update user's balance and unlock-height
        (map-set balances tx-sender new-balance)
        (map-set unlock-heights tx-sender unlock-height)
        
        ;; Update total-locked
        (var-set total-locked (+ (var-get total-locked) amount))
        
        (ok true)
    )
)

;; Withdraw all locked STX (after unlock time)
;; @returns (ok amount) on success
(define-public (withdraw)
    (let
        (
            (user-balance (default-to u0 (map-get? balances tx-sender)))
            (user-unlock-height (default-to u0 (map-get? unlock-heights tx-sender)))
        )
        ;; Check that user has a balance
        (asserts! (> user-balance u0) ERR-NO-BALANCE)
        
        ;; Check that current block-height >= unlock-height
        (asserts! (>= block-height user-unlock-height) ERR-STILL-LOCKED)
        
        ;; Transfer STX from contract back to user
        (unwrap! (as-contract (stx-transfer? user-balance tx-sender sender)) ERR-TRANSFER-FAILED)
        
        ;; Clear user's balance and unlock-height
        (map-delete balances tx-sender)
        (map-delete unlock-heights tx-sender)
        
        ;; Update total-locked
        (var-set total-locked (- (var-get total-locked) user-balance))
        
        (ok user-balance)
    )
)

;; Extend the lock period
;; @param additional-blocks: blocks to add to lock period
;; @returns (ok new-unlock-height) on success
(define-public (extend-lock (additional-blocks uint))
    (let
        (
            (current-unlock (default-to u0 (map-get? unlock-heights tx-sender)))
            (user-balance (default-to u0 (map-get? balances tx-sender)))
            (new-unlock-height (+ current-unlock additional-blocks))
        )
        ;; Check that user has a balance
        (asserts! (> user-balance u0) ERR-NO-BALANCE)
        
        ;; Calculate new unlock height and update
        (map-set unlock-heights tx-sender new-unlock-height)
        
        (ok new-unlock-height)
    )
)

;; Read-only Functions

;; Get locked balance for a user
;; @param user: the principal to check
;; @returns balance amount
(define-read-only (get-balance (user principal))
    ;; Return user's balance from map
    (default-to u0 (map-get? balances user))
)

;; Get unlock height for a user
;; @param user: the principal to check
;; @returns unlock block height
(define-read-only (get-unlock-height (user principal))
    ;; Return user's unlock height
    (default-to u0 (map-get? unlock-heights user))
)

;; Get total STX locked in contract
;; @returns total locked amount
(define-read-only (get-total-locked)
    (var-get total-locked)
)