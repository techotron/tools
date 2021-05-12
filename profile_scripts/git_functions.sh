#/bin/bash

function convert_public_github() {
    REPO_URL=`git remote -v | grep -m1 '^origin' | sed -Ene's#.*(https://[^[:space:]]*).*#\1#p'`
    if [ -z "$REPO_URL" ]; then
        echo "-- ERROR:  Could not identify Repo url."
        echo "   It is possible this repo is already using SSH instead of HTTPS."
        exit 1
    fi

    USER=`echo $REPO_URL | sed -Ene's#https://github.com/([^/]*)/(.*)#\1#p'`
    if [ -z "$USER" ]; then
        echo "-- ERROR:  Could not identify User."
        exit 1
    fi

    REPO=`echo $REPO_URL | sed -Ene's#https://github.com/([^/]*)/(.*)#\2#p'`
    if [ -z "$REPO" ]; then
        echo "-- ERROR:  Could not identify Repo."
        exit 1
    fi

    NEW_URL="git@github.com:$USER/$REPO.git"
    echo "Changing repo url from "
    echo "  '$REPO_URL'"
    echo "      to "
    echo "  '$NEW_URL'"
    echo ""

    git remote set-url origin $NEW_URL

    echo "Success"
}
