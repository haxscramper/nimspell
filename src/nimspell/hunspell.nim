import hmisc/other/oswrap
import std/macros

static:
  let deps = getMissingDependencies({
    DistributionDebianDerivatives : @[
      "hunspell",
      "libhunspell-dev"
    ],
    { Distribution.ArchLinux } : @[ "hunspell" ]
  })


  if deps.len > 0:
    for (pkg, cmd) in deps:
      error "\n\nMissing package '" & pkg & "', install it using '" &
        cmd & "'\n"

{.pragma: cstruct, importc, incompleteStruct,
  header: "<hunspell/hunspell.h>".}

{.pragma: cproc, importc, cdecl,
  header: "<hunspell/hunspell.h>".}

import annotations

type
  Hunhandle {.cstruct.} = object


proc Hunspell_create(affpath: cstring; dpath: cstring): ptr Hunhandle {.cproc.}
proc Hunspell_create_key(affpath: cstring; dpath: cstring; key: cstring): ptr Hunhandle {.cproc.}
proc Hunspell_destroy(pHunspell: ptr Hunhandle) {.cproc.}
  ##  load extra dictionaries (only dic files)
  ##  output: 0 = additional dictionary slots available, 1 = slots are now
  ##  full

proc Hunspell_add_dic(pHunspell: ptr Hunhandle; dpath: cstring): cint {.cproc.}
##  spell(word) - spellcheck word
##  output: 0 = bad word, not 0 = good word
##

proc Hunspell_spell(pHunspell: ptr Hunhandle; a2: cstring): cint {.cproc.}
proc Hunspell_get_dic_encoding(pHunspell: ptr Hunhandle): cstring {.cproc.}
##  suggest(suggestions, word) - search suggestions
##  input: pointer to an array of strings pointer and the (bad) word
##    array of strings pointer (here *slst) may not be initialized
##  output: number of suggestions in string array, and suggestions in
##    a newly allocated array of strings (*slts will be NULL when number
##    of suggestion equals 0.)
##

proc Hunspell_suggest(pHunspell: ptr Hunhandle; slst: ptr cstringArray; word: cstring): cint {.cproc.}
##  morphological functions
##  analyze(result, word) - morphological analysis of the word

proc Hunspell_analyze(pHunspell: ptr Hunhandle; slst: ptr cstringArray; word: cstring): cint {.cproc.}
##  stem(result, word) - stemmer function

proc Hunspell_stem(pHunspell: ptr Hunhandle; slst: ptr cstringArray; word: cstring): cint {.cproc.}
##  stem(result, analysis, n) - get stems from a morph. analysis
##  example:
##  char ** result, result2;
##  int n1 = Hunspell_analyze(result, "words");
##  int n2 = Hunspell_stem2(result2, result, n1);
##

proc Hunspell_stem2(pHunspell: ptr Hunhandle; slst: ptr cstringArray;
                    desc: cstringArray; n: cint): cint {.cproc.}
##  generate(result, word, word2) - morphological generation by example(s)
##

proc Hunspell_generate(pHunspell: ptr Hunhandle; slst: ptr cstringArray;
                       word: cstring; word2: cstring): cint {.cproc.}
##  generate(result, word, desc, n) - generation by morph. description(s)
##  example:
##  char ** result;
##  char * affix = "is:plural"; // description depends from dictionaries,
##  too int n = Hunspell_generate2(result, "word", &affix, 1); for (int i =
##  0; i < n; i++) printf("%s\n", result[i]);
##

proc Hunspell_generate2(pHunspell: ptr Hunhandle; slst: ptr cstringArray;
                        word: cstring; desc: cstringArray; n: cint): cint {.cproc.}
##  functions for run-time modification of the dictionary
##  add word to the run-time dictionary

proc Hunspell_add(pHunspell: ptr Hunhandle; word: cstring): cint {.cproc.}
##  add word to the run-time dictionary with affix flags of
##  the example (a dictionary word): Hunspell will recognize
##  affixed forms of the new word, too.
##

proc Hunspell_add_with_affix(pHunspell: ptr Hunhandle; word: cstring;
                             example: cstring): cint {.cproc.}
##  remove word from the run-time dictionary

proc Hunspell_remove(pHunspell: ptr Hunhandle; word: cstring): cint {.cproc.}
##  free suggestion lists

proc Hunspell_free_list(pHunspell: ptr Hunhandle; slst: ptr cstringArray; n: cint) {.cproc.}

import hmisc/other/oswrap
import hmisc/types/langcodes


type
  HunSpell* = object
    handle: ptr HunHandle

proc `=destroy`*(dic: var HunSpell): void =
  Hunspell_destroy(dic.handle)


proc initHunSpell*(affpath, dictpath: FsFile): HunSpell =
  result.handle = HunspellCreate(
    affpath.getStr().cstring,
    dictpath.getStr().cstring
  )

proc initHunSpell*(
  lc: LanguageCode, cc: CountryCode = ccNone,
  dictSuffix: string = ""): HunSpell =

  var file = "/usr/share/hunspell/" &
    lc.toTwoLetterCode()

  if cc != ccNone:
    file &= "_" & cc.toTwoLetterCode()

  file &= dictSuffix

  return initHunSpell(
    AbsFile(file & ".aff"),
    AbsFile(file & ".dic")
  )

proc isCorrectlySpelled*(hs: HunSpell, word: string): bool =
  Hunspell_spell(hs.handle, word.cstring) != 0


proc getSuggestions*(hs: HunSpell, word: string): seq[string] =
  var suggestions: cstringArray
  let sugCount = Hunspell_suggest(hs.handle, addr suggestions, word.cstring)
  for i in 0 ..< sugCount:
    result.add $suggestions[i]


proc markTypos*(buf: var seq[AnnotatedWord], ph: HunSpell) =
  for word in mitems(buf):
    if word.kind == wkText:
      if not ph.isCorrectlySpelled(word.text):
        let sug = getSuggestions(ph, word.text)
        word.attr = initAnnotation(sug)
