# Skyflow for PostgreSQL Demo

A simple demonstration of using Skyflow's tokenization with PostgreSQL using BEFORE INSERT/UPDATE triggers.

## Features
- Automatic tokenization of PII data (name, email, phone, address) on insert/update
- Detokenization support using SKYFLOW_DETOKENIZE function
- Demonstrates both single row and batch operations
- Uses PostgreSQL's trigger system for seamless integration
- Direct HTTP requests to Skyflow API using PostgreSQL's HTTP extension

## Requirements
- Homebrew (for installation)
- Skyflow credentials:
  - Account ID
  - Vault ID
  - Auth Token/API Key

## Vault Creation
Before proceeding with the setup, you'll need to create a vault in Skyflow:

1. Log into your Skyflow account
2. Create a new vault using the included vault schema file (`vaultSchema.json`)
   - This schema defines a table for storing PII data with appropriate tokenization policies
   - The schema includes a `pii` table with fields for storing sensitive information
   - Tokenization is configured using DETERMINISTIC_FPT policy, for deterministic + format-preserving tokens.
3. Once created, note down the Vault ID as it will be needed during setup

## Setup

Use the provided setup script to manage the PostgreSQL environment:

```bash
# Create environment
./setup.sh create

# Destroy environment
./setup.sh destroy

# Recreate environment
./setup.sh recreate

# Show usage
./setup.sh
```

The create/recreate commands will:
- Install and configure PostgreSQL 17
- Install required extensions
- Prompt for your Skyflow credentials
- Set up the demo database and tables

## Example Usage
```sql
-- Insert a customer (PII fields will be automatically tokenized)
INSERT INTO customers (
    name, 
    email, 
    phone, 
    address, 
    lifetime_purchase_amount, 
    customer_since
) VALUES (
    'John Smith',
    'john@example.com',
    '555-222-5555',
    '123 Fake Street NY NY 10019',
    5000,
    '2020-01-01'
);

-- Query the data to see tokenized values
SELECT * FROM customers;

-- Query with detokenization
SELECT SKYFLOW_DETOKENIZE(name), SKYFLOW_DETOKENIZE(email), customer_since 
FROM customers;
