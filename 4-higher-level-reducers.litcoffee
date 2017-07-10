# 3. Higher-level Reducers

Consider the `counter_reducer` from the first two parts. It works nicely if our application has just one counter. But as soon as the client expands the scope of the counter app and we need another counter on the page, there's an big problem: the `inc` action will be ambiguous.

It's easy to avoid this by namespacing the actions. We have two counters now, so we can call one `counter1` and the other `counter2`. We can prefix the actions to become `counter1.inc` and `counter2.inc`, etc. But defining a reducer for each counter gets a *bit* repetitive...

    counter1_reducer = (state=0, action) ->
        amount = action.amount
        amount = 1 if not amount?
        switch action.type
            when 'counter1.inc'
                return state + amount
            when 'counter1.dec'
                return state - amount
        return state # Fallback

    counter2_reducer = (state=0, action) ->
        amount = action.amount
        amount = 1 if not amount?
        switch action.type
            when 'counter2.inc'
                return state + amount
            when 'counter2.dec'
                return state - amount
        return state # Fallback

Is there a better way? Always. We can create a counter reducer "factory", a higher-level function that returns a reducer function.

    create_counter_reducer = (counter_name) -> (state=0, action) ->
        amount = action.amount
        amount = 1 if not amount?
        switch action.type
            when "#{counter_name}.inc"
                return state + amount
            when "#{counter_name}.dec"
                return state - amount
        return state # Fallback

This is a function that returns a reducer function in the standard shape. The `counter_name` argument will be used as a prefix to namespace the actions and thus avoid collisions. Now we can easily add counter reducers as the client gets ever more feature-hungry.

    {combineReducers} = require 'redux'

    counter1_reducer = create_counter_reducer 'counter1'
    counter2_reducer = create_counter_reducer 'counter2'

    combined_reducer = combineReducers {
        counter1: counter1_reducer
        counter2: counter2_reducer
    }

    state = {
        counter1: 5
        counter2: 10
    }
    console.log 'initial state =', state
    # initial state = { counter1: 5, counter2: 10 }

    state = combined_reducer(state, {type: 'counter1.inc'})
    console.log 'state =', state
    # state = { counter1: 6, counter2: 10 }

## Creating a higher-level collection reducer

We can use the same technique to create a CRUD collection reducer factory. This one will also include an argument to set which key will be used as the ID, to support cases like MongoDB's `_id`.

    update = require 'immutability-helper'

    create_collection_reducer = (collection_name, id_key='id') -> (state={}, action) ->
        switch action.type
            when "#{collection_name}.create"
                created = {}
                created[action.create[id_key]] = action.create
                return Object.assign {}, state, created
            when "#{collection_name}.update"
                updated = {}
                updated[action[id_key]] = update state[action[id_key]], action.update
                return Object.assign {}, state, updated
            when "#{collection_name}.delete"
                new_state = Object.assign {}, state
                delete new_state[action[id_key]]
                return new_state
        return state # Fallback

And use it to manage multiple collections:

    tweets_reducer = create_collection_reducer 'tweets'
    users_reducer = create_collection_reducer 'users', 'username'

    combined_reducer = combineReducers {
        users: users_reducer
        tweets: tweets_reducer
    }

    state = {
        users: {
            joe: {
                username: 'joe'
                name: 'Joe Jones'
            }
        }
        tweets: {}
    }

    state = combined_reducer state, {type: 'users.update', username: 'joe', update: {$merge: {age: 52}}}
    console.log 'state.users.joe =', state.users.joe
    # state.users.joe = { username: 'joe', name: 'Joe Jones', age: 52 }

    state = combined_reducer state, {type: 'tweets.create', create: {id: 'asdf', body: 'so tweet', user_username: 'joe'}}
    console.log 'state.tweets =', state.tweets
    # state.tweets = { asdf: { id: 'asdf', body: 'so tweet', user_username: 'joe' } }

---

**Next:** [](5-.litcoffee)
