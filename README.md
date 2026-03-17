# VEX Auto Generator

**Prototype**: Agentic workflow that auto-generates [OpenVEX](https://openvex.dev/) statements when Dependabot alerts are dismissed.

This is a proof-of-concept for the "dismiss → auto-generate VEX" MVP discussed in [github/supply-chain-security#303](https://github.com/github/supply-chain-security/issues/303).

## How It Works

```
┌─────────────────────┐     ┌──────────────────────────┐     ┌─────────────────────┐
│  Maintainer dismisses│     │  dispatch-vex-on-dismiss  │     │   vex-generator      │
│  a Dependabot alert  │────▶│  (standard Actions)       │────▶│   (gh-aw agentic)    │
│                      │     │  Forwards alert data via   │     │  - Reads alert data   │
└─────────────────────┘     │  repository_dispatch       │     │  - Maps to VEX status │
                            └──────────────────────────┘     │  - Generates OpenVEX  │
                                                              │  - Opens PR with .vex/ │
                                                              └─────────────────────┘
```

### Two-Layer Architecture

1. **`dispatch-vex-on-dismiss.yml`** — Thin standard GitHub Actions workflow that triggers on `dependabot_alert` (dismissed) and forwards the alert data to the agentic workflow via `repository_dispatch`

2. **`vex-generator.md`** — gh-aw agentic workflow that:
   - Reads the dismissed alert details (CVE, package, severity, dismissal reason)
   - Maps the Dependabot dismissal reason to an OpenVEX status:
     - `not_used` → `not_affected` / `vulnerable_code_not_present`
     - `inaccurate` → `not_affected` / `vulnerable_code_not_in_execute_path`  
     - `tolerable_risk` → `not_affected` / `inline_mitigations_already_exist`
     - `no_bandwidth` → skipped (not a security assessment)
   - Generates a valid OpenVEX v0.2.0 JSON document
   - Opens a PR adding the VEX statement to `.vex/`

## Testing

### Automatic (via alert dismissal)
1. Wait for Dependabot to create alerts (vulnerable deps: lodash@4.17.20, minimist@1.2.5, express@4.17.1)
2. Dismiss an alert with a reason like "not_used" or "inaccurate"
3. Watch the Actions tab — the dispatcher fires, then the agentic workflow generates a VEX PR

### Manual (via workflow_dispatch)
1. Go to Actions → "Auto-Generate OpenVEX Statement on Dependabot Alert Dismissal"
2. Click "Run workflow" and enter a Dependabot alert number
3. The agent will fetch the alert details and generate the VEX statement

## Example Output

A generated `.vex/GHSA-xxxx-xxxx-xxxx.json` would look like:

```json
{
  "@context": "https://openvex.dev/ns/v0.2.0",
  "@id": "https://github.com/carlin-dependabot-testing/vex-auto-generator/vex/GHSA-xxxx",
  "author": "GitHub Agentic Workflow <vex-generator@github.com>",
  "timestamp": "2026-03-17T18:00:00Z",
  "statements": [
    {
      "vulnerability": { "@id": "CVE-2021-23337" },
      "products": [{ "@id": "pkg:npm/vex-auto-generator@1.0.0" }],
      "status": "not_affected",
      "justification": "vulnerable_code_not_present",
      "impact_statement": "The lodash template function is not used in this project."
    }
  ]
}
```

## Built With

- [GitHub Agentic Workflows (gh-aw)](https://github.com/github/gh-aw) — Natural language workflows in GitHub Actions
- [OpenVEX v0.2.0](https://openvex.dev/) — Standard for vulnerability exploitability exchange
