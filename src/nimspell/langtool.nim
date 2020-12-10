import hmisc/other/[hshell, oswrap, hjson]
import hmisc/types/[hmap, hprimitives]
import std/[parseutils, strutils]
import annotations
# import hpprint

type
  Langtool* = object
    jarfile: AbsFile

  Software = object
    name: string
    version: string
    buildDate: string
    apiVersion: int
    premium: bool
    premiumHint: string
    status: string

  Warnings = object
    incompleteResults: bool

  Language = object
    name: string
    code: string
    detectedLanguage: tuple[
      name: string,
      code: string,
      confidence: float
    ]

  Rule = object
    id: string
    description: string
    issueType: string
    category: tuple[id: string, name: string]

  Message = object
    message: string
    shortMessage: string
    replacements: seq[tuple[value: string]]
    offset: int
    length: int
    context: tuple[
      text: string,
      offset: int,
      length: int
    ]

    sentence: string
    `type`: tuple[typeName: string]
    rule: Rule
    ignoreForIncompleteSentence: bool
    contextForSureMatch: int

  LangtoolResponse = object
    software: Software
    warnings: Warnings
    language: Language
    matches: seq[Message]

proc initLangTool*(jarfile: FsFile): LangTool =
  jarfile.assertExists()
  Langtool(
    jarfile: jarfile.toAbsFile()
  )

func `<`(lhs, rhs: ArrRange): bool = leCmpPositions(lhs, rhs)

proc markLangtool*(buf: var seq[AnnotatedWord], langtool: Langtool) =
  var
    rangeMap =  initMap[ArrRange, int]()
    intext: string
    start = 0

  for idx, word in buf:
    if idx > 0 and
       (buf[idx].kind, buf[idx - 1].kind) ==
       (wkSpace, wkSpace):
      discard
    elif word.kind in {wkMarkup}:
      discard
    else:
      let slice = toArrRange(start, (start + word.text.len - 1))
      rangeMap[slice] = idx
      start += word.text.len
      intext &= word.text

  var cmd = shCmd(java, -jar)
  cmd.arg langtool.jarfile
  cmd.raw "--json"
  cmd.raw "--language en-US"
  cmd.raw "-"

  # echo intext
  let (sout, serr, code) = runShell(cmd, stdin = intext)
  let parsed = sout.parseJson()
  let data = parsed.to(LangtoolResponse)
  for msg in data.matches:
    # pprint msg
    var last: int = 0
    for key, val in rangeMap:
      if key in msg.offset ..< (msg.offset + msg.length):
        buf[val].attr = initLangtoolAnnotation("")
        # echo key, " ", buf[val]
        last = val

    buf[last].attr = initLangtoolAnnotation(msg.message)
