# Array<Element> -> Array<Element> | Element | string

escapeHtml = (html) ->
  html
  .replace /&/g, '&amp;'
  .replace /</g, '&lt;'
  .replace />/g, '&gt;'
  .replace /"/g, '&quot;'

get = (key, context) ->
  key.split(/\./).reduce(((c, key) -> c[key]), context)

renderElement = (element, context) ->
  return [element] if typeof element is 'string'
  if element.attributes.some((i) -> i.name is 'b-repeat')
    return renderElements element, context
  name = element.name
  children = element.children.slice()
  attributes = []
  element.attributes.forEach (attr) ->
    switch attr.name
      when 'b-attr'
        attr.value.split(/\s*,\s*/).forEach (a) ->
          [n, v] = a.split /\s*:\s*/
          attributes.push
            name: n
            value: get v, context
      when 'b-html'
        html = get attr.value, context
        children = [html]
      when 'b-text'
        html = get attr.value, context
        text = escapeHtml html
        children = [text]
      else
        attributes.push attr
  children = children.reduce (c, child) ->
    c.concat renderElement child, context
  , []
  [{ name, attributes, children }]

renderElements = (element, context) ->
  name = element.name
  children = element.children.slice()
  attributes = element.attributes.filter (i) ->
    i.name isnt 'b-repeat'
  attr = element.attributes.filter((i) -> i.name is 'b-repeat')[0]
  match = attr.value.match /^\s*(\w+)\s*in\s*(\w+)\s*$/
  throw new Error('b-repeat:' + attr.value) unless match?
  itemName = match[1]
  list = context[match[2]]
  list.reduce (c, item) ->
    context[itemName] = item
    c.concat renderElement({ name, attributes, children }, context)
  , []

module.exports = (elements, context) ->
  elements.reduce (c, e) ->
    c.concat renderElement e, context
  , []
