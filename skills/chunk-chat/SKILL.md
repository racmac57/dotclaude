---
name: chunk-chat
description: Chunk the current conversation or a file into semantic chunks for RAG ingestion. Use when the user says "chunk chat", "save session chunks", or "process this conversation".
---

# Chunk Chat

Process the current conversation (or a supplied file) into chunked output
directly in the working directory. This eliminates the manual workflow of
exporting a chat log, moving it to `02_data/`, waiting for the watcher, and
copying output back.

## Output Structure

```
C:\Users\carucci_r\OneDrive - City of Hackensack\KB_Shared\04_output\{timestamp}_{name}/
  chunk_00000.txt ... chunk_NNNNN.txt   # individual semantic chunks
  {timestamp}_{name}_transcript.md      # full readable transcript
  {timestamp}_{name}_sidecar.json       # metadata, tags, key terms per chunk
  {timestamp}_{name}.origin.json        # provenance / source hash
```

## Workflow

### Step 1 - Determine the input source

Check `$ARGUMENTS`:

- **If a file path is provided** (e.g., `/chunk-chat ./logs/session.txt`):
  Verify the file exists. Use it directly as input. Skip to Step 3.

- **If no arguments or the argument is a topic/label**:
  Proceed to Step 2 to capture the conversation from context.

### Step 2 - Capture the conversation

Reconstruct the full conversation from your context window. First resolve
the real system temp directory by running:

```bash
python -c "import tempfile; print(tempfile.gettempdir())"
```

Next, derive a meaningful filename using the AI Suffix Naming Convention
(see section below). If `$ARGUMENTS` contains a topic label, use it.
Otherwise generate a 4–8 word Title_Case topic that describes this
conversation, then append `_Claude`.

Name the temp file: `<temp_dir>/<Topic_Description>_Claude.txt`

Example: `C:\Users\carucci_r\AppData\Local\Temp\Chunk_Chat_Skill_Update_And_Hardening_Claude.txt`

**Do NOT use `/tmp` directly** — on Windows with Git Bash, `/tmp` is a
virtual path that does not exist on the real filesystem. Always use the
path returned by Python's `tempfile.gettempdir()`.

Write the conversation to that file. Format rules:
- Every turn on its own line block prefixed with the role:
  ```
  [User]: <message content>

  [Assistant]: <message content>
  ```
- Preserve code blocks, error messages, and technical content **verbatim**.
- Include tool calls/results as `[Tool: <name>]: <summary of result>`.
- If context has been compressed and you cannot reproduce earlier turns
  faithfully, note that at the top of the file with:
  ```
  [Note]: Earlier portions of this conversation were summarized due to context
  limits. Content below the line is verbatim.
  ---
  ```
- Do NOT summarize or paraphrase turns you can still see in full.

### Step 3 - Run the chunker

Execute the standalone chunker script. It has zero external dependencies
(stdlib only).

```bash
python "C:\Users\carucci_r\.claude\scripts\chat_chunker.py" "<input_file>"
```

> **Windows note:** Use `python` not `python3` — Windows does not register
> a `python3` command by default. Use the full path to `chat_chunker.py`
> to avoid shell path resolution issues with `$HOME`.

The script defaults to `KB_Shared/04_output` on OneDrive. To override,
pass an explicit output directory as the second argument.

Parse the JSON output from stdout.

### Step 4 - Report results

Present a concise summary to the user:

```
Chunked: {source_name}
  Chunks created: {N}
  Total characters: {total_chars}
  Tags detected: {tags}
  Key terms: {top terms}
  Output folder: {path}
  Transcript: {transcript filename}
  Sidecar: {sidecar filename}
```

### Step 5 - Clean up

If a temp file was created in Step 2, remove it from the system temp
directory where it was written.

## Notes

- The chunker uses sentence-boundary splitting at ~800 chars with 50-char
  overlap, matching chunker_web defaults.
- Metadata enrichment (tags, key terms, summary) is rule-based and runs
  inline with no external API calls.
- Default output lands in `KB_Shared/04_output` on OneDrive. Pass an
  explicit output directory as the second argument to override.
- If $ARGUMENTS contains `--chunk-size=N` or `--overlap=N`, edit the
  script invocation to pass those values (the script reads them from argv
  or can be patched at runtime via env vars in a future version).
- **ChromaDB ingestion:** Output chunks land in `KB_Shared\04_output` but
  are **not automatically ingested into ChromaDB**. The watcher only
  monitors `02_data\` for triggers. To add the chunks to the knowledge
  base, run `backfill_knowledge_base.py` in the `C:\_chunker` repo after
  `/chunk-chat` completes, or use the manual process tool.

## AI Suffix Naming Convention

When archiving conversation transcripts, use this filename pattern:

```
{Topic_Description}_{AI_Name}.md
```

| Segment              | Rules                                                |
|----------------------|------------------------------------------------------|
| `Topic_Description`  | 4–8 words, Title_Case, underscores, no dates         |
| `AI_Name`            | The AI that generated the conversation:               |
|                      | `Claude` \| `ChatGPT` \| `Gemini` \| `Cursor`       |

**Examples:**
- `ETL_Pipeline_Design_For_CAD_Data_Claude.md`
- `Power_BI_DAX_Measure_Debugging_ChatGPT.md`
- `ArcGIS_Pro_Field_Mapping_Strategy_Gemini.md`

When using the **Conversation Archivist** prompt to generate a filename,
append `_Claude` (or the appropriate AI name) as the final segment before
the `.md` extension.
