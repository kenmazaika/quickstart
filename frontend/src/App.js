import React, { Component } from 'react';
import logo from './032-boy.svg';
import './App.css';

class App extends Component {
  componentDidMount() {
    setInterval(this.updateTime, 1000);
    this.loadTweets();
  }

  updateTime = () => {
    fetch('/api', {
      method: 'GET'
    })
    .then((response) => response.json())
    .then((result) => {
      console.log(result);
      this.setState({time: result.time, json: result})
    })
    .catch((error) => {
      console.error('Error:', error);
    });
  }


  loadTweets = () => {
    fetch('/api/tweets', {
      method: 'GET'
    })
    .then((response) => response.json())
    .then((result) => {
      console.log(result);
      this.setState({tweets: result})
    })
    .catch((error) => {
      console.error('Error:', error);
    });
  }


  loading = () => {
    return (
      <div className="App">
        <div className="App-header loading">
          <img src={logo} className="App-logo animate" alt="logo" />
          <h1>Loading...</h1>
        </div>
      </div>
    );
  }

  showTime = (time, json, tweets) => {
    return (
      <div className="App">
        <div className="App-header">
          <img src={logo} className="App-logo" alt="logo" />

          <h1>Enabled</h1>
          <h2>{time}</h2>
        </div>
        <div className="App-body">
          <h3>Metropolis Quickstart App</h3>
          <p>
            This is a React frontend that connects to the Ruby on Rails backend ready for deployment using Kubernetes and Terraform.
          </p>
          <p>
            Running frontend version 1.0.0.
          </p>
          <h4>Healthcheck</h4>
          <code><strong>GET</strong> /api</code> <br /><br />
          <code>{json}</code>

          <h4>Tweets</h4>
          <code><strong>GET</strong> /api/tweets</code> <br /><br />

          <code>
            {tweets}
          </code>
        </div>
      </div>
    );    
  }

  render() {
    const time = this.state && this.state.time ? this.state.time : null;
    const json = this.state && this.state.json ? this.state.json : "...";
    const tweets = this.state && this.state.tweets ? this.state.tweets : "...";

    if(time === undefined || time === null) {
      return this.loading();
    }
    else {
      return this.showTime(time, JSON.stringify(json), JSON.stringify(tweets));
    }

  }
}

export default App;
