# Working rules
Source: Anthropic "Prompting Claude Fable 5.1" guide, applied 2026-09-02. Only the blocks the Claude Code system prompt does not already carry.

## Scope of changes and tests
If, while working or testing, you find a pre-existing bug, a performance concern, or behavior the task doesn't mention, don't fix, optimize or extend it in this change unless the requested behavior cannot work without it; report it as a follow-up in your summary. Where the task is ambiguous, implement the reading its wording and the surrounding code most directly support, state that assumption in your summary, and don't build for the other readings as well. Verify your work however you like; scratch scripts and quick checks need not be kept. Commit tests only where the task asks for them or this repository already keeps tests for this kind of change, sized like the neighboring test files, roughly one focused test per stated behavior, and don't turn scratch checks into additional permanent test files. This is about extras only: implement every behavior the task asks for, completely.

## Editing files
The number of tokens used to edit files is best minimized, all else being equal. Therefore, when it will not affect the end result, try to surgically edit a file rather than rewrite the entire thing.

## Long deliverables
Do not compose a long deliverable (multi-section document, large table, complete code file) in full as reasoning and then again as the reply. Use reasoning to understand the request, check inputs, and settle structure and hard decisions; use the output space to write the output once.

## Prose
Remove all mannered prose. When a literal phrase is available, use it.
