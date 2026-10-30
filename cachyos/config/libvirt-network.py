#!/usr/bin/env python3
"""Next-boot NAT setup: no guest creation, XML replacement or firewall bypass."""

import ipaddress
import json
import subprocess
import sys
import xml.etree.ElementTree as ET


def run(*args):
    result = subprocess.run(args, capture_output=True, text=True, timeout=60,
                            env={"PATH": "/usr/bin:/bin", "LC_ALL": "C"})
    if result.returncode:
        raise RuntimeError(f"{' '.join(args)}: {result.stderr.strip() or result.stdout.strip()}")
    return result.stdout.strip()


def virsh(*args):
    return run("virsh", "--connect", "qemu:///system", *args)


def host_networks(bridge=None):
    networks = []
    for route in json.loads(run("ip", "-json", "-4", "route", "show", "table", "all")):
        if (bridge is not None and route.get("dev") == bridge) or route.get("dst", "default") == "default":
            continue
        networks.append(ipaddress.ip_network(route["dst"], strict=False))
    return networks


def network_definition(subnet):
    network = ET.Element("network")
    ET.SubElement(network, "name").text = "default"
    ET.SubElement(network, "forward", mode="nat")
    ET.SubElement(network, "bridge", name="virbr0", stp="on", delay="0")
    ip = ET.SubElement(network, "ip", address=str(subnet[1]), netmask=str(subnet.netmask))
    dhcp = ET.SubElement(ip, "dhcp")
    ET.SubElement(dhcp, "range", start=str(subnet[2]), end=str(subnet[-2]))
    return ET.tostring(network, encoding="unicode")


def main():
    names = virsh("net-list", "--all", "--name").splitlines()
    if "default" not in names:
        links = json.loads(run("ip", "-json", "link", "show"))
        if any(link["ifname"] == "virbr0" for link in links):
            raise RuntimeError("virbr0 already exists without a default libvirt network; review manually")
        occupied = host_networks()
        candidates = (ipaddress.ip_network(f"192.168.{index}.0/24") for index in range(122, 255))
        subnet = next((candidate for candidate in candidates
                       if not any(candidate.overlaps(other) for other in occupied)), None)
        if subnet is None:
            raise RuntimeError("No unused private NAT subnet found; configure the network manually")
        # libvirt validates and persists the XML itself; never write its live state.
        import tempfile
        with tempfile.NamedTemporaryFile(mode="w", suffix=".xml") as source:
            source.write(network_definition(subnet))
            source.flush()
            virsh("net-define", source.name)

    network = ET.fromstring(virsh("net-dumpxml", "default"))
    forward = network.find("forward")
    if forward is None or forward.get("mode") != "nat":
        raise RuntimeError("Existing default network is not NAT; preserved unchanged, review manually")
    bridge = network.find("bridge")
    occupied = host_networks(bridge.get("name") if bridge is not None else None)
    for ip in network.findall("ip"):
        if ip.get("family", "ipv4") != "ipv4":
            continue
        subnet = ipaddress.ip_network(f"{ip.attrib['address']}/{ip.get('netmask', ip.get('prefix', '24'))}", strict=False)
        if any(subnet.overlaps(other) for other in occupied):
            raise RuntimeError(f"Default NAT subnet {subnet} overlaps a host/VPN route; preserved, review manually")
    # Starting first ensures a failure cannot silently mark a broken NAT ready.
    if "default" not in virsh("net-list", "--name").splitlines():
        virsh("net-start", "default")
    virsh("net-autostart", "default")
    print("Default NAT is active and autostarts; existing network XML and firewall policy were preserved.")


if __name__ == "__main__":
    try:
        main()
    except (RuntimeError, OSError, ValueError, KeyError, ET.ParseError, subprocess.SubprocessError) as error:
        sys.exit(f"libvirt network: {error}")
