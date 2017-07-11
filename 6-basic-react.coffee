# # 6. Basic Usage with React

# To view the final result, run server.coffee and navigate to http://localhost:4337/6-basic-react

# *Note*: Because of metaserve inconveniences, the rest of the tutorials are in non-literate CoffeeScript.

# Redux manages state, and that is its only goal. Similarly, React manages views, and that is, or should be, its only goal. Unfortunately state management often creeps into deep corners of a React app, state and views meld into an inseperable tangle, and responsibility diffuses into a bloody mist.

# The Redux paradigm will save our soul as we move to a Single Source of Truth (or State).

# Here I'll be using [Preact, a lightweight React alternative](https://github.com/developit/preact) to make reloading faster as I write the tutorial.

React = require 'preact'
{combineReducers, createStore} = require 'redux'

# This app will be a list of items which we can add and remove. Defining the initial state is a nice way to start describing the app.

initial_state =
    items:
        0: 'this is a test'
        1: 'this is another test'
    new_item: ''

# We'll define an `items_reducer` to add and remove items. Instead of a real database which would manage its own IDs, here we'll accept the created item as a plain string and create the ID based on the largest existing ID.

items_reducer = (state={}, action) ->
    switch action.type
        when 'items.create'
            new_id = Math.max(Object.keys(state)...) + 1
            created = {}
            created[new_id] = action.item
            return Object.assign {}, state, created
        when 'items.delete'
            new_state = Object.assign {}, state
            delete new_state[action.id]
            return new_state
    return state

# And a `new_item_reducer` to be used with an input:

new_item_reducer = (state='', action) ->
    switch action.type
        when 'new_item.set'
            return action.value
    return state

# Then combine these reducers and create a Store:

combined_reducer = combineReducers
    items: items_reducer
    new_item: new_item_reducer

store = createStore combined_reducer, initial_state

# The Items component will show the items in a plain list. Each item will have a "Delete" button, which will dispatch the appropriate `items.delete` action to the Store.

Items = ({items}) ->
    <ul className='items'>
        {Object.entries(items).map ([id, item]) ->
            deleteItem = -> store.dispatch {type: 'items.delete', id}
            <li key=id>
                <strong>{id}</strong> <span>{item}</span>
                <button onClick=deleteItem>Delete</button>
            </li>
        }
    </ul>

# The NewItem component is a form with an input which will dispatch `new_item.update` and `items.create` as you type and eventually hit enter. Creating the item will also set `new_item` to an empty string. 

# *Note*: A slight inconsistency between Preact and React, Preact uses an `onInput` handler instead of `onChange`

NewItem = ({new_item}) ->
    createItem = (e) ->
        e.preventDefault()
        store.dispatch {type: 'items.create', item: new_item}
        store.dispatch {type: 'new_item.set', value: ''}
    changeNewItem = (e) ->
        store.dispatch {type: 'new_item.set', value: e.target.value}
    <form className='new_item' onSubmit=createItem>
        <input value=new_item onInput=changeNewItem />
    </form>

# The App component is the only thing with state here &mdash; it subscribes to the Store and updates its state with the whole Store state when it changes. The child components will get the appropriate values passed down as props.

class App extends React.Component
    constructor: ->
        @state = store.getState()
        store.subscribe =>
            @setState store.getState()

    render: ->
        <div className='app'>
            <Items items=@state.items />
            <NewItem new_item=@state.new_item />
        </div>

React.render <App />, document.body
