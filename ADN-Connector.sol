
// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts@4.7.3/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts@4.7.3/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: ADN-Connector.sol


pragma solidity ^0.8.4;


interface IADN {
    function balanceOf(address _owner) external view returns (uint256 _balance);
}

interface IADNFT {
    function safeMint(address to, string memory uri) external;

    function balanceOf(address _owner) external view returns (uint256 _balance);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function ownerOf(uint256 tokenId) external view returns (address owner);
}


contract AiDreamNetworkConnector is Ownable {
    struct TaskData {
        string prompt;
        uint promptTime;
        uint reward;
        uint confirmTime;
        uint resultPicked;
    }

    struct ResultData {
        uint resolveTime;
        string result;
    }

    address public FINANCE_VAULT;
    uint public MIN_PROMPT_PRICE = 10 ** 17; //0.1 KLAY
    uint public TAX_PER_1000 = 10; //10/1000=> 1%
    uint public LIMIT_MINER = 4; //Just pick top 4 Miner
    uint public MINER_MIN_ADN_BALANCE = 100 * 10 ** 18; //Miner need hold 100 ADN token to become Miner
    uint public TTL_TASK = 15 minutes;// Time To Live Of Task 
    IADN public ADN;
    IADNFT public ADNFT;

    mapping(uint => TaskData) public Tasks;
    uint public taskCount = 0; 

    mapping(uint => ResultData) public Results;
    uint public resultCount = 0; 
 
    mapping(uint => uint[]) public TaskToResults;
    function getTaskResultsCount(uint taskId) public view returns (uint){
        return TaskToResults[taskId].length;
    }
    function getTaskResultId(uint taskId, uint index) public view returns(uint){
        return TaskToResults[taskId][index];
    }
    function getTaskResult(uint taskId, uint index) public view returns(ResultData memory){
        return Results[TaskToResults[taskId][index]];
    }
    mapping(uint => uint) public ResultToTask;


    mapping(address => uint[]) public UserToTasks;
    function totalUserTaskCount(address user) public view returns(uint){
        return UserToTasks[user].length;
    }
    function getUserTask(address user, uint index) public view returns(uint){
        return UserToTasks[user][index];
    }
    mapping(uint => address) public TaskToUser;//Check Owner of task

    mapping(address => uint[]) public MinerToResults;
    function totalMinerResultCount(address user) public view returns(uint){
        return MinerToResults[user].length;
    }
    function getMinerResult(address user, uint index) public view returns(uint){
        return MinerToResults[user][index];
    }
    mapping(uint => address) public ResultToMiner;//Check Owner of result

    constructor() {
        FINANCE_VAULT = _msgSender();
    }

    function setFinanceVault(address newAddress) public onlyOwner {
        FINANCE_VAULT = newAddress;
    }

    function setPrice(uint newValue) public onlyOwner {
        MIN_PROMPT_PRICE = newValue;
    }

    function setTaxt(uint newValue) public onlyOwner {
        TAX_PER_1000 = newValue;
    }

    function setLimitMiner(uint newValue) public onlyOwner {
        LIMIT_MINER = newValue;
    }

    function setTTLTask(uint newValue) public onlyOwner {
        TTL_TASK = newValue;
    }

    function setADNFTAddress(address newAddress) public onlyOwner {
        ADNFT = IADNFT(newAddress);
    }

    function setADNAddress(address newAddress) public onlyOwner {
        ADN = IADN(newAddress);
    }

    function startTask(string memory _prompt) public payable {
        require(msg.value >= MIN_PROMPT_PRICE, "Reward must be greater than min price");
        taskCount++; 
        Tasks[taskCount] = TaskData({
            prompt: _prompt, 
            promptTime: block.timestamp,
            reward: msg.value,
            confirmTime: 0,
            resultPicked: 0
        });

        //Relate User -> task (1-n),  task -> user (1-1)
        UserToTasks[_msgSender()].push(taskCount);
        TaskToUser[taskCount] = _msgSender();
    }

    function postTask(uint taskId,string memory  _cidResult) public {
        require(TaskToResults[taskId].length < LIMIT_MINER, "Task results is enough, let quickly later"); 
        require(Tasks[taskId].confirmTime == 0, "Task must be not confirm");
        require(ADN.balanceOf(_msgSender()) >= MINER_MIN_ADN_BALANCE, "Miner must hold ADN to become miner");
        resultCount++;
        Results[resultCount] = ResultData({
            resolveTime: block.timestamp, 
            result: _cidResult
        });
        //relate task -> result (1-n), result -> task (1-1)
        TaskToResults[taskId].push(resultCount);
        ResultToTask[resultCount] = taskId;
        //Relate Miner -> result (1-n),  result -> miner (1-1)
        MinerToResults[_msgSender()].push(resultCount);
        ResultToMiner[resultCount] = _msgSender();
    }

    function pickResult(uint taskId, uint resultId) public payable {
        require(Tasks[taskId].confirmTime == 0, "Task must be not confirm");
        //Check msg sender is task owner
        require(TaskToUser[taskId] == _msgSender(), "Not own task");
        require(ResultToTask[resultId] == taskId, "Result is not for task");
        //Set status Task
        Tasks[taskId].confirmTime = block.timestamp;
        Tasks[taskId].resultPicked = resultId;
        //Mint new NFT with CID
        ADNFT.safeMint(_msgSender(), Results[resultId].result);
        //Pick tax
        uint tax = Tasks[taskId].reward * TAX_PER_1000 / 1000;
        payable(FINANCE_VAULT).transfer(tax);
        //Send Rest To Miner as Reward
        payable(ResultToMiner[resultId]).transfer(tax);
    }

    //Dev: Incase creator (user) not pickResult? => then any one can finalize task after TTL_TASK (default 15 minutes). 
    //=> Incase no miner post result, creators will get back all reward 
    //==> Incase have least 1 miner. 
    //=> task reward will split = tax + rest
    //=> rest split 2 part: 50% dividen for miners has been posted result, 50% return creators

    function finalizeTask(uint taskId) public payable{
        require(block.timestamp - Tasks[taskId].promptTime > TTL_TASK, "Not passing TTL of Task");
        if(TaskToResults[taskId].length == 0){
            payable(TaskToUser[taskId]).transfer(Tasks[taskId].reward);
        }
        else{
            //Pick tax
            uint tax = Tasks[taskId].reward * TAX_PER_1000 / 1000;
            payable(FINANCE_VAULT).transfer(tax);
            //Send 50% Rest To Miners as Reward
            uint minerReward = ((Tasks[taskId].reward - tax) / 2) / TaskToResults[taskId].length; 
            for(uint i = 0; i< TaskToResults[taskId].length; i++){
                payable(ResultToMiner[TaskToResults[taskId][i]]).transfer(minerReward);
            }
            payable(TaskToUser[taskId]).transfer(Tasks[taskId].reward  - tax - minerReward * TaskToResults[taskId].length);
        }
    }
}
