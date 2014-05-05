Boundary Event SDK Development Appliance
Uses vagrant to create a CentOS 6.5 VM and install with the latest
release of the Boundary Event SDK

## Requirements
- Vagrant (http://www.vagrantup.com/downloads.html)
- Virtualbox (https://www.virtualbox.org/wiki/Downloads)

## Instructions

### Startup

1. Start the virtual machine ```$ vagrant up```

### Suspend
Saves the state of the VM on disk so it can be resumed later

1. ```vagrant suspend```

### Resume
Restarts VM from its preserved state.

1. ```vagrant resume```

### Shutdown
Completely destroys the VM and it state, but it also
frees up all the disk usage associated with the VM instance.

1. Stop and destroy the virtual machine ```$ vagrant destroy```

## Building the Boundary Event SDK

1. 






