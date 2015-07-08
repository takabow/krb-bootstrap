NOTE: This repository has couple of scripts which functions independently.

 Name          | Description
-----------------|---------------------------------
 configure_krb5.sh | This is Kerberos KDC bootstrapper which installs KDC (and dependent) packages, configures, and starts.
 enabling_krb_using_cm.sh | This enables Kerberos authentication over Hadoop cluster managed by Cloudera Manager
 disable_krb5.sh | This disables Kerberos authentication over Hadoop cluster managed by Cloudera Manager

# Kerberos KDC Bootstrapper (configure_krb5.sh)

This utility will configure and create a local Kerberos KDC for use with
Cloudera Manager and CDH.

__WARNING__

The KDC provisioned by this utility is for testing and demo purposes only.
Specifically, the master key is no where near sufficient for a production
deployment of a KDC. No production security infrastructure should ever be
deployed without a complete understanding of the technology and configuration.

Requirements:

* A CentOS/Redhat Linux workalike distribution
* Root privileges
* Intermediate Linux knowledge
* Very basic Kerberos knowledge

## What it does

Here's what running the utility will do to your system:

1. Confirm it can run on your system by checking a bunch of environmental
   information.
2. Alert you that it __will__ make changes to any current Kerberos or KDC
   configuration. __Any existing Kerberos KDC will be replaced__, however the
   original files will be backed up.
3. Install Kerberos-related packages via Yum, if they're not already installed.
4. Generate the necessary configuration files and create a local MIT Kerberos
   KDC (usually under /var/kerberos/krb5kdc).
5. Generate a system-wide Kerberos configuration file (/etc/krb5.conf).
6. Create a Kerberos principal for Cloudera Manager (cloudera-scm/admin) so CM
   can be configured to manage Kerberos principals and keytabs for various CDH
   services.
7. ~~If running on the same host as Cloudera Manager, generate the proper~
   configuration files and keytabs for the CM server
   (/etc/cloudera-scm-server/{cmf.principal, cmf.keytab}).~~
   daisukebe has changed the behavior for configuring Kerberos with Cloudera Manager 5.1 (and above). Then this script just generates a principal as __cloudera-scm/admin__ for CM with a password as '__cloudera__'.
8. Start the Kerberos KDC and Admin services.
9. Create the following principals for a start: hdfs@HADOOP (password: hdfs), hive@HADOOP (password: hive).
10. Tell you where to find the documentation for enabling Kerberos in Cloudera
   Manager, and what to do next.

## What it does not

This utility installs the packages only on the host this runs. If there are
two or more servers in the cluster, install the client libraries on the other hosts:

yum install krb5-workstation

## Running

1. Decide if you need to modify any settings.

   In most cases, nothing needs to be changed. The hostname of the machine,
   however, is absolutely critical to proper functionality of Kerberos. The
   provisioned KDC will use (by default) the hostname produced by `hostname -f`
   and the domain name produced by `hostname -d`. The KDC realm is `CLOUDERA`.
   If you desperately want to change things, see the first few variables in
   `configure_krb5.sh`.

   If you want to adjust the generated configuration files, edit the templates
   found in the `tmpl` directory.

2. Run the following, as root:

    ./configure_krb5.sh

3. Follow directions to configure Cloudera Manager's Kerberos support, and
   configure services.
4. Create any additional Kerberos principals for users for testing.

## License

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

Copyright Cloudera 2013
