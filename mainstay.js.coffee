#= require underscore-contrib

@Mainstay ||= {}
Mainstay = @Mainstay
Mainstay.global = window # TODO nodejs global?

# Make sure we have the dependencies included
reqs = ["Backbone", "Handlebars"]
for req in reqs
  if typeof Mainstay.global[req] is 'undefined'
    throw new Error("Mainstay requires #{req}.")

# Mainstay.Util

# Mainstay.Router
# ---------------
# Extends from Backbone.Router to receive a controller instead of a callback.
# The routes unload route callback to the controller actions.
# If the controller is a string, it will be evaluated under `Mainstay.global`
# scope.
#
#     class MainRouter extends Mainstay.Router
#       routes:
#         'sales*query': SalesController
#         'deals*query': 'DealsController'
#         'pages/about': 'Pages.AboutController'
#
class Mainstay.Router extends Backbone.Router
  findController: (name, options) ->
    if _.isString(name)
      klass = _.getPath(Mainstay.global, name)
    else
      klass = name
    unless klass.prototype instanceof Mainstay.Controller
      throw new Error("Controller #{name} not found")
    klass

  route: (route, name, callback) ->
    klass = @findController(name)
    if klass
      callback = (params)-> (new klass())._run(params)
      name = klass.name

    super(route, name, callback)

# Mainstay.Controller
# ---------------
# Simple controller which defines hooks
#
#     class SalesController extends Mainstay.Controller
#       beforeAction: ->
#         # nothing
#
#       afterAction: ->
#         # nothing
#
#       action: (params) =>
#         @model = new Backbone.Model(attrs)
#
#       waitOn: ->
#         $.when(@model.fetch())
#
#       render: ->
#         $("#content").html @view.render().el
#

class Mainstay.Controller
  model: null
  collection: null
  beforeAction: null
  afterAction:  null
  action: ->
    throw new Error('action not implemented')

  # An internal method called by router which will execute the following
  # beforeAction, action, afterAction, waitOn and render
  _run: (params) =>
    @beforeAction(params) if _.isFunction(@beforeAction)
    @action(params)
    @afterAction(params) if _.isFunction(@afterAction)
    if _.isFunction(@waitOn)
      waitOn = @waitOn(params)
      # If waitOn is a promise
      if _.isFunction(waitOn.done)
        waitOn.done (data) => @render()
    else
      @render()

  findView: (name)->
    if _.isString(name)
      klass = _.getPath(Mainstay.global, name)
    else
      klass = name
    unless klass.prototype instanceof Mainstay.View
      throw new Error("View #{name} not found")
    klass

  # By default Mainstay.Controller will pick up and render the view defined
  # in viewClass. If viewClass is not defined, the controller will assume
  # a custom render method is given
  render: ->
    if @viewClass
      klass = @findView(@viewClass)
      @view = new klass(model: @model, collection: @collection)
      @view.render().el
    else
      throw new Error("@viewClass not found, custom render not implemented")

# Mainstay.Store
# ---------------
# Stores contain the application state and logic. Their role is somewhat
# similar to a model in a traditional MVC, but they manage the state of many
# objects — they are not instances of one object. Nor are they the same
# as Backbone's collections. More than simply managing a collection of
# ORM-style objects, stores manage the application state for a particular
# domain within the application.
#
#     class FoobarStore extends Mainstay.DataStore
#       data:
#         foo: "abc"
#         bar: "123"
#       events:
#         'change:foo': 'logFooChange'
#       logFooChange: -> console.log "foo has changed"
#
#     store = new RestaurantStore()
#     store.on "change:bar", -> console.log "bar has changed"
#     store.set "bar", "new value"
#
class Mainstay.DataStore extends Backbone.Events



# Mainstay.View
# ---------------
#     model = new Payment(total: 100, tax: 10)
#
#     class SalesView extends Mainstay.View
#       dataStore: new DateStore()
#       dataStoreBindings: (store)-> model.on 'change', -
#
#       events:
#         'change:foo': 'logFooChange'
#       logFooChange: -> console.log "foo has changed"
#
class Mainstay.View extends Backbone.View
  initialize: ->
    if @dataStore
      # TODO (hung) For now the view got re-rendered when store has changed
      # Furture approach should include rendering a portion of the template
      # responsible for that variable
      @dataStore.on 'change', =>
        @render()


  getTemplateVars: ->
    if @dataStore
      return @dataStore.toJSON()
    else if @model
      return @model.toJSON() if 'toJSON' of @model
      return @model
    else if @collection
      return @collection.toJSON() if 'toJSON' of @collection
      return @collection
    else
      {}

  render: (options={}) =>
    @$el.html @template(@getTemplateVars()) if @template
    @trigger('render') unless options.silent
    @

  hide: ->
    @$el.hide()



return @
