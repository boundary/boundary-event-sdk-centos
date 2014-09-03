Boundary Event SDK Development
==============================


Uses Vagrant to create a CentOS 6.5 VM and install with the latest
release of the Boundary Event SDK

## Requirements
- Vagrant (http://www.vagrantup.com/downloads.html) version 1.6.3 or later
- Virtualbox (https://www.virtualbox.org/wiki/Downloads) version 4.3.10 or later

## Disable SDK Installation

To disable the installation of the sdk run the following command in the cloned git respository:

```
touch no-boundary-sdk
```

To enable,after disabling run the following command in the cloned git respository:

```
rm no-boundary-sdk
```

## Basic Commands

Simple command line operations for those not familar with using Vagrant

### Startup

This command starts a virtual machine and if the box `centos-6.5` is not already on the system
it will be downloaded.

1. Start the virtual machine

    ```$ vagrant up```

### Suspend
Saves the state of the VM on disk so it can be resumed later

1. Safely shutdown the virtual machine

     ```$ vagrant suspend```

### Resume
Restarts VM from its preserved state.

1. Resume a previously shutdown virtual machine

     ```$ vagrant resume```

### Shutdown
Completely destroys the VM and it state, but it also
frees up all the disk usage associated with the VM instance.

1. Halt and destroy the virtual machine

     ```$ vagrant destroy```

## Building the Boundary Event SDK

1. Start the virtual machine:

     ```$ vagrant up```

2. Login to the virtual machine:

     ``` vagrant ssh```

3. Change directory the Boundary Event SDK source tree:

     ```[vagrant@localhost ~]$ cd boundary-event-sdk```

4. Setup the build environment:

     ```[vagrant@localhost ~]$ bash setup.sh```

5. Build and assembly distribution:

     ```[vagrant@localhost ~]$ mvn assembly:assembly```
