import React, { Component } from 'react';
import 'bootstrap/dist/css/bootstrap.css';
import web3 from './web3';
import lottery from './lottery';

// Η κλάση App αποτελεί απόγονο της Component 
// η οποία είναι θεμελιώδης στην react.
// Σε κάθε αλλαγή κάποιου στοιχείου εντός της App,
// π.χ. πληκτρολογώντας εντός ενός textBox,
// ή αν τροποποιηθεί κάποια μεταβλητή state,
// όλη η ιστοσελίδα (HTML) γίνεται refresh
// καλώντας αυτόματα τη render()...
// ...ΠΡΟΣΟΧΗ! ΔΕΝ γίνεται reload... ΜΟΝΟ refresh

class App extends Component {
  state = {
    owner: '', // O διαχειριστής
    candidates: [], // Λίστα με τους υποψηφίους
    voters: [], // Λίστα με τους ψηφοφόρους
    previousResults: [], // Λίστα με τα προηγούμενα αποτελέσματα
    balance: '',
    value: '',
    message: ''
  };

  // Η componentDidMount() καλείται ΜΟΝΟ την πρώτη φορά
  // που φορτώνει η ιστοσελίδα (είναι σαν την onLoad())
  async componentDidMount() {

    // Κάθε φορά που επιλέγεται άλλο πορτοφόλι στο metamask...
    window.ethereum.on('accountsChanged', (accounts) => {
      // ... να γίνεται reload η σελίδα, δηλ. να καλείται η componentDidMount()
      window.location.reload();
    });

    // Ορισμός των state μεταβλητών
    const owner = await lottery.methods.owner().call();
    const candidates = await lottery.methods.declareCandidacy().call();
    const voters = await lottery.methods.register().call();
    const balance = await web3.eth.getBalance(lottery.options.address);
    const currentAccount = (await web3.eth.getAccounts())[0]; 
    this.setState({ owner, candidates, voters, balance, currentAccount });

    // Όποτε δηλώσει υποψηφιότητα ενημερώνει το candidates & balance
    lottery.events.candidatesFee({}, async (error, event) => {
        if (error) {
            console.error(error);
        } else {
            const candidates = await lottery.methods.declareCandidacy().call();
            const balance = await web3.eth.getBalance(lottery.options.address);
            this.setState({ candidates, balance });
        }
    });

     // Όποτε δηλώσει εγγραφή ενημερώνει το voters
     lottery.events.voterFee({}, async (error, event) => {
      if (error) {
          console.error(error);
      } else {
          const voters = await lottery.methods.register().call();
          const balance = await web3.eth.getBalance(lottery.options.address);
          this.setState({ voters, balance });
      }
  });
    

    // Όποτε ολοκληρωθεί η ψηφοφορία να ενημερώσεις τις candidates & balance
    // και να δημιουργήσεις τη νέα state μεταβλητή lastWinner
    lottery.events.Winner({}, async (error, event) => {
        if (error) { console.error(error);
        } else {
            const candidates = await lottery.methods.getWinner().call();
            const balance = await web3.eth.getBalance(lottery.options.address);
            const lastWinner = event.returnValues.winner;
            this.setState({ lastWinner, candidates, balance });
        }
    });

    // Αν δεν υπήρχε παραπάνω η window.ethereum.on('accountsChanged', (accounts)
    // this.refreshAccount();
  }

// Αν δεν υπήρχε παραπάνω η window.ethereum.on('accountsChanged', (accounts)
//   refreshAccount = async () => {
//     const accounts = await web3.eth.getAccounts();

//     if (this.state.currentAccount !== accounts[0]) {
//       this.setState({ currentAccount: accounts[0] });
//     }

//     setTimeout(() => {
//       this.refreshAccount();
//     }, 1000);
//   };

  // Όταν πατηθεί το κουμπί "declareCandidacy"
  onSubmit = async event => {
    event.preventDefault();

    this.setState({ message: 'Waiting for success...' });

    await lottery.methods.declareCandidacy().send({ // Κλήση της "declareCandidacy()" του συμβολαίου
      from: this.state.currentAccount,
      value: web3.utils.toWei(this.state.value, 'ether')
    });

    this.setState({ message: 'You have been entered!' });
  };
  // Όταν πατηθεί το κουμπί "register"
  onSubmit = async event => {
    event.preventDefault();

    this.setState({ message: 'Waiting for success...' });

    await lottery.methods.register().send({ // Κλήση της "register()" του συμβολαίου
      from: this.state.currentAccount,
      value: web3.utils.toWei(this.state.value, 'ether')
    });

    this.setState({ message: 'You have been entered!' });
  };

  // Όταν πατηθεί το κουμπί "declareWinner"
  onClick = async () => {
    this.setState({ message: 'Waiting for success...' });

    await lottery.methods.declareWinner().send({ // Κλήση της "pickWinner()" του συμβολαίου
      from: this.state.currentAccount
    });

    this.setState({ message: 'A winner has been picked!' });
  };

  // Λειτουργία για την ανάκτηση των προηγούμενων αποτελεσμάτων από το συμβόλαιο
  fetchPreviousResults = async () => {
     const previousResults = await lottery.methods.getPreviousResults().call();
     this.setState({ previousResults });
  };

  // Κάθε φορά που η σελίδα γίνεται refresh
   render() { 
    return (
      <div>
      <h2>Ballot Contract</h2>
      {/* Ό,τι βρίσκεται εντός των άγκιστρων είναι κώδικας JavaScript */}
      {/* Η σελίδα HLML λειτουργεί αυτόνομα, σαν να εκτελείται σε κάποιον server */}
      <p>
        This contract is managed by {this.state.owner}. There are currently{' '}
        {this.state.candidates.length} people entered, competing to win{' '}
        {web3.utils.fromWei(this.state.balance, 'ether')} ether!
      </p>

      <hr /> {/*  -------------------- Οριζόντια γραμμή -------------------- */}

      {/* Η φόρμα "Want to try your luck?" */}
      {/* Θα μπορούσε αντί να χρησιμοποιηθεί φόρμα, */}
      {/* να χρησιμοποιηθεί button... */}
      {/* και αντί .onSubmit να χρησιμοποιούνταν .onClick */}
      <form onSubmit={this.onSubmit}>
        <h4> Connected wallet address: {this.state.currentAccount}</h4>
        <div>
          <label>Amount of ether to enter</label>
          <input
            value={this.state.value}
            onChange={event => this.setState({ value: event.target.value })}
          />
        </div>
        <button>Enter</button>
      </form>

      <hr /> {/*  -------------------- Οριζόντια γραμμή -------------------- */}

      <h4>Ready to pick a winner?</h4>
      <button onClick={this.onClick}>Pick a winner!</button>

      <hr /> {/*  -------------------- Οριζόντια γραμμή -------------------- */}

      <h1>{this.state.message}</h1>
      {this.state.lastWinner &&
       <h3>Last Winner Address: {this.state.lastWinner}</h3>
      }

      <hr /> {/*  -------------------- Οριζόντια γραμμή -------------------- */}

      <h3>View Previous Election Results</h3>
      <button onClick={this.fetchPreviousResults}>View Previous Election Results</button>
      <ul>
          {this.state.previousResults.map((result, index) => (
             <li key={index}>Election #{index + 1}: {result}</li>
       ))}
      </ul>
    </div>
    
    );
  }  
}
 
export default App;

//τα παρακάτω χρησιμοποιούνται για το styling
const button = {
  color: "white",
  backgroundColor: "DodgerBlue",
  padding: "10px",
  fontFamily: "Arial",
  borderRadius: 10,
  };
  const placeholder = {
  borderRadius: 10
  }

