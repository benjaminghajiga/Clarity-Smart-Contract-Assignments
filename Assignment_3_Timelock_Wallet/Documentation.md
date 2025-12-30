# Assignment 3: Time-locked Wallet

## Student Information
- Name: Benjamin Ghajiga
- Date: 30-12-2025
- Contract Address: tx-sender

## Contract Overview
The Time-locked Wallet is a smart contract that enables users to deposit STX tokens and lock them for a specified period, measured in blocks. Funds can only be withdrawn after the lock period expires, making it ideal for implementing vesting schedules, savings plans, or self-imposed spending restrictions. Users can extend their lock periods but cannot shorten them, and multiple deposits from the same user are combined into a single balance with an updated unlock time.

## Assumptions Made
- All amounts are in micro-STX (1 STX = 1,000,000 micro-STX)
- If a user makes multiple deposits, the new deposit is added to their existing balance and the unlock height is updated to the new lock period
- Users can only extend lock periods, never shorten them
- Withdrawals are all-or-nothing (users must withdraw their entire balance at once)
- Block height is used instead of timestamps for more predictable and manipulation-resistant time locks
- Once deposited, there is no emergency withdrawal mechanism (funds are truly locked until unlock height)
- The contract holds custody of the STX tokens using the `as-contract` pattern
- Zero amount deposits are not allowed

## Design Decisions and Tradeoffs

### Decision 1: Additive deposits with unlock height update
- **What I chose:** When a user deposits while having an existing balance, the new amount is added to their balance and the unlock height is recalculated from the current block
- **Why:** This provides flexibility for users to add funds over time while maintaining a single coherent lock period. It's simpler than managing multiple separate deposits per user.
- **Tradeoff:** Users lose the original unlock height when making a new deposit - their entire balance now uses the new lock period. This could be disadvantageous if they deposit additional funds late in their original lock period. However, it simplifies the contract significantly and prevents users from managing multiple concurrent locks.

### Decision 2: All-or-nothing withdrawals
- **What I chose:** Users must withdraw their entire locked balance at once; partial withdrawals are not supported
- **Why:** Simplifies contract logic and prevents complex state management around partial balances and multiple unlock heights
- **Tradeoff:** Less flexibility for users who might want to withdraw funds gradually. However, this ensures cleaner state management and reduces gas costs. Users who need partial withdrawals can create multiple separate deposits in different accounts.

### Decision 3: Using micro-STX for amounts
- **What I chose:** All amounts are handled in micro-STX (1 STX = 1,000,000 micro-STX)
- **Why:** Matches Clarity's native STX representation and allows for precise fractional amounts
- **Tradeoff:** Users must understand the micro-STX denomination (e.g., deposit 1000000 for 1 STX). This is standard blockchain practice but can be confusing initially. DApp interfaces should handle the conversion for better UX.

### Decision 4: Block-based time locks instead of timestamps
- **What I chose:** Lock periods are specified in blocks, and unlock times are checked against block-height
- **Why:** Block height is deterministic, monotonically increasing, and cannot be manipulated by miners. It provides more reliable and predictable time locks.
- **Tradeoff:** Less intuitive for users since they need to calculate blocks (Stacks averages ~10 minutes per block). For example, 144 blocks ≈ 1 day. However, this provides better security against timing attacks and is more consistent with blockchain-native time representation.

### Decision 5: No emergency withdrawal mechanism
- **What I chose:** Once funds are deposited, they cannot be withdrawn before the unlock height under any circumstances
- **Why:** Ensures the integrity of the time lock and prevents users from circumventing their own savings/vesting commitments
- **Tradeoff:** Users have no recourse in true emergencies. This makes the contract more secure and trustworthy for vesting scenarios, but less flexible. Users should only deposit funds they're certain they won't need during the lock period.

### Decision 6: Total locked tracking
- **What I chose:** Maintain a global counter of total STX locked in the contract
- **Why:** Provides useful analytics and allows anyone to verify the contract's total holdings match on-chain balance
- **Tradeoff:** Adds small gas over