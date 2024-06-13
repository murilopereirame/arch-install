#!/bin/bash

has_argument() {
    [[ ("$1" == *=* && -n ${1#*=}) || ( ! -z "$2" && "$2" != -*)  ]];
}

log () {
    status=$?
    output=""
    
    if [ "$verbose" = true ]; then
        for message in "$@"
        do
            output="$output $message"
        done
    else
        if [ "$#" -gt 0 ]; then
            if [ -n "$1" ]; then
                output=$1
            fi
        fi
    fi
    
    if [ -n "$output" ]; then
        date_time=$(date "+%Y/%m/%d %H:%M:%S")
        echo -e "${BYellow}[$date_time]${RESET} $output"
    fi
    
    if [ $status -ne 0 ]; then
        exit $?
    fi
}

extract_argument() {
    echo "${2:-${1#*=}}"
}

load_pacman_packages () {
    package_list=""
    for package in $(cat lists/packages); do
        package_list="$package_list $package"
    done
    
    echo $package_list
}

load_aur_packages () {
    package_list=""
    for package in $(cat lists/aur); do
        package_list="$package_list $package"
    done
    
    echo $package_list
}

load_services () {
    service_list=""
    for service in $(cat lists/services); do
        service_list="$service_list $service"
    done
    
    echo $service_list
}

load_hooks () {
    hooks_list=""
    for hook in $(cat lists/hooks); do
        hooks_list="$hooks_list $hook"
    done
    
    echo $hooks_list
}

load_modules () {
    modules_list=""
    for module in $(cat lists/modules); do
        modules_list="$modules_list $module"
    done
    
    echo $modules_list
}

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo " -h, --help      		Display this help message"
    echo " -v, --verbose   		Enable verbose mode"
    echo " -S, --ssid      		WiFi SSID to connect"
    echo " -P, --passphrase   	WiFi Passphrase"
    echo " -I, --interface     WiFi interface (default: wlan0)"
    echo " -W, --wifi     			Connects to WiFi network"
    echo " -D, --disk					Disk to install Arch into"
    echo " -L, --luks-password	Disk encryption Password"
    echo " -R, --reboot				Reboot when install script finishes"
    echo " -T, --time					Sets system TimeZone"
    echo " -U, --username			Sets system Username"
    echo " -p, --password			Sets User and Root password"
    echo " -H, --hostname			Sets system Hostname"
}

handle_options() {
    while [ $# -gt 0 ]; do
        case $1 in
            -h | --help)
                usage
                exit 0
            ;;
            -v | --verbose)
                verbose=true
            ;;
            -W | --wifi)
                use_wifi=true
            ;;
            -S | --ssid)
                ssid=$(extract_argument $@)
                shift
            ;;
            -P | --passphrase*)
                wifi_passphrase=$(extract_argument $@)
                shift
            ;;
            -I | --interface)
                interface=$(extract_argument $@)
                shift
            ;;
            -D | --disk)
                disk=$(extract_argument $@)
                shift
            ;;
            -L | --luks-password)
                luks_password=$(extract_argument $@)
                shift
            ;;
            -R | --reboot)
                auto_reboot=true
            ;;
            -T | --time)
                time_zone=$(extract_argument $@)
                shift
            ;;
            -U | --username)
                username=$(extract_argument $@)
                shift
            ;;
            -p | --password)
                password=$(extract_argument $@)
                shift
            ;;
            -H | --hostname)
                hostname=$(extract_argument $@)
                shift
            ;;
            *)
                echo "Invalid option: $1" >&2
                usage
                exit 1
            ;;
        esac
        shift
    done
}