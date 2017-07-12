# 8. Using Redux for Navigation

Taking "single source of truth" to the logical extreme, we should be able to represent every aspect of an application &mdash; up to the URL of the page &mdash; in the Store. Perhaps this should be expected, as the URL is usually the application's first chance to determine what to show.

This segment will implement a simple Twitter app with a few pages and nested tabs.  Taking cues from Express routing, each URL will be matched against a set of routes with parameters, e.g. `/:username/following`. A navigation reducer will parse matched paths into `route` and `params` objects.

## State and Store

    React = require 'preact'
    React.__spread = Object.assign
    {combineReducers, createStore} = require 'redux'

Note that the initial navigation state here is just to demonstrate the shape, the true value will be parsed from `window.location` a few sections down.

    initial_state =
        navigation:
            path: '/jj22'
            route:
                tab: 'tweets'
                page: 'profile'
            params:
                username: "jj22"

        tweets:
            0:
                id: '0'
                body: "look at me"
                username: 'fredy42'
            1:
                id: '1'
                body: "i ma here"
                username: 'yosef'
            2:
                id: '2'
                body: "im twitting"
                username: 'jj22'
            3:
                id: '3'
                body: "this is a tweet too"
                username: 'jj22'

        users:
            fredy42:
                id: '0'
                username: 'fredy42'
                name: 'Fred Wilson'
                following: ['yosef']
            yosef:
                id: '1'
                username: 'yosef'
                name: 'Yosefine Jones'
                following: ['fredy42']
            terrence:
                username: 'terrence'
                name: 'Terrence Rutherport'
                following: []
            jj22:
                username: 'jj22'
                name: "Joe Jones"
                following: ['terrence']

We will use two reducer factories. The first is the familiar (simplified) collection reducer:

    nextId = (ids) ->
        if ids.length
            Math.max(ids...) + 1
        else
            0

    create_collection_reducer = (collection_name, id_key='id') -> (state={}, action) ->
        switch action.type
            when "#{collection_name}.create"
                item_id = nextId(Object.keys(state))
                item = Object.assign action.item, {id: item_id}
                created = {}
                created[item[id_key]] = item
                return Object.assign {}, state, created
        return state

The last reducer is a special case to handle navigation. This reducer will match the path string given known routes, and extract `params`. The final matching `route` and `params` are used to set `state.navigation`.

    WORD_MATCH = '([\\w_-]+)'

    # Build a route path matching regex
    pathMatcher = (path) ->
        match_keys = []
        path_match = path.replace /:(\w+)/g, (full, match_key) ->
            match_keys.push match_key
            return WORD_MATCH
        path_match = '^' + path_match + '$'
        path_match = new RegExp path_match
        return [path_match, match_keys]

    # Match a route and params given a path
    matchPath = (routes, path) ->
        for route_path, route of routes
            [path_match, match_keys] = pathMatcher route_path

            if matched = path.match path_match
                # Build params from matching values from path
                params = {}
                for match_value in matched.slice(1)
                    match_key = match_keys.shift()
                    params[match_key] = match_value

                return {route, params, path}

    create_navigation_reducer = (routes) -> (state={}, action) ->
        switch action.type
            when "navigate"
                if matched = matchPath routes, action.path
                    return Object.assign {}, state, matched
        return state

The routes themselves are defined with an Express-style syntax, with the path and parameter names as a single string, and "static" route information (e.g. the name of the page) declared in an object (ending up as `state.navigation.route`).

    routes =
        '/': {page: 'home'}
        '/:username': {page: 'profile', tab: 'tweets'}
        '/:username/following': {page: 'profile', tab: 'following'}
        '/:username/followers': {page: 'profile', tab: 'followers'}

These reducers are instantiated and combined.

    combined_reducer = combineReducers
        navigation: create_navigation_reducer routes
        tweets: create_collection_reducer 'tweets'
        users: create_collection_reducer 'users', 'username'

Before creating the Store the initial navigation state will be matched from the current window hash.

    initial_state.navigation = matchPath routes, window.location.hash.slice(1)

    store = createStore combined_reducer, initial_state

An event listener is added to listen for hash changes, and perform the actual navigation. This is better than doing it directly in a Link component (defined  below) as it will support manual history changes, from the back button or from typing in the URL bar.

    window.addEventListener 'hashchange', ->
        store.dispatch {type: 'navigate', path: window.location.hash.slice(1)}

## Collection helpers

These denormalizing helpers are the same as the last lesson.

    Collection =
        filter: (collection, fn) ->
            filtered = {}
            for id, item of collection
                if fn item
                    filtered[id] = item
            return filtered

        attach: (to_collection, from_collection, from_key, to_key) ->
            attached = {}
            for id, item of to_collection
                attachment = {}
                attachment[to_key] = from_collection[item[from_key]]
                attached[id] = Object.assign {}, item, attachment
            return attached

## Navigation helpers

A Link component starts the navigation by changing the location hash, while the hashchange event above listens and dispatches the `navigate` action.

    Link = ({to, children}) ->
        onClick = (e) ->
            e.preventDefault()
            window.location.hash = to
        <a href="##{to}" onClick=onClick>{children}</a>

## List and item components

    Tweets = ({tweets}) ->
        <div className='tweets'>
            {Object.entries(tweets).map ([tweet_id, tweet]) ->
                <Tweet tweet=tweet key=tweet_id />
            }
        </div>

    Tweet = ({tweet}) ->
        <div className='tweet'>
            <User user=tweet.user />
            <span className='body'>{tweet.body}</span>
        </div>

    Users = ({users}) ->
        <div className='users'>
            {Object.entries(users).map ([user_id, user]) ->
                <User user=user key=user_id />
            }
        </div>

    User = ({user}) ->
        <Link to="/#{user.username}">
            <strong className='name'>{user.name}</strong> <span className='username'>{user.username}</span>
        </Link>

## Page and tab components

    HomePage = ({tweets, users}) ->
        tweets = Collection.attach tweets, users, 'username', 'user'

        <div id='home-page'>
            <h2>Home</h2>
            <Tweets tweets=tweets />
        </div>

    ProfilePage = ({navigation, users, children}) ->
        user = users[navigation.params.username]

        <div id='profile-page'>
            <h2>Profile</h2>
            <User user=user />
            <ul className='tabs'>
                <li><Link to="/#{user.username}">Tweets</Link></li>
                <li><Link to="/#{user.username}/following">Following</Link></li>
                <li><Link to="/#{user.username}/followers">Followers</Link></li>
            </ul>
            {children}
        </div>

    TweetsTab = ({navigation, tweets, users}) ->
        tweets = Collection.filter tweets, (tweet) ->
            tweet.username == navigation.params.username
        tweets = Collection.attach tweets, users, 'username', 'user'

        <div id='tweets-tab'>
            <h3>Tweets</h3>
            <Tweets tweets=tweets />
        </div>

    FollowingTab = ({navigation, users}) ->
        user = users[navigation.params.username]

        following = Collection.filter users, (other_user) ->
            other_user.username in user.following

        <div id='following-tab'>
            <h3>Following</h3>
            <Users users=following />
        </div>

    FollowersTab = ({navigation, users}) ->
        user = users[navigation.params.username]

        followers = Collection.filter users, (other_user) ->
            user.username in other_user.following

        <div id='followers-tab'>
            <h3>Followers</h3>
            <Users users=followers />
        </div>

## App Component

The App component determines which pages and tabs to show from `navigation.route`, using the spread operator to pass all state values down.

    class App extends React.Component
        constructor: ->
            @state = store.getState()
            store.subscribe =>
                @setState store.getState()

        render: ->
            <div id='app'>
                {if @state.navigation.route.page == 'home'
                    <HomePage {...@state} />
                else if @state.navigation.route.page == 'profile'
                    <ProfilePage {...@state}>
                        {if @state.navigation.route.tab == 'tweets'
                            <TweetsTab {...@state} />
                        else if @state.navigation.route.tab == 'following'
                            <FollowingTab {...@state} />
                        else if @state.navigation.route.tab == 'followers'
                            <FollowersTab {...@state} />
                        }
                    </ProfilePage>
                }
            </div>

    React.render <App />, document.body

---

**Next:** [Async Data Flow](9-async-flow.litcoffee)
