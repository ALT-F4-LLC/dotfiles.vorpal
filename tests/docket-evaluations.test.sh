#!/bin/bash
# Check the model-evaluation graders offline; no Claude calls or live store.
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
python3 "$SCRIPT_DIR/docket-evaluations.test.py"
