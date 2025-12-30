;; Simple Voting System Contract
;; Create proposals and vote on them (one vote per user per proposal)

;; Data Variables
(define-data-var proposal-count uint u0)

;; Data Maps
;; Map for proposal details
;; Stores: title, description, yes-votes, no-votes, end-height, creator
(define-map proposals 
    uint 
    {
        title: (string-utf8 100),
        description: (string-utf8 500),
        yes-votes: uint,
        no-votes: uint,
        end-height: uint,
        creator: principal
    }
)

;; Map to track if a user has voted on a proposal
;; Key is composite: {proposal-id: uint, voter: principal}
(define-map votes {proposal-id: uint, voter: principal} bool)

;; Error Constants
(define-constant ERR-NOT-FOUND (err u200))
(define-constant ERR-VOTING-CLOSED (err u201))
(define-constant ERR-ALREADY-VOTED (err u202))
(define-constant ERR-INVALID-PROPOSAL (err u203))

;; Public Functions

;; Create a new proposal
;; @param title: proposal title
;; @param description: proposal description  
;; @param duration: voting duration in blocks
;; @returns (ok proposal-id) on success
(define-public (create-proposal 
    (title (string-utf8 100))
    (description (string-utf8 500))
    (duration uint))
    (let
        (
            (proposal-id (+ (var-get proposal-count) u1))
            ;; Calculate end-height (current block-height + duration)
            (end-height (+ block-height duration))
        )
        ;; Store the proposal data in the proposals map
        (map-set proposals proposal-id {
            title: title,
            description: description,
            yes-votes: u0,
            no-votes: u0,
            end-height: end-height,
            creator: tx-sender
        })
        
        ;; Increment the proposal-count
        (var-set proposal-count proposal-id)
        
        (ok proposal-id)
    )
)

;; Vote on a proposal
;; @param proposal-id: the proposal to vote on
;; @param vote-for: true for yes, false for no
;; @returns (ok true) on success
(define-public (vote (proposal-id uint) (vote-for bool))
    (let
        (
            ;; Get the proposal data
            (proposal (unwrap! (map-get? proposals proposal-id) ERR-NOT-FOUND))
            (current-yes (get yes-votes proposal))
            (current-no (get no-votes proposal))
        )
        ;; Check that voting is still open (block-height <= end-height)
        (asserts! (<= block-height (get end-height proposal)) ERR-VOTING-CLOSED)
        
        ;; Check that user hasn't already voted
        (asserts! (is-none (map-get? votes {proposal-id: proposal-id, voter: tx-sender})) ERR-ALREADY-VOTED)
        
        ;; Record the vote
        (map-set votes {proposal-id: proposal-id, voter: tx-sender} true)
        
        ;; Update vote counts in the proposal
        (map-set proposals proposal-id 
            (merge proposal {
                yes-votes: (if vote-for (+ current-yes u1) current-yes),
                no-votes: (if vote-for current-no (+ current-no u1))
            })
        )
        
        (ok true)
    )
)

;; Read-only Functions

;; Get proposal details
;; @param proposal-id: the proposal to look up
;; @returns proposal data or none
(define-read-only (get-proposal (proposal-id uint))
    ;; Return the proposal data
    (map-get? proposals proposal-id)
)

;; Check if a user has voted on a proposal
;; @param proposal-id: the proposal to check
;; @param user: the user to check
;; @returns true if voted, false otherwise
(define-read-only (has-voted (proposal-id uint) (user principal))
    ;; Check the votes map
    (is-some (map-get? votes {proposal-id: proposal-id, voter: user}))
)

;; Get vote totals for a proposal
;; @param proposal-id: the proposal to check
;; @returns {yes-votes: uint, no-votes: uint}
(define-read-only (get-vote-totals (proposal-id uint))
    (match (map-get? proposals proposal-id)
        proposal {yes-votes: (get yes-votes proposal), no-votes: (get no-votes proposal)}
        {yes-votes: u0, no-votes: u0}
    )
)