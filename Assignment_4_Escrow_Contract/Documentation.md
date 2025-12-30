# Assignment 4: Simple Escrow Contract

## Student Information
- Name: Benjamin Ghajiga
- Date: 29-12-2025

## Contract Overview
The Simple Escrow Contract is a trustless two-party escrow service that facilitates secure transactions between buyers and sellers on the Stacks blockchain. When a buyer creates an escrow, their STX funds are held securely by the smart contract until they either release payment to the seller (upon satisfactory delivery) or request a refund. This protects both parties: sellers are assured that payment is secured, and buyers can recover funds if goods or services aren't delivered as agreed.

## Assumptions Made
- All amounts are in micro-STX (1 STX = 1,000,000 micro-STX)
- Only the buyer can release funds to the seller or request a refund
- The seller has no direct control over the escrow once created
- Each escrow can only be acted upon once (either released or refunded, not both)
- No time limits or automatic releases - escrows remain pending indefinitely until buyer acts
- No arbitration mechanism - buyer has full control over fund release/refund decision
- The seller principal must be different from the buyer (though contract doesn't enforce this)
- Escrow status is immutable once changed from pending to completed or refunded
- No service fees are charged (buyer gets full refund, seller gets full amount)

## Design Decisions and Tradeoffs

### Decision 1: Buyer-only control (no seller actions)
- **What I chose:** Only the buyer can release funds or request refunds; the seller has no direct actions they can perform
- **Why:** Protects the buyer from premature fund release and maintains the purpose of escrow as buyer protection. The seller's incentive is to deliver as promised to receive payment.
- **Tradeoff:** Creates power imbalance where dishonest buyers could hold funds indefinitely. However, this is the standard escrow model and protects against the more common risk of non-delivery. A dispute resolution mechanism would address this but adds complexity.

### Decision 2: No time limits on escrows
- **What I chose:** Escrows remain in pending status indefinitely until the buyer releases or refunds
- **Why:** Different transactions have different timelines (physical goods shipping vs digital delivery). Arbitrary time limits could penalize legitimate slow transactions.
- **Tradeoff:** Funds could remain locked indefinitely if buyer abandons the transaction. This provides maximum flexibility but could lead to permanently locked funds. Future versions could add optional time-based auto-release.

### Decision 3: Immutable status once completed or refunded
- **What I chose:** Once an escrow moves from PENDING to COMPLETED or REFUNDED, the status cannot be changed
- **Why:** Prevents double-spending attacks and ensures finality of transactions. Once funds are transferred, the escrow is permanently closed.
- **Tradeoff:** No way to reverse accidental releases or refunds. However, this is critical for security - allowing status changes would create vulnerabilities for fund theft.

### Decision 4: Simple three-state status system
- **What I chose:** Used only three statuses: PENDING (u1), COMPLETED (u2), and REFUNDED (u3)
- **Why:** Keeps the state machine simple and covers all necessary states for basic escrow functionality
- **Tradeoff:** Doesn't support more complex workflows like partial releases, disputes, or multi-stage payments. However, simplicity reduces bugs and makes the contract easier to audit and understand.

### Decision 5: No service fees or commissions
- **What I chose:** The contract doesn't take any fees from escrow transactions
- **Why:** Keeps the contract pure and predictable - what goes in is exactly what comes out (minus gas fees)
- **Tradeoff:** No revenue model for contract deployment/maintenance. However, this makes the contract more attractive to users and simpler to reason about. Fees could be added in future versions.

### Decision 6: Storing creation block height
- **What I chose:** Record the block height when each escrow is created in the `created-at` field
- **Why:** Provides temporal context and enables future features like time-based analytics or automatic resolution
- **Tradeoff:** Uses a small amount of extra storage, but provides valuable metadata for tracking and potential dispute resolution.

## How to Use This Contract

### Function: create-escrow
- **Purpose:** Create a new escrow by depositing STX funds that will be held until released or refunded
- **Parameters:** 
  - `seller`: The principal address that will receive funds if released
  - `amount`: Amount of STX to escrow in micro-STX (uint). 1 STX = 1,000,000 micro-STX
- **Returns:** `(ok escrow-id)` with the new escrow's ID on success, `(err u404)` if amount is zero or invalid, `(err u403)` if STX transfer fails
- **Example:**
```clarity
;; Create escrow for 10 STX with seller address
(contract-call? .simple-escrow create-escrow 'ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC u10000000)
```

### Function: release-funds
- **Purpose:** Buyer releases the escrowed funds to the seller (indicating satisfactory completion)
- **Parameters:** 
  - `escrow-id`: The ID of the escrow to release (uint)
- **Returns:** `(ok true)` on success, `(err u401)` if escrow not found, `(err u400)` if caller is not the buyer, `(err u402)` if escrow is not pending, `(err u403)` if transfer fails
- **Example:**
```clarity
;; Release funds for escrow #1 to the seller
(contract-call? .simple-escrow release-funds u1)
```

### Function: refund
- **Purpose:** Buyer cancels the escrow and receives their funds back (indicating non-delivery or dissatisfaction)
- **Parameters:** 
  - `escrow-id`: The ID of the escrow to refund (uint)
- **Returns:** `(ok true)` on success, `(err u401)` if escrow not found, `(err u400)` if caller is not the buyer, `(err u402)` if escrow is not pending, `(err u403)` if transfer fails
- **Example:**
```clarity
;; Cancel and refund escrow #1
(contract-call? .simple-escrow refund u1)
```

### Function: get-escrow
- **Purpose:** Retrieve complete details about a specific escrow
- **Parameters:** 
  - `escrow-id`: The ID of the escrow to look up (uint)
- **Returns:** `(some escrow-data)` containing buyer, seller, amount, status, and created-at fields if found, `none` if escrow doesn't exist
- **Example:**
```clarity
;; Get details for escrow #1
(contract-call? .simple-escrow get-escrow u1)
```

### Function: get-escrow-count
- **Purpose:** Get the total number of escrows that have been created
- **Parameters:** None
- **Returns:** Total count of escrows (uint)
- **Example:**
```clarity
;; Get total number of escrows created
(contract-call? .simple-escrow get-escrow-count)
```

## Known Limitations
- No arbitration or dispute resolution mechanism - buyer has complete control
- No time limits or automatic release/refund features
- Seller cannot dispute or contest a refund
- No partial release functionality (all-or-nothing)
- No multi-signature or third-party approval options
- Cannot modify escrow details (amount, parties) after creation
- No service fees or revenue model for contract operators
- No way to list all escrows or filter by buyer/seller
- Buyer and seller could be the same principal (though this defeats the purpose)
- No protection against buyer never taking action (funds locked indefinitely)
- No reputation or rating system for buyers/sellers
- Cannot cancel or delete escrow before any action is taken
- No support for multiple currencies or token types (STX only)

## Future Improvements
- Add optional time-based automatic release (if buyer doesn't act within X blocks, auto-release to seller)
- Implement arbitration mechanism with trusted third party
- Add partial release capability for staged payments
- Charge configurable service fees (e.g., 1% to contract owner)
- Create dispute resolution system with majority voting or oracle integration
- Add multi-signature support requiring both parties or third party approval
- Implement reputation scoring for buyers and sellers
- Add escrow templates for common transaction types (goods, services, real estate)
- Create notification system for status changes
- Add ability to update seller address (with buyer approval)
- Implement escrow extensions/renewals
- Add support for ERC-20 equivalent tokens, not just STX
- Create batch operations for multiple escrows
- Add filtering and search capabilities (by buyer, seller, status, date range)
- Implement escrow insurance or guarantee mechanisms
- Add milestone-based payments for complex projects
- Create escrow marketplace to connect buyers and sellers

## Testing Notes
- Tested using Clarinet console with multiple simulated principals
- Successfully created escrows with various amounts (1 STX, 10 STX, 100 STX equivalents)
- Verified escrow IDs increment sequentially starting from u1
- Confirmed zero-amount escrow creation fails with ERR-INVALID-AMOUNT (u404)
- Tested successful fund release to seller and verified status changed to COMPLETED (u2)
- Tested successful refund to buyer and verified status changed to REFUNDED (u3)
- Attempted to release funds twice on same escrow - second attempt correctly failed with ERR-NOT-PENDING (u402)
- Attempted to refund after release - correctly failed with ERR-NOT-PENDING (u402)
- Tested non-buyer attempting to release funds - correctly failed with ERR-NOT-BUYER (u400)
- Tested non-buyer attempting to refund - correctly failed with ERR-NOT-BUYER (u400)
- Created multiple concurrent escrows between different buyer-seller pairs
- Verified get-escrow returns correct details including all fields (buyer, seller, amount, status, created-at)
- Confirmed get-escrow-count accurately tracks total escrows created
- Tested escrow between same buyer and different sellers works independently
- Verified contract holds custody of STX correctly using as-contract pattern
- Confirmed status constants work correctly (STATUS-PENDING=u1, STATUS-COMPLETED=u2, STATUS-REFUNDED=u3)
- Validated created-at field correctly stores block height at escrow creation
- Tested edge case: creating escrow at specific block heights