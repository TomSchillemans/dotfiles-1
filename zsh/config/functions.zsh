# DO NOT EDIT THIS FILE
# duplicate this file in zsh/config/zshfunctions
# to enable/add your own custom configuration

# Create and CD into the just created folder
function take() {
    mkdir -p $@ && cd ${@:$#}
}

#Switch PHP versions using Homebrew.
function switchphp() {
    brew unlink php && brew link --force --overwrite php@$1
}

# Which commands do you use the most
function zsh_stats() {
    fc -l 1 | awk '{CMD[$2]++;count++;}END { for (a in CMD)print CMD[a] " " CMD[a]/count*100 "% " a;}' | grep -v "./" | column -c3 -s " " -t | sort -nr | nl |  head -n20
}

function open_command() {
    local open_cmd

    # define the open command
    case "$OSTYPE" in
        darwin*)  open_cmd='open' ;;
        cygwin*)  open_cmd='cygstart' ;;
        linux*)   ! [[ $(uname -a) =~ "Microsoft" ]] && open_cmd='xdg-open' || {
            open_cmd='cmd.exe /c start ""'
        [[ -e "$1" ]] && { 1="$(wslpath -w "${1:a}")" || return 1 }
    } ;;
msys*)    open_cmd='start ""' ;;
*)        echo "Platform $OSTYPE not supported"
    return 1
    ;;
  esac

  # don't use nohup on OSX
  if [[ "$OSTYPE" == darwin* ]]; then
      ${=open_cmd} "$@" &>/dev/null
  else
      nohup ${=open_cmd} "$@" &>/dev/null
  fi
}

#########################
# Non OS specific functions to deal with some things
#########################

# Checks if phpunit is installed in vendor folder or if we should use global one.
function get_phpunit_install() {
    if [ -f vendor/bin/paratest ]; then
        echo './vendor/bin/paratest'
    elif [ -f vendor/bin/phpunit ]; then
        echo './vendor/bin/phpunit'
    else
        echo 'phpunit'
    fi
}

# Checks if drush is installed in vendor folder or if we should use global one.
function get_drush_install() {
    if [ -f  vendor/drush/drush/drush ]; then
        echo './vendor/drush/drush/drush'
    else
        echo 'drush'
    fi
}

if [[ "$(declare -f build_project_assets > /dev/null; echo $?)" = 1 ]]; then
    # Check current directory asset building dependencies, install and build them
    function build_project_assets() {
        # Check for composer install
        if [[ -f composer.json ]]; then
            # Install dependencies
            composer install
        fi

        # Check for NPM lock file else use YARN
        if [[ -f package-lock.json ]]; then
            # Install dependencies
            npm install
            # Compile assets
            npm run dev
        elif [[ -f package.json ]]; then
            # Install dependencies
            yarn install
            # Compile assets
            yarn run dev
        fi
    }
fi

# Check current directory assets building dependencies, install and watch them
function watch_project_assets() {
    # Check for NPM lock file else use YARN
    if [[ -f package-lock.json ]]; then
        # Install dependencies
        npm run dev

        # Run watch task
        npm run watch
    elif [[ -f package.json ]]; then
        # Install dependencies
        yarn run dev

        # Run watch task
        yarn run watch
    fi
}

# First get location of current folders Yii file and run it with given arguments
function run_yiic() {
    # Set default Yii location to current dir
    export YII_APP=./protected/yiic

    # If default isn't found, go look for it
    if [[ ! -f ${YII_APP} ]]; then
        find_yiic
    fi

    LOCATION='\033[33myiic not found\033[0m'

    if [[ "$YII_APP" != "" ]] && [[ -f ${YII_APP} ]]; then
        LOCATION="\033[33m$YII_APP\033[0m"
    fi

USAGE="\033[33mUsage:\033[0m art [-h]

Run yiic command from anywhere in your project.

Currently using: $LOCATION

\033[33mOptions:\033[0m
    \033[92m-h\033[0m  Show this help text.
    "

    while getopts ':h' option; do
        case "$option" in
            h) echo -e "$USAGE"
                return 1
                ;;
        esac
    done

    # Do Yii magic with a kick!
    if [[ "$YII_APP" != "" ]] && [[ -f ${YII_APP} ]]; then
        php -d memory_limit=512M $YII_APP $@
    else
        echo -e "$USAGE"
    fi
}

# Do magic to find current projects yiic file
function find_yiic() {
    # Check current folder for yiic, then the parent, then then parents parent, etc., etc.
    DIRECTORY=..; until [[ -e ${DIRECTORY}/protected/yiic || ${DIRECTORY} -ef / ]]; do DIRECTORY+=/..; done

    # Convert path to absolute path
    DIRECTORY=`cd "$DIRECTORY"; pwd`

    # Add default location to path
    APP=${DIRECTORY}/protected/yiic

    # Update global variable
    if [[ "$APP" != "" ]]; then
        YII_APP=$APP
    fi
}

# Remove a file from gits history entirely
function git_history_remove() {
    if ! [[ -d "$(pwd)/.git" ]]; then
        echo "Halt: .git folder not found"

        return 0
    fi

    if [[ $# -eq 0 ]]; then
        echo "Halt: no target given"

        return 0
    else
        TARGET=$1
    fi

    read "?Are you sure you want to remove '$TARGET' from the git history? "

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo # Whitespace

        git stash

        echo -e "\nRemoving '$TARGET' from history"
        git filter-branch --tree-filter 'rm -rf $FOLDER' --prune-empty HEAD

        echo -e "\nRemoving '$TARGET' references"
        git for-each-ref --format="%(refname)" refs/original/ | xargs -n 1 git update-ref -d

        echo -e "\nStarting garbage collection"
        git gc --prune=all --aggressive

        echo # Whitespace

        git stash pop
    fi
}
####################################
# OS specific functions
####################################

if [[ "$OSTYPE" == "linux-gnu" ]]; then
    # Linux functions can go here.
elif [[ "$OSTYPE" == "darwin"* ]]; then
    # Custom MAC OSX functions

    #Fix displaying of ugly user.
    prompt_context() {
        if [[ "$USER" != "$DEFAULT_USER" || -n "$SSH_CLIENT" ]]; then
            prompt_segment black default "%(!.%{%F{yellow}%}.)$USER"
        fi
    }
fi
