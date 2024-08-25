# Event Tickets NFT Platform Smart Contract

This project is a smart contract for an event ticket marketplace on the Scroll Blockchain. The platform allows users to
buy tickets for various events securely and enjoy them. Users can also sell their tickets directly to others through a
peer-to-peer (P2P) system, ensuring a decentralized and trustworthy experience. The contract manages the entire process,
from ticket issuance and ownership transfer to resale, ensuring transparency and reducing fraud. By leveraging
blockchain technology, this project aims to create a seamless, efficient, and secure marketplace for event tickets,
giving users full control over their purchases and sales.

### Future Ideas

* Auction system for P2P sales.
* Large scale usable tickets.

### Vision

Our vision is to revolutionize the event experience by making it easier for fans to access and share event tickets
securely. By creating a decentralized marketplace, we aim to eliminate fraud and provide a seamless, trustworthy way for
people to buy, sell, and trade tickets. This project will empower fans to build real communities around their favorite
events, fostering stronger connections and enhancing the overall event experience. We envision a world where accessing
events is simple, secure, and community-driven, bringing people together through their shared passions.

### Development Plan

1. Smart Contract Development

* Define Variables:
    * ticketId for unique ticket identification.
    * buyer and seller to manage ticket ownership.
    * price for ticket cost.
* Core Functions:
    * Publish ticket
    * buyTicket to purchase a ticket from the event organizer.
      ** sellTicket for P2P resale between users.
      ** transferOwnership to update ticket ownership upon sale.

2. Manual Testing in Remix

* Deploy and test each smart contract function in Remix.
* Ensure all functions work as intended, including event creation, ticket sales, and transfers.

4. Automated Testing in Hardhat

* Use the viem library to write and run automated tests in the Hardhat environment.
* Focus on edge cases, security vulnerabilities, and the correct functioning of the contract under various scenarios.

5. Deployment
* Deploy the smart contract on the Scroll Blockchain.

### Track contract with:
* Marketplace: https://sepolia.scrollscan.com/address/0xd2b084c6c21d3508ca3b518e25749a7145094d47

***
Run test commands with

```shell
npx hardhat test
```
