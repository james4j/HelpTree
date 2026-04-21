# HelpTree Config Schema

This document describes the on-disk config file format for HelpTree theme overrides.

## Supported Formats

| Language | Preferred | Also Accepted |
|----------|-----------|---------------|
| Rust | TOML | JSON |
| Python | JSON | — |
| TypeScript | JSON | — |
| Go | JSON | — |

## JSON Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "properties": {
    "theme": {
      "type": "object",
      "properties": {
        "command": { "$ref": "#/definitions/token" },
        "options": { "$ref": "#/definitions/token" },
        "description": { "$ref": "#/definitions/token" }
      },
      "additionalProperties": false
    }
  },
  "definitions": {
    "token": {
      "type": "object",
      "properties": {
        "emphasis": {
          "type": "string",
          "enum": ["normal", "bold", "italic", "bold_italic"]
        },
        "color_hex": {
          "type": "string",
          "pattern": "^#[0-9A-Fa-f]{6}$"
        }
      },
      "additionalProperties": false
    }
  },
  "additionalProperties": false
}
```

## Examples

### Default theme (JSON)

```json
{
  "theme": {
    "command": {
      "emphasis": "bold",
      "color_hex": "#7ee7e6"
    },
    "options": {
      "emphasis": "normal"
    },
    "description": {
      "emphasis": "italic",
      "color_hex": "#90a2af"
    }
  }
}
```

### Default theme (TOML)

```toml
[theme]

[theme.command]
emphasis = "bold"
color_hex = "#7ee7e6"

[theme.options]
emphasis = "normal"

[theme.description]
emphasis = "italic"
color_hex = "#90a2af"
```

### High-contrast theme (JSON)

```json
{
  "theme": {
    "command": {
      "emphasis": "bold",
      "color_hex": "#ffcc00"
    },
    "options": {
      "emphasis": "bold_italic",
      "color_hex": "#ff6666"
    },
    "description": {
      "emphasis": "italic",
      "color_hex": "#aaaaaa"
    }
  }
}
```

## Notes

- `color_hex` is optional; omitting it means no ANSI color is applied.
- `emphasis` defaults to `"normal"` if omitted.
- Unknown keys at any level should be ignored (forward compatibility).
- If the config file is missing or malformed, implementations fall back to built-in defaults.
