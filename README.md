# Blaster!

Configuration file blaster!  Use tokens to easily create configuration files for multiple environments.

The Blaster! script provides a very simple mechanism for keeping environment sensitive data away from the developers.

Blaster has these goals:

* Keep it simple
* Make it easy for developers
* Make it easy for the release team

The general idea is that Blaster will merge a *.blaster file with a *.environment.[url|data] file to create your config files. The actual config file is never checked into the SCCM system. Developers generate their config file while developing and the system_test and production config files are generated during the release.

Developers will run the "blaster" command and it will recurivly search the current directory for *.blaster files and create your config files for your development environment. This is the exact same procedure the release team performs before going to system_test or production. The advantage here is that you, as the developer, are always testing the *.blaster file and it's replacement file for that environment.

## Identify your config files with passwords or specific environment data.

Look for files that have any "sensitive" information like user id's or passwords.  You can also identify any environment specific items.  For example:

```
database_user:
database_password:
host:
port:
```

### Prepare a config file

Here is a stanza from a database.yml file that contains parameters for the environment and passwords:

```yaml
adapter: mysql2
database: my_dev_database
username: root
password:
host: localhost
port: 3306
```

### We will then create a database.yml.blaster:

```yaml
adapter: mysql2
database: %%DATABASE_NAME%%
username: %%DATABASE_USER%%
password: %%DATABASE_PASS%%
host: %%DATABASE_HOST%%
port: %%DATABASE_PORT%%
```
### Create a file called database.yml.development.data like this:

```
s/%%DATABASE_NAME%%/myapp_development/g
s/%%DATABASE_USER%%/root/g
s/%%DATABASE_PASS%%//g
s/%%DATABASE_HOST%%/localhost/g
s/%%DATABASE_PORT%%/3306/g
````
### When you run the blaster.sh command it will create the database.yml file:

```bash
blaster.sh -e development
```
Blaster will read a file called *environment.data first, if that does not exist it will read *environment.url. If there is a ".url" file, it will "get" the contents of that file to use as the data file.

For example:

```bash
cat database.yml.system_test.url
https://config1.example.com/blaster/trunk/myapp/database.yml.system_test.data
```

When you use a ".url" file you will have to pass the appropriate SVN credentials to blaster. This allows the release team access to the sensitive data only.

```bash
blaster.sh -e development -u svc_user -p ******
```

## Sample Setup

For every environment:

    development
    system_test
    production

Create the following files for database.yml:

    database.yml.blaster
    database.yml.local.data
    database.yml.system_test.url
    database.yml.production.url

The release team will copy your database.yml.local.data file to there repository and change appropriately for that environment. They will provide you with the URL to that file which you will put as the 1st line in the ".url" file.

All of these files will be checked into SCM.

The original database.yml should be removed from SCM, and the ignore property should be set for that file.



