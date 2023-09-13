import React from "react";
import PropTypes from "prop-types";
import { Card, Col, Badge, Stack, Row } from "react-bootstrap";
import { truncateAddress } from "../../../utils";
import Identicon from "../../ui/Identicon";
import { x } from "../../../context";
import { updateNft, removeNft, buyNft, } from "../../../utils/minter";
import { useContractKit } from "@celo-tools/use-contractkit";
import Web3 from "web3";

const web3 = new Web3();

const NftCard = ({ nft, contract, rerestAsset }) => {
  const { image, description, owner, name, index, attributes, price, seller } =
    nft;
  const { content } = React.useContext(x);

  let _price = "";
  if (price) {
    _price = price.toString();
  }

  const { performActions, address } = useContractKit();

  const [show, setShow] = React.useState(false);

  const handleClose = () => setShow(false);
  const handleShow = () => {
    if (seller === address && content === "marketplace") {
      setShow(true);
    }
  };

  const handleUpdate = async (data) => {
    try {
      await updateNft(contract, performActions, index, data);
      rerestAsset();
    } catch (error) {
      console.log(error);
    }
  };

  const handleRemove = async () => {
    try {
      await removeNft(contract, performActions, index);
      rerestAsset();
    } catch (error) {
      console.log(error);
    }
  };

  const handleBuy = async () => {
    try {
      await buyNft(contract, performActions, index, seller, price);
    } catch (error) {
      console.log(error);
    }
  };

  return (
    <Col key={index}>
      <Card className=" h-100">
        <Card.Header>
          <Stack direction="horizontal" gap={2}>
            {content === "collection" ? (
              <>
                <span className="font-monospace text-secondary">
                  Owned by
                  {owner === address ? ` You` : ` ${truncateAddress(owner)}`}
                </span>
                <a
                  href={`https://alfajores-blockscout.celo-testnet.org/address/${owner}/transactions`}
                  target="_blank"
                  rel="noreferrer"
                >
                  <Identicon address={owner} size={28} />
                </a>
              </>
            ) : (
              <>
                <span className="font-monospace text-secondary">
                  Own by
                  {seller === address ? ` You` : ` ${truncateAddress(seller)}`}
                </span>
                <a
                  href={`https://alfajores-blockscout.celo-testnet.org/address/${seller}/transactions`}
                  target="_blank"
                  rel="noreferrer"
                >
                  <Identicon address={seller} size={28} />
                </a>
              </>
            )}

            <Badge bg="secondary" className="ms-auto">
              {index} ID
            </Badge>
          </Stack>
        </Card.Header>

        <div className="ratio ratio-4x3 ">
          <img
            src={image}
            alt={description}
            style={{ objectFit: "cover" }}
            onClick={handleShow}
          />
        </div>

        <Card.Body className="d-flex flex-column text-center ">
          <Card.Title onClick={handleShow}>{name}</Card.Title>
          <Card.Text className="flex-grow-1" onClick={handleShow}>
            {description}
          </Card.Text>

          {content === "marketplace" && (
            <div className="d-grid gap-2 mt-1 mb-3">
              <button
                className="btn btn-lg btn-outline-dark buyBtn fs-6 p-3"
                onClick={handleBuy}
              >
                {/* buy for {parseFloat(price * 10e-19)} CELO  */}
                buy for {parseFloat(web3.utils.fromWei(_price, "ether"))} CELO
              </button>
            </div>
          )}

          <div>
            <Row className="mt-2 row">
              {attributes.map((attribute, key) => (
                <Col key={key} className="col-12 my-1 ">
                  <div className="border rounded bg-light">
                    <div className="text-dark fw-lighter small text-capitalize">
                      {attribute.trait_type}
                    </div>
                    <div className="text-secondary text-capitalize font-monospace">
                      {attribute.value}
                    </div>
                  </div>
                </Col>
              ))}
            </Row>
          </div>
        </Card.Body>
      </Card>
    </Col>
  );
};

NftCard.propTypes = {
  // props passed into this component
  nft: PropTypes.instanceOf(Object).isRequired,
  contract: PropTypes.instanceOf(Object).isRequired,
};

export default NftCard;
