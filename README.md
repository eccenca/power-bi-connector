# eccenca Corporate Memory PowerBI Connector

This component enables Microsoft PowerBI users to easily connect to Corporate Memory reports.

## Building

The build process simply zips some files and puts an `.mez` extension on the resulting archive. Thus, no special prerequisites are required.

### Windows

Run the script `build.bat <sources-folder> <target-folder>` like:

```shell
mkdir target
build.bat CMEMPowerBIConnector target
```

This will build create a `CMEMPowerBIConnector.mez` file in the folder `target`.

### Linux

Run the `build.sh` like:

```shell
./build.sh
```

This will create the `target`folder and will zip the sources to a the file `CMEMPowerBIConnector-<version>.mez`.

`build.sh` can take three positional arguments:

```shell
./build.sh <sources-folder> <target-folder> <file-prefix>

## the defaults are, if no arguments are provided:
# ./build CMEMPowerBIConnector target CMEMPowerBIConnector
```

## Installing with PowerBI Desktop

In order to install and use the Connector copy the `CMEMPowerBIConnector.mez` file into `<Your-Windows-Documents-Folder>\Power BI Desktop\Custom Connectors`, you might need to create the folders if they are not existing.
