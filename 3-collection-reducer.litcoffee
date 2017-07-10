# 3. Building a Collection Reducer

Counters and standalone objects are fine demos to understand the basics of reducers, but they don't represent the shape of data in a real web application. What we're usually working with is a collection of items that can be [created, read, updated, and deleted](https://en.wikipedia.org/wiki/Create,_read,_update_and_delete).

## Indexing by ID

In [part one](1-basic-reducers.litcoffee) there was an array reducer example, adding and removing tweets from a list. The problem with array reducers, as that demo began to demonstrate, is the extra complexity of matching an object every time you want to remove or update it &mdash; `O(N)` for the computer scientists out there. Since we usually have a set of objects with an ID, better practice is to index by those IDs for `O(1)` lookup. In other words:

    tweets = {
        a: {id: 'a', body: 'im twiting'}
        b: {id: 'b', body: 'im still twiting lol'}
    }

## A CRUDdy collection reducer

Operating on an indexed collection is fairly simple if we have flat objects (none of the attributes are objects). We'll create three actions to `create`, `update`, and `delete` items in the collection (we don't need a `read` action because we can just read directly from the state). The update and delete actions will use an `id` attribute to specify which item to act on.

    crud_reducer = (state, action) ->
        switch action.type
            when 'create'
                created = {}
                created[action.create.id] = action.create
                return Object.assign {}, state, created
            when 'update'
                updated = {}
                updated[action.id] = Object.assign {}, state[action.id], action.update
                return Object.assign {}, state, updated
            when 'delete'
                new_state = Object.assign {}, state
                delete new_state[action.id]
                return new_state
        return state # Fallback

Now we can try this reducer on the collection:

    console.log 'initial tweets =', tweets
    # initial tweets = { a: { id: 'a', body: 'im twiting' },
    #   b: { id: 'b', body: 'im still twiting lol' } }

    tweets = crud_reducer tweets, {type: 'create', create: {id: 'c', body: 'here i go again'}}
    tweets = crud_reducer tweets, {type: 'update', id: 'a', update: {body: 'changed it'}}
    tweets = crud_reducer tweets, {type: 'delete', id: 'b'}

    console.log 'tweets =', tweets
    # tweets = { a: { id: 'a', body: 'changed it' },
    #   c: { id: 'c', body: 'here i go again' } }

## Using `immutability-helper`

Note what happens if we try to naively update a nested object attribute...

    tweets = crud_reducer tweets, {type: 'update', id: 'c', update: {user: {name: "Jones"}}}
    console.log 'tweets =', tweets
    # tweets = { a: { id: 'a', body: 'changed it' },
    #   c: { id: 'c', body: 'here i go again', user: { name: 'Jones' } } }

    tweets = crud_reducer tweets, {type: 'update', id: 'c', update: {user: {age: 55}}}
    console.log 'tweets =', tweets
    # tweets = { a: { id: 'a', body: 'changed it' },
    #   c: { id: 'c', body: 'here i go again', user: { age: 55 } } }

The entire object is replaced. It would be possible to write a reducer that handles such arbitrarily nested attributes in a properly immutable way - possible but complex. Maybe someone wrote a library to help us? Maybe you guessed from the title of this section. Mr. Kolodny wrote [immutability-helper](https://github.com/kolodny/immutability-helper), a library for immutable updates with a MongoDB-like syntax. We'll import this as `update`:

    update = require 'immutability-helper'

This library offers commands such as `$push`, `$set`, `$unset`, and `$merge`, acting almost the same as their MongoDB equivalents.

The `update` function takes the existing object and a "command" object that reflects the shape of the existing object and includes one or more of the above command keywords. An important difference from MongoDB is that the `$set` command does a full replace of the given value, while `$merge` does what you actually want.

We'll start with a single tweet object:

    tweet = {user: {name: 'Joe Jones'}, body: 'me tweet good'}
    console.log 'tweet =', tweet
    # tweet = { user: { name: 'Joe Jones' }, body: 'me tweet good' }

### Using `$merge`

To update an attribute on the root tweet object, the update argument will be in the form `{$merge: value}`:

    tweet = update tweet, {$merge: {body: 'I tweet well.'}}
    console.log 'tweet =', tweet
    # tweet = { user: { name: 'Joe Jones' }, body: 'I tweet well.' }

To update a nested attribute, the update argument will be `{key: {$merge: value}}`:

    tweet = update tweet, {user: {$merge: {age: 55}}}
    console.log 'tweet =', tweet
    # tweet = { user: { name: 'Joe Jones', age: 55 }, body: 'I tweet well.' }

### Using `$unset`

To remove an attribute, use `$unset` with an array of keys to remove:

    tweet = update tweet, {user: {$unset: ['age']}}
    console.log 'tweet =', tweet
    # tweet = { user: { name: 'Joe Jones' }, body: 'I tweet well.' }

### Using `$push` and `$splice`

We can also look at the `$push` and `$splice` operations for manipulating arrays. There's another important difference from MongoDB: these only work if the requested value already exists as an array. So first we'll use `$set` to add an empty array, for demonstration purposes.

    tweet = update tweet, {user: {$merge: {colors: []}}}
    tweet = update tweet, {user: {colors: {$push: ['red', 'blue']}}}
    console.log 'tweet =', tweet
    # tweet = { user: { name: 'Joe Jones', colors: [ 'red', 'blue' ] }, body: 'I tweet well.' }

`$splice` takes an array of array arguments, in case you want to do multiple splices at once:

    tweet = update tweet, {user: {colors: {$splice: [[0, 1]]}}}
    console.log 'tweet =', tweet
    # tweet = { user: { name: 'Joe Jones', colors: [ 'blue' ] }, body: 'I tweet well.' }

## A more robust CRUD reducer

You might (should) notice that this immutability-helper `update` function is the same general shape as the reducers we've been using. We can easily replace our CRUD reducer's `update` action with this function to support any kind of update.

    crud_reducer = (state, action) ->
        switch action.type
            when 'create'
                created = {}
                created[action.create.id] = action.create
                return Object.assign {}, state, created
            when 'update'
                updated = {}
                updated[action.id] = update state[action.id], action.update
                return Object.assign {}, state, updated
            when 'delete'
                new_state = Object.assign {}, state
                delete new_state[action.id]
                return new_state
        return state # Fallback

Now we'll need to use immutability-helper commands like `$merge` when using an `update` action:

    tweets = {
        a: {id: 'a', body: 'im twiting', user: {username: 'jones22'}}
        b: {id: 'b', body: 'me too', user: {username: 'fred33'}}
    }

    console.log 'initial tweets =', tweets
    # initial tweets = {
    #   a:
    #    { id: 'a',
    #      body: 'im twiting',
    #      user: { username: 'jones22' } },
    #   b:
    #    { id: 'b',
    #      body: 'me too',
    #      user: { username: 'fred33' } } }

    tweets = crud_reducer tweets, {type: 'update', id: 'a', update: {user: {$merge: {bio: 'i like eggs'}}}}
    console.log 'tweets =', tweets
    # tweets = {
    #   a:
    #    { id: 'a',
    #      body: 'im twiting',
    #      user: { username: 'jones22', bio: 'i like eggs' } },
    #   b:
    #    { id: 'b',
    #      body: 'me too',
    #      user: { username: 'fred33' } } }

---

**Next:** [Higher-level Reducers](4-higher-level-reducers.litcoffee)
