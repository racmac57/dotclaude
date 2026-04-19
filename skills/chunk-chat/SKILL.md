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

Reconstruct the full conversation from your context window as an
**in-memory string**. Do NOT write it to a temp file — the chunker reads
the transcript from stdin so no filesystem writes are required here.

Derive a meaningful basename using the AI Suffix Naming Convention (see
section below). If `$ARGUMENTS` contains a topic label, use it. Otherwise
generate a 4–8 word Title_Case topic that describes this conversation,
then append `_Claude`.

Example basename: `Chunk_Chat_Skill_Update_And_Hardening_Claude`

This basename is passed to the chunker via `--name=` in Step 3 — it
becomes the folder/file stem that previously came from the temp
filename.

Format rules for the transcript string:
- Every turn on its own line block prefixed with the role:
  ```
  [User]: <message content>

  [Assistant]: <message content>
  ```
- Preserve code blocks, error messages, and technical content **verbatim**.
- Include tool calls/results as `[Tool: <name>]: <summary of result>`.
- If context has been compressed and you cannot reproduce earlier turns
  faithfully, prepend this note to the string:
  ```
  [Note]: Earlier portions of this conversation were summarized due to context
  limits. Content below the line is verbatim.
  ---
  ```
- Do NOT summarize or paraphrase turns you can still see in full.

### Step 3 - Run the chunker

Invoke the standalone chunker script. It has zero external dependencies
(stdlib only). The invocation branches on whether Step 1 produced a
file path or Step 2 produced an in-memory transcript:

- **File-path branch** (Step 1 supplied `file_path`): pass the path
  directly as the first positional argument — the script opens it from
  disk.
- **Stdin branch** (Step 2 produced `transcript_text` + `basename`):
  pass `-` as the input and `--name=<basename>` to set the output
  folder/file stem, then feed the transcript in via `stdin`.

Use Python's `subprocess` module to avoid shell quoting and encoding
issues on Windows:

```python
import subprocess

if file_path:
    # File path supplied via $ARGUMENTS — pass it directly to the chunker
    args = [
        "python",
        r"C:\Users\carucci_r\.claude\scripts\chat_chunker.py",
        file_path,
    ]
    run_kwargs = {}
else:
    # In-memory transcript from Step 2 — pipe via stdin
    args = [
        "python",
        r"C:\Users\carucci_r\.claude\scripts\chat_chunker.py",
        "-",
        f"--name={basename}",
    ]
    run_kwargs = {"input": transcript_text}

result = subprocess.run(
    args,
    capture_output=True,
    text=True,
    encoding="utf-8",
    **run_kwargs,
)

if result.returncode != 0:
    raise RuntimeError(f"Chunker failed (exit {result.returncode}):\n{result.stderr.strip()}")
```

- `-` tells the script to read the transcript from stdin instead of
  opening a file.
- `--name=<basename>` supplies the folder/file stem the script would
  normally derive from the input path. Without it, the output folder
  falls back to `{timestamp}_stdin`.
- To override the default output directory, insert it as an additional
  positional argument after the input argument (file path or `-`):
  ```python
  ["python", r"C:\...\chat_chunker.py", "-", r"D:\custom\out", f"--name={basename}"]
  ```
- Non-zero exit codes raise `RuntimeError` with `result.stderr` attached
  so the underlying chunker failure is surfaced instead of being
  swallowed by a silent empty-stdout parse.

> **Windows note:** Use `python` not `python3` — Windows does not register
> a `python3` command by default. Use the full path to `chat_chunker.py`
> to avoid shell path resolution issues with `$HOME`.

Parse the JSON from `result.stdout`.

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

## Notes

- The chunker uses sentence-boundary splitting at ~800 chars with 50-char
  overlap, matching chunker_web defaults.
- Metadata enrichment (tags, key terms, summary) is rule-based and runs
  inline with no external API calls.
- Default output lands in `KB_Shared/04_output` on OneDrive. Pass an
  explicit output directory as the second argument to override.
- If `$ARGUMENTS` contains `--chunk-size=N` or `--overlap=N`, append the
  matching flags to the `args` list before calling `subprocess.run`:
  ```python
  if chunk_size:
      args.append(f"--chunk-size={chunk_size}")
  if overlap:
      args.append(f"--overlap={overlap}")
  ```
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
