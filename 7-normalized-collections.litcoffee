# 7. Working with Normalized Collections


The official Redux docs [suggest normalizing all related objects](http://redux.js.org/docs/recipes/reducers/NormalizingStateShape.html) into flat ID-referenced collections. This simplifies collection reducers and prevents data duplication.

Consider a task app with comments on tasks. When adding a comment to a task, in the un-normalized case, you might consider using the `update` actions seen before &mdash; immutability-helper would make a `$push` on `task.comments` easy enough. However this would be building complexity directly into the actions. Plus a specific nested data model might make it harder to use the comments directly, to add something like a "recent comments" sidebar later. A regular `create` action on a comments collection is conceptually simple and flexible &mdash; especially when considering data coming from external sources like a websocket.

Data de-duplication is another advantage. For example if each comment has a user attached, you can avoid holding multiple identical copies of a user that has made several comments. If the user has some non-static attribute, say they could change their username in real time, it makes the advantage more obvious.

## State and Store

This app will be a basic task manager with nested tasks and comments on tasks, and users associated with comments.

    React = require 'preact'
    React.__spread = Object.assign
    {combineReducers, createStore} = require 'redux'

The initial state gives a good picture of the app's shape, with flat collections of tasks, comments, and users. Plain objects are also used to describe the current page (a first glimpse of using Redux state for navigation) and new task and comment forms.

    initial_state =
        page:
            name: 'tasks'

        tasks:
            0:
                id: '0'
                status: 'in progress'
                title: 'Fix the heebgobbler'
            1:
                id: '1'
                status: 'todo'
                title: 'Check the joining gasket'
                description: 'Make sure it still joins'
                parent_id: '0'
            2:
                id: '2'
                status: 'done'
                title: 'Reposition the internal grimble marker'
                description: 'The marker has veered leftward'
                parent_id: '0'

        comments:
            0:
                id: '0'
                task_id: '1'
                user_id: '0'
                body: 'idk what that means'
            1:
                id: '1'
                task_id: '1'
                user_id: '0'
                body: 'jk i looked it up'
            2:
                id: '2'
                task_id: '0'
                user_id: '1'
                body: 'ok'
            3:
                id: '3'
                task_id: '1'
                user_id: '1'
                body: 'i think this is working pretty well'

        users:
            0:
                id: '0'
                name: 'Joe Jones'
            1:
                id: '1'
                name: 'Konrad Pavlov'

        new_task:
            status: 'todo'
            title: ''
            description: ''

        new_comment:
            body: ''

We will use two reducer factories. The first is for managing a collection of items, with only a `create` action:

    nextId = (ids) ->
        if ids.length
            Math.max(ids...) + 1
        else
            0

    create_collection_reducer = (collection_name) -> (state={}, action) ->
        switch action.type
            when "#{collection_name}.create"
                item_id = nextId(Object.keys(state))
                created = {}
                created[item_id] = Object.assign action.item, {id: item_id}
                return Object.assign {}, state, created
        return state

And for updating a single object, using only an `update` action:

    create_object_reducer = (object_name) -> (state={}, action) ->
        switch action.type
            when "#{object_name}.update"
                return Object.assign {}, state, action.value
        return state

The overall reducer is a combination of these reducers, and the Store is created from there.

    combined_reducer = combineReducers
        page: create_object_reducer 'page'
        tasks: create_collection_reducer 'tasks'
        comments: create_collection_reducer 'comments'
        new_task: create_object_reducer 'new_task'
        new_comment: create_object_reducer 'new_comment'

    store = createStore combined_reducer, initial_state

## Collection helpers

We will want helper functions later to filter collections (working the same as an array filter) and attach items from one collection to another. They'll be built into this `Collection` object to be consistent with `Object.*` and `Array.*` methods.

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

## Item components

These are simple stateless components for displaying lists and summaries of tasks and comments.

    Tasks = ({tasks}) ->
        <div className='tasks'>
            {Object.entries(tasks).map ([task_id, task]) ->
                <Task key=task_id task=task />
            }
        </div>

    Comments = ({comments}) ->
        <div className='comments'>
            {Object.entries(comments).map ([comment_id, comment]) ->
                <Comment key=comment_id comment=comment />
            }
        </div>

The `page.name` attribute of the state is used by the App component to choose whether to show the tasks list page or a specific task page. To navigate we can dispatch a `page.update` action, changing the page name and other context. We'll look more at this [in the next section](8-navigation.litcoffee).

    Task = ({task}) ->
        openTask = ->
            store.dispatch {type: 'page.update', value: {name: 'task', task_id: task.id}}

        <div className='task'>
            <h3 className='title'>
                <span className='status'>{task.status}</span>
                <a onClick=openTask>{task.title}</a>
            </h3>
            <span className='description'>{task.description}</span>
        </div>

    Comment = ({comment}) ->
        <div className='comment'>
            <span className='user'>{comment.user.name}</span>
            {comment.body}
        </div>

# New Item Components

Components for creating a new task and comment are responsible for dispatching `update` actions as the new item changes, and `create` action when the new item is complete.

    NewTask = ({new_task}) ->
        createTask = (e) ->
            e.preventDefault()
            store.dispatch {type: 'tasks.create', item: new_task}
            store.dispatch {type: 'new_task.update', value: {status: 'todo', title: '', description: ''}}

        change = (key) -> (e) ->
            changed = {}
            changed[key] = e.target.value
            store.dispatch {type: 'new_task.update', value: changed}

        <form onSubmit=createTask>
            <h4>New task</h4>
            <input value=new_task.status onInput={change('status')} placeholder='status' />
            <input value=new_task.title onInput={change('title')} placeholder='title' />
            <input value=new_task.description onInput={change('description')} placeholder='description' />
            <button>Create</button>
        </form>

    NewComment = ({task_id, new_comment}) ->
        createComment = (e) ->
            e.preventDefault()
            new_comment.user_id = '0'
            new_comment.task_id = task_id
            store.dispatch {type: 'comments.create', item: new_comment}
            store.dispatch {type: 'new_comment.update', value: {body: ''}}

        changeInput = (e) ->
            body = e.target.value
            store.dispatch {type: 'new_comment.update', value: {body}}

        <form onSubmit=createComment>
            <h4>New comment</h4>
            <input value=new_comment.body onInput=changeInput />
            <button>Create</button>
        </form>

## Page Components

Each page is passed the full app state by the App component, to avoid spreading logic around. Simpler pages need only pull state for the specific components.

    TasksPage = (state) ->
        <div id='tasks-page'>
            <h2>All tasks</h2>
            <Tasks tasks=state.tasks />
            <NewTask new_task=state.new_task />
        </div>

A more involved page like the TaskPage can make use of the Collection helper functions, e.g. to filter comments from the full comments collection to those relevant to this task.

    TaskPage = (state) ->
        goBack = -> store.dispatch {type: 'page.update', value: {name: 'tasks'}}

        task_id = state.page.task_id
        task = state.tasks[task_id]
        comments = Collection.filter state.comments, (comment) ->
            comment.task_id == task_id
        comments = Collection.attach comments, state.users, 'user_id', 'user'
        sub_tasks = Collection.filter state.tasks, (task) ->
            task.parent_id == task_id

        <div id='task-page'>
            <a onClick=goBack>&laquo; All tasks</a>
            <div className='row'>
                <div className='col two-thirds'>
                    <h2>Task</h2>
                    <Task task=task />
                    <Comments comments=comments />
                    <NewComment task_id=task.id new_comment=state.new_comment />
                </div>
                <div className='col one-third'>
                    {if task.parent_id
                        parent_task = state.tasks[task.parent_id]
                        <div className='sub-tasks'>
                            <h2>Parent task</h2>
                            <Task task=parent_task />
                        </div>
                    }
                    {if Object.keys(sub_tasks).length
                        <div className='sub-tasks'>
                            <h2>Sub tasks</h2>
                            <Tasks tasks=sub_tasks />
                        </div>
                    }
                </div>
            </div>
        </div>

## App Component

Again the App is the only stateful component, subscribing to state changes from the Store. The app uses the spread operator to pass all state values down to the pages.

    class App extends React.Component
        constructor: ->
            @state = store.getState()
            store.subscribe =>
                @setState store.getState()

        render: ->
            <div className='app'>
                {if @state.page.name == 'tasks'
                    <TasksPage {...@state} />
                else if @state.page.name == 'task'
                    <TaskPage {...@state} />
                }
            </div>

    React.render <App />, document.body

---

**Next:** [Using Redux for Navigation](8-navigation.litcoffee)
