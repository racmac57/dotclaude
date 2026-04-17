---
name: arcgis-pro
description: Guides writing Python scripts for ArcGIS Pro's bundled arcpy environment, enforcing constraints like no pip, scratchGDB usage, and exec-compatible patterns.
---

# ArcGIS Pro Python Environment

## When to Use

When writing or modifying Python scripts that run inside ArcGIS Pro's bundled
Python environment (arcpy scripts for Clery, SCRPA, CAD dashboards, etc.).

## Environment Constraints

- **No** `pip install` in the Pro default env; assume only packages shipped with Pro unless the user documents a cloned env.
- **No** PyYAML, no package-style `__init__.py` layouts unless the project already uses them in Pro.
- Prefer **file geodatabase** or **`arcpy.env.scratchGDB`** for intermediate data — avoid `in_memory` for large or long workflows.
- Paths: use `pathlib` or raw strings; respect `carucci_r` OneDrive root from `path_config` when scripts also touch file outputs.

## Execution Pattern

Scripts are often run from the Pro Python window with:

```python
exec(open(r"path\to\script.py").read())
```

Design `script.py` to use `if __name__ == "__main__":` or top-level flow compatible with `exec`. `sys.argv` works only for command-line / Task Scheduler invocation (`python.exe script.py ...`); under the Pro Python window `exec()` it is NOT populated with your arguments. For exec-based runs, set module-level variables in the Pro window before calling `exec()` or expose plain top-level constants.

## arcpy Habits

- Set workspace and overwrite explicitly when needed: `arcpy.env.workspace`, `arcpy.env.overwriteOutput`.
- Use Describe/Exists before destructive operations; clear `arcpy.env.scratchGDB` contents between runs when re-runnable.
- Log or print key steps for long geoprocessing chains. Inside geoprocessing tools, use `arcpy.AddMessage` / `arcpy.AddWarning` / `arcpy.AddError` — `print()` only surfaces in the Pro Python window.

## Error Handling

Wrap arcpy calls with try/except and surface the full tool error, not just the Python exception:

```python
try:
    arcpy.management.CopyFeatures(src, dst)
except arcpy.ExecuteError:
    print(arcpy.GetMessages(2))  # severity 2 = errors only
    raise
except Exception as e:
    print(f"Python error: {e}")
    raise
```

For command-line / scheduled runs, exit non-zero on failure (`sys.exit(1)`) so Task Scheduler flags the run as failed (LastTaskResult != 0).

## References

Follow project-specific `CLAUDE.md` under `10_Projects/` for import paths (e.g. local geocoding helpers).
