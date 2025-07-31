#!/usr/bin/env bash
# Helper functions for install script - validation and performance improvements

# Input validation functions
validate_hostname() {
    local hostname="$1"
    if [[ ! "$hostname" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{0,62}$ ]]; then
        echo "Invalid hostname: must start with alphanumeric, contain only alphanumeric and hyphens, max 63 chars"
        return 1
    fi
    return 0
}

validate_username() {
    local username="$1"
    if [[ ! "$username" =~ ^[a-z_][a-z0-9_-]{0,31}$ ]]; then
        echo "Invalid username: must start with lowercase letter or _, contain only lowercase, numbers, _, -, max 32 chars"
        return 1
    fi
    return 0
}

validate_disk() {
    local disk="$1"
    if [[ ! -b "$disk" ]]; then
        echo "Invalid disk: $disk is not a block device"
        return 1
    fi
    
    # Check if disk is mounted
    if mount | grep -q "^$disk"; then
        echo "Warning: $disk appears to be mounted"
        return 1
    fi
    
    return 0
}

validate_profile() {
    local profile="$1"
    local valid_profiles="$2"
    
    if [[ ! " $valid_profiles " =~ " $profile " ]]; then
        echo "Invalid profile: $profile"
        echo "Valid profiles: $valid_profiles"
        return 1
    fi
    return 0
}

validate_zfs_hostid() {
    local hostid="$1"
    if [[ ! "$hostid" =~ ^[0-9a-fA-F]{8}$ ]]; then
        echo "Invalid ZFS host ID: must be exactly 8 hexadecimal characters"
        return 1
    fi
    return 0
}

validate_email() {
    local email="$1"
    if [[ ! "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        echo "Invalid email address format"
        return 1
    fi
    return 0
}

# Progress indicator functions
progress_start() {
    local message="$1"
    echo -ne "${CYAN}⏳ ${message}...${NC}"
}

progress_done() {
    echo -e " ${GREEN}✓${NC}"
}

progress_fail() {
    local error="$1"
    echo -e " ${RED}✗${NC}"
    [[ -n "$error" ]] && echo -e "${RED}   Error: $error${NC}"
}

# Spinner for long operations
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    
    while kill -0 $pid 2>/dev/null; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Parallel validation
validate_all_inputs() {
    local -n errors=$1
    local -a validation_pids=()
    local validation_failed=false
    
    # Run validations in parallel
    (
        if ! validate_hostname "$HOSTNAME"; then
            echo "hostname:$?"
        fi
    ) > /tmp/validate_hostname.$$ &
    validation_pids+=($!)
    
    (
        if ! validate_username "$USERNAME"; then
            echo "username:$?"
        fi
    ) > /tmp/validate_username.$$ &
    validation_pids+=($!)
    
    (
        if ! validate_disk "$DISK"; then
            echo "disk:$?"
        fi
    ) > /tmp/validate_disk.$$ &
    validation_pids+=($!)
    
    # Wait for all validations
    for pid in "${validation_pids[@]}"; do
        wait $pid
    done
    
    # Collect errors
    for field in hostname username disk; do
        if [[ -s "/tmp/validate_$field.$$" ]]; then
            errors["$field"]=$(cat "/tmp/validate_$field.$$")
            validation_failed=true
        fi
        rm -f "/tmp/validate_$field.$$"
    done
    
    return $([ "$validation_failed" = true ] && echo 1 || echo 0)
}

# Performance optimization for nix operations
optimize_nix_build() {
    # Set optimal nix settings for the operation
    export NIX_BUILD_CORES=$(nproc)
    export NIX_MAX_JOBS=$(($(nproc) / 2))  # Conservative to avoid OOM
    
    # Enable build caching
    export NIX_CONF_DIR=$(mktemp -d)
    cat > "$NIX_CONF_DIR/nix.conf" << EOF
max-jobs = $NIX_MAX_JOBS
cores = $NIX_BUILD_CORES
http-connections = 50
connect-timeout = 5
download-attempts = 3
fallback = true
keep-outputs = true
keep-derivations = true
EOF
}

# Check system resources before operation
check_resources() {
    local min_memory_gb=${1:-4}
    local min_disk_gb=${2:-20}
    
    # Check available memory
    local mem_available=$(free -g | awk '/^Mem:/{print $7}')
    if (( mem_available < min_memory_gb )); then
        echo "Warning: Low memory available (${mem_available}GB < ${min_memory_gb}GB required)"
        return 1
    fi
    
    # Check disk space
    local disk_available=$(df -BG /nix 2>/dev/null | awk 'NR==2 {print $4}' | sed 's/G//')
    if (( disk_available < min_disk_gb )); then
        echo "Warning: Low disk space in /nix (${disk_available}GB < ${min_disk_gb}GB required)"
        return 1
    fi
    
    return 0
}

# Export functions for use in main script
export -f validate_hostname validate_username validate_disk validate_profile
export -f validate_zfs_hostid validate_email
export -f progress_start progress_done progress_fail spinner
export -f validate_all_inputs optimize_nix_build check_resources