terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "~> 2.9"
    }
  }
}

provider "proxmox" {
  pm_api_url      = "https://IP.Address/"
  pm_user         = "username"
  pm_password     = "password"    
  pm_tls_insecure = true
}

resource "proxmox_lxc" "dynamic_container" {
  target_node = "host"
  ostemplate  = "local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst"
  memory      = 1024
  swap        = 1024
  cores       = 2
  
  features {
    nesting = true
  }

  rootfs {
    storage = "local-lvm"
    size    = "8G"
  }

  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = "dhcp"
  }

  ssh_public_keys = file("/home/idk/.ssh/id_rsa.pub")

  password = "password"
  onboot   = false
}

output "lxc_vmid" {
  value = proxmox_lxc.dynamic_container.vmid
}




