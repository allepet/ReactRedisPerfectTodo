import React, { Component } from 'react';
import './TaskItem.css'
import "isomorphic-fetch"

class TaskItem extends Component {

    render(){
       return (
           <div className="taskDiv" onClick={this.deleteItem.bind(this)}>
               <h1>{this.props.taskName}</h1>
           </div>
       )
    }

    deleteItem(event){
        fetch("http://localhost:8080/task/" + this.props.index, {method:'DELETE', headers: new Headers(), mode: 'cors',
            cache: 'default'})
    }

}

export default TaskItem;
