import hmisc/algo/htext_algo
import hmisc/types/colorstring
import std/[strutils]

export htext_algo

type
  WAnnotationKind* = enum
    wakNone
    wakSpelling
    wakStyle
    wakLangtool

  WStyleKind* = enum
    wskPassiveVoice
    wskWeaselWord
    wskRepetition

  WAnnotation* = object
    case kind*: WAnnotationKind
      of wakNone:
        discard
      of wakStyle:
        styleError*: WStyleKind
      of wakSpelling:
        replacements*: seq[string]
      of wakLangtool:
        message*: string

  AnnotatedWord* = TextWord[WAnnotation]

func initAnnotation*(styleKind: WStyleKind): WAnnotation =
  WAnnotation(kind: wakStyle, styleError: styleKind)

func initAnnotation*(corrections: seq[string]): WAnnotation =
  WAnnotation(kind: wakSpelling, replacements: corrections)

func initLangtoolAnnotation*(message: string): WAnnotation =
  WAnnotation(kind: wakLangtool, message: message)


func `$`*[T](text: seq[TextWord[T]]): string =
  for idx, word in text:
    if idx > 0 and
       (text[idx].kind, text[idx - 1].kind) ==
       (wkSpace, wkSpace):
      discard
    else:
      result &= $word

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
      of wakLangtool:
        if word.attr.message.len > 0:
          resWord.text &= " ~# {" & word.attr.message & "}"

        resWord.attr = initStyle(fgMagenta)

    result.add resWord

func `$`*(w: TermWord): string = toStyled(w.text, w.attr)
