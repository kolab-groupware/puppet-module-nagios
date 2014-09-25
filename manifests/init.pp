# Nagios configuration module

class nagios {

    @file { "/etc/nagios/nrpe.cfg":
        ensure => file,
        mode => "644",
        owner => "root",
        group => "root",
        source => [
            "puppet://$server/private/$environment/nagios/client/nrpe.cfg.$hostname",
            "puppet://$server/private/$environment/nagios/client/nrpe.cfg",
            "puppet://$server/files/nagios/client/nrpe.cfg.$hostname",
            "puppet://$server/files/nagios/client/nrpe.cfg",
            "puppet://$server/modules/nagios/client/nrpe.cfg"
        ],
        notify => Service["nrpe"],
        noop => false,
        require => Package["nrpe"]
    }

    @file { "/etc/nagios/nsca.cfg":
        ensure => file,
        mode => "644",
        owner => "root",
        group => "root",
        source => [
            "puppet://$server/private/$environment/nagios/server/nsca.cfg.$hostname",
            "puppet://$server/private/$environment/nagios/server/nsca.cfg",
            "puppet://$server/files/nagios/server/nsca.cfg.$hostname",
            "puppet://$server/files/nagios/server/nsca.cfg",
            "puppet://$server/modules/nagios/server/nsca.cfg"
        ],
        notify => Service["nsca"],
        require => Package["nsca"]
    }

    @file { "/etc/nagios/send_nsca.cfg":
        ensure => file,
        mode => "640",
        owner => "root",
        group => "munin",
        source => [
            "puppet://$server/private/$environment/nagios/client/send_nsca.cfg.$hostname",
            "puppet://$server/private/$environment/nagios/client/send_nsca.cfg",
            "puppet://$server/files/nagios/client/send_nsca.cfg.$hostname",
            "puppet://$server/files/nagios/client/send_nsca.cfg",
            "puppet://$server/modules/nagios/client/send_nsca.cfg"
        ],
        require => Package["nsca-client"]
    }

    @package { [
            "nagios",
            "nagios-plugins-nrpe",
            "nrpe",
            "nsca",
            "nsca-client"
        ]:
        ensure => installed,
        noop => false
    }

    case $os {
        "CentOS", "RedHat": {
            case $osmajorver {
                "4": {
                    @package { [
                            "nagios-plugins",
                            "nagios-plugins-apt",
                            "nagios-plugins-breeze",
                            "nagios-plugins-by_ssh",
                            "nagios-plugins-check_sip",
                            "nagios-plugins-dhcp",
                            "nagios-plugins-dig",
                            "nagios-plugins-disk",
                            "nagios-plugins-disk_smb",
                            "nagios-plugins-dns",
                            "nagios-plugins-dummy",
                            "nagios-plugins-file_age",
                            "nagios-plugins-flexlm",
                            "nagios-plugins-game",
                            "nagios-plugins-hpjd",
                            "nagios-plugins-http",
                            "nagios-plugins-icmp",
                            "nagios-plugins-ide_smart",
                            "nagios-plugins-ldap",
                            "nagios-plugins-linux_raid",
                            "nagios-plugins-load",
                            "nagios-plugins-log",
                            "nagios-plugins-mailq",
                            "nagios-plugins-mrtg",
                            "nagios-plugins-mrtgtraf",
                            "nagios-plugins-mysql",
                            "nagios-plugins-nagios",
                            "nagios-plugins-nt",
                            "nagios-plugins-ntp",
                            "nagios-plugins-nwstat",
                            "nagios-plugins-oracle",
                            "nagios-plugins-overcr",
                            "nagios-plugins-perl",
                            "nagios-plugins-pgsql",
                            "nagios-plugins-ping",
                            "nagios-plugins-procs",
                            "nagios-plugins-real",
                            "nagios-plugins-rpc",
                            "nagios-plugins-sensors",
                            "nagios-plugins-smtp",
                            "nagios-plugins-snmp",
                            "nagios-plugins-ssh",
                            "nagios-plugins-swap",
                            "nagios-plugins-tcp",
                            "nagios-plugins-time",
                            "nagios-plugins-udp",
                            "nagios-plugins-ups",
                            "nagios-plugins-users",
                            "nagios-plugins-wave"
                        ]:
                        ensure => installed,
                        tag => "nagios-plugins"
                    }
                }
                default: {
                    @package { "nagios-plugins-all":
                        ensure => installed,
                        tag => "nagios-plugins"
                    }
                }
            }
        }
        default: {
            @package { "nagios-plugins-all":
                ensure => installed,
                tag => "nagios-plugins"
            }
        }
    }

    @service { "nrpe":
        enable => true,
        ensure => running,
        noop => false,
        require => [
            Package["nrpe"],
            File["/etc/nagios/nrpe.cfg"]
        ]
    }

    @service { "nagios":
        ensure => running,
        hasrestart => true,
        enable => true
    }

    define plugin($enable) {
        file { "/usr/lib64/nagios/plugins/$name":
            ensure => file,
            mode => "755",
            owner => "root",
            group => "root",
            noop => false,
            source => [
                "puppet://$server/private/$environment/nagios/plugins/$name.$hostname",
                "puppet://$server/private/$environment/nagios/plugins/$name",
                "puppet://$server/files/nagios/plugins/$name.$hostname",
                "puppet://$server/files/nagios/plugins/$name",
                "puppet://$server/modules/nagios/plugins/$name"
            ]
        }

        case $name {
                "check_activesync": {
                        file { "/usr/lib64/nagios/plugins/$name.data":
                            ensure => file,
                            mode => "644",
                            owner => "root",
                            group => "root",
                            noop => false,
                            source => "puppet://$server/modules/nagios/plugins/$name.data"
                        }
                    }
            }
    }

    @service { "nsca":
        enable => true,
        ensure => running,
        require => [
            Package["nsca"],
            File["/etc/nagios/nsca.cfg"]
        ]
    }

    class server inherits nagios {

        Nagios_host <<| tag == $domain |>>
        Nagios_service <<| tag == $domain |>>

        realize(
                Package["nagios"],
                Package["nagios-plugins-nrpe"],
                Package["nrpe"],
                Service["nagios"],
                Service["nrpe"]
            )

        Package <| tag == "nagios-plugins" |>

        class files inherits nagios {
            realize(
                    File["/etc/nagios/nrpe.cfg"],
                    Package["nagios"],
                    Package["nagios-plugins-nrpe"],
                    Package["nrpe"],
                    Service["nagios"],
                    Service["nrpe"]
                )

            Package <| tag == "nagios-plugins" |>

            file { "/etc/nagios/":
                ensure => directory,
                source => "puppet://$server/private/$environment/nagios/server/",
                recurse => true,
                force => true,
                notify => Service["nagios"]
            }
        }

        class nsca inherits nagios {
            realize(
                Package["nsca"],
                File["/etc/nagios/nsca.cfg"],
                Service["nsca"]
            )
        }
    }

    class client inherits nagios {

        @@nagios_host { "$fqdn":
            ensure => present,
            alias => "$hostname",
            address => "$ipaddress",
            use => "generic-host",
            tag => $domain
        }

        class active inherits nagios::client {
            realize(
                Package["nsca-client"],
                File["/etc/nagios/send_nsca.cfg"]
            )
        }

        class passive inherits nagios::client {
            realize(
                    File["/etc/nagios/nrpe.cfg"],
                    Package["nrpe"],
                    Service["nrpe"]
                )

            Package <| tag == "nagios-plugins" |>

        }

        # These are aliases for active/passive clients, by application name.

        class nsca {
            include nagios::client::passive
        }

        class nrpe {
            include nagios::client::active
        }
    }
}
