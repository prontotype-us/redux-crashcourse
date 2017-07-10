# 3. Building a Collection Reducer

Counters and standalone objects are fine demos to understand the basics of reducers, but they don't represent the shape of data in a real web application. What we're usually working with is a collection of items that can be [created, read, updated, and deleted](https://en.wikipedia.org/wiki/Create,_read,_update_and_delete).

## Indexing by ID

In [part one](1-basic-reducers.litcoffee) there was an array reducer example, adding and removing tweets from a list. The problem with array reducers, as that demo began to demonstrate, is the extra complexity of matching an object every time you want to remove or update it &mdash; `O(N)` for the computer scientists out there. Since we usually have a set of objects with an ID, better practice is to index by those IDs for `O(1)` lookup. In other words:

    tweets = {
        a: {id: 'a', body: 'im twiting'}
        b: {id: 'b', body: 'im still twiting lol'}
    }

## A CRUDdy collection reducer

Operating on an indexed collection is fairly simple if we have flat objects (none of the attributes are objects). We'll create three actions to `create`, `update`, and `delete` items in the collection (we don't need a `read` action because we can just read directly from the state). The update and delete actions will use an `id` attribute to specify the item.

    tweets_reducer = (state, action) ->
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

Now we can use this reducer on the collection:

    console.log 'initial state =', tweets
    # initial state = { a: { id: 'a', body: 'im twiting' },
    #   b: { id: 'b', body: 'im still twiting lol' } }

    tweets = tweets_reducer tweets, {type: 'create', create: {id: 'c', body: 'here i go again'}}
    tweets = tweets_reducer tweets, {type: 'update', id: 'a', update: {body: 'changed it'}}
    tweets = tweets_reducer tweets, {type: 'delete', id: 'b'}

    console.log 'state =', tweets
    # state = { a: { id: 'a', body: 'changed it' },
    #   c: { id: 'c', body: 'here i go again' } }

## Using `immutability-helper`

...

---

**Next:** [Higher-level Reducers](4-higher-level-reducers.litcoffee)
