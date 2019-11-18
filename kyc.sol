pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;
// Phase 2 assignment

contract Kyc {

    address admin;

    /**
    * Struct for a customer
    */
    struct Customer {
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
	struct Bank {
	    string name;
        address ethAddress;
        string regNumber;
        uint rating;
        uint kycCount;
	}

	/*
	Struct for a kyc
    */

	struct KycRequests {
	    string customerName;
        string customerData;
        address bank;
        bool isAllowed;
	}

	/*
    Mapping a customer's username to the Customer struct
    We also keep an array of all keys of the mapping to be able to loop through them when required.
     */
    mapping(string => Customer) customers;
    mapping(string => Customer) finalCustomers;
    /* customer[] public ucustomers; // array of unverified customers; */
    /* customer[] public vcustomers; // array of verified customers; */

    string[] customerNames;
    string[] finalcustomerNames;

    /*
    Mapping a bank's address to the Bank Struct
    We also keep an array of all keys of the mapping to be able to loop through them when required.
    */

    mapping(address => Bank) banks;
    address[] bankaddresses;

	/*
	Mapping a customer's KYC requests to the KYC Struct
    We also keep an array of all keys of the mapping to be able to loop through them when required.
    */

    mapping(string => KycRequests) kycrequests;
    string[] customerDataList;

     /*
    Mapping a customer's user name with a bank's address
    This mapping is used to keep track of every upvote given by a bank to a customer
     */
    //mapping(string => mapping(address => uint256)) upvotes;
    mapping(address => KycRequests[]) bankrequests;
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
        require(isBankAdded(msg.sender), "Bank is not added yet to add a KYC request");
        require(!(kycrequests[customerData].bank == msg.sender), "KYC Request for this customerName and customerData is already added by the same bank" );

        // if customer exits do not add the customer. Infact check if the KYC is completed for this customer. If the KYC is completed, then remove KYC request and upvote for this customer.

        if(!isCustomerAdded(customerName)){
          customers[customerName].customerName = customerName;
          customers[customerName].customerData = customerData;
          customers[customerName].upvotes = 0;
          customers[customerName].bank = msg.sender;
          customers[customerName].rating = 0;
          customerNames.push(customerName);
        }

        customers[customerName].bank = msg.sender;
        kycrequests[customerData].customerName = customerName;
        kycrequests[customerData].customerData = customerData;
        kycrequests[customerData].bank = msg.sender;
        customerDataList.push(customerData);
        bankrequests[msg.sender].push(kycrequests[customerData]);

        if(banks[msg.sender].rating > 50) {
            kycrequests[customerData].isAllowed = true;
            return 1;

        }
        else {
            kycrequests[customerData].isAllowed = false;
            return 0;
        }

    }

    function addCustomer(string memory customerName, string memory customerData) public returns(uint result){

        require(isBankAdded(msg.sender), "Bank is not added yet to perform this operation");
        require(finalCustomers[customerName].bank == address(0), "This customer is already present, please call modifyCustomer to edit the customer data");


        /**
        * All fot the following 3 conditions must be true for the customer to be added
        * check if the request was added by a reliable bank
        * check if the bank is allowed to add the customer
        * check if the customer's ratings is > 50
        */

        if (kycrequests[customerData].isAllowed == true && customers[customerName].rating > 50 && banks[msg.sender].rating > 50) {

            finalCustomers[customerName].customerName = customerName;
            finalCustomers[customerName].customerData = customerData;
            finalCustomers[customerName].bank = msg.sender;
            finalcustomerNames.push(customerName);
            banks[msg.sender].kycCount ++;
            //removeRequest(customerData); // removeRequest needs to be modified to take care of the customerData also

            return 1;
        }

        else {
            return 0;

        }

    }

    function removeRequest(string memory customerData) public returns(uint result){

        require(isBankAdded(msg.sender), "Bank is not added yet to perform this operation");

        // A bank should not be able to delete KYC requests for other banks
        require(kycrequests[customerData].bank == msg.sender, "Bank can not delete other banks KYC request");
        // remove corresponding element from customerDataList

            for (uint i=0; i < customerDataList.length; i++) {
                if (stringsEquals(kycrequests[customerDataList[i]].customerData,customerData)) {
                    customerDataList = removeArrIdxStrings(customerDataList, i);

                    // remove kycrequests for the customer
                    delete kycrequests[customerData];
                    return 1;
              }
          }
          return 0;

      }


    function removeCustomer(string memory customerName)  public returns(uint result){

        require(isBankAdded(msg.sender), "Bank is not added yet to perform this operation");
        require(finalCustomers[customerName].bank == msg.sender, "Bank can not delete other banks added customer");

        // remove customer from customers mapping
        delete finalCustomers[customerName];
        delete customers[customerName];

        // remove customer from customerNames array

        for (uint i=0; i < customerNames.length; i++) {
            if (stringsEquals(customerNames[i],customerName)) {
                customerNames = removeArrIdxStrings(customerNames, i);
                return 1;
            }
        }
        return 0;
    }

    function updateCustomer(string memory customerName, string memory updatedcustomerData)  public returns(uint result){

        require(isBankAdded(msg.sender), "Bank is not added yet to perform this operation");
        require(finalCustomers[customerName].bank == msg.sender, "Bank can not update other banks added customer");
        require(stringsEquals(finalCustomers[customerName].customerName, customerName), "customer is not a verified customer and not present in the final customer yet");
        for (uint8 i = 0; i< customerNames.length; i++) {
            if (stringsEquals(customerNames[i],customerName)) {

                // Delete customer from final customer list
                delete finalCustomers[customerName];

                // Delete all the votes cast for this customer
                delete Bank2CustomerRatings[customerName];

                customers[customerName].customerData = updatedcustomerData;
                customers[customerName].upvotes = 0;
                customers[customerName].rating = 0;

                return 1;
            }
        }
        return 0;
    }

    function viewCustomer(string memory customerName, string memory password)  public view returns(string memory, string memory, uint, address){
        require(isBankAdded(msg.sender), "Bank is not added yet to perform this operation");
        require(stringsEquals(customers[customerName].password , password), "Not authorised to view the customer details");
        return (customers[customerName].customerName, customers[customerName].customerData,customers[customerName].upvotes,customers[customerName].bank);

    }

	function addCustomerRatings(string memory customerName) public returns(uint){

	    require(isBankAdded(msg.sender), "Bank is not added yet to perform this operation");

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

	function addBankRatings(address  bankAddress) public returns(uint) {
        require(isBankAdded(msg.sender), "Bank is not added yet to perform this operation");
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



    function GetCustomerRatings(string memory customerName)  public view returns(uint){
        require(isBankAdded(msg.sender), "Bank is not added yet to perform this operation");

        return (customers[customerName].rating);
    }

    function GetCustomerAccessHistory(string memory customerName)  public view returns(address){
        require(isBankAdded(msg.sender), "Bank is not added yet to perform this operation");

        return (customers[customerName].bank);
    }

    function GetBankRatings(address bankAddress)  public view returns(uint){
        require(isBankAdded(msg.sender), "Bank is not added yet to perform this operation");

        return (banks[bankAddress].rating);
    }


    function GetBankdetails(address bankAddress)  public view returns(Bank memory){
        require(isBankAdded(msg.sender), "Bank is not added yet to perform this operation");

        return (banks[bankAddress]);

    }

    function GetBankRequests(address bankAddress)  public view returns(KycRequests[] memory){
        require(isBankAdded(msg.sender), "Bank is not added yet to perform this operation");

        return bankrequests[bankAddress];

    }

    function GetBankCount()  public view returns(uint256){
        require(isBankAdded(msg.sender), "Bank is not added yet to perform this operation");

        return bankaddresses.length;

    }

    function GetFInalCustomerCount()  public view returns(uint256){
        require(isBankAdded(msg.sender), "Bank is not added yet to perform this operation");

        return finalcustomerNames.length;

    }

    function Getfinalcustomers()  public view returns(string[] memory){
        require(isBankAdded(msg.sender), "Bank is not added yet to perform this operation");

        return finalcustomerNames;

    }

    function GetBankVotes(address bankAddress)  public view returns(address[] memory){
        require(isBankAdded(msg.sender), "Bank is not added yet to perform this operation");

        return Bank2BankRatings[bankAddress];

    }

    function GetCustomerVotes(string memory customerName)  public view returns(address[] memory){
        require(isBankAdded(msg.sender), "Bank is not added yet to perform this operation");

        return Bank2CustomerRatings[customerName];

    }

    function RemoveBank(address bankAddress) public returns(uint) {

        require(msg.sender == admin, "Only Admin can remove a bank");


        delete banks[bankAddress];
        delete bankrequests[bankAddress];

        // Delete all the votes casted for the bank being deleted
        delete Bank2BankRatings[bankAddress];

       // Delete the bank address from bankaddresses
        for (uint i = 0; i< bankaddresses.length; i++) {
            if (bankaddresses[i] == bankAddress) {
                bankaddresses = removeArrIdxAddress(bankaddresses, i);
            }
        }


        // Delete the bank votes casted by the bank being deleted

        for (uint k = 0; k< bankaddresses.length; k++) {
            for (uint i = 0; i< Bank2BankRatings[bankaddresses[k]].length; i++) {
                if (Bank2BankRatings[bankaddresses[k]][i] == bankAddress) {
                     Bank2BankRatings[bankaddresses[k]] = removeArrIdxAddress(Bank2BankRatings[bankaddresses[k]], i);

                }
            }
        }

        // Delete the customer votes casted by the bank being deleted

        for (uint k = 0; k< customerNames.length; k++) {
            for (uint i = 0; i< Bank2CustomerRatings[customerNames[k]].length; i++) {
                if (Bank2CustomerRatings[customerNames[k]][i] == bankAddress) {
                    Bank2CustomerRatings[customerNames[k]] = removeArrIdxAddress(Bank2CustomerRatings[customerNames[k]], i);
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


        require(msg.sender == admin, "Only Admin can add a bank");
        require(banks[bankAddress].ethAddress == address(0), "This bank akready exists in the system");

        banks[bankAddress].name = bankName;
        banks[bankAddress].regNumber = regNumber;
        banks[bankAddress].ethAddress = bankAddress;
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
      require(isBankAdded(msg.sender), "Bank is not added yet to add a KYC request");

      for (uint8 i = 0; i< customerNames.length; i++) {
            if (stringsEquals(customerNames[i],customerName)) {
                customers[customerName].password = password;
                return true;
            }
        }
        return false;
    }

    // Utility functions

    function isCustomerAdded(string memory customerName) internal view returns(bool) {
        for(uint8 i; i< customerNames.length; i++) {
            if(stringsEquals(customers[customerName].customerName, customerName)){
                return true;
            }
        }
        return false;

    }


    function isBankAdded(address bankAddress) internal view returns(bool){
        for(uint8 i; i< bankaddresses.length; i++) {
            if(bankaddresses[i] == bankAddress){
                return true;
            }
        }
        return false;
    }

    // Remove element from the array
    function removeArrIdxAddress(address[] memory array, uint index) internal pure returns(address[] memory) {
        if (index >= array.length)
            return array;

        address[] memory arrayNew = new address[](array.length-1);
        for (uint i = 0; i < arrayNew.length; i++) {
            if (i != index && i < index) {
                arrayNew[i] = array[i];
            }

            else {
                arrayNew[i] = array[i+1];
            }
        }
        delete array;
        return arrayNew;
    }


    function removeArrIdxStrings(string[] memory array, uint index) internal pure returns(string[] memory) {
        if (index >= array.length)
            return array;

        string[] memory arrayNew = new string[](array.length-1);
        for (uint i = 0; i < arrayNew.length; i++) {
            if (i != index && i < index) {
                arrayNew[i] = array[i];
            }

            else {
                arrayNew[i] = array[i+1];
            }
        }
        delete array;
        return arrayNew;
    }

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
