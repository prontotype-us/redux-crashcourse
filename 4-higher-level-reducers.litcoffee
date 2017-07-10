# 3. Higher-level Reducers

Consider the `counter_reducer` from the last two parts. It works nicely if our application has just one counter. But as soon as the client expands the scope of the counter app and we need another counter on the page, there's an big problem: the `inc` action will be ambiguous.

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



---

**Next:** [](5-.litcoffee)
