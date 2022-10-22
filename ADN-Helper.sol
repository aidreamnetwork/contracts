// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

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

interface IADN{
    function TaskToResults(uint taskId, uint index) external view returns (uint);
    function getTaskResultsCount(uint taskId) external view returns (uint);
    function Tasks(uint taskId) external view returns (string memory prompt, uint promptTime, uint rewar, uint confirmTime, uint resultPicked);
    function Results(uint resultId) external view returns (uint resolveTime, string memory result);
    function ResultToMiner(uint resultId) external view returns (address miner);
    function ResultToTask(uint resultId) external view returns (uint taskId);
    function ResultToNFT(uint resultId) external view returns (uint tokenId);
    function TaskToUser(uint taskId) external view returns (address user);
}

contract ADN_HELPER{
    
    address public owner;
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    constructor(address _ADN){
        owner = msg.sender;
        ADN = IADN(_ADN);
    }

    IADN ADN; 
    function setADN(address newAdd) public onlyOwner{
        ADN = IADN(newAdd);
    }
    function TaskToResults(uint taskId, uint index) public view returns (uint){
        return ADN.TaskToResults(taskId, index);
    }

    function Tasks(uint taskId) public view returns (TaskData memory taskData){
        string memory prompt;
        uint promptTime;
        uint rewar;
        uint confirmTime;
        uint resultPicked;
        (prompt, promptTime, rewar, confirmTime, resultPicked) =  ADN.Tasks(taskId);
        taskData = TaskData(prompt, promptTime, rewar, confirmTime, resultPicked);
    }

    function Results(uint resultId) public view returns (ResultData memory resultData){
        string memory result;
        uint resolveTime;
        (resolveTime, result) =  ADN.Results(resultId);
        resultData = ResultData(resolveTime, result);
    }

    function getTaskFullData(uint taskId) public view returns(address creator, TaskData memory taskData, uint resultCount, uint[] memory resultIds, address[] memory miners, string[] memory results, uint[] memory resolveTimes, uint tokenId ){
        creator = ADN.TaskToUser(taskId);
        taskData = Tasks(taskId);
        resultCount = ADN.getTaskResultsCount(taskId);
        resultIds = new uint[](resultCount); 
        results = new string[](resultCount);
        resolveTimes = new uint[](resultCount);
        miners = new address[](resultCount);
        for(uint i = 0; i< resultCount; i++){
            uint resultId = ADN.TaskToResults(taskId, i);
            ResultData memory result = Results(resultId);
            resultIds[i] = resultId; 
            results[i] = result.result;
            resolveTimes[i] = result.resolveTime;
            miners[i] = ADN.ResultToMiner(resultId);
            if(taskData.resultPicked == resultId)
            {
                tokenId = ADN.ResultToNFT(resultId);
            }
        } 
    }

    function getResultFullData(uint resultId) public view returns(ResultData memory resultData, address miner, uint taskId, TaskData memory taskData, address creator, uint tokenId){
        resultData = Results(resultId);
        miner = ADN.ResultToMiner(resultId);
        taskId = ADN.ResultToTask(resultId);
        taskData = Tasks(taskId); 
        creator = ADN.TaskToUser(taskId);
        if(taskData.resultPicked == resultId)
        {
            tokenId = ADN.ResultToNFT(resultId);
        }
    }

}