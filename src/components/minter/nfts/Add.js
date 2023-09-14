/* eslint-disable react/jsx-filename-extension */
import React, { useState } from "react";
import PropTypes from "prop-types";
import { Button, Modal, Form, FloatingLabel } from "react-bootstrap";
import { uploadFileToWebStorage } from "../../../utils/minter";

// basic attributes that can be added to NFT
const STYLES = [
  "Impressionism",
  "Cubism",
  "Surrealism",
  "Pop",
  "Realism",
  "Fauvism"
];
const EDITION = [
  "Open Edition",
  "Collectors Edition",
  "Special Release",
  "Unique Variant",
  "Exclusive Edition",
];
const THEMES = ["Pop Cultue and Icon", "Emotional Expression", "Abstract Geometry", "Natue and Botanicals"];

const AddNfts = ({ save, address }) => {
  const [name, setName] = useState("");
  const [ipfsImage, setIpfsImage] = useState("");
  const [description, setDescription] = useState("");

  //store attributes of an NFT
  const [attributes, setAttributes] = useState([]);
  const [show, setShow] = useState(false);

  // check if all form data has been filled
  const isFormFilled = () =>
    name && ipfsImage && description && attributes.length > 2;

  // close the popup modal
  const handleClose = () => {
    setShow(false);
    setAttributes([]);
  };

  // display the popup modal
  const handleShow = () => setShow(true);

  // add an attribute to an NFT
  const setAttributesFunc = (e, trait_type) => {
    const { value } = e.target;
    const attributeObject = {
      trait_type,
      value,
    };
    const arr = attributes;

    // check if attribute already exists
    const index = arr.findIndex((el) => el.trait_type === trait_type);

    if (index >= 0) {
      // update the existing attribute
      arr[index] = {
        trait_type,
        value,
      };
      setAttributes(arr);
      return;
    }

    // add a new attribute
    setAttributes((oldArray) => [...oldArray, attributeObject]);
  };

  return (
    <>
      <Button
        onClick={handleShow}
        variant="dark"
        className="rounded-pill py-2 d-flex justify-content-center "
        style={{ width: "130px" }}
      >
        <i className="bi bi-plus"></i> <span style={{height: "10px"}}>Mint NFT</span>
      </Button>

      {/* Modal */}
      <Modal show={show} onHide={handleClose} centered>
        <Modal.Header closeButton>
          <Modal.Title>Mint NFT</Modal.Title>
        </Modal.Header>

        <Modal.Body>
          <Form>
            <FloatingLabel
              controlId="inputLocation"
              label="Name"
              className="mb-3"
            >
              <Form.Control
                type="text"
                placeholder="Name of NFT"
                onChange={(e) => {
                  setName(e.target.value);
                }}
              />
            </FloatingLabel>

            <FloatingLabel
              controlId="inputDescription"
              label="Description"
              className="mb-3"
            >
              <Form.Control
                as="textarea"
                placeholder="description"
                style={{ height: "80px" }}
                onChange={(e) => {
                  setDescription(e.target.value);
                }}
              />
            </FloatingLabel>

            <Form.Control
              type="file"
              className={"mb-3"}
              onChange={async (e) => {
                try {
                  const imageUrl = await uploadFileToWebStorage(e);
                  if (!imageUrl) {
                    throw new Error("Failed to upload image");
                  }
                  setIpfsImage(imageUrl);
                } catch (error) {
                  // Display the error message within the modal
                  alert(`Error: ${error.message}`);
                }
              }}
              placeholder="Product name"
            />
            
            <Form.Label>
              <h5>Metadata</h5>
            </Form.Label>
            <Form.Control
              as="select"
              className={"mb-3"}
              onChange={async (e) => {
                setAttributesFunc(e, "Style");
              }}
              placeholder="styles"
            >
              <option hidden>Styles</option>
              {STYLES.map((_style) => (
                <option
                  key={`style-${_style.toLowerCase()}`}
                  value={_style.toLowerCase()}
                >
                  {_style}
                </option>
              ))}
            </Form.Control>

            <Form.Control
              as="select"
              className={"mb-3"}
              onChange={async (e) => {
                setAttributesFunc(e, "edition");
              }}
              placeholder="NFT Edition"
            >
              <option hidden>Edition</option>
              {EDITION.map((_edition) => (
                <option
                  key={`edition-${_edition.toLowerCase()}`}
                  value={_edition.toLowerCase()}
                >
                  {_edition}
                </option>
              ))}
            </Form.Control>

            <Form.Control
              as="select"
              className={"mb-3"}
              onChange={async (e) => {
                setAttributesFunc(e, "theme");
              }}
              placeholder="NFT Theme"
            >
              <option hidden>Theme</option>
              {THEMES.map((theme) => (
                <option
                  key={`theme-${theme.toLowerCase()}`}
                  value={theme.toLowerCase()}
                >
                  {theme}
                </option>
              ))}
            </Form.Control>
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
                name,
                ipfsImage,
                description,
                ownerAddress: address,
                attributes,
              });
              handleClose();
            }}
          >
            Mint NFT
          </Button>
        </Modal.Footer>
      </Modal>
    </>
  );
};

AddNfts.propTypes = {
  // props passed into this component
  save: PropTypes.func.isRequired,
  address: PropTypes.string.isRequired,
};

export default AddNfts;
