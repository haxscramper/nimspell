import unittest

import hmisc/other/oswrap
import hmisc/types/langcodes
import nimspell/[writegood, annotations, hunspell, langtool]

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

  test "Langtool":
    if not exists($$CI):
      let text = "This fnction should copy the complete state of " &
        "your scanner into a given byte buffer,and return the number " &
        "of bytes written. "

      var words = splitText[WAnnotation](text)
      let langt = initLangTool(
        ~".config/hax-software/langtool" /.
        "languagetool-commandline.jar"
      )

      markLangtool(words, langt)

      echo words.highlightSuggestions()
