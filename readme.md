# GitHub Branch Rename

This is a small utility that I put together to '*rename*' branches in your GitHub repositories. Rename is *italicized* because it technically does not rename but creates a new branch, then sets that branch to be the repository default, then deletes the old branch.  This script runs using the GitHub API only.  There is no need to clone your repositories or even know their names.

It will rename branches from your public and private repositories that are not forks and have the default branch set to the `FromBranch` argument.  When you are done running the script, if you have a copy of the repository locally, you will need to run the following commands in that repositories folder.

```bash
git pull
git checkout newBranchName # replace newBranchName with your new name
```

**Note** There has been limited testing on this.  Use at your own risk!

## Running It

In order to run the script you will need [Powershell Core](https://docs.microsoft.com/en-us/powershell/scripting/overview?view=powershell-7) and a GitHub [Personal Access Token](https://help.github.com/en/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line). The token should need the following scopes:

* repo
* public_repo

I don't think it needs any other scopes.

From Powershell

```powershell
Rename-GitHub-Branches -GitHubToken "<yourToken>" -User "<yourUserId>" -FromBranch "<oldBranchName>" -ToBranch "<newBranchName>"
```

Optionally change the API Endpoint for Enterprise repositories

```powershell
Rename-GitHub-Branches -GitHubToken "<yourToken>" -User "<yourUserId>" -FromBranch "<oldBranchName>" -ToBranch "<newBranchName>" -ApiRootUri "<yourApi>"
```

Replace the following:

Argument | Description | Sample
--- | --- | ---
`<yourToken>` | Your GitHub personal access token | `abc123`
`<yourUserId>` | Your GitHub user id | `jguadagno`
`<oldBranchName` | The branch name you want to change | `master`
`<newBranchName>` | The name for the new branch | `main`
`<yourApi>` | The api url (defaults to `https://api.github.com`) | `https://www.yourdomain.com/api/v3/`

## Want to Contribute

See something that I can approve?  PR accepted :smile:
