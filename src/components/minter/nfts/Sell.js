/* eslint-disable react/jsx-filename-extension */
import React, { useState } from "react";
import PropTypes from "prop-types";
import { Button, Modal, Form, FloatingLabel } from "react-bootstrap";

const SellNft = ({ save }) => {
  const [tokenId, setTokenId] = useState("");
  const [price, setPrice] = useState("");
  const [show, setShow] = useState(false);

  // check if all form data has been filled
  const isFormFilled = () => tokenId && price;

  // close the popup modal
  const handleClose = () => {
    setShow(false);
  };

  // display the popup modal
  const handleShow = () => setShow(true);

  return (
    <>
      <Button
        onClick={handleShow}
        variant="dark"
        className="rounded-pill py-2 d-flex justify-content-center"
        style={{ width: "auto" }}
      >
        <i className="bi bi-plus"></i> <span>Sell Your NFT</span>
      </Button>

      {/* Modal */}
      <Modal show={show} onHide={handleClose} centered>
        <Modal.Header closeButton>
          <Modal.Title>Sell Your NFT</Modal.Title>
        </Modal.Header>

        <Modal.Body>
          <Form>
            <FloatingLabel
              controlId="tokenid"
              label="Token ID"
              className="mb-3"
            >
              <Form.Control
                type="number"
                placeholder="token id of NFT"
                onChange={(e) => {
                  setTokenId(e.target.value);
                }}
              />
            </FloatingLabel>

            <FloatingLabel controlId="price" label="Price" className="mb-3">
              <Form.Control
                type="number"
                placeholder="price of NFT"
                onChange={(e) => {
                  setPrice(e.target.value);
                }}
              />
            </FloatingLabel>
          </Form>
        </Modal.Body>

        <Modal.Footer>
          <Button variant="outline-secondary" onClick={handleClose}>
            Close
          </Button>
          <Button
            variant="dark"
            disabled={!isFormFilled()}
            onClick={() => {
              save({
                tokenId,
                price,
              });
              handleClose();
            }}
          >
            Sell Your NFT
          </Button>
        </Modal.Footer>
      </Modal>
    </>
  );
};

SellNft.propTypes = {
  // props passed into this component
  save: PropTypes.func.isRequired,
};

export default SellNft;
