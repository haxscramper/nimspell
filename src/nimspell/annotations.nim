import hmisc/algo/htext_algo

export htext_algo

type
  WAnnotationKind* = enum
    wakNone
    wakSpelling
    wakStyle

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

  AnnotatedWord* = TextWord[WAnnotation]

func initAnnotation*(styleKind: WStyleKind): WAnnotation =
  WAnnotation(kind: wakStyle, styleError: styleKind)

func initAnnotation*(corrections: seq[string]): WAnnotation =
  WAnnotation(kind: wakSpelling, replacements: corrections)

func `$`*[T](text: seq[TextWord[T]]): string =
  for idx, word in text:
    if idx > 0 and
       (text[idx].kind, text[idx - 1].kind) ==
       (wkSpace, wkSpace):
      discard
    else:
      result &= $word
