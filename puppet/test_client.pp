# Build system
package { [ "cmake" , "make", "nasm", "libssl-dev" ] :
  ensure => present,
}

# Compilers
package { [ "clang-6.0", "gcc-7", "g++-multilib", "c++-7-aarch64-linux-gnu" ] :
  ensure => present,
}

# Test system dependencies
package { [ "qemu-system", "lcov", "grub2", "openjdk-8-jre-headless" ] :
  ensure => present,
}

# Test tools
package { [ "arping", "httperf", "hping3", "iperf3", "dnsmasq", "dosfstools", "xorriso" ] :
        ensure => present,
}

package { [ "python3-pip", "python3-setuptools", "python3-dev" ] :
  ensure => present,
}

$pip_packages = [ "wheel", "jsonschema", "conan", "psutil", "ws4py" ]
package { $pip_packages :
  ensure => present,
  provider => pip3,
}

service { 'dnsmasq' :
        ensure => running,
        require => Package['dnsmasq'],
}

# This requires the bridge to be configured
exec { "modify-dnsmasq" :
        path => "/opt/puppetlabs/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin",
        command => 'echo "interface=bridge43 \ndhcp-range=10.0.0.2,10.0.0.200,12h\nport=0" >> /etc/dnsmasq.conf',
        unless => 'grep -q bridge43 /etc/dnsmasq.conf',
        notify => Service['dnsmasq'],
}

# Only need python2 until NaCl is ported to python 3
package { "python" :
  ensure => present,
}
