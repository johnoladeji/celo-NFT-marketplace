import axios from "axios";
import { Web3Storage } from "web3.storage/dist/bundle.esm.min.js";
import MyNFTContractAddress from "../contracts/MyNFT-address.json";
import Web3 from "web3";
import {
  NotificationSuccess,
  NotificationError,
} from "../components/ui/Notifications";
import React from "react";
import { toast } from "react-toastify";

const web3 = new Web3();

// initialize IPFS
const client = new Web3Storage({
  token: process.env.REACT_APP_STORAGE_API_KEY,
});

const formatName = (name) => {
  // replace all spaces with %20
  return encodeURI(name);
};

// object to convert to file
const convertObjectToFile = (data) => {
  const blob = new Blob([JSON.stringify(data)], { type: "application/json" });
  const files = [new File([blob], `${data.name}.json`)];
  return files;
};

// mint an NFT
export const mintNft = async (
  minterContract,
  performActions,
  { name, description, ipfsImage, ownerAddress, attributes }
) => {
  
  await performActions(async (kit) => {
    if (!name || !description || !ipfsImage) return;
    const { defaultAccount } = kit;

    const data = {
      name,
      description,
      image: ipfsImage,
      owner: defaultAccount,
      attributes,
    };

    try {
      const limit = await minterContract.methods.getMinterLimit().call()
      if(limit >= 2) {
        toast(<NotificationSuccess text="You have exceeded minting limit" />);
      }
      
      // trim any extra whitespaces from the name and
      // replace the whitespace between the name with %20
      const fileName = formatName(name);

      //  bundle nft metadata into a file
      const files = convertObjectToFile(data);

      // save NFT metadata to web3 storage
      const cid = await client.put(files);

      // IPFS url for uploaded metadata
      const url = `https://${cid}.ipfs.w3s.link/${fileName}.json`;

      // mint the NFT and save the IPFS url to the blockchain
      return await minterContract.methods
        .mintNft(ownerAddress, url)
        .send({ from: defaultAccount });
    } catch (error) {
      console.log("Error uploading file: ", error);
    }
  });
};

// list an NFT
export const listNft = async (
  minterContract,
  performActions,
  { tokenId, price }
) => {
  await performActions(async (kit) => {
    const { defaultAccount } = kit;

    try {
      await minterContract.methods
        .listNft(tokenId, web3.utils.toWei(price))
        .send({ from: defaultAccount });
      toast(<NotificationSuccess text="List NFT Succesfully." />);
    } catch (error) {
      console.log(error);
    }
  });
};



// buy an NFT
export const buyNft = async (
  minterContract,
  performActions,
  tokenId,
  seller,
  price
) => {
  await performActions(async (kit) => {
    const { defaultAccount } = kit;

    if (seller === kit.defaultAccount) {
      toast(<NotificationError text="You can not buy your own NFT." />);
    } else {
      try {
        await minterContract.methods
          .buyNft(tokenId)
          .send({ from: defaultAccount, value: price });
        toast(<NotificationSuccess text="Bought NFT Succesfully." />);
      } catch (error) {
        console.log(error);
      }
    }
  });
};

// update an NFT price
export const updateNft = async (
  minterContract,
  performActions,
  tokenId,
  { newPrice }
) => {
  await performActions(async (kit) => {
    try {
      await minterContract.methods
        .updateListing(tokenId, web3.utils.toWei(newPrice))
        .send({ from: kit.defaultAccount });
      toast(<NotificationSuccess text="Update NFT Succesfully." />);
    } catch (error) {
      console.log(error);
    }
  });
};

// remove an NFT from marketplace
export const removeNft = async (minterContract, performActions, tokenId) => {
  await performActions(async (kit) => {
    try {
      await minterContract.methods
        .cancelListing(tokenId)
        .send({ from: kit.defaultAccount });
      toast(<NotificationSuccess text="Remove NFT Succesfully." />);
    } catch (error) {
      console.log(error);
    }
  });
};

// function to upload a file to IPFS via web3.storage
export const uploadFileToWebStorage = async (e) => {
  // Construct with token and endpoint
  const client = new Web3Storage({
    token: process.env.REACT_APP_STORAGE_API_KEY,
  });
  const files = e.target.files;
  const file = files[0];
  const fileName = file.name;
  const imageName = formatName(fileName);
  const cid = await client.put(files);
  return `https://${cid}.ipfs.w3s.link/${imageName}`;
};

// fetch all NFTs on the smart contract
export const getNfts = async (minterContract) => {
  try {
    const nfts = [];
    const nftsLength = await minterContract.methods.totalSupply().call();
    for (let i = 0; i < Number(nftsLength); i++) {
      const nft = new Promise(async (resolve) => {
        const res = await minterContract.methods.tokenURI(i).call();
        const meta = await fetchNftMeta(res);
        const owner = await fetchNftOwner(minterContract, i);
        resolve({
          index: i,
          owner,
          name: meta.data.name,
          image: meta.data.image,
          description: meta.data.description,
          attributes: meta.data.attributes,
        });
      });
      nfts.push(nft);
    }
    return Promise.all(nfts);
  } catch (e) {
    console.log({ e });
  }
};


export const getOwnersNfts = async (minterContract, address) => {
  try {
    const nfts = [];
    const nftsLength = await minterContract.methods.totalSupply().call();
    
    for (let i = 0; i < Number(nftsLength); i++) {
      
      const nft = new Promise(async (resolve,reject) => {
        const res = await minterContract.methods.tokenURI(i).call();
        const meta = await fetchNftMeta(res);
        const owner = await fetchNftOwner(minterContract, i);
          resolve({
            index: i,
            owner,
            name: meta.data.name,
            image: meta.data.image,
            description: meta.data.description,
            attributes: meta.data.attributes,
          });
            
      });
      nfts.push(nft);
    }
    return Promise.all(nfts);
  } catch (e) {
    console.log({ e });
  }
};




// fetch all listed NFTs on the smart contract
export const getActiveItem = async (minterContract) => {
  const activeNfts = [];
  const nftsLength = await minterContract.methods.totalSupply().call();

  for (let i = 0; i < Number(nftsLength); i++) {
    const nft = new Promise(async (resolve, reject) => {
      try {
        const res = await minterContract.methods.getActiveItem(i).call();
        const meta = await fetchNftMeta(res.url);

        if (meta != null) {
          resolve({
            index: i,
            seller: res.seller,
            price: res.price,
            image: meta.data.image,
            name: meta.data.name,
            description: meta.data.description,
            attributes: meta.data.attributes,
          });
        } else {
          resolve({
            index: i,
            seller: "0x0000000000000000000000000000000000000000",
            price: "",
            image: "",
            name: "",
            description: "",
            attributes: [{}, {}, {}],
          });
        }
      } catch (e) {
        reject(e);
      }
    });

    try {
      const resolvedNft = await nft;
      activeNfts.push(resolvedNft);
    } catch (e) {
      console.log({ e });
    }
  }

  return activeNfts;
};

// get the metedata for an NFT from IPFS
export const fetchNftMeta = async (ipfsUrl) => {
  try {
    if (!ipfsUrl) return null;
    const meta = await axios.get(ipfsUrl);
    return meta;
  } catch (e) {
    console.log({ e });
  }
};

// get the owner address of an NFT
export const fetchNftOwner = async (minterContract, index) => {
  try {
    return await minterContract.methods.ownerOf(index).call();
  } catch (e) {
    console.log({ e });
  }
};
