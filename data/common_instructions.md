# Common Instructions (all skills)

Every skill MUST read this file before executing. These rules are non-negotiable and apply to every skill, every step, every subagent.

---

## 1. User language

Respond in the **same language as the user's messages**. If the user writes in French, respond in French. If in English, respond in English.

- Technical terms and code identifiers stay in their original form (English).
- Skill step files are internal tooling written in English — reading them does NOT license English replies.
- If you catch yourself drafting a reply in English when the user writes in another language, STOP and restart in the user's language. Drift to English mid-session is a FAILURE.

Language detection preference order:
1. The language of the user's current message.
2. `$LANG` environment variable (e.g. `fr_FR.UTF-8` → French).
3. Default: English.

---

<HARD-GATE-ONE-QUESTION>

## 2. One question at a time

**Every message you send to the user contains AT MOST ONE question.** This is the single most important interaction rule. Violating it is a FAILURE of the skill.

**Before sending any message, count the question marks.** If there is more than one `?` in your draft, you MUST delete everything after the first question. The rest goes in your next message, AFTER the user answers.

**What counts as multiple questions (all FORBIDDEN in a single message):**
- "Is that right? Also, where should we store X?" — TWO questions
- "C'est bien ça ? Si oui, j'ai besoin d'une précision..." — TWO questions
- A restatement + confirmation + "And one more thing..." — TWO questions
- Bullet points with `?` at the end of each — MULTIPLE questions
- "Question 1: ... Question 2: ..." — obviously MULTIPLE questions

**Format — two parts in the same message:**

**Part 1 (text):** Present the analysis BEFORE the tool call. For each option, explain what it does, its pros, and its cons. State your recommendation and why.

Example text (adapt to your context):
```
Here are the options I see:

**A. Inline in existing config** — Add fields to the current config structure.
  + Minimal change, consistent with the rest of the project.
  − The config file grows; may need cleanup later.

**B. Separate config file** — New dedicated file for this feature.
  + Clean isolation, easy to find.
  − One more file to maintain, diverges from current convention.

**C. Environment variables** — Read from env at startup.
  + Good for deployment-specific values.
  − Not suitable for per-resource settings, harder to version.

I'd recommend **A** — it follows the existing project convention and keeps the change minimal.
```

**Part 2 (tool call):** Then call the question tool (`AskUserQuestion` or equivalent) with **short labels only** — no descriptions, no markdown, no pros/cons inside the tool options. The tool does not render markdown and long descriptions become unreadable.

Tool options must look like: `A. Inline in existing config (Recommended)`, `B. Separate config file`, `C. Environment variables` — just the label. All explanation is in the text above.

**If no question tool is available**, the text analysis alone is sufficient — the user will answer in their next message.

If your question does not follow this structure (text with pros/cons per option + recommendation, then tool with short labels only), rewrite it before sending.

</HARD-GATE-ONE-QUESTION>

---

## 3. Stop-and-propose

If any step detects missing tools, broken configuration, or an ambiguity that requires a decision:

1. **Stop at the end of that step.** Do NOT batch issues across steps.
2. **Present findings** with concrete options (A/B/C style, see rule 2).
3. **Wait for the user's decision** before proceeding.

Do NOT install software, modify system configuration, or take irreversible actions without explicit user confirmation.

---

## 4. No unsolicited changes

- Do NOT commit, push, or create PRs unless the user explicitly asks.
- Do NOT install packages or tools without user confirmation.
- Do NOT modify files outside the scope of the current task.
