import unittest

import nimspell/[writegood, annotations]

suite "Writegood":
  test "test 1":
    let text = "We offer a completely different formulation of CFA. " &
      "Termination is is guaranteed on any input."
    var words = splitText[WAnnotation](text)
    markWeasels(words)
    markPassives(words)
    markRepetitions(words)
    echo words.highlightSuggestions()
