import { useContractKit } from "@celo-tools/use-contractkit";
import React, { useEffect, useState } from "react";
import { toast } from "react-toastify";
import PropTypes from "prop-types";
import AddNfts from "./Add";
import SellNft from "./Sell";
import Nft from "./Card";
import Loader from "../../ui/Loader";
import { NotificationSuccess, NotificationError } from "../../ui/Notifications";
import {
  getActiveItem,
  mintNft,
  listNft,
  getOwnersNfts,
} from "../../../utils/minter";
import { Row } from "react-bootstrap";
import { x } from "../../../context";

const NftList = ({ minterContract, name }) => {
  /* performActions : used to run smart contract interactions in order
   *  address : fetch the address of the connected wallet
   */
  const { performActions, address } = useContractKit();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null)
  const [myNFT, setMyNFT] = useState([])
  const [myLimit, setMyLimit] = useState(0)
  const { content, nfts, setNfts, activeNfts, setActiveNfts } =
    React.useContext(x);

  const handleResetAsset = () => getAssets(); // reset when update or delete NFT
  

  // function to get NFTs
  const getAssets = async () => {
    try {
      setLoading(true);
      
      // fetch all nfts from the smart contract
      if (content === "collection") {
        
        // const _nfts = await getNfts(minterContract);
        const _nfts = await getOwnersNfts(minterContract, address)
        setNfts(_nfts);

      } else if (content === "marketplace") {
        const _activeNfts = await getActiveItem(minterContract);
        setActiveNfts(_activeNfts);
      }
      if (!nfts || !activeNfts) return;
    } catch (error) {
      toast(<NotificationError text={error} />);
      setError(error)
      console.log( error );
    } finally {
      setLoading(false);
    }
  };


useEffect(() =>{
  const getMyNFTs = nfts.filter(nft => nft.owner == address)
  setMyNFT(getMyNFTs)
  console.log(getMyNFTs, address, nfts)
}, [address, nfts])
  


  


  // function when click on the sell button, check owner, exist,...
  const sellNft = async (data) => {
    try {
      if (nfts[data.tokenId] === undefined) {
        toast(<NotificationError text="NFT does not exist." />);
      } else if (nfts[data.tokenId].owner !== address) {
        toast(<NotificationError text="You are not the owner of the NFT." />);
      } else if (nfts[data.tokenId].price !== undefined) {
        toast(<NotificationError text="NFT already in marketplace." />);
      } else {
        setLoading(true);

        // create an nft functionality
        await listNft(minterContract, performActions, data);
        getAssets();
      }
    } catch (error) {
      console.log({ error });
      toast(<NotificationError text="Failed to mint an NFT." />);
    } finally {
      setLoading(false);
    }
  };

  // function when click on the create button
  const addNft = async (data) => {
    
    try {
      setLoading(true);

      // create an nft functionality
      await mintNft(minterContract, performActions, data);
      toast(<NotificationSuccess text="Adding to NFT list...." />);
      getAssets();
    } catch (error) {
      console.log({ error });
      toast(<NotificationError text="Failed to mint an NFT." />);
    } finally {
      setLoading(false);
    }
  };


  // useEffect that get the asset when something change
  useEffect(() => {
    try {
      if (address && minterContract) {
        getAssets();
      }
    } catch (error) {
      console.log({ error });
    }
  }, [minterContract, address, content,]);


  if (address) {
    return (
      <>
        {!loading ? (
          <>
            <div className="d-flex justify-content-between align-items-center mb-4">
              <h1 className="fs-4 fw-bold mb-0">{name}</h1>
              
            
              {content === "collection" ? (
                <AddNfts save={addNft} address={address} />
              ) : (
                <SellNft save={sellNft} />
              )}
            </div>
            
            <Row xs={1} sm={2} lg={3} className="g-3  mb-5 g-xl-4 g-xxl-5">
              {/* display all NFTs */}
              {content === "collection"
                ? myNFT.map((_nft) => (
                    <Nft
                      key={_nft.index}
                      nft={{
                        ..._nft,
                      }}
                      contract={minterContract}
                      rerestAsset={handleResetAsset}
                    />
                  ))
                : activeNfts.map((_nft) => {
                    if (
                      _nft.seller !==
                      "0x0000000000000000000000000000000000000000"
                    ) {
                      return (
                        <Nft
                          key={_nft.index}
                          nft={{
                            ..._nft,
                          }}
                          contract={minterContract}
                          rerestAsset={handleResetAsset}
                        />
                      );
                    }
                  })}
            </Row>
          </>
        ) : (
          <Loader />
        )}
      </>
    );
  }
  return null;
};

NftList.propTypes = {
  // props passed into this component
  minterContract: PropTypes.instanceOf(Object),
  updateBalance: PropTypes.func.isRequired,
};

NftList.defaultProps = {
  minterContract: null,
};

export default NftList;
