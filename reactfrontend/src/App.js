import React, { Component } from 'react';
import TaskItem from './TaskItem'
import './App.css'

class App extends Component {


    updateTasks() {
        fetch("http://localhost:8080/lastSave").then((response) => {
            return response.json()
        }).then((timestamp) => {
            if (timestamp.lastsave > this.newestSave) {
                fetch('http://localhost:8080/task')
                    .then((response) => {
                        return response.json()
                    })
                    .then((tasks) => {
                        let ndx = 0
                        tasks = tasks.map(d => {
                            ndx++
                            return(<TaskItem key={ndx-1} index={ndx-1} taskName={d}/>)
                        })
                        this.setState({tasks: tasks})
                    })
                this.newestSave = timestamp.lastsave
            }
        })

        setTimeout(this.updateTasks.bind(this), 100)
    }

    addTask(){
        fetch("http://localhost:8080/task", {method:"post", body : "task=" + document.getElementById("taskInfo").value })
        document.getElementById("taskInfo").value = ""
    }

    constructor(props){
        super(props)
        this.newestSave = 0
        this.state = {tasks: []}
        this.updateTasks.bind(this)()

    }

  render() {
    return (

        <div>
            <nav>
                <span>🐦 + ⚛️ + Perfect = 💓</span>
                <span className="description">A simple task app using Perfect, Swift and React</span>
            </nav>
            <div className="tasks">
                {this.state.tasks}
            </div>
            <footer>
                <div>
                    <label>Task to add</label>
                    <input id="taskInfo" type="text"></input>
                    <button onClick={this.addTask}>Add task</button>
                </div>
            </footer>
        </div>
    );
  }
}

export default App;
