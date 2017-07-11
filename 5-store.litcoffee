# 5. From State to Store

So far we have been keeping a state object around and applying reducers directly to modify it. The second piece of the Redux library &mdash; the Store &mdash; a simple wrapper around the state and reducers that makes things more convenient. The most important things it does are `dispatch` actions, applying the reducers to the state as we've already seen, and offer a stream of state changes with `subscribe`.

    {combineReducers, createStore} = require 'redux'

We'll borrow the counter reducer factory from the last lesson:

    create_counter_reducer = (counter_name) -> (state=0, action) ->
        amount = action.amount
        amount = 1 if not amount?
        switch action.type
            when "#{counter_name}.inc"
                return state + amount
            when "#{counter_name}.dec"
                return state - amount
        return state # Fallback

## Creating a Store

A Store is created with `createStore`, with a reducer function and optionally an initial state. This initial state is useful when bootstrapping data from the server.

    combined_reducer = combineReducers {
        counter1: create_counter_reducer 'counter1'
        counter2: create_counter_reducer 'counter2'
    }

    initial_state = {
        counter1: 5
        counter2: 10
    }

    store = createStore combined_reducer, initial_state

## Using the Store

You can get the current state from the Store with `getState()`:

    console.log 'current state =', store.getState()
    # current state = { counter1: 5, counter2: 10 }

And apply actions with `dispatch(action)`. As usual, this action is passed through all the combined reducers. The main difference here is you don't need to keep the state variable around, and instead always fetch the changed state with `getState()`.

    store.dispatch {type: 'counter1.inc'}
    console.log 'current state =', store.getState()
    # current state = { counter1: 6, counter2: 10 }

## Subscribing to changes

Create an event listener, called every time an action is dispatched, with `subscribe(fn)`. The subscribed function is called with no arguments - again use `getState()` to get the state.

    onChange = ->
        console.log "changed state =", store.getState()

    unsubscribe = store.subscribe onChange

    store.dispatch {type: 'counter1.inc'}
    # changed state = { counter1: 7, counter2: 10 }

The function returned by `subscribe` can be used to unsubscribe (important when unmounting components).

    unsubscribe()

    store.dispatch {type: 'counter1.inc'}
    # (onChange not called here ...)

---

**Next:** [](6-.litcoffee)

