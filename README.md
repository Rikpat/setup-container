# Setup Container

This is a container image built to simplify setup of services running on kubernetes.

As of now, it consists of 2 scripts
- **envsubst.sh** - Loads files in /workdir folder *recursively*, runs envsubst and copies to /processed folder - inspired by [fabric8io/envsubst](https://github.com/fabric8io/envsubst/blob/master/envsubst-file.sh)
- **zip.sh** - Downloads zip files from `ZIP_URLS` and unpacks them in directory specified in `ZIP_DESTINATION_PATH` env variable.

Container scripts run as user specified in env variables `PUID`:`PGID` as in linuxserver.io containers. This only works if the default entrypoint is used (so use args instead of command to specify the desired script), but preferably the user should be set using securityContext (examples have both).

## Examples

To show the use case for both scripts we will be working with [Jellyfin container provided by linuxserver.io](https://docs.linuxserver.io/images/docker-jellyfin/). This configuration will automatically set up LDAP auth plugin. 
Scripts can be run both as initContainer or a job.


### EnvSubst as an initContainer

Envsubst script is made for loading data from configMap and putting in environment values from secrets, then copying the config file to mounted volume. This also keeps the config file read/write if the app needs it (but is overwritten on restart if it's used as initcontainer - consider using as job with hook for configmap if changing config in UI often).

Example deployment.yaml part for setting up config file
```yaml
...
initContainers:
  - name: init-config
    image: ghcr.io/rikpat/setup-container
    securityContext:
      runAsGroup: 990
      runAsUser: 990
    env:
      - name: PGID
        value: "990"
      - name: PUID
        value: "990"
    envFrom:
      - secretRef:
          name: lldap
    volumeMounts:
      - name: "jellyfin-config"
        mountPath: /target
      - name: "jellyfin-configfiles"
        mountPath: "/workdir"
volumes:
  - name: "jellyfin-config"
    persistentVolumeClaim:
      claimName: "jellyfin-config"
  - name: "jellyfin-configfiles"
    configMap:
      name: "jellyfin-configfiles"
      items:
        - key: "LDAP-Auth.xml"
          path: data/plugins/configurations/LDAP-Auth.xml

```

Configmap Definition (notice `$LLDAP_BIND_USER`, `$LLDAP_BIND_PASSWORD` and `$LLDAP_BASE_DN`):
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: "jellyfin-configfiles"
  labels:
    ...
data:
  "LDAP-Auth.xml": |
      <?xml version="1.0" encoding="utf-8"?>
      <PluginConfiguration xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
        <LdapUsers />
        <LdapServer>lldap.auth.svc.cluster.local</LdapServer>
        <LdapPort>3890</LdapPort>
        <UseSsl>false</UseSsl>
        <UseStartTls>false</UseStartTls>
        <SkipSslVerify>false</SkipSslVerify>
        <LdapBindUser>$LLDAP_BIND_USER</LdapBindUser
        <LdapBindPassword>$LLDAP_BIND_PASSWORD</LdapBindPassword>
        <LdapBaseDn>ou=people,$LLDAP_BASE_DN</LdapBaseDn>
        <LdapSearchFilter>(memberOf=cn=mediaUsers,ou=groups,$LLDAP_BASE_DN)</LdapSearchFilter>
        <LdapAdminBaseDn />
        <LdapAdminFilter>(memberOf=cn=admin,ou=groups,$LLDAP_BASE_DN)</LdapAdminFilter>
        <EnableLdapAdminFilterMemberUid>false</EnableLdapAdminFilterMemberUid>
        <LdapSearchAttributes>uid, cn, mail, displayName</LdapSearchAttributes>
        <LdapClientCertPath />
        <LdapClientKeyPath />
        <LdapRootCaPath />
        <CreateUsersFromLdap>true</CreateUsersFromLdap>
        <AllowPassChange>false</AllowPassChange>
        <LdapUidAttribute>uid</LdapUidAttribute>
        <LdapUsernameAttribute>cn</LdapUsernameAttribute>
        <LdapPasswordAttribute>userPassword</LdapPasswordAttribute>
        <EnableAllFolders>false</EnableAllFolders>
        <EnabledFolders />
        <PasswordResetUrl />
      </PluginConfiguration>
```

### Zip downloader as a job

The other script, **zip.sh** is intended for initial setup of extra files other than text. In this example it will be used for downloading the LDAP authentication plugin for jellyfin.

The example job:
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: install-extensions
spec:
  template:
    spec:
      containers:
      - name: download-and-unzip
        image: ghcr.io/rikpat/setup-container
        args: ["/scripts/zip.sh"] # notice this setting
        # args: ["/scripts/envsubst.sh && /scripts/zip.sh"] # it is also possible to run both
        securityContext:
          runAsUser: 1000
          runAsGroup: 1000
        # In this case, PUID and PGID values of 1000 are default, so they are not specified
        env:
        - name: ZIP_URLS
          # Space separated zips
          value: "https://repo.jellyfin.org/releases/plugin/ldap-authentication/ldap-authentication_18.0.0.0.zip https://example.com/some.other.zip"
        - name: ZIP_DESTINATION_PATH
          value: "/target/data/plugins"
        volumeMounts:
        - name: target
          mountPath: /target
      restartPolicy: OnFailure
      volumes:
      - name: target
        persistentVolumeClaim:
          claimName: jellyfin-config
```