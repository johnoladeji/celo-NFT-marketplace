import { createContext, useState } from "react";

export const x = createContext();

export const Provider = ({ children }) => {
  // context to share global variables
  const [content, setContent] = useState("collection");
  const [nfts, setNfts] = useState([]);
  const [activeNfts, setActiveNfts] = useState([]);

  return (
    <x.Provider
      value={{ content, setContent, nfts, setNfts, activeNfts, setActiveNfts }}
    >
      {children}
    </x.Provider>
  );
};
