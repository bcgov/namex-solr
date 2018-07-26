// Be in the tools project

// First - build the base solr image

// check the file for sanity
(venv) NDM050057:templates vboettch$ oc process -f namex-solr-base-build.json

// A JSON output means it's valid.  Not necessarily correct, but it's valid JSON.

// Now actually build it
(venv) NDM050057:templates vboettch$ oc process -f namex-solr-base-build.json | oc create -f -
imagestream "namex-solr-base" created
buildconfig "namex-solr-base" created

# Solr Deployment Notes

Apache Solr is the search index database used by the name examination system.

This documentation describes the process used when recreating the `namex-solr-base` build and image in the
`servicebc-ne-tools` OpenShift project. These steps must be performed before the `solr` build and image can be created.

This documentation assumes that `oc.exe` from OpenShift Origin Client Tools has been installed and that the user has
an account on the Pathfinder OpenShift cluster.

## Log in to OpenShift

Log into the [OpenShift Web Console](https://console.pathfinder.gov.bc.ca:8443/console). Click the drop-down for your
username in the upper-right corner, and select `Copy Login Command`. Paste the command into your shell:

```
C:\> oc login https://console.pathfinder.gov.bc.ca:8443 --token=<blahblahblah>
Logged into "https://console.pathfinder.gov.bc.ca:8443" as "<username>" using the token provided.

You have access to the following projects and can switch between them with 'oc project <projectname>':

    servicebc-ne-dev
    servicebc-ne-test
  * servicebc-ne-tools

Using project "servicebc-ne-tools".
```

(Note that you could also run `oc login` and enter the same credentials).

## Creating the `namex-solr-base` Build

Creating the `namex-solr-base` build only needs to be once. Subsequent changes are picked up by *replacing*, below. As
the creation process is nearly identical to the replacement process, just follow the replacement instructions except
using `create` rather than `replace` for the final `oc` call.

## Replacing the `namex-solr-base` Build

*This step is used when the `namex-base-solr` build already exists in the OpenShift project `servicebc-ne-tools`, but it
needs to be updated.*

### Replacing the Build

Ensure that your current project is `servicebc-ne-tools`:

```
C:\> oc project servicebc-ne-tools
```

Change directory to the OpenShift template files in your local copy of the `bcgov/namex-solr` repository:

```
C:\> cd \<path>\namex-solr\openshift\templates
C:\<path>\namex-solr\openshift\templates>
```

Generate the configuration file from the template, and pipe the output back into `oc` to replace the build:

```
C:\<path>\namex\solr\openshift> oc process -f namex-solr-base-build.json | oc replace -f -
imagestream "namex-solr-base" replaced
buildconfig "namex-solr-base" replaced
```

In the OpenShift Web Console go to the `names examination (tools)` project, and then `Builds` > `Builds`. Wait for the
`solr` build to change Status to `Running` and then to `Complete`. You can also check the Created value to ensure that
it is recent. 

In the OpenShift Web Console go to the `names examination (tools)` project, and then `Builds` > `Images`. Click the
`solr` image and the tag `Latest` should now have been updated. The image needs to be tagged in order to get it into a
specific environment.
