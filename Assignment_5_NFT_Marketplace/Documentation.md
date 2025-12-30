# Assignment 5: NFT Marketplace

## Student Information
- Name: Benjamin Ghajiga
- Date: 29-12-2025

## Contract Overview
The NFT Marketplace is a decentralized exchange platform for trading SIP-009 compliant NFTs on the Stacks blockchain. Users can list their NFTs for sale, browse and purchase listed NFTs, cancel their listings, and update prices for active listings. The marketplace acts as an escrow service, holding NFTs until they are sold or cancelled, and automatically handles payment distribution including marketplace fees. The contract supports any NFT collection that implements the SIP-009 standard trait, making it a universal marketplace solution.

## Assumptions Made
- All NFTs must conform to the SIP-009 standard trait (transfer and get-owner functions)
- Prices are in micro-STX (1 STX = 1,000,000 micro-STX)
- The marketplace fee is charged in basis points (250 = 2.5%, 100 = 1%)
- Only the original seller can cancel or update their listing
- NFTs are held in escrow by the marketplace contract while listed
- Each listing can only be in one state at a time (active, sold, or cancelled)
- The buyer must have sufficient STX balance to cover both the NFT price and marketplace fee
- NFT transfers are atomic - if any part of the transaction fails, the entire transaction reverts
- The marketplace owner is set at contract deployment and receives all marketplace fees
- Marketplace fee cannot exceed 100% (though contract doesn't enforce this - trust in owner)
- The NFT contract address must be provided again during buy/cancel operations to match the listing

## Design Decisions and Tradeoffs

### Decision 1: Escrow-based listing model
- **What I chose:** NFTs are transferred to the marketplace contract when listed and held until sold or cancelled
- **Why:** Ensures the NFT is actually available for sale and prevents sellers from transferring it elsewhere while listed. This guarantees buyers that listed NFTs are genuinely available.
- **Tradeoff:** Sellers temporarily lose custody of their NFT and cannot use it elsewhere (display in wallet, use in other dapps) while listed. However, this is necessary for marketplace security and buyer confidence. Sellers retain the ability to cancel and reclaim their NFT at any time.

### Decision 2: Basis points for fee calculation
- **What I chose:** Express marketplace fees in basis points (1 basis point = 0.01%, so 250 = 2.5%)
- **Why:** Basis points provide precise percentage representation without floating-point arithmetic. This is standard in financial applications and prevents rounding errors.
- **Tradeoff:** Less intuitive for users (must convert 250 to 2.5%), but provides accurate calculations and prevents precision loss. DApp interfaces should display the percentage format for user convenience.

### Decision 3: Separate fee and seller payment transfers
- **What I chose:** Split the buyer's payment into two transfers: one to the seller (price minus fee) and one to the marketplace owner (fee)
- **Why:** Ensures transparent fee collection and allows the marketplace to earn revenue. Both transfers happen atomically in the same transaction.
- **Tradeoff:** Two transfers cost slightly more gas than one, but provides clear accounting and prevents fee circumvention. If either transfer fails, the entire transaction reverts, ensuring all-or-nothing execution.

### Decision 4: Immutable listing status after sale/cancellation
- **What I chose:** Once a listing is marked as SOLD or CANCELLED, the status cannot be changed
- **Why:** Prevents double-spending of NFTs and provides permanent transaction history. Ensures each NFT can only be sold once per listing.
- **Tradeoff:** Cannot reactivate a cancelled listing - must create a new listing instead. However, this is crucial for security and prevents complex state management bugs.

### Decision 5: Requiring NFT contract parameter in buy/cancel
- **What I chose:** Buyers and sellers must provide the NFT contract as a trait reference when buying or cancelling
- **Why:** Allows the contract to call the NFT's transfer function using the trait. This verifies the correct NFT contract is being used.
- **Tradeoff:** Slight inconvenience requiring users to specify the contract again, but necessary for Clarity's trait system and provides an extra verification step.

### Decision 6: No listing expiration or time limits
- **What I chose:** Listings remain active indefinitely until sold or cancelled by the seller
- **Why:** Different NFTs have different optimal sale timeframes. Allowing indefinite listings gives sellers maximum flexibility.
- **Tradeoff:** Could lead to stale listings if sellers forget about them, but this is preferable to arbitrary time limits that might expire during a potential sale. Sellers maintain full control through cancellation.

### Decision 7: Storing NFT contract as principal, not trait reference
- **What I chose:** Store the NFT contract address as a principal in the listing data using `(contract-of nft-contract)`
- **Why:** Traits cannot be stored directly in maps; we must store the principal address instead
- **Tradeoff:** Requires passing the NFT contract trait again during buy/cancel operations to interact with it, but this is necessary for Clarity's type system and provides additional verification.

## How to Use This Contract

### Function: list-nft
- **Purpose:** List an NFT for sale on the marketplace (NFT is transferred to escrow)
- **Parameters:** 
  - `nft-contract`: The NFT contract implementing the SIP-009 trait
  - `nft-id`: The token ID of the NFT to list (uint)
  - `price`: The listing price in micro-STX (uint). 1 STX = 1,000,000 micro-STX
- **Returns:** `(ok listing-id)` with the new listing's ID on success, `(err u506)` if price is zero or invalid, `(err u503)` if NFT transfer fails
- **Example:**
```clarity
;; List NFT #42 from my-nft-collection for 50 STX
(contract-call? .nft-marketplace list-nft .my-nft-collection u42 u50000000)
```

### Function: buy-nft
- **Purpose:** Purchase a listed NFT (pays seller and marketplace fee, receives NFT)
- **Parameters:** 
  - `listing-id`: The ID of the listing to purchase (uint)
  - `nft-contract`: The NFT contract implementing the SIP-009 trait (must match the listing)
- **Returns:** `(ok true)` on success, `(err u501)` if listing not found, `(err u502)` if listing is not active, `(err u504)` if payment fails, `(err u503)` if NFT transfer fails
- **Example:**
```clarity
;; Buy listing #1
(contract-call? .nft-marketplace buy-nft u1 .my-nft-collection)
```

### Function: cancel-listing
- **Purpose:** Cancel an active listing and return the NFT to the seller
- **Parameters:** 
  - `listing-id`: The ID of the listing to cancel (uint)
  - `nft-contract`: The NFT contract implementing the SIP-009 trait (must match the listing)
- **Returns:** `(ok true)` on success, `(err u501)` if listing not found, `(err u500)` if caller is not the seller, `(err u502)` if listing is not active, `(err u503)` if NFT transfer fails
- **Example:**
```clarity
;; Cancel listing #1 and reclaim NFT
(contract-call? .nft-marketplace cancel-listing u1 .my-nft-collection)
```

### Function: update-price
- **Purpose:** Change the price of an active listing
- **Parameters:** 
  - `listing-id`: The ID of the listing to update (uint)
  - `new-price`: The new price in micro-STX (uint)
- **Returns:** `(ok true)` on success, `(err u501)` if listing not found, `(err u500)` if caller is not the seller, `(err u502)` if listing is not active, `(err u506)` if new price is zero or invalid
- **Example:**
```clarity
;; Update listing #1 price to 75 STX
(contract-call? .nft-marketplace update-price u1 u75000000)
```

### Function: set-marketplace-fee
- **Purpose:** Update the marketplace fee percentage (marketplace owner only)
- **Parameters:** 
  - `new-fee`: The new fee in basis points (uint). Example: 250 = 2.5%, 500 = 5%
- **Returns:** `(ok true)` on success, `(err u505)` if caller is not the marketplace owner
- **Example:**
```clarity
;; Set marketplace fee to 3% (300 basis points)
(contract-call? .nft-marketplace set-marketplace-fee u300)
```

### Function: get-listing
- **Purpose:** Retrieve complete details about a specific listing
- **Parameters:** 
  - `listing-id`: The ID of the listing to look up (uint)
- **Returns:** `(some listing-data)` containing seller, nft-contract, nft-id, price, and status if found, `none` if listing doesn't exist
- **Example:**
```clarity
;; Get details for listing #1
(contract-call? .nft-marketplace get-listing u1)
```

### Function: get-marketplace-fee
- **Purpose:** Get the current marketplace fee percentage
- **Parameters:** None
- **Returns:** Fee in basis points (uint). Example: 250 = 2.5%
- **Example:**
```clarity
;; Check current marketplace fee
(contract-call? .nft-marketplace get-marketplace-fee)
```

### Function: get-marketplace-owner
- **Purpose:** Get the principal address of the marketplace owner
- **Parameters:** None
- **Returns:** The marketplace owner's principal address
- **Example:**
```clarity
;; Get marketplace owner address
(contract-call? .nft-marketplace get-marketplace-owner)
```

### Function: get-listing-count
- **Purpose:** Get the total number of listings ever created
- **Parameters:** None
- **Returns:** Total listing count (uint)
- **Example:**
```clarity
;; Get total number of listings created
(contract-call? .nft-marketplace get-listing-count)
```

## Known Limitations
- No royalty payments to original NFT creators
- Cannot list the same NFT multiple times simultaneously
- No auction or bidding mechanisms (fixed price only)
- No batch listing or buying operations
- Cannot transfer marketplace ownership
- No maximum fee cap enforced (owner could theoretically set 100% fee)
- No listing categories, tags, or search functionality
- Cannot filter or iterate through active listings
- No reputation system for buyers or sellers
- Seller loses custody of NFT while listed (cannot display or use in other dapps)
- No offer system (buyers can only purchase at listed price)
- No escrow for buyer protection (instant transfer on purchase)
- No dispute resolution mechanism
- Fee calculation could result in rounding down to zero for very low-priced NFTs
- No support for bundle sales (multiple NFTs in one transaction)
- No time-limited sales or flash sales functionality

## Future Improvements
- Add royalty payment system for original creators (SIP-009 extension)
- Implement auction mechanisms (English auction, Dutch auction)
- Add offer system allowing buyers to propose different prices
- Create collection-level features (verify collections, featured collections)
- Implement batch operations for listing/buying multiple NFTs
- Add search and filtering by price, collection, seller, traits
- Create reputation/rating system for buyers and sellers
- Add marketplace owner transfer functionality with multi-sig
- Implement maximum fee cap to prevent owner abuse
- Add time-limited sales and scheduled listings
- Create bundle sale functionality for multiple NFTs
- Add "make offer" feature for negotiation
- Implement lazy minting for gas efficiency
- Add escrow period for buyer protection/dispute resolution
- Create listing categories and tags for better discovery
- Add notification system for price changes and sales
- Implement floor price tracking per collection
- Add analytics dashboard (volume, sales, trending)
- Create whitelist/blacklist for specific NFT contracts
- Add staking rewards for active marketplace participants
- Implement cross-chain NFT support
- Add metadata caching for faster loading

## Testing Notes
- Tested using Clarinet console with mock NFT contract implementing SIP-009 trait
- Successfully listed NFTs with various prices (1 STX, 10 STX, 100 STX equivalents)
- Verified listing IDs increment sequentially starting from u1
- Confirmed zero-price listing fails with ERR-INVALID-PRICE (u506)
- Tested successful NFT purchase with correct payment distribution (seller receives price minus fee, marketplace owner receives fee)
- Verified marketplace fee calculation accuracy: 2.5% fee on 100 STX = 2.5 STX fee, 97.5 STX to seller
- Tested successful listing cancellation and verified NFT returned to seller
- Attempted to buy cancelled listing - correctly failed with ERR-NOT-ACTIVE (u502)
- Attempted to cancel already sold listing - correctly failed with ERR-NOT-ACTIVE (u502)
- Tested non-seller attempting to cancel listing - correctly failed with ERR-NOT-SELLER (u500)
- Tested non-seller attempting to update price - correctly failed with ERR-NOT-SELLER (u500)
- Successfully updated listing prices and verified changes persisted
- Tested update-price with zero value - correctly failed with ERR-INVALID-PRICE (u506)
- Verified set-marketplace-fee only works for marketplace owner
- Tested non-owner attempting to change fee - correctly failed with ERR-NOT-OWNER (u505)
- Created multiple concurrent listings from different sellers for different NFTs
- Verified get-listing returns correct details for existing and non-existing listings
- Confirmed get-listing-count accurately tracks total listings created
- Tested edge case: very low price (1 micro-STX) and verified fee calculation
- Validated escrow pattern: marketplace contract holds NFT custody during listing
- Tested atomic transaction guarantee: if payment fails, NFT transfer doesn't happen
- Verified status constants work correctly (STATUS-ACTIVE=u1, STATUS-SOLD=u2, STATUS-CANCELLED=u3)
- Confirmed NFT contract principal is stored correctly using contract-of

## Security Checklist:

- [x] Verify NFT ownership before listing - NFT transfer will fail if seller doesn't own it
- [x] Prevent double-spending of NFTs - Status changes prevent re-selling same listing
- [x] Ensure atomic swaps (payment + NFT transfer together) - All transfers in same transaction, any failure reverts all
- [x] Validate all state transitions - Status checks ensure listings can only move from ACTIVE to SOLD/CANCELLED
- [x] Check for integer overflow in fee calculations - Using safe arithmetic with basis points (max 10000)
- [x] Only seller can modify their listings - ERR-NOT-SELLER check on cancel and update-price functions