#!/usr/bin/env bash
set -euo pipefail

# Dispatch the VEX generator agentic workflow for a dismissed Dependabot alert.
#
# Usage:
#   ./scripts/dispatch-vex.sh <alert-number>
#
# Requires: gh CLI authenticated with repo access

ALERT_NUMBER="${1:?Usage: dispatch-vex.sh <alert-number>}"
REPO="${REPO:-$(gh repo view --json nameWithOwner -q .nameWithOwner)}"

echo "Fetching alert #${ALERT_NUMBER} from ${REPO}..."

alert=$(gh api "/repos/${REPO}/dependabot/alerts/${ALERT_NUMBER}")

STATE=$(echo "$alert" | jq -r '.state')
if [ "$STATE" != "dismissed" ]; then
  echo "Error: Alert #${ALERT_NUMBER} is not dismissed (state: ${STATE})"
  exit 1
fi

GHSA_ID=$(echo "$alert" | jq -r '.security_advisory.ghsa_id // ""')
CVE_ID=$(echo "$alert" | jq -r '.security_advisory.cve_id // ""')
PACKAGE_NAME=$(echo "$alert" | jq -r '.dependency.package.name // ""')
PACKAGE_ECOSYSTEM=$(echo "$alert" | jq -r '.dependency.package.ecosystem // ""')
SEVERITY=$(echo "$alert" | jq -r '.security_advisory.severity // ""')
SUMMARY=$(echo "$alert" | jq -r '.security_advisory.summary // ""')
DISMISSED_REASON=$(echo "$alert" | jq -r '.dismissed_reason // ""')

echo ""
echo "Alert #${ALERT_NUMBER}: ${GHSA_ID} (${CVE_ID})"
echo "  Package:  ${PACKAGE_NAME} (${PACKAGE_ECOSYSTEM})"
echo "  Severity: ${SEVERITY}"
echo "  Reason:   ${DISMISSED_REASON}"
echo "  Summary:  ${SUMMARY}"
echo ""
echo "Dispatching VEX generator workflow..."

gh workflow run vex-generator.lock.yml \
  --repo "$REPO" \
  -f alert_number="$ALERT_NUMBER" \
  -f ghsa_id="$GHSA_ID" \
  -f cve_id="$CVE_ID" \
  -f package_name="$PACKAGE_NAME" \
  -f package_ecosystem="$PACKAGE_ECOSYSTEM" \
  -f severity="$SEVERITY" \
  -f summary="$SUMMARY" \
  -f dismissed_reason="$DISMISSED_REASON"

echo "✓ Workflow dispatched. Check progress at:"
echo "  https://github.com/${REPO}/actions/workflows/vex-generator.lock.yml"
