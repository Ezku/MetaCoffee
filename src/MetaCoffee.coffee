indent = (amount, string) ->
  return string if !amount
  indentation = (" " for i in [0..amount-1]).join('')
  indentation + string.replace /\n/g, "\n" + indentation

nothing = ""

empty = (stringable) ->
  (not stringable?) or
    stringable.empty or
    stringable.toString().replace(/\s/g, '') is nothing

complex = (stringable) ->
  (not empty stringable) and
    (stringable.complex or
      (newlines stringable) or
      (lambdas stringable))

newlines = (stringable) ->
  stringable?.toString().match(/\n/)?

lambdas = (stringable) ->
  stringable?.toString().match(/->/)?

all = (things, predicate) ->
  for thing in things || []
    if not predicate thing
      return false
  return true

some = (things, predicate) ->
  for thing in things || []
    if predicate thing
      return true
  return false

fold = (stringable, left, right) ->
  content = if complex stringable
    left stringable
  else
    right stringable
  {
    content
    empty: (empty content)
    complex: (complex content)
    toString: -> content.toString()
  }

map = (f) -> (stringable) ->
  content = if not empty stringable
    f stringable.toString()
  else
    ""

  {
    content
    empty: (empty content)
    complex: (complex content)
    toString: -> content
  }

assign = (variable, value) ->
  value = value()
  {
    variable
    value
    empty: false
    toString: ->
      "#{variable} = #{value}"
  }

call = (target, args...) ->
  {
    target,
    args,
    empty: false
    complex: (some args, complex)
    toString: ->
      if not args.length
        target + "()"
      else if args.length is 1 and args[0].call?
        target + wrap "(", ")", trail block args[0]()
      else
        target + " " + list args
  }

block = map (content) -> "\n" + (indent 2, content.toString())
trail = map (content) -> content + "\n"
lead = map (content) -> "\n" + content
pad = map (content) -> " " + content + " "

list = (items) ->
  {
    items
    empty: (all items, empty)
    complex: (some items, complex)
    toString: ->
      items.join ", "
  }

wrap = (start, end, content) ->
  {
    start
    end
    content
    empty: (empty content)
    toString: ->
      start + content + end
  }

tuple = (values) ->
  {
    values,
    empty: (all values, empty)
    complex: false
    toString: ->
      (wrap "(", ")", list values).toString()
  }

hash = (properties...) ->
  {
    properties
    empty: (all properties, empty)
    complex: (some properties, complex)
    toString: ->
      (wrap "{", "}",
        fold properties,
          (complex) -> trail block sequence complex
          (simple) -> pad list simple
      ).toString()
  }

array = (items) ->
  {
    items
    empty: (all items, empty)
    complex: (some items, complex)
    toString: ->
      (wrap "[", "]",
        if @empty
          ""
        else
          fold items,
            (complex) -> trail block sequence complex
            (simple) -> pad list simple
      ).toString()
  }

lambda = (args..., body) ->
  body = body?() || ""
  {
    args
    body
    empty: false
    complex: (complex body)
    toString: ->
      [
        tuple args
        "->"
        do =>
          if @complex
            block body
          else
            body
      ].filter((e) -> not empty e).join ' '
  }

sequence = (statements) ->
  {
    statements
    empty: (all statements, empty)
    complex: true
    toString: ->
      (for statement in statements when not empty statement
        statement.toString()
      ).join "\n"
  }

property = (key, value) ->
  {
    key
    value
    empty: (empty value)
    complex: (complex value)
    toString: ->
      "#{key}: #{value}"
  }

comment = (content) ->
  {
    content
    empty: (empty content)
    complex: true
    toString: ->
      (fold content,
        (complex) -> wrap '###\n', '\n###', complex
        (simple) -> '# ' + simple
      ).toString()
  }

condition = (predicate, thenBranch, elseBranch) ->
  thenBranch = thenBranch?() || nothing
  elseBranch = elseBranch?() || nothing
  {
    predicate
    thenBranch
    elseBranch
    empty: (empty thenBranch) and (empty elseBranch)
    toString: ->
      ("if " + predicate.toString()) +
        (if empty thenBranch
          ""
        else
          trail block thenBranch
        ) +
      (if empty elseBranch
        ""
      else "else" + trail block elseBranch
      )
  }

console.log sequence([
  assign "foo", ->
    lambda "qux", "bar", ->
      sequence [
        property "onSuccess", lambda ->
          sequence [
            call "console.log", hash(
              property "pow", lambda -> "foobar"
            ), hash(
              property "a", "b"
            )
            call "new Foobar", ->
              sequence [
                lambda ->
                  array [
                    comment("stuff\ngoes here")
                  ]
                lambda ->
                  property "foo", lambda -> "baah"
              ]
            call "new Foobar", array [
              lambda -> comment("stuff goes here")
            ]
          ]
        property "onFailure", lambda ->
          condition "was",
            -> sequence [
              "woot"
            ]
      ]
]).toString()

module.exports = {
  sequence
  assign
  call
  lambda
  property
  hash
  array
  condition
  comment
}