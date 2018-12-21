pragma solidity ^0.5.0;

import './ERC721Token.sol';

contract assetTracker is ERC721Token {
    
    // Create owner variable
    address private owner;
    
    // Constructor for initializing the contract and setting the owner
    constructor() public {
        owner == msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    // Set a counter to track total amount of tokens/items in existence
    uint256 private tokenCounter = 0;
    
    // Create a struct to allow item creation/registration
    struct Item {
        string identifier;
        string code;
        string description;
    }
    
    // Map a tokenId to an Item
    mapping (uint256 => Item) tokenIdtoItem;
    // Map a hash of item details to a bool that allows us to check if the item already exists
    mapping (bytes32 => bool) itemExists;
    // Map whether an item (tokenId) is on sale (0 value means no);
    mapping (uint256 => uint256) itemsOnSale;
    // Map tokenId to owner that has reserved rights to buy
    mapping (uint256 => address) reservedBy;
    
    modifier onlyItemOwner(uint256 _tokenId) {
        require(msg.sender == tokenToOwner[_tokenId], "Only the owner of the token can do this");
        _;
    }
    
    event ItemRegistered(uint256 indexed _tokenId, string indexed _identifier, string indexed _code);
    
    // Register an item using an identifier type (no., PID, barcode, etc.), the actual identifier/code, and a description
    function registerItem(string memory _identifier, string memory _code, string memory _description) public {
        // Make sure the item does not already exists/is not already registered
        require(!itemExists[keccak256(abi.encodePacked(_identifier,_code))]);
        // Create an Item struct in memory that stores the item data
        Item memory newItem;
        newItem.identifier = _identifier;
        newItem.code = _code;
        newItem.description = _description;
        // Map hash of item details to true/bring item into existence
        itemExists[keccak256(abi.encodePacked(_identifier,_code))] = true;
        // Increment tokenCounter;
        tokenCounter ++;
        // Set unique tokenId using tokenCounter
        uint256 tokenId = tokenCounter;
        // Map the tokenId to the item
        tokenIdtoItem[tokenId] = newItem;
        // Mint the token using ERC721 mint method, which checks if the token is already owned and if not sets it to the new owner
        ERC721Token.mint(tokenId);
        //Emit event
        emit ItemRegistered(tokenId, _identifier, _code);
    }
    
    // Get item details by providing a tokenId
    function getItemByToken(uint256 _tokenId) public view returns (string memory identifier, string memory code, string memory description) {
        Item memory returnItem = tokenIdtoItem[_tokenId];
        return(returnItem.identifier,returnItem.code,returnItem.description);
    }
    
    // Check if item already exists
    function doesItemExist(string memory _identifier, string memory _code) public view returns (bool) {
        return itemExists[keccak256(abi.encodePacked(_identifier,_code))];
    }
    
    // Allow the owner of an item to put it on sale
    function putOnSale(uint256 _tokenId, uint256 _price) public onlyItemOwner(_tokenId) {
        itemsOnSale[_tokenId] = _price;
    }

    // Allow any user to see if an item is on sale
    function isOnSale(uint256 _tokenId) public view returns(bool _onSale, uint256 _price) {
        if(itemsOnSale[_tokenId] == 0) {
            return(false, 0);
        }
        else {
            return(true, itemsOnSale[_tokenId]);
        }
    }
    
    // Allow the owner of an item to limit buy option to somebody that has reserved the right
    function setReserved(uint256 _tokenId, address _reservedBuyer) public onlyItemOwner(_tokenId) {
        reservedBy[_tokenId] = _reservedBuyer;
    }
    
    function getReserved(uint256 _tokenId) public view returns(address) {
        return reservedBy[_tokenId];
    }
    
    // Allow somebody to buy an item if it is on sale
    function buyItem(uint256 _tokenId) public payable {
        // Require that the item is on sale, that the msg.value send is higher than the price, and that there are no reservation or that the msg.sender has the reservation
        require(itemsOnSale[_tokenId] > 0 && msg.value >= itemsOnSale[_tokenId] && (reservedBy[_tokenId] == msg.sender || reservedBy[_tokenId] == address(0)), "make sure that the item is on sale, the value you send is higher than the selling price, and that you are allowed to buy.");
        uint256 salePrice = itemsOnSale[_tokenId];
        // We need to convert address to address payabale of the owner of the token
        address payable seller = address(uint160(this.ownerOf(_tokenId)));
        itemsOnSale[_tokenId] == 0;
        // Clear reservation
        reservedBy[_tokenId] = address(0);
        // Transfer token
        transferFromHelper(seller, msg.sender, _tokenId);
        // Transfer money to seller
        seller.transfer(salePrice);
        // Return change
        msg.sender.transfer(msg.value - salePrice);
    }
    
    // Allow the owner of an item to burn it out of existence
    function burnItem(uint256 _tokenId) public onlyItemOwner(_tokenId) {
        Item memory ogItem = tokenIdtoItem[_tokenId];
        // Delete item from existence
        itemExists[keccak256(abi.encodePacked(ogItem.identifier,ogItem.code))] = false;
        // Create an empty Item to replace the struct
        Item memory burnedItem;
        burnedItem.identifier = "";
        burnedItem.code = "";
        burnedItem.description = "";
        // Delete the tokenId to item reference by replacing it with the burnItem struct
        tokenIdtoItem[_tokenId] = burnedItem;
        // Take item of sale if on sale
        itemsOnSale[_tokenId] = 0;
        // Decrease tokenCounter by 1
        tokenCounter --;
        // Delete token to owner reference
        tokenToOwner[_tokenId] = address(0);
        // Lower token balance of owner
        ownerToBalance[msg.sender] --;
        // Clear approvals regarding the tokenId
        tokenToApproved[_tokenId] = address(0);
        // Clear reservation
        reservedBy[_tokenId] = address(0);
    }
    
    function killContract(uint _sure) public onlyOwner {
        require(_sure == 1, "_sure needs to be 1.");
        selfdestruct(msg.sender);
    } 
    
    
}