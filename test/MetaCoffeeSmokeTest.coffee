{
  sequence
  assign
  call
  lambda
  property
  hash
  array
  condition
  comment
} = require '../src/MetaCoffee'

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