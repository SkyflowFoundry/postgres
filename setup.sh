#!/bin/bash

# Configuration
PORT=5433

function prompt_skyflow_config() {
    # Prompt for Skyflow configuration
    read -p "Enter your Skyflow Account ID: " ACCOUNT_ID
    read -p "Enter your Skyflow Vault ID: " VAULT_ID
    read -p "Enter your Skyflow Auth Token or API Key: " BEARER_TOKEN

    # Validate inputs are not empty
    if [ -z "$VAULT_ID" ] || [ -z "$ACCOUNT_ID" ] || [ -z "$BEARER_TOKEN" ]; then
        echo "Error: All Skyflow configuration values must be provided"
        exit 1
    fi

    # Create temporary SQL file with replaced values
    echo "Configuring Skyflow settings..."
    sed -e "s/__SKYFLOW_VAULT_ID__/$VAULT_ID/g" \
        -e "s/__SKYFLOW_ACCOUNT_ID__/$ACCOUNT_ID/g" \
        -e "s/__SKYFLOW_BEARER_TOKEN__/$BEARER_TOKEN/g" \
        postgres_setup.sql > postgres_setup_temp.sql
}

function create() {
    echo "Installing PostgreSQL 17..."
    brew install postgresql@17

    echo "Installing build dependencies..."
    brew install curl
    brew install pkg-config

    # Add PostgreSQL to PATH
    echo "Adding PostgreSQL to PATH..."
    export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH"

    # Configure PostgreSQL to use custom port
    echo "Configuring PostgreSQL port..."
    echo "port = $PORT" >> /opt/homebrew/var/postgresql@17/postgresql.conf

    echo "Starting PostgreSQL service..."
    brew services start postgresql@17

    # Wait for PostgreSQL to be ready with proper connection check
    echo "Waiting for PostgreSQL to be ready..."
    max_attempts=30
    attempt=1
    until pg_isready -h localhost -p $PORT >/dev/null 2>&1 || [ $attempt -eq $max_attempts ]; do
        echo "Waiting for PostgreSQL to start (attempt $attempt of $max_attempts)..."
        attempt=$((attempt + 1))
        sleep 1
    done

    if [ $attempt -eq $max_attempts ]; then
        echo "Failed to connect to PostgreSQL after $max_attempts attempts. Exiting..."
        exit 1
    fi

    echo "PostgreSQL is ready!"

    echo "Installing PostgreSQL HTTP extension..."
    git clone https://github.com/pramsey/pgsql-http.git
    cd pgsql-http
    make USE_PGXS=1
    make USE_PGXS=1 install
    cd ..
    rm -rf pgsql-http

    # Prompt for Skyflow configuration before database setup
    prompt_skyflow_config

    echo "Creating database..."
    createdb -p $PORT skyflow_demo

    echo "Running setup SQL..."
    psql -p $PORT -d skyflow_demo -f postgres_setup_temp.sql
    rm postgres_setup_temp.sql  # Clean up temporary SQL file

    echo "Setup complete!"
    echo
    echo "Connection Details:"
    echo "Host: localhost"
    echo "Port: $PORT"
    echo "Database: skyflow_demo"
    echo "User: $USER (your system username)"
    echo "Password: (none)"
    echo "SSL: disabled"
    echo
}

function destroy() {
    echo "Stopping PostgreSQL service..."
    brew services stop postgresql@17

    echo "Uninstalling PostgreSQL..."
    brew uninstall postgresql@17

    echo "Removing PostgreSQL data directory..."
    rm -rf /opt/homebrew/var/postgresql@17

    echo "Cleanup complete!"
    echo
    echo "Note: You may want to remove the PostgreSQL PATH from your ~/.zshrc or ~/.bash_profile if you added it"
    echo 'The line to remove is: export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH"'
}

# Check command line argument
case "$1" in
    "create")
        create
        ;;
    "destroy")
        destroy
        ;;
    "recreate")
        destroy
        create
        ;;
    *)
        echo "Usage: $0 {create|destroy|recreate}"
        echo
        echo "Commands:"
        echo "  create  - Install and configure PostgreSQL with Skyflow demo"
        echo "  destroy - Stop and remove PostgreSQL installation"
        echo "  recreate - Perform a destroy and a then a create"
        exit 1
        ;;
esac
