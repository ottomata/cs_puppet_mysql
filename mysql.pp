
# downloads and unpacks binary versions of
# mysql that we might want to run.  These saved in
# /usr/local/mysqls/${version}.
# /usr/local/mysql is a symlink to the default
# version we want to use.
# Currently we are downloading and unpacking
#  mysql-5.0.87-d10-ourdelta65 and mariadb-5.1.39-maria-beta-ourdelta67
class mysql_binary_installations
{
  file { "/usr/local/mysqls":
    ensure => "directory",
    owner  => "mysql",
    group  => "mysql",
    mode   => 0755,
  }

  # download and unpack the MySQL 5.0 version to
  # /usr/local/mysqls/...
  $mysql_50_file = "mysql-5.0.87-d10-ourdelta65-Linux-x86_64.tar.gz"
  $mysql_50_url  = "http://mirror.ourdelta.org/bin/$mysql_50_file"
  exec { "mysql_50_install":
    command   => "/usr/bin/wget -c -P /usr/local/src $mysql_50_url &&
                  /bin/tar xpzf /usr/local/src/$mysql_50_file -C /usr/local/mysqls",
    path      => "/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin",
    cwd       => "/usr/local/src",
    creates   => "/usr/local/mysqls/mysql-5.0.87-d10-ourdelta65-Linux-x86_64/bin/mysqld",
    timeout   => 600,
    require   => [File["/usr/local/mysqls"], User['mysql']],
  }

  # download and unpack the MySQL 5.0 version to
  # /usr/local/mysqls/...
  $mysql_50p_file = "Percona-Server-5.0.92-b23.85.Linux.x86_64.tar.gz"
  $mysql_50p_url  = "http://www.percona.com/downloads/Percona-Server-5.0/Percona-Server-5.0.92-b23/Linux/binary/$mysql_50p_file"
  exec { "mysql_50p_install":
    command   => "/usr/bin/wget -c -P /usr/local/src $mysql_50p_url &&
                  /bin/tar xpzf /usr/local/src/$mysql_50p_file -C /usr/local/mysqls",
    path      => "/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin",
    cwd       => "/usr/local/src",
    creates   => "/usr/local/mysqls/Percona-Server-5.0.92-b23.85.Linux.x86_64/bin/mysqld",
    timeout   => 600,
    require   => [File["/usr/local/mysqls"], User['mysql']],
  }

  # symlink mysqld for Percona (50p) cos it lives in another location and we don't want to
  # break our mysql_instance definition
  file { "/usr/local/mysqls/Percona-Server-5.0.92-b23.85.Linux.x86_64/bin/mysqld":
    ensure    => "/usr/local/mysqls/Percona-Server-5.0.92-b23.85.Linux.x86_64/libexec/mysqld",
    require   => [Exec["mysql_50p_install"]];
  }


  # download and unpack the Percona MySQL 5.1 version to
  # /usr/local/mysqls/...
  $mysql_51p_file = "Percona-Server-5.1.61-rel13.2-430.Linux.x86_64.tar.gz"
  $mysql_51p_url  = "http://www.percona.com/redir/downloads/Percona-Server-5.1/Percona-Server-5.1.61-13.2/binary/linux/x86_64/$mysql_51p_file"
  exec { "mysql_51p_install":
    command   => "/usr/bin/wget -c -P /usr/local/src $mysql_51p_url &&
                  /bin/tar xpzf /usr/local/src/$mysql_51p_file -C /usr/local/mysqls",
    path      => "/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin",
    cwd       => "/usr/local/src",
    creates   => "/usr/local/mysqls/Percona-Server-5.1.61-rel13.2-430.Linux.x86_64/libexec/mysqld",
    timeout   => 600,
    require   => [File["/usr/local/mysqls"], User['mysql']],
  }

  # symlink mysqld for Percona (51p) cos it lives in another location and we don't want to
  # break our mysql_instance definition
  file { "/usr/local/mysqls/Percona-Server-5.1.61-rel13.2-430.Linux.x86_64/bin/mysqld":
    ensure    => "/usr/local/mysqls/Percona-Server-5.1.61-rel13.2-430.Linux.x86_64/libexec/mysqld",
    require   => [Exec["mysql_51p_install"]];
  }

  # symlink /usr/local/mysql to 5.0 for now.
  file { "/usr/local/mysql":
    ensure => "/usr/local/mysqls/mysql-5.0.87-d10-ourdelta65-Linux-x86_64",
  }

  include maatkit_package
  include mylvmbackup_package
}



# Define: mysql_instance
define mysql_instance (
  $version = '5.0.92',
  # path to mysql instance directory.  Default is /mysql/$name
  $path   = false,
  $port   = 3306,

  # set replication_enabled to false if you don't want to enable binary logging
  $replication_enabled = true,

  # set read_only to true if you want this instance to be read_only
  $read_only = false,
  $expire_log_days = '4',
  $replicate_ignore_table = [],
  $replicate_ignore_db    = [],
  $replicate_do_table     = [],
  $replicate_do_db        = [],

  # the following are puppet configurable
  # MySQL server startup variables
  # and their defaults.  These will only work if you use the
  # mysql.conf.erb file
  $tmp_table_size                  = '512M',
  $max_heap_table_size             = '512M',
  $max_tmp_tables                  = '64',

  $join_buffer_size                = '3M',
  $read_buffer_size                = '4M',
  $sort_buffer_size                = '4M',

  $table_cache                     = '2100',
  $table_definition_cache          = '512',
  $open_files_limit                = '3000',

  $thread_cache_size               = '256',
  $thread_concurrency              = '8',

  $query_cache_size                = '128M',
  $query_cache_limit               = '4M',
  $tmp_table_size                  = '512M',
  $read_rnd_buffer_size            = '1M',

  $key_buffer_size                 = '200M',
  $myisam_sort_buffer_size         = '4M',
  $myisam_max_sort_file_size       = '512M',

  $max_connections                 = '300',

  $innodb_file_per_table           = '1',
  $innodb_status_file              = '0',
  $innodb_support_xa               = '0',
  $innodb_flush_log_at_trx_commit  = '0',
  $innodb_buffer_pool_size         = '512M',
  $innodb_log_file_size            = '1024M',
  $innodb_flush_method             = 'O_DIRECT',
  $innodb_thread_concurrency       = '0',
  $innodb_concurrency_tickets      = '100',
  $innodb_doublewrite              = '1'
  )
{
  #  ensure that mysql binaries have been installed at /usr/local/mysqls
  include mysql_binary_installations
  # install the custom mysqlstatus script
  # so that zabbix can easily find out various
  # stats about mysql instances.
  include mysqlstatus

  # Figure out where the instance path for this instance is.
  # by default it will be /mysql/$name
  $instance_path = $path ? {
    false        => "/mysql/${name}",
    default      => $path,
  }


  # select the MySQL basedir based on version
  $basedir = $version ? {
    "5.0.87" => "/usr/local/mysqls/mysql-5.0.87-d10-ourdelta65-Linux-x86_64",
    "5.0.92" => "/usr/local/mysqls/Percona-Server-5.0.92-b23.85.Linux.x86_64",
    "5.1.39" => "/usr/local/mysqls/mariadb-5.1.39-maria-beta-ourdelta67-Linux-x86_64",
    "5.1.61" => "/usr/local/mysqls/Percona-Server-5.1.61-rel13.2-430.Linux.x86_64",
    default  => "/usr",   # default to a global MySQL installation
  }

  # ensure that the required directories in $instance_path exist
  file { ["$instance_path",
          "$instance_path/data",
          "$instance_path/binlog",
          "$instance_path/log",
          "$instance_path/tmp"]:
    ensure    => "directory",
    owner     => "mysql",
    group     => "mysql",
    mode      => 4770,
    require   => [Class["mysql_binary_installations"], User["mysql"], Group["mysql"]]
  }

  # render a mysql.conf file into the instance_path.
  file { "$instance_path/mysql.conf":
    content   => template("db/mysql.conf.erb"),
    require   => [File[$instance_path], File["$instance_path/data"], File["$instance_path/binlog"], File["$instance_path/log"], File["$instance_path/tmp"], Class["mysql_binary_installations"]],
  }

  # configure a supervisor .ini file for this mysql instance
  supervisor_program { "mysql_${name}":
    command           => "$basedir/bin/mysqld --defaults-file=$instance_path/mysql.conf",
    user              => 'root',    # mysql will start itself as mysql, we want to use root to actually start the proc
    ensure            => 'running',
    log_directory     => "$instance_path/log",
    subscribe_program => false,  # do not autorestart mysql
    retries           => 0,   # don't try to start mysql a bunch of times if there are problems
    startsecs         => 30,  # mysql needs to stay up for 30 seconds for supervisor to consider it up.
    stopwait          => 30,  # wait for 30 seconds before forcefully killing mysql on shutdown
    require           => File["$instance_path/mysql.conf"],
  }

}


# Manages MySQL users.
# a user is specifically a user@hostname.
# If the permissions for the user@hostname do
# not match the desired ones here, permissions
# will be revoked and then the new ones regranted.
# This ensures that a user will have only the
# desired permissions.  (The namevar is arbitrary
# and is used only for uniquely identifying
# the define when it is used.)
#
# Usage:
#   mysql_user { namevar: user => "'username'@'host',  access =>  "read", password => "encrypted_pw" }
# Example:
#   mysql_user { readonly_user:
#     user     => "'readonly'@'192.168.0.%'",
#     access   => "read",
#     password => "xxxxxxxxxx",
#   }
#
#  access has 4 shortcuts defined:
#   "all"         == ALL PRIVILEGES
#   "write"       == DELETE, INSERT, SELECT, UPDATE
#   "read"        == PROCESS, REPLICATION CLIENT, SELECT
#   "replication" == REPLICATION CLIENT, REPLICATION SLAVE
#
# Otherwise, the string you pass in for access will be used as the MySQL permissions to grant.
# Make SURE that the access string you pass is either one of these shortcuts, OR that
# it exactly matches the permissions that will be printed out by mk-show-grants once
# the MySQL user has been created.  This define uses mk-show-grants to
# check that the specified permissions match what MySQL currently has.  If they don't
# match exactly, the GRANT statement will be run every puppet run.
#
define mysql_user(
  $ensure       = "present",
  $socket       = '/var/run/mysql/mysql.sock',
  $access       = "write",
  $database     = "*",
  $user,
  $password)
{
  # default paths for following execs
  Exec { path => "/bin:/usr/bin" }

  # permission aliases
  $permissions = $access ? {
    "all"         => "ALL PRIVILEGES",
    # if this is global write, give extra permissions
    "write"       => $database ? {
      '*'     => "DELETE, EXECUTE, INSERT, PROCESS, REPLICATION CLIENT, SELECT, UPDATE",
      default => "DELETE, EXECUTE, INSERT, SELECT, UPDATE"
    },
    # if this is global read, give extra permissions
    "read"        => $database ? {
      '*'     => "EXECUTE, PROCESS, REPLICATION CLIENT, SELECT",
      default => "EXECUTE, SELECT, UPDATE"
    },
    "replication" => "REPLICATION CLIENT, REPLICATION SLAVE",
    default     => $access,
  }


  # this shell command will return 0 if the mysql user grant we are looking for currently exists.
  $grant_exists_command = "mk-show-grants --socket ${socket} | grep \"${user}\" | grep \"GRANT ${permissions}\" | grep '`${database}`.\\*'"

  case $ensure {
    # if we want the MySQL user to be present.
    "present": {
      # exec for revoking and granting MySQL user permissions.
      exec { "mysql_grant_user_${name}":
        # first attempt to revoke all privileges for this user, then grant the desired permissions.
        command => "$grant_exists_command && mysql -v --socket ${socket} -e \"REVOKE ${permissions} ON ${database}.* FROM ${user};\"; mysql -v --socket ${socket} -e \"GRANT ${permissions} ON ${database}.* TO ${user} IDENTIFIED BY PASSWORD '${password}';\" &> /tmp/mysql_user_exec.out",
        # only execute this command if $socket is a socket file
        onlyif  => "test -S ${socket}",
        # only execute this if this user does not already have this permission.
        unless  => $grant_exists_command,
        require => Package["maatkit"],
      }
    }
    "absent": {
      # exec for droping the MySQL user
      exec { "mysql_drop_user_${name}":
        command => "mysql --socket ${socket} -e \"REVOKE ${permissions} ON ${database}.* FROM ${user}\"",
        # only execute this if $socket is a socket file AND the user exists.
        onlyif  => "test -S ${socket} && $grant_exists_command",
        require => Package["maatkit"],
      }
    }
  }

}


