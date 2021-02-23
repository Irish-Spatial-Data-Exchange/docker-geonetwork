# Docker File Build + Deployment

The included _dockerfile_ builds a vanilla install of **GeoNetwork** using a custom implementation of an underlying UBUNTU container.

With this container, you have the ability to pull any version of **GeoNetwork**, implement custom code and rebuild it into a deployable **WAR** file.

Container WAR File Location: \geonetwork\web\target.

## Detailed Build Steps

**IMPORTANT: Any files included in this github repository must be included in the 'geonetwork_build' maven config script (if you have one), otherwise files will not be picked up by the build. Ensure your files are included in the build script before starting a build.**

Run the following:

- Launch a new Git CMD Window and naviagte to (or create) a folder for your git local repositories.

Run the commands:

- `git clone --recurse-submodules https://github.com/geonetwork/core-geonetwork.git geonetwork`
- `cd geonetwork`
- `git checkout tags/3.10.6 -b build`
- `git status`

Run a clean build by running the command:

- `mvn clean install -DskipTests`

The build should be sucessfull.
Note: Maven default location: C:\Users\<user>\.m2\repository. Output WAR is stored in: **\geonetwork\web\target**

Pull in sub-modules for Plugins:

- navigate to 'geonetwork\schemas' directory.

Run commands:

- `git submodule add https://github.com/metadata101/sensorML.git sensorML`
- `git submodule add https://github.com/metadata101/iso19139.sdn-csr.git`
- `git submodule add https://github.com/metadata101/iso19139.sdn-cdi.git`

Navigate to the data-catalogue repository and run the custom script: geonetwork_build.xml. This is an ant build script and will copy all required custom content into the build branch of the geonetwork repository (created earlier).

- `cd data-catalogue`
- `ant -buildfile geonetwork_build.xml`

The build (copy files) should complete successfully.

The final step is to navigate back to the 'geonetwork' repository and re-run the Maven build. This will build a new version of the geonetwork application with MI specific changes applied.

- `mvn clean install -DskipTests`

The build should be sucessfull. The final build output is an output WAR file stored in: \geonetwork\web\target.

## Geonetwork h2 Database

The default loctaion of the geonetwork h2 databse is: `\Apache Software Foundation\Tomcat 9.0`
The following files are created:

`gn.h2.db`
`gn.lock.db`
`gn.trace.db`
`gn.trace.db.old`

To deploy a fully clean version, the above files should be deleted and a new data harvest performed.

## Deployment

- Take WAR file made from the steps described.
- Deploy in **WebApps** folder of an installed Tomcat instance - Stop and Start Tomcat. (Memory of 2GB needed - Java 8 and Tomcat 8 recommended by devs (9 works too though).
- Log-in to the GeoNetwork instance (initially default as `Admin/Admin`): `/geonetwork/srv/eng/catalog.signin`
- Under Admin Console:
  - Change the password: `/geonetwork/srv/eng/admin.console#/organization`
  - Change the catalogue name, organisation, host (e.g. [isde.ie]), preferred protocol and save changes: `/geonetwork/srv/eng/admin.console#/settings`
  - Run harvest: Create directory harvest (name it), run from the folder where the XML data has been saved to,
    - Group: `Sample Group`
    - User: `Admin`
    - Directory: `Local file location`
    - Uncheck `keep catalog record even if deleted at source`
    - Type of Record: `Metadata`
    - Ensure all is clicked
- Go to Tools and click `rebuild index`.

- Alternatively, use the _dockerfile_ included in this repo.

## TODO

- Create Docker network for two containers to separate tomcat container for Deployment of selected GeoNetwork build.
