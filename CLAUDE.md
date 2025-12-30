# Claude Code Instructions for caschooldata

## Commit Messages
- Do NOT include "Generated with Claude Code" in commit messages
- Do NOT include "Co-Authored-By: Claude" in commit messages
- Keep commit messages concise and descriptive

## Pull Requests
- Do NOT mention Claude or AI assistance in PR descriptions
- Focus PR descriptions on the changes and their purpose

## Code Style
- Follow tidyverse style guide
- Use roxygen2 documentation for all exported functions
- Prefer pipe-based workflows with dplyr

## Testing
- Write testthat tests for all exported functions
- Use snapshot tests for data processing output validation

## Data Sources
- Primary data source: California Department of Education (CDE)
- DataQuest URL: https://dq.cde.ca.gov/dataquest/
- Data files: https://www.cde.ca.gov/ds/

## CDS Code Format
- 14-digit identifier: 2 (county) + 5 (district) + 7 (school)
- Example: 01611920130229
