import { buildModule } from '@nomicfoundation/hardhat-ignition/modules';
import { parseEther } from 'viem';

const customListPrice = parseEther('0.0005');
const customTransferFeeRate = 8;

const TicketsNFTCollectionModule = buildModule('TicketsNFTCollectionModule', (m) => {
  const listPrice = m.getParameter('listPrice', customListPrice);

  const transferFeeRate = m.getParameter('transferFeeRate', customTransferFeeRate);

  const ticketsNFTCollection = m.contract('TicketsNFTCollection', [listPrice, transferFeeRate]);
  
  return { ticketsNFTCollection };
});

export default TicketsNFTCollectionModule;
