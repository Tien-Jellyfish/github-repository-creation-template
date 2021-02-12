#!/bin/bash

# Variable
private="true"
auto_init="true"

print_usage() {
  echo "        Please use these supported flags below to provide input:"
  echo "        -o: provide input for repository owner. Ex: -o JellyfishGroup"
  echo "        -n: provide input for repository name. Ex: -n jfgp-dmh-automation-eng"
  echo "        -t: provide input for teams and permission. You can use multiple -t flag. Ex: -t DevOps:push -t Data:admin"
  echo "        -u: provide input for users and permission. You can use multiple -u flag. Ex: -u Dave:admin -u Ashley:admin"
}

while getopts 'o:n:t:u:' flag; do
  case "${flag}" in
    o) repo_owner="${OPTARG}" ;;
    n) repo_name="${OPTARG}" ;;
    t) teams+=("$OPTARG") ;;
    u) users+=("$OPTARG") ;;
    *) print_usage
       exit 1 ;;
  esac
done

# Check data input is not empty

if [[ -z $repo_owner || -z $repo_name ]]; then
  print_usage
  exit 1
fi

# Check data input existed in github organization
repo_check=$(gh api /repos/$repo_owner/$repo_name | jq '.name')

if [[ $repo_check != null ]]; then
  echo "Repository $repo_check has been existed in our Github Organization"
else
  # Create repository with provided data 
  echo "Creating repository $repo_name for $repo_owner organization"
  echo "Please wait for a few seconds..."
  sleep 1
  gh api /orgs/$repo_owner/repos --silent -F name="$repo_name" -F private="$private" -F auto_init="$auto_init"
  echo "Github repository has been created successfully."
fi

# Add collaborators/users and permission to repository
#
for x in "${users[@]}"; do
  #Check if data input is not empty
  #
  user=$(echo $x | cut -f1 -d:)
  permission=$(echo $x | cut -f2 -d:)
  if [[ -z $user || -z $permission ]]; then
    echo "There are no users and permission added to repository"
    exit 1
  fi
  
  # Check if user value input exist in gh user list
  #
  user_check=$(gh api /users/$user | jq '.login')
  if [[ $user_check != null ]]; then
    if [[ 
    "$permission" == "pull" || 
    "$permission" == "push" || 
    "$permission" == "triage" || 
    "$permission" == "maintain" || 
    "$permission" == "admin" 
    ]]; then
      echo "Adding user and permission to repository"
      echo "Please wait for a few seconds..."
      gh api /repos/$repo_owner/$repo_name/collaborators/$user \
      -X PUT \
      -F permission="$permission"
      echo "User $user with $permission permission has been added to repository $repo_name"
    else
      echo "The permission you input does not exist in github user list"
      exit 1
    fi
  else
    echo "user $user does not exist in our github user list"
    exit 1
  fi
done


# Add teams and permission to repository
#
for y in "${teams[@]}"; do
  #Check if data input is not empty
  #
  team=$(echo $y | cut -f1 -d:)
  permission=$(echo $y | cut -f2 -d:)
  if [[ -z $team  || -z $permission ]]; then
    echo "There are no team and permission added to repository"
    exit 1
  fi
  
  # Check if team value input exist in gh user list
  #
  team_check=$(gh api /orgs/$repo_owner/teams/$team | jq '.name')

  if [[ $team_check != null ]]; then
    if [[ 
    "$permission" == "pull" || 
    "$permission" == "push" || 
    "$permission" == "triage" || 
    "$permission" == "maintain" || 
    "$permission" == "admin" 
    ]]; then
      echo "Adding team and permission to repository"
      echo "Please wait for a few seconds..."
      gh api /orgs/$repo_owner/teams/$team/repos/$repo_owner/$repo_name \
      -X PUT \
      -F permission="$permission"
      echo "$team team with $permission permission has been added to repository $repo_name"
    else
      echo "The permission $permission does not exist"
      exit 1
    fi
  else
    echo "The team $team does not exist"
    exit 1
  fi
done

echo "You can now access to repository with URL below:" 
echo "URL: https://github.com/$repo_owner/$repo_name"
