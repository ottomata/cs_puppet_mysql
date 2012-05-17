

# Creates a supervisor program .ini file in /etc/supervisord/.
# Requires that the supervisor class is included.
# Also handles stopping and starting of the program via supervisorctl.
#
# Usage:
#
#  supervisor_program { "query_workerd":
#    command     => "php /var/www/alpha/tasks/query_workerd.php",
#    environment => 'cs_environment=alpha',
#    user        => $web_user,
#    ensure      => 'running',
#  }
#
# If $log_directory is not specified, logs will be stored in
# /var/log/supervisord/$name.
#
# $subscribe_program = false means that the service will not be restarted if it's .ini file changes.
# $subscribe_program = true means that it will
# $subscribe_program = anything else will subscribe the service to that resource
#   you can use this to subscribe the program to another config file, if needed.
#
# Stolen and modified from https://github.com/plathrop/puppet-module-supervisor
define supervisor_program(
  $command,
  $enable=true,
  $ensure=running,
  $numprocs=1,
  $priority="",
  $autorestart="unexpected",
  $startsecs=1,
  $retries=3,
  $exitcodes="0,2",
  $stopsignal="TERM",
  $stopwait=10,
  $user="",
  $group="",
  $redirect_stderr=false,
  $stdout_logfile_maxsize="250MB",
  $stdout_logfile_keep=10,
  $stderr_logfile_maxsize="250MB",
  $stderr_logfile_keep=10,
  $environment="",
  $chdir="",
  $umask="",
  $log_directory=false,
  $subscribe_program=true)
{
    $autostart = $ensure ? {
      running => true,
      stopped => false,
      default => false
    }

    # Figure out where logfiles for this process should go.
    # By default they will go into /var/log/supervisord/name
    $log_path = $log_directory ? {
      false        => "/var/log/supervisord/${name}",
      default      => $log_directory,
    }

    # because multiple supervisor programs are allowed to
    # use the same log directory, we can't use
    # a file resource to make sure the directory exists.
    # Doing so would end up in a duplicate
    # resource definition error.
    # Instead, use an exec.
    case $ensure {
      purged: {
        exec { "${name}_log_directory":
          command => "/bin/rm -rf $log_path",
          onlyif  => "/usr/bin/test -d $log_path",
        }
      }
      default: {
        $log_owner = $user ? {
          "" => "root",
          default => $user,
        }
        $log_group = $group ? {
          "" => "root",
          default => $group,
        }

        exec { "${name}_log_directory":
          command => "/bin/mkdir -m 644 -p $log_path && /bin/chown $log_owner:$log_group $log_path",
          creates => $log_path,
        }
      }
    }

    # install a supervisord .ini program file
    file { "/etc/supervisord/${name}.ini":
      content => $enable ? {
        true    => template("common/supervisor_program.ini.erb"),
        default => undef
      },
      ensure => $enable ? {
        false   => absent,
        default => undef
      },
      require => [Class["supervisor"], Exec["${name}_log_directory"]],
    }

    # This exec will only be run when the supervisord/ .ini
    # file is changed.  This forces supervisord to re-read
    # the config files in /etc/supervisord/
    exec { "supervisor_update_${name}":
        command => "/usr/bin/supervisorctl update",
        logoutput => on_failure,
        refreshonly => true,
        subscribe => File["/etc/supervisord/${name}.ini"],
        require => Class["supervisor"],
    }


    
    # The name used to refer to this supervisor program in supervisorctl
    # varies based on how the program has been grouped.  There are 3 
    # cases.
    # 1:    (program_name)                  - no grouping has been done
    # 2:    (program_name:)program_name_##  - grouping by process count (numprocs in .ini config file)
    # 3:    (group_name:program_name)       - grouping done by a supervisor [group] section
    # 4:    group_name:program_name_##      - 4th case -- eeg, not handled by this define right now.
    # This regexp finds the appropriate name for supervisorctl commands
    $program_name_command = "/usr/bin/supervisorctl avail | /usr/bin/perl -ne 'print \$1,$/ if /^([^\s]*?${name}:{0,1})/' | sed -n '1p'"
    $supervisord_log_file = "/var/log/supervisord/supervisord.log"

    # as long as we don't purge this supervisor program,
    # then create a 'service' that will make puppet
    # manage supervisorctl when running the program.
    service { "supervisor_service_${name}":
      ensure    => $ensure ? {
        purged  => 'stopped',
        default => $ensure,
      },
      provider  => base,
      restart   => "echo \"Puppet restarting $($program_name_command)\"        >> $supervisord_log_file && /usr/bin/supervisorctl restart $($program_name_command) >> $supervisord_log_file",
      start     => "echo \"Puppet starting $($program_name_command)\"          >> $supervisord_log_file && /usr/bin/supervisorctl start   $($program_name_command) >> $supervisord_log_file",
      status    => "echo \"Puppet getting status of $($program_name_command)\" >> $supervisord_log_file && /usr/bin/supervisorctl status | grep $($program_name_command) | sed -n '1p' | grep -q 'RUNNING'",
      stop      => "echo \"Puppet stopping $($program_name_command)\"          >> $supervisord_log_file && /usr/bin/supervisorctl stop    $($program_name_command) >> $supervisord_log_file",
      require   => [Class["supervisor"], Exec["${name}_log_directory"], File["/etc/supervisord/${name}.ini"]],
    }

    case $subscribe_program {
      true: {
        Service["supervisor_service_${name}"] { subscribe => File["/etc/supervisord/${name}.ini"] }
      }
      "": {
        # do nothing
      }
      false: {
         # do nothing
      }
      default: {
        Service["supervisor_service_${name}"] { subscribe => $subscribe_program }
      }
    }
}


# Define: supervisor_group
# Parameters:
# $programs
#
define supervisor_group ($programs)
{
  $group_name = $name

  file { "/etc/supervisord/$group_name.ini":
    content => template('common/supervisor_group.ini.erb'),
  }
}