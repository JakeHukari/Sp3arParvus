name: Bug report
description: Create a report to help us improve
labels: ["bug"]
body:
  - type: markdown
    attributes:
      value: |
        Thanks for taking the time to fill out this bug report!
  - type: textarea
    id: what-happened
    attributes:
      label: What happened?
      description: Also tell us what you expected to happen
      placeholder: Tell us what you see!
    validations:
      required: true
  - type: input
    id: executor
    attributes:
      label: Executor used
      description: Which Roblox executor are you using? (e.g., Solara, Wave, etc.)
  - type: input
    id: game-link
    attributes:
      label: Game Link
      description: Provide a link to the game where the bug occurs.
