export AUTOSWITCH_VERSION='1.11.1'

RED="\e[31m"
GREEN="\e[32m"
PURPLE="\e[35m"
BOLD="\e[1m"
NORMAL="\e[0m"

function _autoswitch_message() {
    if [ -z "$AUTOSWITCH_SILENT" ]; then
        printf "$@"
    fi
}


# Gives the path to the nearest parent .venv file or nothing if it gets to root
function _check_venv_path()
{
    local check_dir="$1"

    if [[ -e "${check_dir}/env" ]]; then
        printf "${check_dir}/env"
        return
    else
        # Abort search at file system root or HOME directory (latter is a perfomance optimisation).
        if [[ "$check_dir" = "/" || "$check_dir" = "$HOME" ]]; then
            return
        fi
        _check_venv_path "$(dirname "$check_dir")"
    fi
}

# Automatically switch virtualenv when .venv file detected
function check_venv()
{
    # Get the .venv file, scanning parent directories
    local venv_path=$(_check_venv_path "$PWD")
    if [[ -n "$venv_path" ]]; then
        if [[ -z $VIRTUAL_ENV ]]; then
            source $venv_path/bin/activate
        fi
        return
    fi
    _default_venv
}

# Switch to the default virtual environment
function _default_venv()
{
    if which deactivate > /dev/null; then
        deactivate
    fi
    return
}


# remove virtual environment for current directory
function rmvenv()
{
    if [[ -f ".venv" ]]; then
        /bin/rm -fR env
    else
        printf "No .venv file in the current directory!\n"
    fi
}


# helper function to create a virtual environment for the current directory
function mkvenv()
{
    if [[ -e "env" ]]; then
        printf "env already exists. If this is a mistake use the rmvenv command\n"
    else
        python3 -m venv env
        source env/bin/activate
        install_requirements
    fi
}


function install_requirements() {
    if [[ -f "$AUTOSWITCH_DEFAULT_REQUIREMENTS" ]]; then
        printf "Install default requirements? (${PURPLE}$AUTOSWITCH_DEFAULT_REQUIREMENTS${NORMAL}) [y/N]: "
        read ans

        if [[ "$ans" = "y" || "$ans" == "Y" ]]; then
            pip install -r "$AUTOSWITCH_DEFAULT_REQUIREMENTS"
        fi
    fi

    if [[ -f "$PWD/setup.py" ]]; then
        printf "Found a ${PURPLE}setup.py${NORMAL} file. Install dependencies? [y/N]: "
        read ans

        if [[ "$ans" = "y" || "$ans" = "Y" ]]; then
            if [[ "$AUTOSWITCH_PIPINSTALL" = "FULL" ]]
            then
                pip install .
            else
                pip install -e .
            fi
        fi
    fi

    setopt nullglob
    local requirements
    for requirements in **/*requirements.txt
    do
        printf "Found a ${PURPLE}%s${NORMAL} file. Install? [y/N]: " "$requirements"
        read ans

        if [[ "$ans" = "y" || "$ans" = "Y" ]]; then
            pip install -r "$requirements"
        fi
    done
}


function enable_autoswitch_virtualenv() {
    autoload -Uz add-zsh-hook
    disable_autoswitch_virtualenv
    add-zsh-hook chpwd check_venv
}


function disable_autoswitch_virtualenv() {
    add-zsh-hook -D chpwd check_venv
}


enable_autoswitch_virtualenv
check_venv
