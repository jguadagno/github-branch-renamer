$GitHubUser = ""
$GitHubApi_Headers = ""
$GitHubApi_RootUri = ""

function Get-Ref-Head-Sha {
    Param ([string] $repoName, [string] $oldBranchName)

    $refHeadUri = Get-GitHub-RepoRefs-Uri $GitHubUser $repoName + "/heads"
    $refHeads = Invoke-RestMethod -Uri $refHeadUri -Headers $GitHubApi_Headers
 
    $ref = "refs/heads/" + $oldBranchName
    $refHeads.Where{$_.ref -eq $ref}.object.sha
}

function New-Branch {
    Param ([string] $repoName, [string] $oldBranchName, [string] $newBranchName)

    $sha = Get-Ref-Head-Sha $repoName $oldBranchName

    $ref = "refs/heads/{new_branch_name}" -replace "{new_branch_name}", $newBranchName
    $data = @{
        "ref" = $ref
        "sha" = $sha
    }
    $body = $data | ConvertTo-Json

    $refHeadUri = Get-GitHub-RepoRefs-Uri $GitHubUser $repoName
    $results = Invoke-RestMethod -Method 'Post' -Uri $refHeadUri -Headers $GitHubApi_Headers -Body $body
}

function Set-Default-Branch {
    Param ([string] $repoName, [string] $branchName)

    $data = @{
        "default_branch" = $branchName
    }
    $body = $data | ConvertTo-Json

    $repoUri = Get-GitHub-Repo-Uri $GitHubUser $repoName
    $results = Invoke-RestMethod -Method 'PATCH' -Uri $repoUri -Headers $GitHubApi_Headers -Body $body
}

function Remove-Branch {
    Param ([string] $repoName, [string] $branchName)

    $data = @{
        "default_branch" = $branchName
    }
    $body = $data | ConvertTo-Json

    $branchRootUri = Get-GitHub-RepoRefs-Uri $GitHubUser $repoName 
    $branchUri = $branchRootUri + "/heads/{branch_name}" -replace "{branch_name}", $branchName
    $results = Invoke-RestMethod -Method 'DELETE' -Uri $branchUri -Headers $GitHubApi_Headers -Body $body
}

function Get-GitHub-Repo-Uri {
    Param ([string] $UserName, [string] $RepoName)

    $GitHubApi_RootUri + "/repos/{user_name}/{repo_name}" -replace "{user_name}", $UserName -replace "{repo_name}", $RepoName
}

function Get-GitHub-UserRepos-Uri {
    Param ([string] $UserName)

    $GitHubApi_RootUri + "/users/{user_name}/repos" -replace "{user_name}", $UserName
}

function Get-GitHub-RepoRefs-Uri {
    Param ([string] $UserName, [string] $RepoName)

    $GitHubApi_RootUri + "/repos/{user_name}/{repo_name}/git/refs" -replace "{user_name}", $UserName -replace "{repo_name}", $RepoName
}

function Rename-GitHub-Branches {
    Param (

        [Parameter(Mandatory=$true)] [string] $GitHubToken, 
        [Parameter(Mandatory=$true)] [string] $User, 
        [Parameter(Mandatory=$true)] [string] $FromBranch, 
        [Parameter(Mandatory=$true)] [string] $ToBranch,
        [Parameter(Mandatory=$false)] [string] $ApiRootUri = 'https://api.github.com' 
    )
    
    # Set Variables
    $script:GitHubApi_RootUri = $ApiRootUri;
    $script:GitHubUser = $User;
    $script:GitHubApi_Headers = @{'Authorization' = 'Bearer ' + $GitHubToken}

    $userRepoUri = Get-GitHub-UserRepos-Uri $GitHubUser
    $reposFromApi = Invoke-RestMethod -Uri $userRepoUri -Headers $GitHubApi_Headers -FollowRelLink -MaximumFollowRelLink 5

    $repos = @()
    $userRepos = @()
    foreach ($page in $reposFromApi) {
        $repos = $repos + $page
    }

    $userRepos = $repos.Where{($_.fork -eq $false) -and ($_.default_branch -eq $FromBranch)}

    $processed=0
    $total = $userRepos.count
    foreach ($repo in $userRepos) {
        
        $repoName = $repo.name
        Write-Progress -Activity "Renaming Branches" -Status "Updating '$repoName'" -PercentComplete (($processed/$total)*100)
    
        #Step 1: Create the new branch off the old branch ($FromBranch)
        New-Branch $repo.name $FromBranch $ToBranch

        #Step 2: Change the Default branch to new branch ($ToBranch)
        Set-Default-Branch $repo.name $ToBranch

        #Step 3: Delete the old branch ($FromBranch)
        Remove-Branch $repo.name $FromBranch

        $processed = $processed + 1
        Write-Progress -Activity "Renaming Branches" -Status "Finished updating '$repoName'" -PercentComplete (($processed/$total)*100)
    }
}
