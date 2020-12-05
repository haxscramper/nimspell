import unittest

import hmisc/other/oswrap
import hmisc/types/langcodes
import nimspell/[writegood, annotations, hunspell]

{.passl: "-lhunspell".}

suite "Writegood":
  test "test 1":
    let text = "We offer a completely diffrent formulation of CFA. " &
      "Termination is is guaranteed on any input."
    var words = splitText[WAnnotation](text)
    markWeasels(words)
    markPassives(words)
    markRepetitions(words)

    let hunsp = initHunSpell(lcEnglish, ccUnitedStatesOfAmerica)

    markTypos(words, hunsp)
    echo words.highlightSuggestions()
