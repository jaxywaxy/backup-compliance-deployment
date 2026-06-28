# Bicep Drift Detection

Detect configuration drift between your Bicep infrastructure-as-code templates and deployed Azure resources.

## Overview

This service runs drift detection for your Bicep templates against deployed Azure infrastructure. It detects:

- **Missing resources** — Defined in Bicep but not deployed
- **Extra resources** — Deployed but not defined in Bicep  
- **Property changes** — Configuration changes made outside of IaC
- **Smart matching** — Handles runtime-generated resource names

## Setup

### 1. Azure Credentials

The GitHub Actions workflow uses Azure Federated Identity (OIDC) to authenticate. Configure these secrets in your GitHub repo:

| Secret | Description |
| --- | --- |
| `AZURE_CLIENT_ID` | Service principal client ID |
| `AZURE_TENANT_ID` | Azure tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Azure subscription ID |
| `ANTHROPIC_API_KEY` | API key from [console.anthropic.com](https://console.anthropic.com) |

### 2. Local Testing

To run drift checks locally:

```bash
cd drift-detection

# Install dependencies
pip install -r requirements.txt

# Set environment variables
export ANTHROPIC_API_KEY='your-api-key'
export AZURE_SUBSCRIPTION_ID='your-subscription-id'

# Login to Azure
az login

# Run drift check
python analyze_drift.py ../bicep/main.bicep rg-prod
```

## Workflow

The drift check workflow runs:

- **Automatically** on push to `bicep/` directory
- **Manually** via GitHub Actions > Bicep Drift Check > Run workflow

### Checking Dev Environment

```bash
python analyze_drift.py ../bicep/main.bicep rg-dev
```

### Checking Prod Environment

```bash
python analyze_drift.py ../bicep/main.bicep rg-prod
```

## Reports

After the workflow completes:

1. Download the **drift-reports** artifact from the workflow run
2. Open `rg-dev-drift.html` or `rg-prod-drift.html` in your browser

Reports include:

- **Property Changes** — Configuration differences
- **Missing Resources** — Defined in Bicep, not deployed
- **Extra Resources** — Deployed but not in Bicep
- **AI Recommendations** — Claude-powered suggestions to fix drift

## Understanding Results

### Modified Configuration
Resources exist in both Bicep and Azure, but properties differ. This indicates out-of-band changes.

### Missing Resources
Resources are defined in Bicep but not deployed. Deploy them or remove from Bicep.

### Extra Resources
Resources are deployed but not in Bicep. Add them to Bicep or remove from Azure.

## Limitations

- Complex nested parameters may not fully resolve
- System-managed properties (IDs, timestamps) are filtered out
- Large deployments may take several minutes to analyze

## Files

```
drift-detection/
├── analyze_drift.py          # Phase 1 + Phase 2 entry point
├── run_drift_check.py        # Phase 1 (drift detection)
├── requirements.txt          # Python dependencies
├── .github/workflows/        # GitHub Actions workflows
├── tools/                    # Core drift detection modules
│   ├── property_drift.py     # Property-level comparison
│   ├── smart_matching.py     # Resource matching
│   ├── ignore_patterns.py    # Ignore rules
│   ├── html_report.py        # Report generation
│   └── ...
└── agent/                    # Claude AI agent
    └── drift_agent.py        # AI analysis
```

## Troubleshooting

### "No Azure credentials found"
Make sure you're logged in: `az login`

### "Bicep file not found"
Check the file path is correct relative to where you're running the command.

### "No drifts detected" but you know there are changes
The Bicep template may need parameters. Check `ARM_PARAMETERS` in the workflow.

## Support

For issues or questions about the drift detection service, refer to the parent project documentation.
