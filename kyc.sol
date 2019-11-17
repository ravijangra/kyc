pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;
// Phase 2 assignment

contract kyc {

    address admin;

	/*
    Struct for a customer
    */
	struct customer {
	    string customerName;
        string customerData;
        uint upvotes;
        address bank;
        uint rating;
        string password;
	}
	
    /*
    Struct for a bank
    */
	struct bank {
	    string name;
        address ethaddress;
        string regNumber;
        uint rating;
        uint kycCount;
	}
	
	/*
	Struct for a kyc
    */
    
	struct kyc_requests {
	    string customerName;
        string customerData;
        address bank;
        bool isAllowed;
	}
	
	/*
    Mapping a customer's username to the Customer struct
    We also keep an array of all keys of the mapping to be able to loop through them when required.
     */
    mapping(string => customer) customers;
    string[] customerNames;

    /*
    Mapping a bank's address to the Bank Struct
    We also keep an array of all keys of the mapping to be able to loop through them when required.
    */
    
    mapping(address => bank) banks;
    address[] bankaddresses;
	
	/*
	Mapping a customer's KYC requests to the KYC Struct
    We also keep an array of all keys of the mapping to be able to loop through them when required.
    */
    
    mapping(string => kyc_requests) kycrequests;
    string[] customerDataList;
    
     /*
    Mapping a customer's user name with a bank's address
    This mapping is used to keep track of every upvote given by a bank to a customer
     */
    mapping(string => mapping(address => uint256)) upvotes;
    mapping(address => kyc_requests[]) bankrequests;
    mapping(string => address[]) public Bank2CustomerRatings;
    mapping(address => address[]) public Bank2BankRatings;
    
     /*
     * Constructor of the contract.
     * We save the contract's admin as the account which deployed this contract.
     */
    constructor() public {
        admin = msg.sender;
    }
	
	
	function addRequest(string memory customerName, string memory customerData) public returns(uint8){
        // Check that the user's KYC has not been done before, the Bank is a valid bank and it is allowed to perform KYC.
    
    require(kycrequests[customerData].bank == address(0), "This user already has a KYC request with same data in process.");
        if(banks[msg.sender].rating > 50) {
            
            kycrequests[customerData].customerName = customerName;
            kycrequests[customerData].customerData = customerData;
            kycrequests[customerData].bank = msg.sender;
            kycrequests[customerData].isAllowed = true;
            customerDataList.push(customerData);
            bankrequests[msg.sender].push(kycrequests[customerData]);
            return 1;
        
        }
        else {
            
            kycrequests[customerData].customerName = customerName;
            kycrequests[customerData].customerData = customerData;
            kycrequests[customerData].bank = msg.sender;
            kycrequests[customerData].isAllowed = false;
            customerDataList.push(customerData);    
            bankrequests[msg.sender].push(kycrequests[customerData]);
            return 0;   
        
        }
    
    }

	function addCustomerRatings(string memory customerName) public returns(uint){
	    bool ifNotAlreadyVoted = true;
	    for (uint8 i =0 ; i< Bank2CustomerRatings[customerName].length; i++){
	        if (Bank2CustomerRatings[customerName][i] == msg.sender) {
	            ifNotAlreadyVoted = false;
	            return 0;
	        }
	    }
        if (ifNotAlreadyVoted) {        
            uint numberOfbanks = bankaddresses.length;
            Bank2CustomerRatings[customerName].push(msg.sender);
            customers[customerName].upvotes++;
            uint numberOfVotes = Bank2CustomerRatings[customerName].length;
            customers[customerName].rating = (numberOfVotes*100)/numberOfbanks;
            return 1;
        }
        else return 0;
	    
    }
	
	function addBankRatings(address  bankAddress) public returns(uint){
	    
	    bool ifNotAlreadyVoted = true;
	    for (uint8 i =0 ; i< Bank2BankRatings[bankAddress].length; i++){
	        if (Bank2BankRatings[bankAddress][i] == msg.sender) {
	            ifNotAlreadyVoted = false;
	            return 0;
	        }
	    }
        if (ifNotAlreadyVoted) {
            
            Bank2BankRatings[bankAddress].push(msg.sender);
            uint numberOfbanks = bankaddresses.length;
            uint numberOfVotes = Bank2BankRatings[bankAddress].length;
            banks[bankAddress].rating = (numberOfVotes*100)/numberOfbanks;
        
        //update isAllowed for all kycrequests 
     
        for ( uint8 i = 0; i< customerDataList.length; i++) {
            
            if (banks[kycrequests[customers[customerDataList[i]].customerData].bank].rating > 50 ) {
                kycrequests[customers[customerDataList[i]].customerData].isAllowed = true;
                
                // update the bank requests' isAllowed for the impacted bank 
                for (uint8 j=0 ; j< bankrequests[bankAddress].length ; j++ ){
                    
                   bankrequests[bankAddress][j].isAllowed = true; 
                }
           
            }
            
        else {
            
            kycrequests[customers[customerDataList[i]].customerData].isAllowed = false;
        }
    
        }
            
            return 1;
        }
        else return 0;
    }
	
	function addCustomer(string memory customerName, string memory customerData) public returns(uint result){
    //add customer to customers list;
    require(customers[customerName].bank == address(0), "This customer is already present, please call modifyCustomer to edit the customer data");
    
    if (kycrequests[customerData].isAllowed == true) {
        
        customers[customerName].customerName = customerName;
        customers[customerName].customerData = customerData;
        customers[customerName].bank = msg.sender;
        customers[customerName].upvotes = 0;
        
        customerNames.push(customerName);
        banks[msg.sender].kycCount ++;
        return 1;
    }
    
    else {
        return 0;   
        
    }
    
    }
    
    function removeRequest(string memory customerName) public returns(uint result){
    
    // delete kycrequests[customers[customerName].customerData];

      uint8 i;
        for (i = 0; i< customerDataList.length; i++) {
            if (stringsEquals(kycrequests[customerDataList[i]].customerName,customerName)) {
                delete kycrequests[customerDataList[i]];
                for(uint j = i+1;j < customerDataList.length;j++) 
                { 
                    customerDataList[j-1] = customerDataList[j];
                }
                customerDataList.length--;
                i=1;
            }
        }
        return i; // 0 is returned if no request with the input username is found.
        
    }
    

    function removeCustomer(string memory customerName)  public returns(uint result){

        for (uint8 i = 0; i< customerNames.length; i++) {
            if (stringsEquals(customerNames[i],customerName)) {
                delete customers[customerName];
                for(uint j = i+1;j < customerNames.length;j++) 
                { 
                    customerNames[j-1] = customerNames[j];
                }
                customerNames.length--;
                return 1;
            }
        }
        return 0; 

    }
    
    function updateCustomer(string memory customerName, string memory updatedcustomerData)  public returns(uint result){
    //update customer data in customer_list;
    
      for (uint8 i = 0; i< customerNames.length; i++) {
            if (stringsEquals(customerNames[i],customerName)) {
                customers[customerName].customerData = updatedcustomerData;
                return 1;
            }
        }
        return 0; 
    
    
    }
    
    function viewCustomer(string memory customerName, string memory password)  public view returns(string memory, string memory, uint, address){

    require(stringsEquals(customers[customerName].password , password), "password not correct");
    // if (stringsEquals(customers[customerName].password , password)) {
    return (customers[customerName].customerName, customers[customerName].customerData,customers[customerName].upvotes,customers[customerName].bank);
    // }
    
    }
    
    function GetCustomerRatings(string memory customerName)  public view returns(uint){

    return (customers[customerName].rating);   
    }
    
    function GetCustomerAccessHistory(string memory customerName)  public view returns(address){

    return (customers[customerName].bank);   
    }
    
    function GetBankRatings(address bankAddress)  public view returns(uint){

    return (banks[bankAddress].rating);      
    }
    
    
    function GetBankdetails(address bankAddress)  public view returns(bank memory){

    return (banks[bankAddress]);   
    
    }
    
    function GetBankRequests(address bankAddress)  public view returns(kyc_requests[] memory){

    return bankrequests[bankAddress];   
    
    }
    
    function RemoveBank(address bankAddress) public returns(uint) {
        
        require(msg.sender == admin, "Only Admin can remove a bank");   
        // Delete all the votes casted for the bank being deleted        
        for (uint i = 0; i< bankaddresses.length; i++) {
            if (banks[bankAddress].ethaddress == bankAddress) {
                delete banks[bankAddress];
                delete bankrequests[bankAddress]; 
                delete Bank2BankRatings[bankAddress];
                
                for(uint j = i+1;j < bankaddresses.length;j++) 
                { 
                    bankaddresses[j-1] = bankaddresses[j];
                }
                bankaddresses.length--;
              //  i=1;
            }
        }
        
        // Delete the bank votes casted by the bank being deleted
        for (uint k = 0; k< bankaddresses.length; k++) {
            for (uint i = 0; i< Bank2BankRatings[bankaddresses[k]].length; i++) {
                if (Bank2BankRatings[bankaddresses[k]][i] == bankAddress) {
                     for(uint j = i+1;j < Bank2BankRatings[bankaddresses[k]].length;j++) 
                        { 
                            Bank2BankRatings[bankaddresses[k]][j-1] = Bank2BankRatings[bankaddresses[k]][j];
                        
                        }
                        Bank2BankRatings[bankaddresses[k]].length--;
                } 
            }
        }
        
        // Delete the customer votes casted by the bank being deleted
        for (uint k = 0; k< customerNames.length; k++) {
            for (uint i = 0; i< Bank2CustomerRatings[customerNames[k]].length; i++) {
                if (Bank2CustomerRatings[customerNames[k]][i] == bankAddress) {
                     for(uint j = i+1;j < Bank2CustomerRatings[customerNames[k]].length;j++) 
                        { 
                            Bank2CustomerRatings[customerNames[k]][j-1] = Bank2CustomerRatings[customerNames[k]][j];
                        
                        }
                        Bank2CustomerRatings[customerNames[k]].length--;
                } 
            }
        }
        
           
    //Update Ratings for each customers

    for (uint8 i = 0; i< customerNames.length; i++) {
        
   
        customers[customerNames[i]].rating = (Bank2CustomerRatings[customerNames[i]].length*100)/bankaddresses.length;

    }
    
    //update ratings for all banks
    
    for (uint8 i = 0; i< bankaddresses.length; i++) {
            
        banks[bankaddresses[i]].rating = (Bank2BankRatings[bankaddresses[i]].length*100)/bankaddresses.length;

    }   
    
    //update isAllowed for all kycrequests
        
    for (uint8 i = 0; i< customerDataList.length; i++) {
        
        if (banks[kycrequests[customers[customerDataList[i]].customerData].bank].rating > 50 ) {
            kycrequests[customers[customerDataList[i]].customerData].isAllowed = true;
        }
        
        else {
            
            kycrequests[customers[customerDataList[i]].customerData].isAllowed = false;
        }
    }
    }
    
    function AddBank(string memory bankName, string memory regNumber, address bankAddress)  public  returns(uint){

    // Check if the bank is not added before - DONE
    // check if the msg.sender is admin - DONE
    // update all banks ratings - DONE
    // update all customer ratings - DONE
    // update all banks requests is Allowed - DONE
   

    require(msg.sender == admin, "Only Admin can add a bank");
    require(banks[bankAddress].ethaddress == address(0), "This bank is already present");
    
    banks[bankAddress].name = bankName;
    banks[bankAddress].regNumber = regNumber;
    banks[bankAddress].ethaddress = bankAddress;
    banks[bankAddress].rating = 0;
    banks[bankAddress].kycCount = 0;
    bankaddresses.push(bankAddress);
    
    //Update Ratings for each customers
    
    for (uint8 i = 0; i< customerNames.length; i++) {
            
        customers[customerNames[i]].rating = (Bank2CustomerRatings[customerNames[i]].length*100)/bankaddresses.length;
        
    }
    
    //update ratings for all banks
    
    for (uint8 i = 0; i< bankaddresses.length; i++) {
            
       banks[bankaddresses[i]].rating = (Bank2BankRatings[bankaddresses[i]].length*100)/bankaddresses.length;
  
    }
    
     //update isAllowed for all kycrequests 
     
    for (uint8 i = 0; i< customerDataList.length; i++) {
        
        if (banks[kycrequests[customers[customerDataList[i]].customerData].bank].rating > 50 ) {
            kycrequests[customers[customerDataList[i]].customerData].isAllowed = true;
        }
        
        else {
            
            kycrequests[customers[customerDataList[i]].customerData].isAllowed = false;
        }
        
        
    }

      return 1;  
    
    }
    
    
    function SetPassword(string memory customerName, string memory password)  public  returns(bool){

      for (uint8 i = 0; i< customerNames.length; i++) {
            if (stringsEquals(customerNames[i],customerName)) {
                customers[customerName].password = password;
                return true;
            }
        }
        return false;
    }
    
    // function upvote(string memory customerName) public  returns(uint){
    // //increment votes for customer_name in customer_list and return true or false;
    
    //   for (uint8 i = 0; i< customerNames.length; i++) {
    //         if (stringsEquals(customerNames[i],customerName)) {
    //             customers[customerName].upvotes++;
    //             upvotes[customerName][msg.sender] = now;
                
    //             return 1;
    //         }
    //     }
    //     return 0; 
    
    // }
	
	
    function stringsEquals(string storage _a, string memory _b) internal view returns (bool) {
        bytes storage a = bytes(_a);
        bytes memory b = bytes(_b); 
        if (a.length != b.length)
            return false;
        // @todo unroll this loop
        for (uint i = 0; i < a.length; i ++)
        {
            if (a[i] != b[i])
                return false;
        }
        return true;
    }


}
