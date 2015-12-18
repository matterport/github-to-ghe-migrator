#!/bin/sh

# Be careful with this set to true
LOCKREPOS=false
ARCHIVE=githubdotcom-archive.tar.gz

failquit() {
	echo "FATAL: $*"
	exit 1
}

usagequit() {
	echo 'Usage:'
	echo 'GITHUBTOKEN=token'
	echo 'ORGNAME=yourorg'
	echo 'GITHUBUSER=your github.com username'
	echo "$0: <repository name>"
	exit 1
}

[ -z "$@" ] && usagequit

[ -z "$GITHUBTOKEN" ] && failquit "GITHUBTOKEN must be set."
[ -z "$ORGNAME" ] && failquit "ORGNAME must be set."
[ -z "$GITHUBUSER" ] && failquit "GITHUBUSER must be set."

# Only support one repo for now. Multiple should be simple.
REPO=$1
REPOS=\"$ORGNAME/$REPO\"

[ -z "$(which curl 2> /dev/null)" ] && failquit 'You need to install curl.'

migrationurl=$( \
	curl -s -H "Authorization: token $GITHUBTOKEN" -X POST \
		-H "Accept: application/vnd.github.wyandotte-preview+json" \
		-d'{"lock_repositories":'"$LOCKREPOS"',"repositories":['"$REPOS"']}' \
		"https://api.github.com/orgs/$ORGNAME/migrations" | \
		grep '"url"' | grep migrations | cut -d \" -f 4
	)


while sleep 10; do
	state=$(
		curl -s -H "Authorization: token $GITHUBTOKEN" \
			-H "Accept: application/vnd.github.wyandotte-preview+json" \
			"$migrationurl" | grep '"state"'
		)
	echo "$migrationurl: $state"
	echo $state | grep -q exported && break
	echo "Polling again in ten seconds."
done

curl -u $GITHUBUSER:$GITHUBTOKEN \
	-H "Accept: application/vnd.github.wyandotte-preview+json" \
	-L -o $ARCHIVE \
	"$migrationurl/archive"

ls -l $ARCHIVE
