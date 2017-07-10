# 2. Combining Reducers

Redux is more of a paradigm than a library. The library consists of just a few helper functions to make this paradigm easier to implement.

One of the first things you might notice about reducers is that the functionality of a real-life application will not be satisfied by the simplistic functions we've seen so far. Perhaps we could define one monolithic reducer function, but that would easily become a tangled nest of code. We need some way to combine reducers. The aptly named `combineReducers` helper will help us.

First import the function from Redux:

    {combineReducers} = require 'redux'

We will borrow two reducers from the last segment, with one important distinction: the `state` argument defines a default value. For the counter reducer the initial state is `0`, for the user reducer `{}`. The reasoning behind this is to ensure each part of the combined state is valid.

    counter_reducer = (state=0, action) ->
        amount = action.amount
        amount = 1 if not amount?
        switch action.type
            when 'inc'
                return state + amount
            when 'dec'
                return state - amount
        return state # Fallback

    user_reducer = (state={}, action) ->
        if action.type == 'set'
            return Object.assign {}, state, action.values
        return state # Fallback

To combine the reducers into a `combined_reducer`, we call `combineReducers`. Surprised? The argument to this helper function defines the shape of the final combined state, an object with the keys we set here, and the values output by our reducers.

    combined_reducer = combineReducers {
        counter: counter_reducer
        user: user_reducer
    }

When we define the initial state it should satisfy the nested shape defined by the `combineReducers` argument:

    state = {
        counter: 1
        user: {
            name: "Josh"
            username: "itsmejosh"
            age: 22
        }
    }

    console.log 'initial state =', state
    # initial state = { counter: 1,
    #   user: { name: 'Josh', username: 'itsmejosh', age: 22 } }

And as usual we call the reducer with a state and an action to get an updated state:

    state = combined_reducer(state, {type: 'inc'})
    state = combined_reducer(state, {type: 'set', values: {username: 'omgimjosh'}})

    console.log 'state =', state
    # state = { counter: 2,
    #   user: { name: 'Josh', username: 'omgimjosh', age: 22 } }

What happens when we run this combined reducer is the action is passed through *every reducer*. This means we could do some tricky things with actions that match multiple reducers, but more likely means we should be careful with the names of our actions. Overly simple names like `inc` and `set` will easily collide as the application becomes more complex. We'll look at ways to avoid this, while avoiding some boilerplate of common reducer actions, in the next episode.

---

**Next:** [Higher-level Reducers](3-higher-level-reducers.litcoffee)
