# 1. Basic reducers

The main point of Redux is implementing a Flux-like unidirectional data flow using "reducers", functions that update a state given an action. The goal is to store the *entire state of your app in a single object*.

Reducers have a common shape:

    reducer = (state, action) ->
        return state

They take a state and an action, and return an updated state. The state is a plain Javascript value, likely an object or array, but could be a number, boolean, etc. The action is a plain object, usually with a `type` key and some associated data.

## The simplest reducer

To demonstrate how a reducer can be used to modify a state, we will keep track of a single number state with a `counter` reducer.

    counter_reducer = (state, action) ->
        amount = action.amount
        amount = 1 if not amount?
        switch action.type
            when 'inc'
                return state + amount
            when 'dec'
                return state - amount
            when 'reset'
                return 0
        return state

This reducer supports three actions: `inc`, `dec`, or `reset`. The `inc` and `dec` actions can also make use of an optional `amount` parameter, which will be 1 by default. In case none of the actions are relevant, the current state is returned (this is important to consider when we start combining reducers).

To use this reducer we define an initial state, and apply the `counter` reducer with an action to change it.

    counter_state = 0
    console.log 'initial counter state =', counter_state
    # initial counter state = 0

    counter_state = counter_reducer(counter_state, {type: 'inc'})
    console.log 'counter state =', counter_state
    # counter state = 1

    counter_state = counter_reducer(counter_state, {type: 'dec', amount: 3})
    console.log 'counter state =', counter_state
    # counter state = -2

## Object reducers

Usually our app state consists of something more complicated than a single integer value. This isn't much more complicated, but...

    user_reducer = (state, action) ->
        switch action.type
            when 'setUsername'
                return Object.assign {}, state, {username: action.username}
            when 'setName'
                return Object.assign {}, state, {name: action.name}
            when 'setAge'
                return Object.assign {}, state, {age: action.age}
        return state

Like before we start with an initial state (this time an object) and 

    user_state = {
        name: null
        username: null
        age: null
    }
    console.log 'initial user state =', user_state
    # initial user state = { name: null, username: null, age: null }

    user_state = user_reducer(user_state, {type: 'setName', name: 'Jones'})
    user_state = user_reducer(user_state, {type: 'setAge', age: 55})
    console.log 'user state =', user_state
    # user state = { name: 'Jones', username: null, age: 55 }

### Note on mutability

When working with reducers, especially with Objects, you should be very aware that reducers **should not directly modify the state** - they must always return a new state, or the same state. The main reason is to avoid ghost state bugs. There are also "time travelling" features that the Redux developer tools offer (for debugging a history of actions), and mutating the state breaks those. Keeping an accurate state history also makes "undo" features possible.

When reducing objects mutation is usually avoided with `Object.assign {}, ...` to assign existing properties to a new object. Be sure to think about deeper level objects when doing this, you might need something like `deepAssign` instead.

## Array reducers

    tweets_reducer = (state, action) ->
        switch action.type
            when 'addTweet'
                return state.concat [action.tweet]
            when 'removeTweet'
                tweet_ids = state.map (tweet) -> tweet.id
                tweet_index = tweet_ids.indexOf action.id
                state = state.slice(0) # Copy to avoid mutation
                state.splice(tweet_index, 1)
                return state
        return state

    tweets_state = []
    console.log 'initial tweets state =', tweets_state
    # initial tweets state = []

    tweets_state = tweets_reducer(tweets_state, {type: 'addTweet', tweet: {id: 123, body: 'im twiting'}})
    tweets_state = tweets_reducer(tweets_state, {type: 'addTweet', tweet: {id: 432, body: 'stil twiting lol'}})
    console.log 'tweets state =', tweets_state
    # tweets state = [ { id: 123, body: 'im twiting' },
    #     { id: 432, body: 'stil twiting lol' } ]

    tweets_state = tweets_reducer(tweets_state, {type: 'removeTweet', id: 123})
    console.log 'tweets state =', tweets_state
    # tweets state = [ { id: 432, body: 'stil twiting lol' } ]

Using arrays is not usually recommended - you have to build in these extra indexing operations, while it would be easier in most cases to do a direct lookup by ID. We'll dive into normalized collections with Redux some time in the future.

---

Did you notice we haven't imported any libraries yet? Most of Redux is based around this simple reducer concept, using plain functions. The Redux library itself offers helpers to make more complex reducers easier (as seen in the next episode).

**Next:** [Combining Reducers](2-combining-reducers.litcoffee)

