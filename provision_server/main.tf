terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

# Configure the DigitalOcean Provider
provider "digitalocean" {
  token = var.do_token
}

data "digitalocean_vpc" "example" {
  name     = "example"
}


# Create a web server
resource "digitalocean_droplet" "master" {
  name     = "master"
  size     = "s-4vcpu-8gb"
  image    = "ubuntu-22-04-x64"
  region   = "NYC3"
  vpc_uuid = data.digitalocean_vpc.example.id
  ssh_keys = [data.digitalocean_ssh_key.k8s-key.id]
}
# Create a web server
resource "digitalocean_droplet" "worker1" {
  name     = "worker1"
  size     = "s-4vcpu-8gb"
  image    = "ubuntu-22-04-x64"
  region   = "NYC3"
  vpc_uuid = data.digitalocean_vpc.example.id
  ssh_keys = [data.digitalocean_ssh_key.k8s-key.id]
}
# Create a web server
resource "digitalocean_droplet" "worker2" {
  name     = "worker2"
  size     = "s-4vcpu-8gb"
  image    = "ubuntu-22-04-x64"
  region   = "NYC3"
  vpc_uuid = data.digitalocean_vpc.example.id
  ssh_keys = [data.digitalocean_ssh_key.k8s-key.id]
}


# # Create a new SSH key
# resource "digitalocean_ssh_key" "droplet-ssh-key" {
#   name       = "k8s-key"
#   public_key = file(var.ssh_key)                     //file(var.ssh_key)
# }

// getting ssh key from digital ocean
data "digitalocean_ssh_key" "k8s-key" {
  name = "wsl2_key"
}


//this will give ipv4 address of our newly created droplets
output "master_ip" {
  value = digitalocean_droplet.master.ipv4_address
}
output "worker1_ip" {
  value = digitalocean_droplet.worker1.ipv4_address
}
output "worker2_ip" {
  value = digitalocean_droplet.worker2.ipv4_address
}


resource "digitalocean_firewall" "master_firewall" {
  name        = "k8s-firewall-master"
  droplet_ids = [digitalocean_droplet.master.id]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

// ports for master and worker nodes
  inbound_rule {
    protocol = "tcp"
    port_range = "6443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }
  inbound_rule {
    protocol = "tcp"
    port_range = "2379-2380"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }
  inbound_rule {
    protocol = "tcp"
    port_range = "10250"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }
  inbound_rule {
    protocol = "tcp"
    port_range = "10259"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }
  inbound_rule {
    protocol = "tcp"
    port_range = "10257"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }
  // inbound rule for weavenet
  inbound_rule {
    protocol = "tcp"
    port_range = "6783"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }




  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "icmp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

resource "digitalocean_firewall" "worker_firewall" {
  name        = "k8s-firewall-worker"
  droplet_ids = [digitalocean_droplet.worker1.id, digitalocean_droplet.worker2.id]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

// ports for master and worker nodes
    inbound_rule {
        protocol = "tcp"
        port_range = "10250"
        source_addresses = ["0.0.0.0/0", "::/0"]
    }
    inbound_rule {
        protocol = "tcp"
        port_range = "30000-32767"
        source_addresses = ["0.0.0.0/0", "::/0"]
    }
    inbound_rule {
    protocol = "tcp"
    port_range = "6783"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }



  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "icmp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
    }
}