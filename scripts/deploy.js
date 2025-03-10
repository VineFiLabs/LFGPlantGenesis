const hre = require("hardhat");

const LFGPlantGenesisNFTABI=require("../artifacts/contracts/core/LFGPlantGenesisNFT.sol/LFGPlantGenesisNFT.json");

async function main() {
  const [owner, manager ,testuser1] = await hre.ethers.getSigners();
  console.log("owner:", owner.address);
  console.log("manager:", manager.address);
  console.log("testuser1:", testuser1.address);


  const provider = ethers.provider;
  const network = await provider.getNetwork();
  const chainId = network.chainId;
  console.log("Chain ID:", chainId);

  async function sendETH(toAddress, amountInEther) {
    const amountInWei = ethers.parseEther(amountInEther);
    const tx = {
      to: toAddress,
      value: amountInWei,
    };
    const transactionResponse = await owner.sendTransaction(tx);
    await transactionResponse.wait();
    console.log("Transfer eth success");
  }

  const fee = ethers.parseEther("0.01");

  const lfgPlantGenesisNFT = await hre.ethers.getContractFactory("LFGPlantGenesisNFT");
  const LFGPlantGenesisNFT = await lfgPlantGenesisNFT.deploy(
    owner.address,
    manager.address,
    manager.address,
    fee
  );
  const LFGPlantGenesisNFTAddress = LFGPlantGenesisNFT.target;
  console.log("LFGPlantGenesisNFT Address:", LFGPlantGenesisNFTAddress);

  const URI="https://9ddc5954c64cf31c9c8b721bae2421d3.ipfs.4everland.link/ipfs/bafybeibdcu2bpzuwqi2p35sovkpbprrhfkokzxkcqwfu5fwltq4tpycwii";
  const setURI = await LFGPlantGenesisNFT.setURI(URI);
  const setURITx = await setURI.wait();
  console.log("setURITx:", setURITx.hash);


  const mintFee = await LFGPlantGenesisNFT.fee();
  console.log("mintFee:", mintFee);

  const ownerBeforeBalance = await provider.getBalance(manager.address);
  console.log("ownerBeforeBalance:", ownerBeforeBalance);

  const UserLFG = new ethers.Contract(LFGPlantGenesisNFTAddress, LFGPlantGenesisNFTABI.abi, testuser1);

  const mintAmount = 3;
  const totalFee = mintFee * 3n;
  const claim = await UserLFG.claim(mintAmount, {value: totalFee});
  const claimTx = await claim.wait();
  console.log("claim Tx:", claimTx.hash);

  const ownerBeforeAfter = await provider.getBalance(manager.address);
  console.log("ownerBeforeAfter:", ownerBeforeAfter);

  const tokenURI = await LFGPlantGenesisNFT.tokenURI(0n);
  console.log("tokenURI:", tokenURI);

  const whitelistAmount = 5;

  const signHash = await UserLFG.getEncodeData(whitelistAmount);
  console.log("signHash:", signHash);

  const signature = await manager.signMessage(ethers.toBeArray(signHash));
  console.log("signature:", signature);

  const getSignatureVerify = await UserLFG.getSignatureVerify(
    signHash,
    signature
  );
  console.log("getSignatureVerify:", getSignatureVerify);

  const whitelistClaim = await UserLFG.whitelistClaim(
    signHash,
    signature,
    5
  );
  const whitelistClaimTx = await whitelistClaim.wait();
  console.log("whitelistClaim Tx:", whitelistClaimTx.hash);


}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
