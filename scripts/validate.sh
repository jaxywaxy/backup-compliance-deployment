#!/bin/bash
# Validate all Bicep templates

set -e

echo "🔍 Validating Bicep templates..."
echo ""

# Validate main template
echo "Validating bicep/main.bicep..."
az bicep build --file bicep/main.bicep --outdir /tmp

# Validate all modules
echo "Validating modules..."
for module in bicep/modules/*.bicep; do
  echo "  ✓ $(basename $module)"
  az bicep build --file "$module" --outdir /tmp
done

echo ""
echo "✅ All templates are valid!"
echo ""
echo "Parameter files:"
echo "  - bicep/parameters/dev.bicepparam"
echo "  - bicep/parameters/prod.bicepparam"
