#!/usr/bin/env bash
set -euo pipefail

PR_INFO=$(gh pr view --json number,headRepository 2>/dev/null) || { echo "Pull Request not found." >&2; exit 1; }
PR_NUMBER=$(echo "$PR_INFO" | jq '.number')
REPO_NAME=$(echo "$PR_INFO" | jq -r '.headRepository.name')
OWNER=$(echo "$PR_INFO" | jq -r '.headRepository.nameWithOwner | split("/")[0]')

gh api graphql \
  -f query="
    query {
      repository(owner: \"$OWNER\", name: \"$REPO_NAME\") {
        pullRequest(number: $PR_NUMBER) {
          reviewThreads(first: 100) {
            nodes {
              id
              isResolved
              comments(first: 100) {
                nodes { author { login } body url }
              }
            }
          }
        }
      }
    }
  " \
| jq '.data.repository.pullRequest.reviewThreads.nodes[]
  | select(.isResolved == false)
  | {id: .id, comments: (.comments.nodes[] | select(.author.login == "copilot-pull-request-reviewer") | {url: .url, body: .body})}'
