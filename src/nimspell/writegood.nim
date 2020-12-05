import hmisc/algo/[htext_algo, hstring_algo, halgorithm]
import hmisc/types/colorstring
import annotations
import std/[strformat, options, strutils]

export htext_algo

func markWeasels*(buf: var seq[AnnotatedWord]) =
  for word in mitems(buf):
    if word.kind == wkText:
      if word.text in [
        "many", "various", "very", "fairly", "several", "extremely",
        "exceedingly", "quite", "remarkably", "few", "surprisingly",
        "mostly", "largely", "huge", "tiny", "are a number", "is a number",
        "excellent", "interestingly", "significantly", "substantially",
        "clearly", "vast", "relatively", "completely",
      ]:
        word.attr = initAnnotation(wskWeaselWord)

func markPassives*(buf: var seq[AnnotatedWord]) =
  for idx, word in mpairs(buf):
    if word.kind == wkText:
      let isPassive =
        word.text[^"ed"] or
        word.text in [
          "awoken", "been", "born", "beat", "become", "begun", "bent",
          "beset", "bet", "bid", "bidden", "bound", "bitten", "bled",
          "blown", "broken", "bred", "brought", "broadcast", "built",
          "burnt", "burst", "bought", "cast", "caught", "chosen", "clung",
          "come", "cost", "crept", "cut", "dealt", "dug", "dived", "done",
          "drawn", "dreamt", "driven", "drunk", "eaten", "fallen", "fed",
          "felt", "fought", "found", "fit", "fled", "flung", "flown",
          "forbidden", "forgotten", "foregone", "forgiven", "forsaken",
          "frozen", "gotten", "given", "gone", "ground", "grown", "hung",
          "heard", "hidden", "hit", "held", "hurt", "kept", "knelt", "knit",
          "known", "laid", "led", "leapt", "learnt", "left", "lent", "let",
          "lain", "lighted", "lost", "made", "meant", "met", "misspelt",
          "mistaken", "mown", "overcome", "overdone", "overtaken",
          "overthrown", "paid", "pled", "proven", "put", "quit", "read",
          "rid", "ridden", "rung", "risen", "run", "sawn", "said", "seen",
          "sought", "sold", "sent", "set", "sewn", "shaken", "shaven",
          "shorn", "shed", "shone", "shod", "shot", "shown", "shrunk",
          "shut", "sung", "sunk", "sat", "slept", "slain", "slid", "slung",
          "slit", "smitten", "sown", "spoken", "sped", "spent", "spilt",
          "spun", "spit", "split", "spread", "sprung", "stood", "stolen",
          "stuck", "stung", "stunk", "stridden", "struck", "strung",
          "striven", "sworn", "swept", "swollen", "swum", "swung", "taken",
          "taught", "torn", "told", "thought", "thrived", "thrown", "thrust",
          "trodden", "understood", "upheld", "upset", "woken", "worn",
          "woven", "wed", "wept", "wound", "won", "withheld", "withstood",
          "wrung", "written"
        ]

      if isPassive and buf.prevTextWord(idx).ifSomeIt(it.text in [
        "am", "are", "were", "being", "is", "been", "was", "be"
      ]):
        debugecho "Found passive"
        word.attr = initAnnotation(wskPassiveVoice)

func markRepetitions*(buf: var seq[AnnotatedWord]) =
  for idx, word in mpairs(buf):
    if word.kind == wkText:
      let prev = buf.prevTextWordIdx(idx)
      if prev > 0 and buf[prev].text == buf[idx].text:
        buf[prev].attr = initAnnotation(wskRepetition)
        buf[idx].attr = initAnnotation(wskRepetition)

func highlightSuggestions*(buf: seq[AnnotatedWord]): seq[TermWord] =
  for word in buf:
    var resWord = TermWord(text: word.text, kind: word.kind)
    case word.attr.kind:
      of wakNone:
        discard
      of wakStyle:
        case word.attr.styleError:
          of wskWeaselWord:
            resWord.attr = initStyle(fgRed)
          of wskPassiveVoice:
            resWord.attr = initStyle(fgYellow)
          of wskRepetition:
            resWord.attr = initStyle(fgGreen)
      of wakSpelling:
        resWord.text &= " -> [" & word.attr.replacements.join(" ") & "]"
        resWord.attr = initStyle(fgBlue)

    result.add resWord

func `$`*(w: TermWord): string = toStyled(w.text, w.attr)
