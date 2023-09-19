// SPDX-License-Identifier: MIT
pragma solidity >= 0.5.9;

contract VoterRegistry {
    address payable public owner; // Διεύθυνση του διαχειριστή
    uint public totalVoters; // Συνολικός αριθμός ψηφοφόρων
    uint public totalCandidates; // Συνολικός αριθμός υποψηφίων
    uint public totalFunds; // Συνολικό ποσό διαθέσιμο από τις συνδρομές
    uint public registrationFee = 0.01 ether; // Ποσό εγγραφής για υποψηφίους
    bool public votingStarted; // Ένδειξη για την έναρξη της ψηφοφορίας
    bool public votingFinished; // Ένδειξη για το πέρας της ψηφοφορίας
    address public winner; // Διεύθυνση του νικητή των εκλογών
    address[] public candidateAddresses; // Πίνακας διευθύνσεων υποψηφίων 
    address[] public voterAddresses; // Πίνακας διευθύνσεων ψηφοφόρων
    uint public totalVote; // Αριθμός ψήφων
    uint public currentElection; // Δείκτης νικητών
    

    
    // Τα δομημένα στοιχεία του υποψήφιου 
    struct Candidate {
        address addr;
        uint measure;
    }

    // Τα δομημένα στοιχεία του ψηφοφόρου
    struct Voter {
        bool voted;
        uint reward;
    }

    //Ορόσημο του νικητή
    event Winner(address winner);

    // Μόλις κάποιος δηλώσει υποψηφιότητα
    event candidateFee(address candidateFee);

    // Μόλις κάποιος κάνει εγγραφή
    event voterFee(address voter);
    
    // Τα στάδια της διαδικασίας
    enum Stage {Init, Reg, Vote, Done}
    Stage public currentStage = Stage.Init;


    // Αντιστοίχιση των διευθύνσεων με τους υποψηφίους
    mapping(address => Candidate) public candidates;
    
    // Αντιστοίχιση των διευθυνσεών με τους ψηφοφόρους
    mapping(address => Voter) voters;

    
    // Εγγεγραμμένοι ψηφοφόροι
    mapping(address => bool) public registeredVoters;

    // Εγγεγραμμένοι υποψήφιοι
    mapping(address => bool) public registeredCandidates;

    // Ψηφοί ανά ψηφοφόρο
    mapping(address => bool) public voted;
    
    // Νικητές
    mapping(uint => address) public winners;

    constructor() {
        owner = payable(msg.sender);
        winner = msg.sender;  
    }
    
    // Ο ιδιοκτήτης του συμβολαίου
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }

    /* 
    Η συνάρτηση register() επιτρέπει σε έναν χρήστη να εγγραφεί στον κατάλογο των ψηφοφόρων. 
    Ελέγχει αν ο χρήστης έχει ήδη εγγραφεί και στη συνέχεια τον εγγράφει και αυξάνει τον αριθμό των εγγεγραμμένων ψηφοφόρων.
    */

    function register() public {
        require(!registeredVoters[msg.sender], "Already registered");
        

        registeredVoters[msg.sender] = true;
        totalVoters++;
        voterAddresses.push(msg.sender);
        emit voterFee(msg.sender);
    }

    
    /* 
    Η συνάρτηση declareCandidacy() επιτρέπει στους εγγεγραμμένους ψηφοφόρους να δηλώσουν υποψηφιότητα για τη θέση του Προέδρου.
    Η συνάρτηση αυτή ελέγχει αν ο χρήστης είναι εγγεγραμμένος ψηφοφόρος και δεν έχει ήδη δηλώσει υποψηφιότητα. 
    Ορίζεται το «μέτρο» του συγκεκριμένου υποψηφίου. (Το ποσό που δίνει ο κάθε υποψήφιος, διαιρεμένο με το πλήθος όλων των ψηφοφόρων)
    Στη συνέχεια, εγγράφει τον χρήστη ως υποψήφιο και αυξάνει τον συνολικό αριθμό των υποψηφίων. 
    */
    
    function declareCandidacy() external payable {
        require(registeredVoters[msg.sender], "Not registered as voter");
        require(!registeredCandidates[msg.sender], "Already declared candidacy");
        require(msg.value >= registrationFee, "Insufficient registration fee");


        candidates[msg.sender] = Candidate({
            addr: msg.sender,
            measure: msg.value / totalVoters
    
        });
        
        candidateAddresses.push(msg.sender); // καταχώρηση του υποψήφιου στον πίνακα candidateAddresses
        
        totalCandidates++;
        totalFunds += msg.value;
        

        registeredCandidates[msg.sender] = true;
        emit candidateFee(msg.sender);

    }

    
    // Ξεκινάει η διαδικασία της ψηφοφορίας εάν υπάρχουν πάνω απο δύο υποψήφιοι διαφορετικά εμφανίζει το μήνυμα "No candidates registered".
    function startVoting() public onlyOwner {
     
        require(totalCandidates >= 2, "No candidates registered");
        

        votingStarted = true;
    }

    
    // Ψηφοφορία
    function vote(address candidate) public {
        require(votingStarted, "Voting has not started");
        require(registeredVoters[msg.sender], "Not registered as voter");
        require(registeredCandidates[candidate], "Invalid candidate");
        require(!voted[msg.sender], "Already voted");

        voted[msg.sender] = true;
        totalVote++;
    }


    // Τερματισμός της διαδικασίας ψηφοφορίας. Μόνο ο owner μπορεί να το κάνει αυτό.
    function finishVoting() public onlyOwner {
        require(votingStarted, "Voting has not started");
        require(!votingFinished, "Voting already finished");
        
        votingFinished = true;

    }

    /*
    Η συνάρτηση getWinner ξεκινάει να βρεί τον νικητή. 
    */

    function getWinner() public {
        
        
        uint maxMeasure = 0;
        for (uint i = 0; i < totalCandidates; i++) {
            if (candidates[candidateAddresses[i]].measure > maxMeasure) {
                maxMeasure = candidates[candidateAddresses[i]].measure;
                winner = candidates[candidateAddresses[i]].addr;
            }
            
        }
        
        candidateAddresses = new address[](0); // Μηδένισε τον πίνακα candidateAddresses


    }

    /*
    Στη συνάρτηση getBalance() μπορεί να δεί ο διαχειριστής και τα υπόλοιπα μέλη το ποσό που έχει συγκεντροθεί στο συμβόλαιο. 
    Η διαφορά με το totalFunds είναι πως το getBalance εμφανίζει την συνολική τιμή που έχει μέσα το συμβολαίο,
    ενώ το totalFunds το συνολικό ποσό που έχουν καταθέσει οι υποψήφιοι.
    */

    function getBalance() external view returns (uint) {
        return address(this).balance;
    }

    /*
    Στη συνάρτηση withdraw() o owner (Διαχειριστής) βλέπει από το getBalance το συνολικό ποσό που έχει 
    συγκεντρωθεί και στέλνει το ποσό που θέλει αυτός στο πορτοφόλι του. 
    Στη συνέχεια μπορεί να στείλει το ποσό στο ΚΥΔ του Πανεπιστημίου Μακεδονίας.
    Μόνο ο owner μπορεί να το κάνει αυτό.
    */

    function withdraw(uint _amount) external {
        require(msg.sender == owner, "caller is not owner");
        payable(msg.sender).transfer(_amount);
        totalFunds = totalFunds - _amount;

    }

    /* 
    Με την συνάρτηση deaclareWinner δηλώνει ο owner τον νικητή τον εκλογών αφού ελέγξει ότι η ψηφοφορία έχει σταματήσει
    και αποθηκεύει τον νικητή των εκλογών.
    Μόνο ο owner μπορεί να το κάνει αυτό.
    */
    function declareWinner(address _winner) external onlyOwner {
        require(votingFinished, "Voting has not Finish");
        winners[currentElection] = _winner;
        currentElection++;
        winner = _winner;
        emit Winner(_winner);
    }

    // Λειτουργία για ανάκτηση των προηγούμενων νικητών.
    function getPreviousResults() public view returns (address) {
        require(currentElection > 1, "No previous elections");
        return winners[currentElection - 1];
    }

    
    // Αλλαγή διαχειριστή. Μόνο ο owner μπορεί να το κάνει αυτό.
    function changeOwner(address _newManager) public onlyOwner {
        owner = payable(_newManager);
    }

    // Επανεκκίνηση της διαδικασίας. Μόνο ο owner μπορεί να το κάνει αυτό.
    function restart() public onlyOwner {
        owner.transfer(address(this).balance);
        owner = payable(msg.sender);
        currentStage = Stage.Init;
        totalCandidates = 0; 
        totalVoters = 0; 
        votingStarted = false;
        votingFinished = false;
        winner = msg.sender;
        totalFunds = 0;
        registeredVoters[msg.sender] = false;
        registeredCandidates[msg.sender] = false;
              
    }
    
    // Καταστροφή του συμβολαίου. Μόνο ο owner μπορεί να το κάνει αυτό.
    function kill(Kill _kill) public onlyOwner {
       _kill.kill();
    }

    
}

/*
Προσοχή το συμβόλαιο θα καταστραφεί!
*/
contract Kill{

    function kill() external {
       selfdestruct(payable(msg.sender));
    }

    function test() external pure returns (uint){
        return 99;
    }
}