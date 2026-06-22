#!/bin/bash
# PreToolUse hook — auto-approves Write on session_commit_msg.txt
# Workaround for VS Code extension bugs #15921/#14956 where Write/Edit permissions
# in settings.json are ignored. Remove when bugs are fixed.

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')

if [ "$TOOL" = "Write" ]; then
    FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
    if echo "$FILE" | grep -q 'session_commit_msg\.txt$'; then
        echo '{"decision":"approve"}'
        exit 0
    fi
fi

exit 0
