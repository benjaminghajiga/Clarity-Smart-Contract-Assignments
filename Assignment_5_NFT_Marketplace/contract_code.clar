;; NFT Marketplace Contract
;; List, buy, and manage NFT sales with marketplace fees

;; Traits
;; Define the NFT trait (SIP-009)
(define-trait nft-trait
    (
        (transfer (uint principal principal) (response bool uint))
        (get-owner (uint) (response (optional principal) uint))
    )
)

;; Data Variables
(define-data-var listing-count uint u0)
(define-data-var marketplace-fee uint u250) ;; 2.5% (250 basis points)
(define-data-var marketplace-owner principal tx-sender)

;; Constants for listing status
(define-constant STATUS-ACTIVE u1)
(define-constant STATUS-SOLD u2)
(define-constant STATUS-CANCELLED u3)

;; Data Maps
;; Map for listing details
(define-map listings
    uint
    {
        seller: principal,
        nft-contract: principal,
        nft-id: uint,
        price: uint,
        status: uint
    }
)

;; Error Constants
(define-constant ERR-NOT-SELLER (err u500))
(define-constant ERR-NOT-FOUND (err u501))
(define-constant ERR-NOT-ACTIVE (err u502))
(define-constant ERR-NFT-TRANSFER-FAILED (err u503))
(define-constant ERR-PAYMENT-FAILED (err u504))
(define-constant ERR-NOT-OWNER (err u505))
(define-constant ERR-INVALID-PRICE (err u506))

;; Private Functions

;; Calculate marketplace fee
;; @param price: the sale price
;; @returns fee amount
(define-private (calculate-fee (price uint))
    ;; Calculate fee based on marketplace-fee percentage
    ;; Fee is in basis points (e.g., 250 = 2.5%)
    (/ (* price (var-get marketplace-fee)) u10000)
)

;; Public Functions

;; List an NFT for sale
;; @param nft-contract: the NFT contract
;; @param nft-id: the NFT token ID
;; @param price: listing price in STX
;; @returns (ok listing-id) on success
(define-public (list-nft 
    (nft-contract <nft-trait>)
    (nft-id uint)
    (price uint))
    (let
        (
            (listing-id (+ (var-get listing-count) u1))
        )
        ;; Validate price > 0
        (asserts! (> price u0) ERR-INVALID-PRICE)
        
        ;; Transfer NFT from seller to this contract (escrow)
        (unwrap! (contract-call? nft-contract transfer nft-id tx-sender (as-contract tx-sender)) ERR-NFT-TRANSFER-FAILED)
        
        ;; Create listing with STATUS-ACTIVE
        (map-set listings listing-id {
            seller: tx-sender,
            nft-contract: (contract-of nft-contract),
            nft-id: nft-id,
            price: price,
            status: STATUS-ACTIVE
        })
        
        ;; Increment listing-count
        (var-set listing-count listing-id)
        
        (ok listing-id)
    )
)

;; Purchase a listed NFT
;; @param listing-id: the listing to purchase
;; @param nft-contract: the NFT contract (must match listing)
;; @returns (ok true) on success
(define-public (buy-nft 
    (listing-id uint)
    (nft-contract <nft-trait>))
    (let
        (
            (listing (unwrap! (map-get? listings listing-id) ERR-NOT-FOUND))
            (price (get price listing))
            (seller (get seller listing))
            (nft-id (get nft-id listing))
            (fee (calculate-fee price))
            (seller-proceeds (- price fee))
        )
        ;; Verify listing is active
        (asserts! (is-eq (get status listing) STATUS-ACTIVE) ERR-NOT-ACTIVE)
        
        ;; Transfer payment from buyer to seller (minus fee)
        (unwrap! (stx-transfer? seller-proceeds tx-sender seller) ERR-PAYMENT-FAILED)
        
        ;; Transfer fee to marketplace owner
        (unwrap! (stx-transfer? fee tx-sender (var-get marketplace-owner)) ERR-PAYMENT-FAILED)
        
        ;; Transfer NFT from contract to buyer
        (unwrap! (as-contract (contract-call? nft-contract transfer nft-id tx-sender seller)) ERR-NFT-TRANSFER-FAILED)
        
        ;; Update listing status to SOLD
        (map-set listings listing-id (merge listing {status: STATUS-SOLD}))
        
        (ok true)
    )
)

;; Cancel a listing and return NFT
;; @param listing-id: the listing to cancel
;; @param nft-contract: the NFT contract (must match listing)
;; @returns (ok true) on success
(define-public (cancel-listing 
    (listing-id uint)
    (nft-contract <nft-trait>))
    (let
        (
            (listing (unwrap! (map-get? listings listing-id) ERR-NOT-FOUND))
            (seller (get seller listing))
            (nft-id (get nft-id listing))
        )
        ;; Verify caller is seller
        (asserts! (is-eq tx-sender seller) ERR-NOT-SELLER)
        
        ;; Verify listing is active
        (asserts! (is-eq (get status listing) STATUS-ACTIVE) ERR-NOT-ACTIVE)
        
        ;; Transfer NFT back to seller
        (unwrap! (as-contract (contract-call? nft-contract transfer nft-id tx-sender seller)) ERR-NFT-TRANSFER-FAILED)
        
        ;; Update listing status to CANCELLED
        (map-set listings listing-id (merge listing {status: STATUS-CANCELLED}))
        
        (ok true)
    )
)

;; Update listing price
;; @param listing-id: the listing to update
;; @param new-price: the new price
;; @returns (ok true) on success
(define-public (update-price (listing-id uint) (new-price uint))
    (let
        (
            (listing (unwrap! (map-get? listings listing-id) ERR-NOT-FOUND))
        )
        ;; Verify caller is seller
        (asserts! (is-eq tx-sender (get seller listing)) ERR-NOT-SELLER)
        
        ;; Verify listing is active
        (asserts! (is-eq (get status listing) STATUS-ACTIVE) ERR-NOT-ACTIVE)
        
        ;; Validate new-price > 0
        (asserts! (> new-price u0) ERR-INVALID-PRICE)
        
        ;; Update listing price
        (map-set listings listing-id (merge listing {price: new-price}))
        
        (ok true)
    )
)

;; Set marketplace fee (owner only)
;; @param new-fee: new fee in basis points (e.g., 250 = 2.5%)
;; @returns (ok true) on success
(define-public (set-marketplace-fee (new-fee uint))
    (begin
        ;; Verify caller is marketplace owner
        (asserts! (is-eq tx-sender (var-get marketplace-owner)) ERR-NOT-OWNER)
        
        ;; Update marketplace-fee
        (var-set marketplace-fee new-fee)
        
        (ok true)
    )
)

;; Read-only Functions

;; Get listing details
;; @param listing-id: the listing to look up
;; @returns listing data or none
(define-read-only (get-listing (listing-id uint))
    ;; Return listing data
    (map-get? listings listing-id)
)

;; Get current marketplace fee
;; @returns fee in basis points
(define-read-only (get-marketplace-fee)
    (var-get marketplace-fee)
)

;; Get marketplace owner
;; @returns owner principal
(define-read-only (get-marketplace-owner)
    (var-get marketplace-owner)
)

;; Get total listings created
;; @returns count
(define-read-only (get-listing-count)
    (var-get listing-count)
)