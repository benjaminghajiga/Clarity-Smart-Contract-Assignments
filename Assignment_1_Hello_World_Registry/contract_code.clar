;; Hello World Registry Contract
;; Users can store and retrieve personalized greeting messages

;; Data Maps
;; Store messages with principal as key and string as value
(define-map messages principal (string-utf8 500))

;; Error Constants
(define-constant ERR-EMPTY-MESSAGE (err u100))
(define-constant ERR-MESSAGE-NOT-FOUND (err u101))

;; Public Functions

;; Set or update a greeting message for the caller
;; @param message: the greeting message to store
;; @returns (ok true) on success, ERR-EMPTY-MESSAGE if message is empty
(define-public (set-message (message (string-utf8 500)))
    (begin
        ;; Validate that message is not empty
        (asserts! (> (len message) u0) ERR-EMPTY-MESSAGE)
        
        ;; Store the message in the map with tx-sender as key
        (map-set messages tx-sender message)
        
        (ok true)
    )
)

;; Delete the caller's message
;; @returns (ok true) on success
(define-public (delete-message)
    (begin
        ;; Delete the message for tx-sender
        (map-delete messages tx-sender)
        
        (ok true)
    )
)

;; Read-only Functions

;; Get message for a specific principal
;; @param user: the principal to look up
;; @returns (some message) if found, none otherwise
(define-read-only (get-message (user principal))
    ;; Retrieve and return the message for the given user
    (map-get? messages user)
)

;; Get the caller's own message
;; @returns (some message) if found, none otherwise
(define-read-only (get-my-message)
    ;; Call get-message with tx-sender
    (get-message tx-sender)
)