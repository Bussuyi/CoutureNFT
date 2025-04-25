# CoutureNFT

CoutureNFT is a Stacks blockchain platform that enables fashion designers to create limited edition digital fashion NFTs with physical item redemption capabilities.

## Overview

The fashion industry is rapidly embracing digital assets, but there remains a disconnect between digital ownership and physical products. CoutureNFT bridges this gap by allowing designers to create digital fashion NFTs that can be collected, traded, and ultimately redeemed for physical counterparts.

## Features

- **Designer Registration**: Fashion designers can register and get verified on the platform
- **Collection Management**: Designers can create and manage collections with customizable supply limits
- **Digital Ownership**: Users can mint and own digital fashion NFTs
- **Physical Redemption**: NFT owners can redeem their digital assets for physical fashion items
- **Secure Transfer**: NFTs can be securely transferred between users

## Smart Contract Functions

### Designer Management

- `register-designer`: Register as a fashion designer on the platform
- `verify-designer`: Admin function to verify legitimate designers
- `get-designer`: View designer information

### Collection Management

- `create-collection`: Create a new fashion collection with metadata
- `toggle-collection-status`: Activate or deactivate a collection
- `get-collection`: View collection details
- `get-collection-price`: Get the price for minting from a collection

### NFT Operations

- `mint-nft`: Mint a new fashion NFT from a collection
- `transfer-nft`: Transfer NFT ownership to another user
- `get-nft`: View NFT details
- `get-owner`: Check who owns a specific NFT
- `is-redeemed`: Check if an NFT has been redeemed for a physical item

### Redemption System

- `set-redemption-code`: Designer sets a redemption code for physical item claiming
- `redeem-nft`: NFT owner redeems their digital asset for a physical item

## Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed
- [Stacks CLI](https://github.com/blockstack/stacks.js) (optional for deployment)

### Installation

1. Clone the repository
```bash
git clone https://github.com/yourusername/couture-nft.git
cd couture-nft