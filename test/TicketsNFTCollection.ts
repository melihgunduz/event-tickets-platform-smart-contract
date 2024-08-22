import { loadFixture } from '@nomicfoundation/hardhat-toolbox-viem/network-helpers';
import { expect } from 'chai';
import hre, { ignition } from 'hardhat';
import { getAddress, parseEther } from 'viem';
import TicketsNFTCollectionModule from '../ignition/modules/TicketsNFTCollection';
import type { WalletClient } from '@nomicfoundation/hardhat-viem/src/types';

describe('TicketsNFTCollection', function() {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployNextTicketCollection() {
    const { ticketsNFTCollection } = await ignition.deploy(TicketsNFTCollectionModule);

    // Contracts are deployed using the first signer/account by default
    const [owner, secondAcc, thirdAcc, fourthAcc] = await hre.viem.getWalletClients();

    const publicClient = await hre.viem.getPublicClient();


    const mintNFT = async (executer: WalletClient, to: string, uri: string) => {
      const { request } = await publicClient.simulateContract({
        address: getAddress(ticketsNFTCollection.address),
        abi: ticketsNFTCollection.abi,
        functionName: '_mintNFT',
        account: getAddress(executer.account.address),
        args: [getAddress(to), uri],
        value: parseEther('0.0005'),
      });
      await executer.writeContract(request);
    };

    const safeMintNFT = async (executer: WalletClient, to: string, uri: string) => {
      const { request } = await publicClient.simulateContract({
        address: getAddress(ticketsNFTCollection.address),
        abi: ticketsNFTCollection.abi,
        functionName: '_safeMintNFT',
        account: getAddress(executer.account.address),
        args: [getAddress(to), uri],
      });
      await executer.writeContract(request);
    };

    const transferNFT = async (executer: WalletClient, from: string, to: string, userListPrice: string, tokenId: bigint) => {
      const { request } = await publicClient.simulateContract({
        address: getAddress(ticketsNFTCollection.address),
        abi: ticketsNFTCollection.abi,
        functionName: '_transferNFT',
        account: getAddress(executer.account.address),
        args: [getAddress(from), getAddress(to), parseEther(userListPrice), tokenId],
        value: parseEther(userListPrice),
      });
      await executer.writeContract(request);
    };

    const listNFT = async (executer: WalletClient, from: string, tokenId: string, userListPrice: string) => {
      const { request } = await publicClient.simulateContract({
        address: getAddress(ticketsNFTCollection.address),
        abi: ticketsNFTCollection.abi,
        functionName: '_listToken',
        account: getAddress(executer.account.address),
        args: [getAddress(from), BigInt(tokenId), parseEther(userListPrice)],
      });
      await executer.writeContract(request);
    };

    return {
      owner,
      secondAcc,
      thirdAcc,
      fourthAcc,
      ticketsNFTCollection,
      publicClient,
      mintNFT,
      safeMintNFT,
      transferNFT,
      listNFT,
    };
  }

  describe('Deployment', function() {
    it('Should set the right transfer fee rate', async function() {
      const { ticketsNFTCollection } = await loadFixture(deployNextTicketCollection);

      expect(await ticketsNFTCollection.read.transferFeeRate()).to.equal(8);
    });

    it('Should set the right list price', async function() {
      const { ticketsNFTCollection } = await loadFixture(deployNextTicketCollection);

      expect(await ticketsNFTCollection.read.listPrice()).to.be.equal(parseEther('0.0005'));
    });

    it('Should set the right owner', async function() {
      const { ticketsNFTCollection, owner } = await loadFixture(deployNextTicketCollection);

      expect(await ticketsNFTCollection.read.owner()).to.equal(
        getAddress(owner.account.address),
      );
    });

  });

  describe('Owner functions', function() {
    it('Should pause contract as owner', async function() {
      const { ticketsNFTCollection, secondAcc } = await loadFixture(deployNextTicketCollection);

      try {
        await secondAcc.writeContract({
          address: getAddress(ticketsNFTCollection.address),
          abi: ticketsNFTCollection.abi,
          functionName: 'pause',
          account: getAddress(secondAcc.account.address),
          args: [],
        });
      } catch (error: any) {
        expect(error.message).include(['OwnableUnauthorizedAccount']);
        expect(await ticketsNFTCollection.read.paused()).to.be.false;
      }

      await ticketsNFTCollection.write.pause();
      expect(await ticketsNFTCollection.read.paused()).to.be.true;

    });

  });


  describe('Minting', async function() {
    it('Should mint an NFT as second user', async function() {
      const { ticketsNFTCollection, secondAcc, mintNFT } = await loadFixture(deployNextTicketCollection);
      const secondAccAddress = getAddress(secondAcc.account.address);
      await mintNFT(secondAcc, secondAccAddress, '{desc:test, model:"2024"}');
      await mintNFT(secondAcc, secondAccAddress, '{desc:test, model:"2024"}');
      await mintNFT(secondAcc, secondAccAddress, '{desc:test, model:"2024"}');

      const ticketBalance = await ticketsNFTCollection.read.balanceOf([secondAccAddress]);

      expect(ticketBalance.toString()).to.equal('3');
    });

    it('Should transfer NFT between second user and third user', async function() {
      const {
        ticketsNFTCollection,
        secondAcc,
        thirdAcc,
        mintNFT,
        transferNFT,
      } = await loadFixture(deployNextTicketCollection);

      const secondAccAddress = getAddress(secondAcc.account.address);
      const thirdAccAddress = getAddress(thirdAcc.account.address);

      await mintNFT(secondAcc, secondAccAddress, '{desc:test, model:"2024"}');
      await transferNFT(secondAcc, secondAccAddress, thirdAccAddress, '1', BigInt(0));

      const ticketBalanceOfSecondUser = await ticketsNFTCollection.read.balanceOf([secondAccAddress]);
      const ticketBalanceOfThirdUser = await ticketsNFTCollection.read.balanceOf([thirdAccAddress]);

      expect(ticketBalanceOfSecondUser.toString()).to.equal('0');
      expect(ticketBalanceOfThirdUser.toString()).to.equal('1');
    });

    describe('Get user tokens', async function() {
      it('Should get user tokens', async function() {
        const { ticketsNFTCollection, owner, safeMintNFT } = await loadFixture(deployNextTicketCollection);
        await safeMintNFT(owner, owner.account.address, 'Test safe minting');
        await safeMintNFT(owner, owner.account.address, 'Test safe minting 2');
        const tokens = await ticketsNFTCollection.read._getAllTokensOfUser([owner.account.address]);

        expect(tokens.length).to.equal(2);
        expect(tokens[0].tokenId.toString()).to.equal('0');
      });
    });

    describe('Safe Minting', async function() {
      it('Should reverted with authorization error', async function() {
        const { secondAcc, safeMintNFT } = await loadFixture(deployNextTicketCollection);
        try {
          await safeMintNFT(secondAcc, secondAcc.account.address, 'Test safe minting without owner account');
        } catch (error: any) {
          expect(error.message).include(['OwnableUnauthorizedAccount']);
        }
      });

      it('Should mint for contract owner', async function() {
        const { ticketsNFTCollection, owner, safeMintNFT } = await loadFixture(deployNextTicketCollection);
        await safeMintNFT(owner, owner.account.address, 'Test safe minting');
        const tokenBalance = await ticketsNFTCollection.read.balanceOf([owner.account.address]);

        expect(tokenBalance.toString()).to.equal('1');
      });

    });

  });

  describe('Listing', async function() {
    it('Should list an NFT as second user', async function() {
      const { ticketsNFTCollection, secondAcc, mintNFT, listNFT } = await loadFixture(deployNextTicketCollection);
      const secondAccAddress = getAddress(secondAcc.account.address);
      await mintNFT(secondAcc, secondAccAddress, '{desc:test, model:"2024"}');
      await listNFT(secondAcc, secondAccAddress, '0', '1');

      const listedNFTs = await ticketsNFTCollection.read._getAllListings();

      expect(listedNFTs.length).to.equal(1);
    });

  });

});
