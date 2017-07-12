# 9. Async Data Flow

So far every action has been synchronous, which is an entirely unrealistic way to build a web app. We need to consider loading, failed loading, websocket-sourced updates, and other asynchronous pieces of state.

Redux is not async, because reducer functions are not async. That doesn't mean we can't build an async application with it &mdash; we just need to define loading, errors, etc. as pieces of our application state, and describe the data flow as an explicit series of actions.

This time we'll be building another (simpler) Twitter clone with loading and more loading (an approximation of "scroll to load more"). Loading states will be supported simply by adding `loading` and `loading_more` parameters to the collection state. The actual request and response will be represented by individual actions, `tweets.load` &rarr; `tweets.loaded`, and `tweets.load_more` &rarr; `tweets.loaded_more`.

    React = require 'preact'
    Kefir = require 'kefir'
    KefirBus = require 'kefir-bus'
    moment = require 'moment'
    React.__spread = Object.assign
    {combineReducers, createStore} = require 'redux'

## (Fake) loadable data

Insteading of introducing an API, the tweets will be generated and loading time will be faked with `Kefir.later`.

    last_id = 0
    last_time = new Date().getTime()

    letters = 'abcdefghijklmnopqrstuvwxyz'
    randomChoice = (l) -> l[Math.floor(Math.random() * l.length)]
    randomLetter = -> randomChoice letters
    randomWord = -> [0..Math.ceil(Math.random() * 10)].map(randomLetter).join('')
    randomSentence = -> [0..Math.ceil(Math.random() * 10)].map(randomWord).join(' ')

    fakeTweet = ->
        last_id += 1
        last_time -= Math.random() * 1000 * 60 * 10

        id = last_id
        time = last_time
        body = randomSentence()

        return {id, time, body}

    indexById = (l) ->
        o = {}
        for i in l
            o[i.id] = i
        return o

    loadTweets = (reload=false) ->
        if reload
            last_id = 0
            last_time = new Date().getTime()
        fake_tweets = [0...10].map fakeTweet
        fake_tweets = indexById fake_tweets
        Kefir.later Math.random() * 1000, fake_tweets

## State and Store

To fit the loading state in there's a slight departure from previous collections: the items in the collection will be contained in an explicit `items` parameter, alongside the `loading` parameter(s).

    initial_state =
        tweets:
            loading: true
            loading_more: false
            items: {}

    create_collection_reducer = (collection_name) -> (state={}, action) ->
        switch action.type
            when "#{collection_name}.load"
                return Object.assign {}, state, {loading: true}
            when "#{collection_name}.load_more"
                return Object.assign {}, state, {loading_more: true}
            when "#{collection_name}.loaded"
                return Object.assign {}, state, {loading: false, items: action.items}
            when "#{collection_name}.loaded_more"
                return Object.assign {}, state, {loading_more: false, items: Object.assign {}, state.items, action.items}
        return state

    combined_reducer = combineReducers
        tweets: create_collection_reducer 'tweets'

    store = createStore combined_reducer, initial_state

## Action streams

In order to support subscriptions to the actions themselves (rather than just resulting state changes, as `store.subscribe` offers) we'll pass all actions through a Kefir stream `actions$`. To dispatch an action from now on, we'll use `actions$.emit(action)`, and that stream will call the `store.dispatch(action)`. You'll see why in a second.

    actions$ = KefirBus()
    actions$.onValue (action) ->
        store.dispatch action

Now with a stream of actions always available, we can trigger side effects when certain actions occur. For example, we'll have a reload button to reload the tweets. That button will dispatch the `tweets.load` action, but all that does is set the collection's loading state. The actual fetch will be triggered by a response to this action:

    actions$
        .filter (action) ->
            action.type == 'tweets.load'
        .onValue ->
            loadTweets(true).onValue (tweets) ->
                actions$.emit {type: 'tweets.loaded', items: tweets}

Similarly, when loading more tweets we'll trigger the `load_more` action and `loaded_more` after:

    actions$
        .filter (action) ->
            action.type == 'tweets.load_more'
        .onValue ->
            loadTweets().onValue (tweets) ->
                actions$.emit {type: 'tweets.loaded_more', items: tweets}

## Initial load

To start things off we'll dispatch a `load` action:

    actions$.emit {type: 'tweets.load'}

## List and item components

The usual stateless greatness...

    Tweets = ({tweets}) ->
        <div className='tweets'>
            {Object.entries(tweets).map ([tweet_id, tweet]) ->
                <Tweet tweet=tweet key=tweet_id />
            }
        </div>

    Tweet = ({tweet}) ->
        <div className='tweet'>
            <span className='body'>{tweet.body}</span>
            <span className='time'>{moment(tweet.time).fromNow()}</span>
        </div>

## App Component

Since there are no other pages in this demo, the main logic is built directly into the App component.

    class App extends React.Component
        constructor: ->
            @state = store.getState()
            store.subscribe =>
                @setState store.getState()

        render: ->
            console.log '[App.render]', @state
            reload = -> actions$.emit {type: 'tweets.load'}
            loadMore = -> actions$.emit {type: 'tweets.load_more'}

            <div id='app'>
                <button onClick=reload>Reload</button>
                {if @state.tweets.loading
                    <p>Loading...</p>
                else
                    <Tweets tweets=@state.tweets.items />
                }
                {if !@state.tweets.loading
                    if @state.tweets.loading_more
                        <p>Loading more...</p>
                    else
                        <button onClick=loadMore>Load more</button>
                }
            </div>

    React.render <App />, document.body

---

**Next:** [](10-.litcoffee)
