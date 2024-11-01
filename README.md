# Pages Download Script

This repository contains a script to download Power Pages content and create deployment profiles. The script is generalized to work with different environments and table names.

## Features

- Verbose output for detailed logging.
- Option to overwrite existing folders.
- Handles 1-based indexing as displayed by `pac powerpages list`.
- Converts 1-based index to 0-based index for internal processing.
- Sanitizes the friendly name to create a safe folder name.
- Error handling to check if the folder already exists and prompt for confirmation if the `-overwrite` flag is not set.
- Ensures the correct usage of the `--websiteid` flag and `--modelVersion 2` in the `pac powerpages download` command.
- Creates a deployment profile folder and YAML file if it doesn't already exist.
- Generates dynamic GUIDs for `adx_sitesettingid` values using Python.
- Includes `Webapi/error/innererror` setting only if no profile is provided, assuming dev/test environments.
- Ensures the deployment profile folder is created inside the actual folder containing the downloaded portal content.
- Generalized by replacing specific environment names and table names with placeholders.

## Usage

### Command-Line Options

- `-verbose`: Enable verbose output.
- `-o` or `-overwrite`: Overwrite existing folders without confirmation.
- `-profile <profile>`: Specify the deployment profile name [dev | test | prod]
- `-env <environment>`: Specify the environment name.
- `-table <table_name>`: Specify the table name.

### Example Command


$ ./pages-download.sh -env *your-environment* -table *your_table_name* -profile *your_profile_name* 2

*Note: This command will download the 2nd item in the list.*

*If you omit the number, the script will show the list of Power Pages without downloading any:*

$ ./pages-download.sh -env your-environment -table your_table_name -profile your_profile_name

#### Parameters

- `<environment>`: The name of the environment to authenticate to.
- `<table_name>`: The name of the table for which to enable Web API permissions.
- `<profile_name>`: The name of the deployment profile.
- n: The index of the Power Page to download (1-based index).

#### Script Details

The script performs the following steps:

1. Parses command-line options and sets variables.
2. Authenticates to the specified environment if not already authenticated.
3. Lists current authentication profiles.
4. Lists Power Pages and captures the output into an array.
5. Prints the array for verification.
6. Downloads the selected Power Page based on the provided index.
7. Generates dynamic GUIDs for adx_sitesettingid values using Python.
8. Creates a deployment profile folder and YAML file if it doesn't already exist.
9. Includes the Webapi/error/innererror setting only if no profile is provided, assuming dev/test environments.

### Requirements

- **Python**: The script uses Python to generate UUIDs.
- **Power Platform CLI**: The script uses pac commands to interact with Power Pages.

### License

This project is licensed under the MIT License. See the LICENSE file for details.

### Contributing

Contributions are welcome! Please open an issue or submit a pull request for any improvements or bug fixes.

### Contact

For questions or support, please contact the repository owner.

