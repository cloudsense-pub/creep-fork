# Generate a random repo name
$RepoName = "repo-" + [guid]::NewGuid().ToString("N").Substring(0, 8)

# Initialize git and commit everything (safe to run in an existing repo)
git init
git add -A
git commit -m "Initial commit"
git branch -M main

# Create the GitHub repo and push the current folder to it
gh repo create $RepoName --private --source=. --remote=origin --push

Write-Host "Pushed to: $(gh repo view --json url -q .url)"
